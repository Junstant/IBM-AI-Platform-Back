"""
🚀 STATS API V2.0 ENDPOINTS
Endpoints que cumplen con la especificación completa del frontend

Cambios respecto a versión anterior:
- Nombres de endpoints estandarizados según especificación
- Formato de respuesta unificado (UTC timestamps con 'Z')
- Métricas con percentiles (p50, p95, p99)
- Vista unificada de servicios (LLM models + APIs)
- Activity log system
"""

import logging
import json
import re
from datetime import datetime, timedelta
from typing import List, Optional
from functools import lru_cache

import psutil
from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

# ============================================================================
# DEPENDENCY INJECTION
# ============================================================================

_db_manager = None

def set_db_manager(db):
    """
    Establecer db_manager globalmente.
    Debe llamarse desde app.py después de inicializar db_manager.
    """
    global _db_manager
    _db_manager = db
    logger.info("✅ db_manager inyectado en endpoints v2.0")

async def get_db():
    """
    Dependency para inyectar db_manager en endpoints.
    Usado por FastAPI para inyectar automáticamente en cada request.
    """
    if not _db_manager:
        raise HTTPException(status_code=503, detail="Database not initialized")
    return _db_manager

# ============================================================================
# PYDANTIC MODELS (Response Schemas)
# ============================================================================

class DashboardSummaryCard(BaseModel):
    """Tarjeta resumen del dashboard - Especificación Frontend v2.0"""
    active_models: int = Field(..., description="Número de modelos LLM activos")
    error_models: int = Field(..., description="Número de modelos LLM con error")
    active_apis: int = Field(..., description="Número de APIs activas")
    error_apis: int = Field(..., description="Número de APIs con error")
    daily_queries: int = Field(..., description="Queries totales últimas 24h")
    daily_successful_queries: int = Field(..., description="Queries exitosas últimas 24h")
    daily_failed_queries: int = Field(..., description="Queries fallidas últimas 24h")
    avg_response_time: float = Field(..., description="Tiempo promedio de respuesta en segundos")
    global_accuracy: float = Field(..., description="Precisión global (0-100)")
    timestamp: str = Field(..., description="Timestamp ISO 8601 UTC")

class ServiceStatus(BaseModel):
    """Estado de un servicio (modelo LLM o API endpoint) - Especificación Frontend v2.0"""
    service_name: str = Field(..., description="Nombre interno del servicio")
    display_name: str = Field(..., description="Nombre para mostrar en UI")
    service_type: str = Field(..., description="llm | fraud | textosql | rag")
    status: str = Field(..., description="online | offline | error | degraded")
    uptime_seconds: Optional[int] = Field(None, description="Tiempo en línea en segundos")
    total_requests: int = Field(..., description="Total de requests")
    successful_requests: int = Field(..., description="Requests exitosos")
    failed_requests: int = Field(..., description="Requests fallidos")
    avg_latency_ms: Optional[float] = Field(None, description="Latencia promedio en ms")
    last_check: str = Field(..., description="Última verificación (UTC ISO 8601)")
    metadata: Optional[dict] = Field(None, description="Información adicional (port, version, etc.)")

class SystemResources(BaseModel):
    """Recursos del sistema en tiempo real"""
    timestamp: str = Field(..., description="Timestamp de lectura (UTC ISO 8601)")
    cpu_percent: float = Field(..., description="Uso de CPU (%)")
    memory_used_mb: float = Field(..., description="Memoria RAM usada (MB)")
    memory_total_mb: float = Field(..., description="Memoria RAM total (MB)")
    memory_percent: float = Field(..., description="Uso de memoria (%)")
    disk_used_gb: float = Field(..., description="Disco usado (GB)")
    disk_total_gb: float = Field(..., description="Disco total (GB)")
    disk_percent: float = Field(..., description="Uso de disco (%)")
    network_sent_mb: Optional[float] = Field(None, description="Datos enviados (MB)")
    network_received_mb: Optional[float] = Field(None, description="Datos recibidos (MB)")

class HourlyTrend(BaseModel):
    """Tendencia horaria de métricas"""
    hour: str = Field(..., description="Hora (UTC ISO 8601)")
    functionality: str = Field(..., description="Funcionalidad (fraud_detection, text_to_sql, etc.)")
    total_requests: int = Field(..., description="Total de requests")
    successful_requests: int = Field(..., description="Requests exitosas")
    failed_requests: int = Field(..., description="Requests fallidas")
    avg_response_time_ms: float = Field(..., description="Tiempo de respuesta promedio (ms)")
    median_response_time_ms: Optional[float] = Field(None, description="Mediana (p50)")
    p95_response_time_ms: Optional[float] = Field(None, description="Percentil 95")
    p99_response_time_ms: Optional[float] = Field(None, description="Percentil 99")
    success_rate: float = Field(..., description="Tasa de éxito (%)")
    error_rate: float = Field(..., description="Tasa de error (%)")

class FunctionalityPerformance(BaseModel):
    """Performance por funcionalidad"""
    functionality: str = Field(..., description="Nombre de la funcionalidad")
    total_requests: int = Field(..., description="Total de requests")
    avg_response_time_ms: float = Field(..., description="Tiempo de respuesta promedio (ms)")
    success_rate: float = Field(..., description="Tasa de éxito (%)")
    error_rate: float = Field(..., description="Tasa de error (%)")
    median_response_time_ms: Optional[float] = Field(None, description="Mediana (p50)")
    p95_response_time_ms: Optional[float] = Field(None, description="Percentil 95")

class RecentError(BaseModel):
    """Error reciente"""
    timestamp: str = Field(..., description="Timestamp del error (UTC ISO 8601)")
    endpoint: str = Field(..., description="Endpoint donde ocurrió")
    functionality: str = Field(..., description="Funcionalidad afectada")
    status_code: int = Field(..., description="Código HTTP de error")
    error_message: Optional[str] = Field(None, description="Mensaje de error")
    error_type: Optional[str] = Field(None, description="Tipo de error (timeout, server_error, etc.)")
    request_id: Optional[str] = Field(None, description="ID único de la request")

class ActiveAlert(BaseModel):
    """Alerta activa del sistema - v2.1 con campo id para frontend"""
    alert_id: int = Field(..., description="ID numérico de la alerta")
    id: str = Field(..., description="ID como string (para frontend)")
    timestamp: str = Field(..., description="Timestamp de creación (UTC ISO 8601)")
    severity: str = Field(..., description="info | warning | critical | success")
    title: str = Field(..., description="Título de la alerta")
    message: str = Field(..., description="Descripción de la alerta")
    component: Optional[str] = Field(None, description="Componente afectado")
    component_name: Optional[str] = Field(None, description="Nombre del componente")

class ActivityLog(BaseModel):
    """Registro de actividad del sistema"""
    activity_id: str = Field(..., description="ID único de la actividad")
    timestamp: str = Field(..., description="Timestamp (UTC ISO 8601)")
    activity_type: str = Field(..., description="Tipo (model_health_check, high_traffic, etc.)")
    severity: str = Field(..., description="info | warning | critical | success")
    title: str = Field(..., description="Título del evento")
    description: str = Field(..., description="Descripción detallada")
    user: str = Field(..., description="Usuario/sistema que generó el evento")
    metadata: Optional[dict] = Field(None, description="Datos adicionales")

class DetailedMetrics(BaseModel):
    """Métricas detalladas con percentiles"""
    total_requests: int = Field(..., description="Total de requests")
    successful_requests: int = Field(..., description="Requests exitosas")
    failed_requests: int = Field(..., description="Requests fallidas")
    success_rate: float = Field(..., description="Tasa de éxito (%)")
    error_rate: float = Field(..., description="Tasa de error (%)")
    avg_response_time_ms: float = Field(..., description="Tiempo de respuesta promedio (ms)")
    median_response_time_ms: float = Field(..., description="Mediana (p50)")
    p95_response_time_ms: float = Field(..., description="Percentil 95")
    p99_response_time_ms: float = Field(..., description="Percentil 99")
    top_endpoints: List[dict] = Field(..., description="Endpoints más usados")
    slowest_endpoints: List[dict] = Field(..., description="Endpoints más lentos")

class AlertResolveResponse(BaseModel):
    """Respuesta de resolución de alerta"""
    success: bool = Field(..., description="Si la operación fue exitosa")
    message: str = Field(..., description="Mensaje de resultado")
    alert_id: int = Field(..., description="ID de la alerta resuelta")

# ============================================================================
# ROUTER CONFIGURATION
# ============================================================================

router = APIRouter(prefix="/api/stats", tags=["Stats V2.0"])

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def to_utc_iso(dt: datetime) -> str:
    """Convertir datetime a formato UTC ISO 8601 con 'Z'"""
    if dt is None:
        return None
    # Asegurar que es UTC
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=None)
    return dt.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'

@lru_cache(maxsize=100)
def calculate_success_rate(successful: int, total: int) -> float:
    """Calcular tasa de éxito en porcentaje"""
    if total == 0:
        return 0.0
    return round((successful / total) * 100, 2)

# ============================================================================
# ENDPOINTS V2.0
# ============================================================================

@router.get("/dashboard/summary", response_model=DashboardSummaryCard)
async def get_dashboard_summary(db = Depends(get_db)):
    """
    📊 Dashboard Summary (4 Cards)
    
    Retorna resumen de 4 indicadores principales:
    - Modelos LLM activos
    - APIs activas
    - Queries totales (24h)
    - Precisión promedio
    """
    try:
        # 1. Contar modelos LLM activos y con error
        models_query = """
        SELECT 
            COUNT(*) FILTER (WHERE status = 'active' OR status = 'online') as active_count,
            COUNT(*) FILTER (WHERE status = 'error' OR status = 'offline') as error_count
        FROM ai_models_metrics
        WHERE model_type = 'llm'
        """
        models_result = await db.fetch_one(models_query)
        active_models = models_result['active_count'] if models_result else 0
        error_models = models_result['error_count'] if models_result else 0
        
        # 2. Contar APIs activas y con error (basado en health checks recientes)
        apis_query = """
        SELECT 
            COUNT(DISTINCT functionality) FILTER (
                WHERE timestamp >= NOW() - INTERVAL '5 minutes'
            ) as active_count,
            COUNT(DISTINCT functionality) FILTER (
                WHERE timestamp >= NOW() - INTERVAL '5 minutes'
                  AND status_code >= 500
            ) as error_count
        FROM api_performance_logs
        WHERE functionality IN ('fraud_detection', 'text_to_sql', 'rag_documents')
        """
        apis_result = await db.fetch_one(apis_query)
        active_apis = apis_result['active_count'] if apis_result else 0
        error_apis = apis_result['error_count'] if apis_result else 0
        
        # 3. Queries últimas 24h (total, exitosas, fallidas)
        # SOLO CONTAR QUERIES AI (is_ai_query = TRUE) - v2.1
        queries_query = """
        SELECT 
            COUNT(*) as total,
            COUNT(*) FILTER (WHERE status_code < 400) as successful,
            COUNT(*) FILTER (WHERE status_code >= 400) as failed,
            AVG(response_time) as avg_response_time_ms
        FROM api_performance_logs
        WHERE timestamp >= NOW() - INTERVAL '24 hours'
          AND is_ai_query = TRUE
        """
        queries_result = await db.fetch_one(queries_query)
        
        daily_queries = queries_result['total'] if queries_result else 0
        daily_successful = queries_result['successful'] if queries_result else 0
        daily_failed = queries_result['failed'] if queries_result else 0
        avg_response_ms = queries_result['avg_response_time_ms'] if queries_result else 0
        
        # Convertir a segundos (forzar a float para evitar error Decimal/float)
        avg_response_time = round(float(avg_response_ms) / 1000.0, 3) if avg_response_ms else 0.0
        
        # 4. Precisión global (success rate)
        global_accuracy = 0.0
        if daily_queries > 0:
            global_accuracy = calculate_success_rate(daily_successful, daily_queries)
        
        return DashboardSummaryCard(
            active_models=active_models,
            error_models=error_models,
            active_apis=active_apis,
            error_apis=error_apis,
            daily_queries=daily_queries,
            daily_successful_queries=daily_successful,
            daily_failed_queries=daily_failed,
            avg_response_time=avg_response_time,
            global_accuracy=global_accuracy,
            timestamp=to_utc_iso(datetime.utcnow())
        )
        
    except Exception as e:
        logger.error(f"Error in get_dashboard_summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/services/status", response_model=List[ServiceStatus])
async def get_services_status(db = Depends(get_db)):
    """
    🔍 Services Status (Unified View)
    
    Retorna estado unificado de todos los servicios:
    - Modelos LLM (gemma-2b, gemma-4b, mistral-7b, etc.)
    - API Endpoints (fraud detection, textosql, rag, chatbot)
    """
    try:
        query = """
        SELECT 
            service_name,
            display_name,
            service_type,
            status,
            last_health_check,
            uptime_seconds,
            total_requests,
            successful_requests,
            failed_requests,
            avg_latency_ms,
            metadata
        FROM services_unified
        ORDER BY service_type, service_name
        """
        
        results = await db.fetch_all(query)
        
        services = []
        for row in results:
            success_rate = None
            if row['total_requests'] and row['total_requests'] > 0:
                success_rate = calculate_success_rate(
                    row['successful_requests'],
                    row['total_requests']
                )
            
            # Convertir metadata de string JSON a dict si es necesario
            metadata = row['metadata']
            if isinstance(metadata, str):
                try:
                    metadata = json.loads(metadata)
                except (json.JSONDecodeError, TypeError):
                    metadata = {}
            
            services.append(ServiceStatus(
                service_name=row['service_name'],
                display_name=row['display_name'],
                service_type=row['service_type'],
                status=row['status'] or 'unknown',
                uptime_seconds=row['uptime_seconds'],
                total_requests=row['total_requests'] or 0,
                successful_requests=row['successful_requests'] or 0,
                failed_requests=row['failed_requests'] or 0,
                avg_latency_ms=row['avg_latency_ms'],
                last_check=to_utc_iso(row['last_health_check']),
                metadata=metadata
            ))
        
        return services
        
    except Exception as e:
        logger.error(f"Error in get_services_status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/system/resources", response_model=SystemResources)
async def get_system_resources():
    """
    💻 System Resources (Real-time)
    
    Retorna recursos del sistema en tiempo real usando psutil:
    - CPU usage
    - Memory usage
    - Disk usage
    - Network I/O
    """
    try:
        # CPU
        cpu_percent = psutil.cpu_percent(interval=0.1)
        
        # Memory
        memory = psutil.virtual_memory()
        memory_used_mb = memory.used / (1024 * 1024)
        memory_total_mb = memory.total / (1024 * 1024)
        
        # Disk
        disk = psutil.disk_usage('/')
        disk_used_gb = disk.used / (1024 * 1024 * 1024)
        disk_total_gb = disk.total / (1024 * 1024 * 1024)
        
        # Network (opcional - puede fallar en algunos sistemas)
        network_sent_mb = None
        network_received_mb = None
        try:
            net_io = psutil.net_io_counters()
            network_sent_mb = net_io.bytes_sent / (1024 * 1024)
            network_received_mb = net_io.bytes_recv / (1024 * 1024)
        except:
            pass
        
        return SystemResources(
            timestamp=to_utc_iso(datetime.utcnow()),
            cpu_percent=round(cpu_percent, 2),
            memory_used_mb=round(memory_used_mb, 2),
            memory_total_mb=round(memory_total_mb, 2),
            memory_percent=round(memory.percent, 2),
            disk_used_gb=round(disk_used_gb, 2),
            disk_total_gb=round(disk_total_gb, 2),
            disk_percent=round(disk.percent, 2),
            network_sent_mb=round(network_sent_mb, 2) if network_sent_mb else None,
            network_received_mb=round(network_received_mb, 2) if network_received_mb else None
        )
        
    except Exception as e:
        logger.error(f"Error in get_system_resources: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/trends/hourly", response_model=List[HourlyTrend])
async def get_hourly_trends(
    hours: int = Query(24, description="Número de horas hacia atrás", ge=1, le=168),
    db = Depends(get_db)
):
    """
    📈 Hourly Trends
    
    Retorna tendencias horarias con percentiles.
    Parámetros:
    - hours: Número de horas hacia atrás (default: 24, max: 168)
    """
    try:
        query = """
        SELECT 
            hour,
            functionality,
            total_requests,
            successful_requests,
            failed_requests,
            avg_response_time_ms,
            median_response_time_ms,
            p95_response_time_ms,
            p99_response_time_ms,
            success_rate,
            error_rate
        FROM detailed_metrics_hourly
        WHERE hour >= NOW() - INTERVAL '%s hours'
        ORDER BY hour DESC, functionality
        LIMIT 500
        """ % hours
        
        results = await db.fetch_all(query)
        
        trends = []
        for row in results:
            trends.append(HourlyTrend(
                hour=to_utc_iso(row['hour']),
                functionality=row['functionality'],
                total_requests=row['total_requests'],
                successful_requests=row['successful_requests'],
                failed_requests=row['failed_requests'],
                avg_response_time_ms=row['avg_response_time_ms'],
                median_response_time_ms=row['median_response_time_ms'],
                p95_response_time_ms=row['p95_response_time_ms'],
                p99_response_time_ms=row['p99_response_time_ms'],
                success_rate=row['success_rate'],
                error_rate=row['error_rate']
            ))
        
        return trends
        
    except Exception as e:
        logger.error(f"Error in get_hourly_trends: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/functionality/performance", response_model=List[FunctionalityPerformance])
async def get_functionality_performance(db = Depends(get_db)):
    """
    🎯 Functionality Performance
    
    Retorna performance por funcionalidad (fraud_detection, text_to_sql, rag_documents, chatbot).
    """
    try:
        query = """
        SELECT 
            functionality,
            COUNT(*) as total_requests,
            ROUND(AVG(response_time)::numeric, 2) as avg_response_time_ms,
            ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_time)::numeric, 2) as median_response_time_ms,
            ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time)::numeric, 2) as p95_response_time_ms,
            COUNT(*) FILTER (WHERE status_code < 400) as successful_requests,
            COUNT(*) FILTER (WHERE status_code >= 400) as failed_requests
        FROM api_performance_logs
        WHERE timestamp >= NOW() - INTERVAL '24 hours'
          AND functionality IN ('fraud_detection', 'text_to_sql', 'rag_documents', 'chatbot')
        GROUP BY functionality
        ORDER BY total_requests DESC
        """
        
        results = await db.fetch_all(query)
        
        performances = []
        for row in results:
            total = row['total_requests']
            successful = row['successful_requests']
            failed = row['failed_requests']
            
            success_rate = calculate_success_rate(successful, total)
            error_rate = calculate_success_rate(failed, total)
            
            performances.append(FunctionalityPerformance(
                functionality=row['functionality'],
                total_requests=total,
                avg_response_time_ms=row['avg_response_time_ms'],
                success_rate=success_rate,
                error_rate=error_rate,
                median_response_time_ms=row['median_response_time_ms'],
                p95_response_time_ms=row['p95_response_time_ms']
            ))
        
        return performances
        
    except Exception as e:
        logger.error(f"Error in get_functionality_performance: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/errors/recent", response_model=List[RecentError])
async def get_recent_errors(
    limit: int = Query(20, description="Número de errores a retornar", ge=1, le=100),
    db = Depends(get_db)
):
    """
    ⚠️ Recent Errors
    
    Retorna errores recientes (status_code >= 400).
    Parámetros:
    - limit: Número de errores (default: 20, max: 100)
    """
    try:
        query = """
        SELECT 
            timestamp,
            endpoint,
            functionality,
            status_code,
            error_message,
            error_type,
            request_id
        FROM api_performance_logs
        WHERE status_code >= 400
          AND timestamp >= NOW() - INTERVAL '7 days'
        ORDER BY timestamp DESC
        LIMIT %s
        """ % limit
        
        results = await db.fetch_all(query)
        
        errors = []
        for row in results:
            errors.append(RecentError(
                timestamp=to_utc_iso(row['timestamp']),
                endpoint=row['endpoint'],
                functionality=row['functionality'] or 'unknown',
                status_code=row['status_code'],
                error_message=row['error_message'],
                error_type=row['error_type'],
                request_id=row['request_id']
            ))
        
        return errors
        
    except Exception as e:
        logger.error(f"Error in get_recent_errors: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/alerts/active", response_model=List[ActiveAlert])
async def get_active_alerts(db = Depends(get_db)):
    """
    🚨 Active Alerts
    
    Retorna alertas activas del sistema (no resueltas).
    """
    try:
        query = """
        SELECT 
            id as alert_id,
            CAST(id AS TEXT) as id,
            created_at as timestamp,
            CASE 
                WHEN severity >= 4 THEN 'critical'
                WHEN severity = 3 THEN 'warning'
                WHEN severity = 2 THEN 'info'
                ELSE 'success'
            END as severity,
            title,
            message,
            component,
            component_name
        FROM system_alerts
        WHERE resolved = false
        ORDER BY created_at DESC
        LIMIT 50
        """
        
        results = await db.fetch_all(query)
        
        alerts = []
        for row in results:
            alerts.append(ActiveAlert(
                alert_id=row['alert_id'],
                id=row['id'],
                timestamp=to_utc_iso(row['timestamp']),
                severity=row['severity'],
                title=row['title'],
                message=row['message'],
                component=row['component'],
                component_name=row['component_name']
            ))
        
        return alerts
        
    except Exception as e:
        logger.error(f"Error in get_active_alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/alerts/{alert_id}/resolve", response_model=AlertResolveResponse)
async def resolve_alert(alert_id: int, db = Depends(get_db)):
    """
    ✅ Resolve Alert
    
    Marca una alerta como resuelta.
    Parámetros:
    - alert_id: ID de la alerta a resolver
    """
    try:
        query = """
        UPDATE system_alerts
        SET resolved = true, updated_at = NOW()
        WHERE id = $1
        RETURNING id
        """
        
        result = await db.fetch_one(query, (alert_id,))
        
        if not result:
            raise HTTPException(status_code=404, detail=f"Alert {alert_id} not found")
        
        return AlertResolveResponse(
            success=True,
            message=f"Alert {alert_id} resolved successfully",
            alert_id=alert_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in resolve_alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/activity/recent", response_model=List[ActivityLog])
async def get_recent_activity(
    limit: int = Query(10, description="Número de actividades a retornar", ge=1, le=50),
    db = Depends(get_db)
):
    """
    📜 Recent Activity
    
    Retorna actividades recientes del sistema.
    Parámetros:
    - limit: Número de actividades (default: 10, max: 50)
    """
    try:
        query = """
        SELECT 
            activity_id,
            timestamp,
            activity_type,
            severity,
            title,
            description,
            user,
            metadata
        FROM activity_log_view
        LIMIT %s
        """ % limit
        
        results = await db.fetch_all(query)
        
        activities = []
        for row in results:
            # Convertir metadata de string JSON a dict si es necesario
            metadata = row['metadata']
            if isinstance(metadata, str):
                try:
                    metadata = json.loads(metadata)
                except (json.JSONDecodeError, TypeError):
                    metadata = {}
            
            activities.append(ActivityLog(
                activity_id=row['activity_id'],
                timestamp=to_utc_iso(row['timestamp']),
                activity_type=row['activity_type'],
                severity=row['severity'],
                title=row['title'],
                description=row['description'],
                user=row['user'],
                metadata=metadata
            ))
        
        return activities
        
    except Exception as e:
        logger.error(f"Error in get_recent_activity: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/metrics/detailed", response_model=DetailedMetrics)
async def get_detailed_metrics(
    timeframe: str = Query('24h', regex='^(24h|7days|30days)$'),
    funcionalidad: str = Query('all'),
    db = Depends(get_db)
):
    """
    📊 Detailed Metrics (Advanced)
    
    Retorna métricas detalladas con percentiles y top/slowest endpoints.
    Incluye:
    - Métricas globales con percentiles
    - Top 10 endpoints más usados
    - Top 10 endpoints más lentos
    """
    try:
        # Calcular intervalo según timeframe
        interval = {
            '24h': '24 hours',
            '7days': '7 days',
            '30days': '30 days'
        }[timeframe]
        
        # Filtrar por funcionalidad si no es 'all'
        func_filter = "" if funcionalidad == 'all' else f"AND functionality = '{funcionalidad}'"
        
        # 1. Métricas globales
        global_query = f"""
        SELECT 
            COUNT(*) as total_requests,
            COUNT(*) FILTER (WHERE status_code < 400) as successful_requests,
            COUNT(*) FILTER (WHERE status_code >= 400) as failed_requests,
            ROUND(AVG(response_time)::numeric, 2) as avg_response_time_ms,
            ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_time)::numeric, 2) as median_response_time_ms,
            ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time)::numeric, 2) as p95_response_time_ms,
            ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time)::numeric, 2) as p99_response_time_ms
        FROM api_performance_logs
        WHERE timestamp >= NOW() - INTERVAL '{interval}'
          {func_filter}
        """
        
        global_result = await db.fetch_one(global_query)
        
        total = global_result['total_requests']
        successful = global_result['successful_requests']
        failed = global_result['failed_requests']
        
        success_rate = calculate_success_rate(successful, total)
        error_rate = calculate_success_rate(failed, total)
        
        # 2. Top endpoints
        top_query = """
        SELECT 
            endpoint_base,
            functionality,
            total_requests,
            avg_response_time,
            p95_response_time,
            success_rate
        FROM top_endpoints_view
        LIMIT 10
        """
        
        top_results = await db.fetch_all(top_query)
        top_endpoints = [dict(row) for row in top_results]
        
        # 3. Slowest endpoints
        slow_query = """
        SELECT 
            endpoint_base,
            functionality,
            total_requests,
            avg_response_time,
            p95_response_time
        FROM slowest_endpoints_view
        LIMIT 10
        """
        
        slow_results = await db.fetch_all(slow_query)
        slowest_endpoints = [dict(row) for row in slow_results]
        
        return DetailedMetrics(
            total_requests=total,
            successful_requests=successful,
            failed_requests=failed,
            success_rate=success_rate,
            error_rate=error_rate,
            avg_response_time_ms=global_result['avg_response_time_ms'],
            median_response_time_ms=global_result['median_response_time_ms'],
            p95_response_time_ms=global_result['p95_response_time_ms'],
            p99_response_time_ms=global_result['p99_response_time_ms'],
            top_endpoints=top_endpoints,
            slowest_endpoints=slowest_endpoints
        )
        
    except Exception as e:
        logger.error(f"Error in get_detailed_metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# EXTERNAL METRICS INGESTION (v2.1)
# ============================================================================

class ExternalMetricRequest(BaseModel):
    """Modelo para recibir métricas de servicios externos"""
    service_name: str = Field(..., description="Nombre del servicio (fraude, textosql, rag)")
    endpoint: str = Field(..., description="Endpoint llamado")
    method: str = Field(..., description="Método HTTP (GET, POST, etc.)")
    status_code: int = Field(..., description="Código de status HTTP")
    response_time: float = Field(..., description="Tiempo de respuesta en segundos")
    request_size_bytes: int = Field(0, description="Tamaño del request en bytes")
    response_size_bytes: int = Field(0, description="Tamaño del response en bytes")
    client_ip: Optional[str] = Field(None, description="IP del cliente")
    user_agent: Optional[str] = Field(None, description="User agent del cliente")
    request_id: str = Field(..., description="ID único del request")
    is_ai_query: bool = Field(False, description="Si es una query AI que debe contar")
    functionality: Optional[str] = Field(None, description="Funcionalidad detectada")
    model_used: Optional[str] = Field(None, description="Modelo utilizado")
    error_message: Optional[str] = Field(None, description="Mensaje de error si aplica")
    error_type: Optional[str] = Field(None, description="Tipo de error")
    # Campos opcionales específicos por servicio
    query_complexity_score: Optional[int] = Field(None, description="Score de complejidad (textosql)")
    fraud_risk_score: Optional[float] = Field(None, description="Score de riesgo (fraude)")
    sql_execution_time: Optional[float] = Field(None, description="Tiempo SQL (textosql)")
    database_name: Optional[str] = Field(None, description="Nombre de BD (textosql)")

class ExternalMetricResponse(BaseModel):
    """Respuesta de ingesta de métrica"""
    success: bool = Field(..., description="Si la métrica fue guardada exitosamente")
    message: str = Field(..., description="Mensaje de resultado")
    request_id: str = Field(..., description="ID del request procesado")

@router.post("/metrics/log", response_model=ExternalMetricResponse)
async def log_external_metric(
    metric: ExternalMetricRequest,
    db = Depends(get_db)
):
    """
    📊 Endpoint para recibir métricas de servicios externos
    
    Servicios como fraude, textosql y rag envían sus métricas aquí
    para ser almacenadas centralizadamente en la base de datos de stats.
    
    NO requiere autenticación (confianza dentro de la red Docker interna).
    """
    try:
        # Extraer endpoint_base (sin parámetros)
        endpoint_base = metric.endpoint.split('?')[0]
        parts = endpoint_base.split('/')
        endpoint_base = '/'.join([p for p in parts if p and not re.match(r'^[0-9]+$', p)])
        
        # Construir log_data para insertar en DB
        log_data = {
            'endpoint': metric.endpoint,
            'endpoint_base': endpoint_base,
            'method': metric.method,
            'functionality': metric.functionality or _detect_functionality_helper(metric.endpoint),
            'model_used': metric.model_used,
            'request_size_bytes': metric.request_size_bytes,
            'response_size_bytes': metric.response_size_bytes,
            'response_time': metric.response_time,
            'status_code': metric.status_code,
            'error_message': metric.error_message,
            'error_type': metric.error_type,
            'user_agent': metric.user_agent,
            'client_ip': metric.client_ip,
            'request_id': metric.request_id,
            'is_ai_query': metric.is_ai_query,
            'query_complexity_score': metric.query_complexity_score,
            'fraud_risk_score': metric.fraud_risk_score,
            'sql_execution_time': metric.sql_execution_time,
            'database_name': metric.database_name
        }
        
        # Guardar en base de datos
        await db.insert_api_log(log_data)
        
        logger.info(f"✅ Métrica externa guardada: {metric.service_name} - {metric.endpoint} - {metric.request_id}")
        
        return ExternalMetricResponse(
            success=True,
            message="Metric logged successfully",
            request_id=metric.request_id
        )
        
    except Exception as e:
        logger.error(f"❌ Error guardando métrica externa: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to log metric: {str(e)}"
        )

def _detect_functionality_helper(endpoint: str) -> str:
    """Helper para detectar funcionalidad basada en endpoint"""
    endpoint = endpoint.lower()
    if "/fraud" in endpoint or "/fraude" in endpoint:
        return "fraud_detection"
    elif "/textosql" in endpoint or "/sql" in endpoint:
        return "text_to_sql"
    elif "/rag" in endpoint or "/documents" in endpoint:
        return "rag_documents"
    elif "/chat" in endpoint or "/bot" in endpoint or "/proxy" in endpoint:
        return "chatbot"
    else:
        return "general"
