"""
🚀 GUÍA RÁPIDA DE IMPLEMENTACIÓN - STATS API V2.0
================================================

IMPLEMENTACIÓN COMPLETADA:
✅ SQL Migration (02-migration-v2.sql) - 13 secciones con vistas y triggers
✅ Middleware actualizado (endpoint_base, functionality naming)
✅ Database manager actualizado (insert_api_log con endpoint_base)
✅ 10 endpoints v2.0 completamente implementados
✅ Dependency injection configurada (FastAPI Depends)

PASOS PARA ACTIVAR V2.0:
========================

📋 PASO 1: EJECUTAR MIGRACIÓN SQL
---------------------------------
cd database/init-scripts/databases/ai_platform_stats/
psql -U postgres -h localhost -d ai_platform_stats -f 02-migration-v2.sql

O desde Docker:
docker exec -it database psql -U postgres -d ai_platform_stats -f /docker-entrypoint-initdb.d/databases/ai_platform_stats/02-migration-v2.sql

Verificar:
- Columna endpoint_base agregada a api_performance_logs
- Funcionalidades actualizadas (fraud_detection, text_to_sql, rag_documents, chatbot)
- 5 vistas creadas (services_unified, detailed_metrics_hourly, etc.)
- Triggers activos (update_endpoint_base, normalize_functionality)

📝 PASO 2: INTEGRAR ENDPOINTS EN APP.PY
----------------------------------------
Agregar estas líneas en stats/app.py:

# 1. En la sección de imports (después de línea 30):
from endpoints_v2 import router as v2_router, set_db_manager

# 2. Dentro de lifespan(), después de db_manager.initialize():
@asynccontextmanager
async def lifespan(app: FastAPI):
    global db_manager, health_checker, metrics_collector, alert_system
    
    logger.info("🚀 Iniciando AI Platform Stats API...")
    
    background_tasks = []
    
    try:
        # Inicializar componentes
        db_manager = DatabaseManager(settings.database_url)
        await db_manager.initialize()
        
        # ✨ NUEVO: Configurar endpoints v2.0
        set_db_manager(db_manager)
        
        health_checker = ModelHealthChecker(db_manager)
        metrics_collector = MetricsCollector(db_manager)
        alert_system = AlertSystem(db_manager)
        
        # ... resto del código sin cambios ...

# 3. Después de crear app FastAPI (línea ~103):
app = FastAPI(
    title="🤖 AI Platform Stats API",
    description="Sistema de métricas y estadísticas para la plataforma IBM AI Backend",
    version="2.0.0",  # ← Actualizar versión
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# Configurar CORS (sin cambios)
app.add_middleware(...)

# ✨ NUEVO: Incluir router v2.0
app.include_router(v2_router)

# IMPORTANTE: Agregar middleware DESPUÉS de include_router
# (comentado actualmente en línea ~119)

🧪 PASO 3: PROBAR ENDPOINTS
----------------------------
1. Reiniciar Stats API:
   docker-compose restart stats

2. Verificar que levantó correctamente:
   docker logs -f stats

3. Abrir Swagger UI:
   http://localhost:8084/docs

4. Verificar que aparecen los endpoints v2.0:
   - GET  /api/stats/dashboard/summary
   - GET  /api/stats/services/status
   - GET  /api/stats/system/resources
   - GET  /api/stats/trends/hourly
   - GET  /api/stats/functionality/performance
   - GET  /api/stats/errors/recent
   - GET  /api/stats/alerts/active
   - POST /api/stats/alerts/{alert_id}/resolve
   - GET  /api/stats/activity/recent
   - GET  /api/stats/metrics/detailed

5. Probar cada endpoint manualmente en Swagger

6. Verificar formato de respuesta:
   - Timestamps en UTC ISO 8601 con 'Z' (ejemplo: "2025-01-15T10:30:45.123Z")
   - Success rates calculadas correctamente (0-100)
   - Percentiles presentes (p50, p95, p99)
   - Funcionalidades con nombres correctos (fraud_detection, text_to_sql)

✅ PASO 4: ACTUALIZAR FRONTEND
-------------------------------
1. Actualizar URLs en frontend de:
   /api/stats/dashboard-summary → /api/stats/dashboard/summary
   /api/stats/models-status → /api/stats/services/status
   
2. Adaptar parseo de respuestas:
   - Timestamps: new Date(timestamp) ya funciona con formato ISO 8601
   - Success rates: Ya vienen en porcentaje (0-100), no necesita * 100
   - Nuevos campos: p50, p95, p99 disponibles

3. Aprovechar nuevas funcionalidades:
   - Vista unificada de servicios (LLM models + APIs)
   - Activity log (eventos del sistema)
   - Métricas detalladas con percentiles

🔍 PASO 5: MONITOREO Y VALIDACIÓN
----------------------------------
1. Monitorear logs de Stats API:
   docker logs -f stats | grep -E "(ERROR|WARNING|endpoint|v2\.0)"

2. Verificar que middleware capture métricas:
   SELECT endpoint, endpoint_base, functionality 
   FROM api_performance_logs 
   WHERE timestamp >= NOW() - INTERVAL '5 minutes'
   ORDER BY timestamp DESC LIMIT 10;

3. Verificar que vistas funcionan:
   SELECT * FROM services_unified;
   SELECT * FROM detailed_metrics_hourly LIMIT 10;
   SELECT * FROM top_endpoints_view;

4. Verificar triggers:
   -- Insertar request de prueba y verificar que endpoint_base se autocomplete
   INSERT INTO api_performance_logs (endpoint, method, functionality, response_time, status_code)
   VALUES ('/api/fraud/analyze/123?debug=true', 'POST', 'fraude', 150.5, 200);
   
   -- Verificar que endpoint_base = '/api/fraud/analyze' y functionality = 'fraud_detection'
   SELECT endpoint, endpoint_base, functionality 
   FROM api_performance_logs 
   ORDER BY timestamp DESC LIMIT 1;

📊 PASO 6: PERFORMANCE TESTING
-------------------------------
1. Ejecutar test de carga:
   # Instalar ab (Apache Benchmark)
   ab -n 1000 -c 10 http://localhost:8084/api/stats/dashboard/summary

2. Verificar tiempos de respuesta:
   - dashboard/summary: < 100ms
   - services/status: < 150ms
   - trends/hourly: < 300ms (depende de percentiles)
   - metrics/detailed: < 500ms (query más compleja)

3. Si hay problemas de performance:
   - Verificar índices creados en migración
   - Considerar cache en endpoints más usados
   - Considerar vistas materializadas para percentiles

🐛 TROUBLESHOOTING
------------------
❌ Error: "Database not initialized"
   → Verificar que set_db_manager() se llama antes de include_router()

❌ Error: "column endpoint_base does not exist"
   → Ejecutar migración SQL 02-migration-v2.sql

❌ Error: "relation services_unified does not exist"
   → Verificar que la migración se ejecutó en la base correcta (ai_platform_stats)

❌ Timestamps sin 'Z' suffix
   → Verificar función to_utc_iso() en endpoints_v2.py

❌ Percentiles siempre NULL
   → Verificar que hay suficientes datos (al menos 5 requests por grupo)

❌ Funcionalidades con nombres antiguos
   → Verificar triggers de normalización activos
   → Re-ejecutar UPDATE de funcionalidades en migración

❌ Middleware no registra endpoint_base
   → Verificar que middleware.py tiene _extract_endpoint_base()
   → Verificar que database.py acepta endpoint_base en insert_api_log()

📚 DOCUMENTACIÓN ADICIONAL
---------------------------
- Especificación completa: stats/SPECIFICATION_V2.md (si existe)
- Endpoints v2.0: stats/endpoints_v2.py (comentarios en código)
- Integración: stats/INTEGRATION_V2.py
- Changelog: CHANGELOG_STATS_V2.md (crear si se hace release)

🎉 FIN DE LA IMPLEMENTACIÓN
============================
Una vez completados estos pasos, tendrás:
✅ Stats API v2.0 completamente funcional
✅ 10 endpoints especificados por el frontend
✅ Percentiles (p50, p95, p99) calculados automáticamente
✅ Vista unificada de servicios (LLM + APIs)
✅ Activity log del sistema
✅ Middleware automático de tracking
✅ Normalización automática de datos

¡Listo para integrarse con el dashboard del frontend! 🚀
"""