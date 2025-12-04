"""
Middleware compartido para reportar métricas a Stats API desde servicios externos
Versión: 1.0 (Compatible con Stats API v2.1)
"""

import time
import uuid
import logging
import asyncio
from typing import Callable, Optional, Set
import httpx

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

logger = logging.getLogger(__name__)


class StatsReporterMiddleware(BaseHTTPMiddleware):
    """
    Middleware para reportar métricas automáticamente al Stats API
    
    Cada servicio (fraude, textosql, rag) usa este middleware para
    enviar sus métricas centralizadas al Stats API sin bloquear requests.
    """
    
    def __init__(
        self,
        app: ASGIApp,
        service_name: str,
        stats_api_url: str = "http://stats-api:8003",
        timeout: float = 2.0,
        excluded_paths: Optional[Set[str]] = None
    ):
        """
        Args:
            app: Aplicación ASGI
            service_name: Nombre del servicio ("fraude", "textosql", "rag")
            stats_api_url: URL base del Stats API
            timeout: Timeout para envío de métricas (default 2s)
            excluded_paths: Paths a excluir del reporte (ej: /health, /docs)
        """
        super().__init__(app)
        self.service_name = service_name
        self.stats_api_url = stats_api_url.rstrip('/')
        self.timeout = timeout
        self.excluded_paths = excluded_paths or {'/health', '/docs', '/redoc', '/openapi.json'}
        
        logger.info(
            f"✅ StatsReporterMiddleware inicializado para '{service_name}' → {stats_api_url}"
        )
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Interceptar request, ejecutar, y reportar métricas"""
        
        # Verificar si el path debe ser excluido
        if request.url.path in self.excluded_paths:
            return await call_next(request)
        
        # Generar ID único para el request
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        
        # Capturar datos del request
        start_time = time.time()
        endpoint = str(request.url.path)
        method = request.method
        user_agent = request.headers.get("user-agent", "")
        client_ip = self._get_client_ip(request)
        request_size = await self._get_request_size(request)
        
        # Ejecutar el request real
        response = None
        error_message = None
        error_type = None
        
        try:
            response = await call_next(request)
        except Exception as e:
            logger.error(f"Request failed: {e}")
            error_message = str(e)
            error_type = "internal_error"
            
            # Crear response de error
            from fastapi.responses import JSONResponse
            response = JSONResponse(
                status_code=500,
                content={"error": "Internal server error", "request_id": request_id}
            )
        
        # Calcular métricas
        response_time = time.time() - start_time
        status_code = response.status_code if response else 500
        response_size = self._get_response_size(response)
        
        # Detectar tipo de error por status code
        if status_code >= 400 and not error_type:
            if status_code == 408 or status_code == 504:
                error_type = "timeout"
            elif status_code >= 500:
                error_type = "server_error"
            elif status_code >= 400:
                error_type = "client_error"
        
        # Determinar funcionalidad y si es AI query
        functionality = self._detect_functionality(endpoint)
        is_ai_query = self._should_count_as_ai_query(endpoint, method)
        
        # Obtener datos adicionales del request.state (si el endpoint los setea)
        model_used = getattr(request.state, 'model_used', None)
        query_complexity_score = getattr(request.state, 'query_complexity_score', None)
        fraud_risk_score = getattr(request.state, 'fraud_risk_score', None)
        sql_execution_time = getattr(request.state, 'sql_execution_time', None)
        database_name = getattr(request.state, 'database_name', None)
        
        # Agregar headers útiles al response
        if response:
            response.headers["X-Request-ID"] = request_id
            response.headers["X-Response-Time"] = f"{response_time:.3f}s"
            response.headers["X-AI-Query"] = "true" if is_ai_query else "false"
        
        # Enviar métricas al Stats API (async, no bloquea)
        asyncio.create_task(
            self._send_metrics_to_stats(
                service_name=self.service_name,
                endpoint=endpoint,
                method=method,
                status_code=status_code,
                response_time=response_time,
                request_size_bytes=request_size,
                response_size_bytes=response_size,
                client_ip=client_ip,
                user_agent=user_agent,
                request_id=request_id,
                is_ai_query=is_ai_query,
                functionality=functionality,
                model_used=model_used,
                error_message=error_message,
                error_type=error_type,
                query_complexity_score=query_complexity_score,
                fraud_risk_score=fraud_risk_score,
                sql_execution_time=sql_execution_time,
                database_name=database_name
            )
        )
        
        return response
    
    async def _send_metrics_to_stats(self, **metric_data):
        """
        Enviar métricas al Stats API de forma asíncrona
        
        NO debe levantar excepciones que rompan el servicio.
        Si falla, solo loguea el error.
        """
        try:
            url = f"{self.stats_api_url}/api/stats/metrics/log"
            
            async with httpx.AsyncClient(timeout=self.timeout) as client:
                response = await client.post(url, json=metric_data)
                
                if response.status_code == 200:
                    logger.debug(f"✅ Métrica enviada: {metric_data['request_id']}")
                else:
                    logger.warning(
                        f"⚠️ Stats API respondió {response.status_code}: {response.text}"
                    )
                    
        except httpx.TimeoutException:
            logger.warning(f"⚠️ Timeout enviando métrica a Stats API (request_id: {metric_data['request_id']})")
        except httpx.ConnectError:
            logger.warning(f"⚠️ No se pudo conectar a Stats API en {self.stats_api_url}")
        except Exception as e:
            logger.error(f"❌ Error enviando métrica a Stats API: {e}")
    
    def _get_client_ip(self, request: Request) -> str:
        """Obtener IP del cliente considerando proxies"""
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip
        
        if hasattr(request.client, 'host'):
            return request.client.host
        
        return "unknown"
    
    async def _get_request_size(self, request: Request) -> int:
        """Obtener tamaño del request en bytes"""
        try:
            content_length = request.headers.get("content-length")
            if content_length:
                return int(content_length)
            
            if hasattr(request, '_body'):
                return len(request._body)
            
            return 0
        except:
            return 0
    
    def _get_response_size(self, response: Response) -> int:
        """Obtener tamaño del response en bytes"""
        try:
            if hasattr(response, 'body'):
                if isinstance(response.body, bytes):
                    return len(response.body)
                elif isinstance(response.body, str):
                    return len(response.body.encode('utf-8'))
            
            content_length = response.headers.get("content-length")
            if content_length:
                return int(content_length)
            
            return 0
        except:
            return 0
    
    def _should_count_as_ai_query(self, endpoint: str, method: str) -> bool:
        """
        Determina si un request debe contar como query AI
        
        Criterios (según especificación Stats API v2.1):
        - Solo POST requests
        - Endpoints de demos AI (fraude/predict, textosql/query, rag/query, rag/upload)
        - Excluir: stats, admin, metrics, health
        """
        # Solo POST
        if method != "POST":
            return False
        
        endpoint_lower = endpoint.lower()
        
        # Excluir endpoints administrativos
        excluded_patterns = [
            "/api/stats/",
            "/api/admin/",
            "/api/metrics/",
            "/health",
            "/docs",
            "/redoc"
        ]
        
        for pattern in excluded_patterns:
            if pattern in endpoint_lower:
                return False
        
        # Incluir endpoints de AI
        ai_patterns = [
            "/predict",              # Fraude: /predict_single_transaction
            "/api/fraude/predict",   # Fraude explícito
            "/query/ask",            # TextoSQL: /query/ask, /query/ask-dynamic
            "/query/execute",        # TextoSQL: /query/execute
            "/api/textosql/query",   # TextoSQL explícito
            "/api/rag/query",        # RAG query
            "/api/rag/upload",       # RAG upload
            "/upload",               # RAG: /upload
            "/query"                 # RAG: /query
        ]
        
        for pattern in ai_patterns:
            if pattern in endpoint_lower:
                return True
        
        return False
    
    def _detect_functionality(self, endpoint: str) -> str:
        """Detectar funcionalidad basada en endpoint"""
        endpoint = endpoint.lower()
        
        if "/fraud" in endpoint or "/fraude" in endpoint:
            return "fraud_detection"
        elif "/textosql" in endpoint or "/sql" in endpoint or "/query" in endpoint:
            return "text_to_sql"
        elif "/rag" in endpoint or "/documents" in endpoint or "/upload" in endpoint:
            return "rag_documents"
        elif "/chat" in endpoint or "/bot" in endpoint or "/proxy" in endpoint:
            return "chatbot"
        else:
            return "general"
