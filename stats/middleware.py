"""
Middleware para capturar automáticamente métricas de todas las requests
VERSIÓN 2.0 - Cumple con especificación completa del frontend
"""

import json
import time
import uuid
import re
from typing import Callable
import logging

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

logger = logging.getLogger(__name__)

class MetricsMiddleware(BaseHTTPMiddleware):
    """Middleware para capturar métricas automáticamente"""
    
    def __init__(self, app: ASGIApp, db_manager=None):
        super().__init__(app)
        self.db_manager = db_manager
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """Interceptar y medir todas las requests"""
        
        # Generar ID único para la request
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        
        # Marca de tiempo de inicio
        start_time = time.time()
        
        # Información de la request
        endpoint = str(request.url.path)
        endpoint_base = self._extract_endpoint_base(endpoint)  # NUEVO: endpoint sin parámetros
        method = request.method
        user_agent = request.headers.get("user-agent", "")
        client_ip = self._get_client_ip(request)
        
        # Tamaño de la request
        request_size = await self._get_request_size(request)
        
        # Variables para response
        response = None
        error_message = None
        error_type = None
        functionality = None
        model_used = None
        
        try:
            # Ejecutar request
            response = await call_next(request)
            
            # Obtener información específica si está disponible
            functionality = getattr(request.state, 'functionality', None)
            model_used = getattr(request.state, 'model_used', None)
            
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
        
        # Calcular tiempo de respuesta
        response_time = time.time() - start_time
        
        # Tamaño de la response
        response_size = self._get_response_size(response)
        
        # Status code
        status_code = response.status_code if response else 500
        
        # Detectar tipo de error por status code
        if status_code >= 400 and not error_type:
            if status_code == 408 or status_code == 504:
                error_type = "timeout"
            elif status_code >= 500:
                error_type = "server_error"
            elif status_code >= 400:
                error_type = "client_error"
        
        # Detectar funcionalidad por endpoint
        if not functionality:
            functionality = self._detect_functionality(endpoint)
        
        # Agregar headers útiles
        if response:
            response.headers["X-Request-ID"] = request_id
            response.headers["X-Response-Time"] = f"{response_time:.3f}s"
        
        # Guardar métricas en base de datos (asíncrono)
        if self.db_manager:
            try:
                await self._save_metrics(
                    endpoint=endpoint,
                    endpoint_base=endpoint_base,  # NUEVO: endpoint sin parámetros
                    method=method,
                    functionality=functionality,
                    model_used=model_used,
                    request_size_bytes=request_size,
                    response_size_bytes=response_size,
                    response_time=response_time,
                    status_code=status_code,
                    error_message=error_message,
                    error_type=error_type,
                    user_agent=user_agent,
                    client_ip=client_ip,
                    request_id=request_id
                )
            except Exception as e:
                logger.error(f"Failed to save metrics: {e}")
        
        return response
    
    def _get_client_ip(self, request: Request) -> str:
        """Obtener IP del cliente considerando proxies"""
        # Verificar headers de proxy
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        
        real_ip = request.headers.get("x-real-ip")
        if real_ip:
            return real_ip
        
        # IP directa
        if hasattr(request.client, 'host'):
            return request.client.host
        
        return "unknown"
    
    async def _get_request_size(self, request: Request) -> int:
        """Obtener tamaño de la request en bytes"""
        try:
            content_length = request.headers.get("content-length")
            if content_length:
                return int(content_length)
            
            # Si no hay content-length, estimar por el body
            if hasattr(request, '_body'):
                return len(request._body)
            
            return 0
        except:
            return 0
    
    def _get_response_size(self, response: Response) -> int:
        """Obtener tamaño de la response en bytes"""
        try:
            if hasattr(response, 'body'):
                if isinstance(response.body, bytes):
                    return len(response.body)
                elif isinstance(response.body, str):
                    return len(response.body.encode('utf-8'))
            
            # Estimar por headers
            content_length = response.headers.get("content-length")
            if content_length:
                return int(content_length)
            
            return 0
        except:
            return 0
    
    def _detect_functionality(self, endpoint: str) -> str:
        """Detectar funcionalidad basada en el endpoint (v2.0 naming)"""
        endpoint = endpoint.lower()
        
        # Nombres estandarizados según especificación v2.0
        if "/fraud" in endpoint or "/fraude" in endpoint:
            return "fraud_detection"  # Cambio: fraud-detection → fraud_detection
        elif "/textosql" in endpoint or "/sql" in endpoint or "/texto" in endpoint:
            return "text_to_sql"  # Cambio: textosql → text_to_sql
        elif "/rag" in endpoint or "/documents" in endpoint:
            return "rag_documents"  # Cambio: rag → rag_documents
        elif "/chat" in endpoint or "/bot" in endpoint:
            return "chatbot"  # Sin cambio
        elif "/stats" in endpoint or "/metrics" in endpoint:
            return "stats"  # Endpoint de estadísticas (no cuenta como funcionalidad de negocio)
        elif "/health" in endpoint:
            return "model_health"  # Health checks
        else:
            return "general"
    
    def _extract_endpoint_base(self, endpoint: str) -> str:
        """Extraer endpoint base sin parámetros (ej: /api/fraud/{id} → /api/fraud)"""
        # Remover query parameters
        endpoint = endpoint.split('?')[0]
        
        # Remover segmentos numéricos o UUIDs (parámetros de ruta)
        # Ejemplos:
        # /api/fraud/123 → /api/fraud
        # /api/stats/alerts/abc-123-def → /api/stats/alerts
        # /api/textosql/execute/session_456 → /api/textosql/execute
        
        parts = endpoint.split('/')
        cleaned_parts = []
        
        for part in parts:
            # Si es un UUID, número puro, o contiene muchos números/guiones (ID)
            if part and not (
                re.match(r'^[0-9]+$', part) or  # Solo números
                re.match(r'^[0-9a-f-]{32,}$', part, re.IGNORECASE) or  # UUID-like
                re.match(r'^[a-z_]+_[0-9]+$', part, re.IGNORECASE)  # session_123, alert_456
            ):
                cleaned_parts.append(part)
        
        return '/'.join(cleaned_parts)
    
    async def _save_metrics(self, **kwargs):
        """Guardar métricas en la base de datos"""
        try:
            await self.db_manager.insert_api_log(kwargs)
        except Exception as e:
            logger.error(f"Error saving API metrics: {e}")
            # No re-lanzar la excepción para no afectar la response

def add_functionality_context(request: Request, functionality: str, model_used: str = None):
    """Función helper para agregar contexto de funcionalidad a una request"""
    request.state.functionality = functionality
    if model_used:
        request.state.model_used = model_used

def add_complexity_score(request: Request, score: int):
    """Función helper para agregar score de complejidad (TextoSQL)"""
    request.state.query_complexity_score = score

def add_fraud_score(request: Request, score: float):
    """Función helper para agregar score de riesgo de fraude"""
    request.state.fraud_risk_score = score

def add_sql_execution_time(request: Request, execution_time: float):
    """Función helper para agregar tiempo de ejecución SQL"""
    request.state.sql_execution_time = execution_time

def add_database_name(request: Request, database_name: str):
    """Función helper para agregar nombre de base de datos utilizada"""
    request.state.database_name = database_name