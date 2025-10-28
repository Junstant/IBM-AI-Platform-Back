"""
🚀 AI PLATFORM STATS API
Sistema completo de métricas y estadísticas para la plataforma IBM AI Backend

Características:
- Middleware automático de métricas para TODAS las requests
- Health checks automáticos de modelos IA 
- Sistema de alertas proactivo
- APIs optimizadas para dashboard
- Métricas de performance por funcionalidad
- Limpieza automática de logs antiguos
"""

import asyncio
import logging
import time
import uuid
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from typing import Dict, List, Optional

import psutil
import uvicorn
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from config import Settings
from database import DatabaseManager
from health_checker import ModelHealthChecker
from metrics_collector import MetricsCollector
from alert_system import AlertSystem
from middleware import MetricsMiddleware

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuración global
settings = Settings()

# Instancias globales
db_manager: DatabaseManager = None
health_checker: ModelHealthChecker = None
metrics_collector: MetricsCollector = None
alert_system: AlertSystem = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Gestión del ciclo de vida de la aplicación"""
    global db_manager, health_checker, metrics_collector, alert_system
    
    logger.info("🚀 Iniciando AI Platform Stats API...")
    
    # Inicializar variables
    background_tasks = []
    
    try:
        # Inicializar componentes
        db_manager = DatabaseManager(settings.database_url)
        await db_manager.initialize()
        
        health_checker = ModelHealthChecker(db_manager)
        metrics_collector = MetricsCollector(db_manager)
        alert_system = AlertSystem(db_manager)
        
        # Inicializar modelos en la base de datos
        await health_checker.initialize_models()
        
        # Tareas en background
        background_tasks = [
            asyncio.create_task(health_checker.start_health_monitoring()),
            asyncio.create_task(metrics_collector.start_system_monitoring()),
            asyncio.create_task(alert_system.start_alert_monitoring()),
        ]
        
        logger.info("✅ AI Platform Stats API iniciada correctamente")
        
        yield
        
    except Exception as e:
        logger.error(f"❌ Error iniciando aplicación: {e}")
        raise
    finally:
        # Limpiar recursos
        logger.info("🔄 Cerrando AI Platform Stats API...")
        
        # Cancelar tareas
        for task in background_tasks:
            if not task.done():
                task.cancel()
        
        if db_manager:
            await db_manager.close()
        
        logger.info("✅ AI Platform Stats API cerrada correctamente")

# Crear aplicación FastAPI
app = FastAPI(
    title="🤖 AI Platform Stats API",
    description="Sistema de métricas y estadísticas para la plataforma IBM AI Backend",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Agregar middleware de métricas
app.add_middleware(MetricsMiddleware, db_manager=db_manager)

# ================================================================
# MODELOS DE DATOS
# ================================================================

class DashboardSummary(BaseModel):
    active_models: int
    error_models: int
    daily_queries: int
    daily_successful_queries: int
    avg_response_time: float
    global_accuracy: float
    critical_alerts: int
    avg_memory_usage: float
    avg_cpu_usage: float

class ModelStatus(BaseModel):
    model_name: str
    model_type: str
    model_size: Optional[str]
    status: str
    port: Optional[int]
    total_requests: int
    successful_requests: int
    success_rate: float
    avg_response_time: Optional[float]
    memory_usage_mb: Optional[int]
    cpu_usage_percent: Optional[float]
    uptime_seconds: int
    last_health_check: datetime
    health_status: str
    
    class Config:
        protected_namespaces = ()

class FunctionalityPerformance(BaseModel):
    functionality: str
    total_queries: int
    successful_queries: int
    failed_queries: int
    avg_response_time: float
    success_rate: float
    first_date: Optional[str]
    last_date: Optional[str]

class RecentError(BaseModel):
    error_type: str
    error_count: int
    functionality: str
    endpoint: str
    last_occurrence: datetime
    avg_response_time: float

class HourlyTrend(BaseModel):
    hour: datetime
    functionality: str
    request_count: int
    avg_response_time: float
    p95_response_time: float
    error_count: int

class SystemResource(BaseModel):
    timestamp: datetime
    total_memory_mb: int
    used_memory_mb: int
    memory_usage_percent: float
    total_cpu_cores: int
    cpu_usage_percent: float
    disk_total_gb: int
    disk_used_gb: int
    disk_usage_percent: float
    docker_containers_running: int

class Alert(BaseModel):
    id: int
    alert_type: str
    component: str
    component_name: Optional[str]
    title: str
    message: str
    severity: int
    resolved: bool
    resolved_at: Optional[datetime]
    resolved_by: Optional[str]
    created_at: datetime

# ================================================================
# ENDPOINTS PRINCIPALES
# ================================================================

@app.get("/", tags=["Health"])
async def root():
    """Endpoint de salud básico"""
    return {
        "service": "AI Platform Stats API",
        "status": "healthy",
        "version": "1.0.0",
        "timestamp": datetime.now().isoformat()
    }

@app.get("/health", tags=["Health"])
async def health_check():
    """Health check completo del servicio"""
    try:
        # Verificar conexión a base de datos
        await db_manager.execute_query("SELECT 1")
        
        return {
            "status": "healthy",
            "database": "connected",
            "timestamp": datetime.now().isoformat(),
            "uptime": time.time() - app.state.start_time if hasattr(app.state, 'start_time') else 0
        }
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail="Service unavailable")

# ================================================================
# ENDPOINTS DE DASHBOARD
# ================================================================

@app.get("/api/stats/dashboard-summary", response_model=DashboardSummary, tags=["Dashboard"])
async def get_dashboard_summary():
    """Obtener resumen principal para el dashboard"""
    try:
        query = "SELECT * FROM dashboard_summary LIMIT 1"
        result = await db_manager.fetch_one(query)
        
        if not result:
            # Retornar valores por defecto si no hay datos
            return DashboardSummary(
                active_models=0,
                error_models=0,
                daily_queries=0,
                daily_successful_queries=0,
                avg_response_time=0.0,
                global_accuracy=0.0,
                critical_alerts=0,
                avg_memory_usage=0.0,
                avg_cpu_usage=0.0
            )
        
        return DashboardSummary(**dict(result))
    except Exception as e:
        logger.error(f"Error getting dashboard summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/stats/models-status", response_model=List[ModelStatus], tags=["Dashboard"])
async def get_models_status():
    """Obtener estado detallado de todos los modelos"""
    try:
        query = "SELECT * FROM models_status_detailed ORDER BY model_type, model_name"
        results = await db_manager.fetch_all(query)
        
        return [ModelStatus(**dict(row)) for row in results]
    except Exception as e:
        logger.error(f"Error getting models status: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/stats/functionality-performance", response_model=List[FunctionalityPerformance], tags=["Dashboard"])
async def get_functionality_performance():
    """Obtener performance por funcionalidad (últimos 7 días)"""
    try:
        query = "SELECT * FROM functionality_performance"
        results = await db_manager.fetch_all(query)
        
        return [FunctionalityPerformance(**dict(row)) for row in results]
    except Exception as e:
        logger.error(f"Error getting functionality performance: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/stats/recent-errors", response_model=List[RecentError], tags=["Dashboard"])
async def get_recent_errors():
    """Obtener top errores recientes (últimas 24 horas)"""
    try:
        query = "SELECT * FROM top_errors_recent"
        results = await db_manager.fetch_all(query)
        
        return [RecentError(**dict(row)) for row in results]
    except Exception as e:
        logger.error(f"Error getting recent errors: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/stats/hourly-trends", response_model=List[HourlyTrend], tags=["Dashboard"])
async def get_hourly_trends():
    """Obtener tendencias por hora (últimas 24 horas)"""
    try:
        query = "SELECT * FROM hourly_performance_trends ORDER BY hour DESC, functionality"
        results = await db_manager.fetch_all(query)
        
        return [HourlyTrend(**dict(row)) for row in results]
    except Exception as e:
        logger.error(f"Error getting hourly trends: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/stats/system-resources", response_model=List[SystemResource], tags=["Dashboard"])
async def get_system_resources(hours: int = 24):
    """Obtener uso de recursos del sistema"""
    try:
        query = """
        SELECT * FROM system_resources 
        WHERE timestamp >= NOW() - INTERVAL $1::text || ' hours'
        ORDER BY timestamp DESC
        LIMIT 100
        """
        results = await db_manager.fetch_all(query, (hours,))
        
        return [SystemResource(**dict(row)) for row in results]
    except Exception as e:
        logger.error(f"Error getting system resources: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/stats/alerts", response_model=List[Alert], tags=["Dashboard"])
async def get_alerts(resolved: Optional[bool] = None, severity: Optional[int] = None):
    """Obtener alertas del sistema"""
    try:
        conditions = []
        params = []
        
        if resolved is not None:
            conditions.append("resolved = %s")
            params.append(resolved)
        
        if severity is not None:
            conditions.append("severity >= %s")
            params.append(severity)
        
        where_clause = ""
        if conditions:
            where_clause = "WHERE " + " AND ".join(conditions)
        
        query = f"""
        SELECT * FROM system_alerts 
        {where_clause}
        ORDER BY created_at DESC
        LIMIT 50
        """
        
        results = await db_manager.fetch_all(query, params)
        return [Alert(**dict(row)) for row in results]
    except Exception as e:
        logger.error(f"Error getting alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ================================================================
# ENDPOINTS DE ADMINISTRACIÓN
# ================================================================

@app.post("/api/admin/cleanup-logs", tags=["Admin"])
async def cleanup_old_logs():
    """Ejecutar limpieza de logs antiguos manualmente"""
    try:
        await db_manager.execute_query("SELECT cleanup_old_logs()")
        return {"message": "Limpieza de logs ejecutada correctamente"}
    except Exception as e:
        logger.error(f"Error cleaning up logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/admin/calculate-metrics", tags=["Admin"])
async def calculate_daily_metrics():
    """Calcular métricas diarias manualmente"""
    try:
        await db_manager.execute_query("SELECT calculate_daily_metrics()")
        return {"message": "Cálculo de métricas ejecutado correctamente"}
    except Exception as e:
        logger.error(f"Error calculating metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/admin/refresh-models", tags=["Admin"])
async def refresh_models():
    """Refrescar estado de modelos manualmente"""
    try:
        await health_checker.check_all_models()
        return {"message": "Verificación de modelos ejecutada correctamente"}
    except Exception as e:
        logger.error(f"Error refreshing models: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/admin/resolve-alert/{alert_id}", tags=["Admin"])
async def resolve_alert(alert_id: int, resolved_by: str = "admin"):
    """Resolver una alerta específica"""
    try:
        query = """
        UPDATE system_alerts 
        SET resolved = TRUE, resolved_at = NOW(), resolved_by = $1
        WHERE id = $2 AND resolved = FALSE
        """
        result = await db_manager.execute_query(query, (resolved_by, alert_id))
        
        if result == 0:
            raise HTTPException(status_code=404, detail="Alert not found or already resolved")
        
        return {"message": f"Alert {alert_id} resolved successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error resolving alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ================================================================
# ENDPOINTS DE MÉTRICAS ESPECÍFICAS
# ================================================================

@app.get("/api/metrics/model/{model_name}", tags=["Metrics"])
async def get_model_metrics(model_name: str):
    """Obtener métricas específicas de un modelo"""
    try:
        query = """
        SELECT * FROM ai_models_metrics 
        WHERE model_name = $1
        ORDER BY updated_at DESC 
        LIMIT 1
        """
        result = await db_manager.fetch_one(query, (model_name,))
        
        if not result:
            raise HTTPException(status_code=404, detail="Model not found")
        
        return dict(result)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting model metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/metrics/functionality/{functionality}/history", tags=["Metrics"])
async def get_functionality_history(functionality: str, days: int = 7):
    """Obtener historial de métricas de una funcionalidad"""
    try:
        query = """
        SELECT * FROM functionality_metrics 
        WHERE functionality = $1 
        AND date >= CURRENT_DATE - INTERVAL $2::text || ' days'
        ORDER BY date DESC, hour DESC
        """
        results = await db_manager.fetch_all(query, (functionality, days))
        
        return [dict(row) for row in results]
    except Exception as e:
        logger.error(f"Error getting functionality history: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ================================================================
# INICIALIZACIÓN DE LA APLICACIÓN
# ================================================================

if __name__ == "__main__":
    # Configurar tiempo de inicio
    app.state.start_time = time.time()
    
    # Ejecutar servidor
    uvicorn.run(
        "app:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="info"
    )