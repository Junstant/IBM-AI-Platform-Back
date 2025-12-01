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
from fastapi import FastAPI, HTTPException, Request, Response, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import APIKeyHeader
from pydantic import BaseModel

from config import Settings
from database import DatabaseManager
from health_checker import ModelHealthChecker
from metrics_collector import MetricsCollector
from alert_system import AlertSystem
from middleware import MetricsMiddleware
from endpoints_v2 import router as v2_router, set_db_manager

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
        
        # ✨ NUEVO: Configurar endpoints v2.0
        set_db_manager(db_manager)
        logger.info("✅ Endpoints v2.0 configurados con db_manager")
        
        # ✨ Agregar middleware de métricas
        app.add_middleware(MetricsMiddleware, db_manager=db_manager)
        logger.info("✅ Middleware de métricas agregado")
        
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
    version="2.0.0",  # ← ACTUALIZADO a v2.0
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

# ✨ NUEVO: Incluir router de endpoints v2.0
app.include_router(v2_router)
logger.info("✅ Router v2.0 incluido en la aplicación")

# ================================================================
# ENDPOINTS DE UTILIDAD (Health checks)
# ================================================================

@app.get("/", tags=["Health"])
async def root():
    """Endpoint de salud básico"""
    return {
        "service": "AI Platform Stats API",
        "status": "healthy",
        "version": "2.0.0",
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
# ENDPOINTS DE ADMINISTRACIÓN (Con autenticación)
# ================================================================

# Seguridad para endpoints de admin
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def verify_admin_key(api_key: Optional[str] = Depends(api_key_header)):
    """Verificar API key de administrador"""
    admin_key = settings.admin_api_key if hasattr(settings, 'admin_api_key') else "admin-key-change-me"
    if not api_key or api_key != admin_key:
        raise HTTPException(
            status_code=401, 
            detail="Unauthorized - Valid API key required"
        )
    return api_key

@app.post("/api/admin/cleanup-logs", tags=["Admin"], dependencies=[Depends(verify_admin_key)])
async def cleanup_old_logs():
    """Ejecutar limpieza de logs antiguos manualmente (requiere API key)"""
    try:
        await db_manager.execute_query("SELECT cleanup_old_logs()")
        return {"message": "Limpieza de logs ejecutada correctamente"}
    except Exception as e:
        logger.error(f"Error cleaning up logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/admin/calculate-metrics", tags=["Admin"], dependencies=[Depends(verify_admin_key)])
async def calculate_daily_metrics():
    """Calcular métricas diarias manualmente (requiere API key)"""
    try:
        await db_manager.execute_query("SELECT calculate_daily_metrics()")
        return {"message": "Cálculo de métricas ejecutado correctamente"}
    except Exception as e:
        logger.error(f"Error calculating metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/admin/refresh-models", tags=["Admin"], dependencies=[Depends(verify_admin_key)])
async def refresh_models():
    """Refrescar estado de modelos manualmente (requiere API key)"""
    try:
        await health_checker.check_all_models()
        return {"message": "Verificación de modelos ejecutada correctamente"}
    except Exception as e:
        logger.error(f"Error refreshing models: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/admin/resolve-alert/{alert_id}", tags=["Admin"], dependencies=[Depends(verify_admin_key)])
async def resolve_alert(alert_id: int, resolved_by: str = "admin"):
    """Resolver una alerta específica (requiere API key)"""
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