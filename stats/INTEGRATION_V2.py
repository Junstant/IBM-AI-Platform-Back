"""
🔧 INTEGRACIÓN DE ENDPOINTS V2.0 CON APP.PY

Este archivo muestra cómo integrar los nuevos endpoints v2.0 con la aplicación existente.

OPCIÓN 1: Usar APIRouter (Recomendado)
--------------------------------------
1. Importar el router desde endpoints_v2.py
2. Incluir el router en app.py con app.include_router()
3. Los endpoints estarán disponibles bajo /api/stats/...

OPCIÓN 2: Reemplazar endpoints existentes
------------------------------------------
1. Modificar app.py para usar los modelos Pydantic de endpoints_v2.py
2. Actualizar las queries para usar las nuevas vistas de la base de datos
3. Mantener compatibilidad con v1.0 si es necesario

PASOS PARA INTEGRACIÓN:
"""

# ==============================================================================
# PASO 1: MODIFICAR app.py - Importar el router de v2.0
# ==============================================================================

# Agregar esta línea después de los imports existentes en app.py:
# from endpoints_v2 import router as v2_router

# ==============================================================================
# PASO 2: MODIFICAR app.py - Incluir el router
# ==============================================================================

# Agregar después de crear la app FastAPI (línea ~103):
# app.include_router(v2_router)

# ==============================================================================
# PASO 3: MODIFICAR app.py - Pasar db_manager a los endpoints
# ==============================================================================

# Los endpoints v2.0 necesitan acceso a db_manager. Hay 2 opciones:

# OPCIÓN A: Usar FastAPI dependency injection
# --------------------------------------------
# En endpoints_v2.py, agregar al principio:
"""
from fastapi import Depends

async def get_db():
    from app import db_manager
    if not db_manager:
        raise HTTPException(status_code=503, detail="Database not initialized")
    return db_manager

# Luego en cada endpoint, agregar:
async def get_dashboard_summary(db = Depends(get_db)):
    ...
"""

# OPCIÓN B: Inyectar db_manager al router
# ----------------------------------------
# En app.py, después de inicializar db_manager en lifespan:
"""
@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_manager, health_checker, metrics_collector, alert_system
    
    # ... inicialización existente ...
    
    db_manager = DatabaseManager(settings.database_url)
    await db_manager.initialize()
    
    # NUEVO: Inyectar db_manager en endpoints v2.0
    from endpoints_v2 import router as v2_router
    
    # Crear wrapper para inyectar db_manager
    for route in v2_router.routes:
        original_endpoint = route.endpoint
        
        async def wrapped_endpoint(*args, **kwargs):
            return await original_endpoint(*args, db=db_manager, **kwargs)
        
        route.endpoint = wrapped_endpoint
    
    app.include_router(v2_router)
    
    # ... resto del código ...
"""

# ==============================================================================
# PASO 4: CÓDIGO COMPLETO DE INTEGRACIÓN (app.py modificado)
# ==============================================================================

INTEGRATION_CODE = '''
# En la sección de imports (línea ~31):
from endpoints_v2 import router as v2_router

# Después de crear la app (línea ~103), ANTES de add_middleware:
app = FastAPI(
    title="🤖 AI Platform Stats API",
    description="Sistema de métricas y estadísticas para la plataforma IBM AI Backend",
    version="2.0.0",  # ← ACTUALIZAR versión
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configurar CORS (sin cambios)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# En la función lifespan, después de inicializar db_manager:
@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_manager, health_checker, metrics_collector, alert_system
    
    logger.info("🚀 Iniciando AI Platform Stats API...")
    
    background_tasks = []
    
    try:
        # Inicializar componentes
        db_manager = DatabaseManager(settings.database_url)
        await db_manager.initialize()
        
        # ✨ NUEVO: Configurar endpoints v2.0 con db_manager
        configure_v2_endpoints(app, db_manager)
        
        # Agregar middleware DESPUÉS de configurar endpoints
        app.add_middleware(MetricsMiddleware, db_manager=db_manager)
        
        # ... resto del código sin cambios ...
'''

# ==============================================================================
# FUNCIÓN HELPER PARA INYECTAR DB_MANAGER
# ==============================================================================

def configure_v2_endpoints(app, db_manager):
    """
    Configura los endpoints v2.0 inyectando db_manager.
    
    Esta función debe llamarse desde lifespan() después de inicializar db_manager.
    """
    from endpoints_v2 import router as v2_router
    
    # Wrapper para inyectar db_manager en todos los endpoints
    for route in v2_router.routes:
        if hasattr(route, 'endpoint'):
            original_endpoint = route.endpoint
            
            # Crear wrapper que inyecta db
            async def create_wrapped_endpoint(original):
                async def wrapped(*args, db=db_manager, **kwargs):
                    return await original(*args, db=db, **kwargs)
                return wrapped
            
            route.endpoint = create_wrapped_endpoint(original_endpoint)
    
    # Incluir router en la app
    app.include_router(v2_router)
    
    logger.info("✅ Endpoints v2.0 configurados correctamente")

# ==============================================================================
# ALTERNATIVA SIMPLE: Usar FastAPI Depends (Recomendado)
# ==============================================================================

SIMPLE_INTEGRATION = '''
# Modificar endpoints_v2.py para usar Depends:

from fastapi import Depends

# Variable global para db_manager (será inyectada desde app.py)
_db_manager = None

def set_db_manager(db):
    """Llamar esto desde app.py después de inicializar db_manager"""
    global _db_manager
    _db_manager = db

async def get_db():
    """Dependency para inyectar db_manager en endpoints"""
    if not _db_manager:
        raise HTTPException(status_code=503, detail="Database not initialized")
    return _db_manager

# En cada endpoint, cambiar:
# async def get_dashboard_summary(db):
# por:
# async def get_dashboard_summary(db = Depends(get_db)):

# Luego en app.py, después de inicializar db_manager:
from endpoints_v2 import set_db_manager, router as v2_router

db_manager = DatabaseManager(settings.database_url)
await db_manager.initialize()

set_db_manager(db_manager)  # ← Inyectar db_manager
app.include_router(v2_router)  # ← Incluir router
'''

# ==============================================================================
# RESUMEN DE CAMBIOS
# ==============================================================================

print("""
📋 RESUMEN DE INTEGRACIÓN V2.0
==============================

ARCHIVOS A MODIFICAR:
1. ✅ stats/endpoints_v2.py (ya creado)
2. ✅ stats/middleware.py (ya actualizado)
3. ✅ stats/database.py (ya actualizado)
4. ⚠️  stats/app.py (pendiente - agregar integración)

CAMBIOS EN app.py:
------------------
1. Importar: from endpoints_v2 import router as v2_router, set_db_manager
2. En lifespan(), después de db_manager.initialize():
   - Llamar: set_db_manager(db_manager)
   - Llamar: app.include_router(v2_router)
3. Actualizar version="2.0.0" en FastAPI()

ENDPOINTS V2.0 DISPONIBLES:
---------------------------
✅ GET  /api/stats/dashboard/summary          - 4 cards dashboard
✅ GET  /api/stats/services/status            - Estado unificado de servicios
✅ GET  /api/stats/system/resources           - Recursos del sistema
✅ GET  /api/stats/trends/hourly?hours=24     - Tendencias horarias
✅ GET  /api/stats/functionality/performance  - Performance por funcionalidad
✅ GET  /api/stats/errors/recent?limit=20     - Errores recientes
✅ GET  /api/stats/alerts/active              - Alertas activas
✅ POST /api/stats/alerts/{id}/resolve        - Resolver alerta
✅ GET  /api/stats/activity/recent?limit=10   - Actividad reciente
✅ GET  /api/stats/metrics/detailed           - Métricas detalladas

COMPATIBILIDAD CON V1.0:
------------------------
Los endpoints antiguos seguirán funcionando:
- /api/stats/dashboard-summary (v1.0)
- /api/stats/dashboard/summary (v2.0)

Se recomienda migrar el frontend gradualmente a v2.0.

TESTING:
--------
1. Ejecutar migración SQL: 02-migration-v2.sql
2. Reiniciar Stats API
3. Visitar: http://localhost:8084/docs
4. Probar cada endpoint v2.0 manualmente
5. Verificar formato de respuesta (UTC timestamps con 'Z')
6. Verificar percentiles (p50, p95, p99)
7. Verificar vista unificada de servicios
""")
