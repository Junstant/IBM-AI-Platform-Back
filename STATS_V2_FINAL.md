# ✅ STATS API V2.0 - CONFIGURACIÓN FINAL PARA MÁQUINAS VÍRGENES

## 🎯 Resumen de Cambios

Se **eliminaron todas las migraciones** y se **integraron las características v2.0 directamente en el schema base** (`01-schema.sql`).

## 📁 Archivos Eliminados

```bash
❌ database/init-scripts/databases/ai_platform_stats/02-migration-v2.sql
❌ activate-stats-v2.ps1
❌ migrate-stats-v2.sh
❌ DEPLOYMENT_CHECKLIST_V2.md
❌ ACTIVACION_FINAL_V2.md
```

## 📝 Archivos Modificados

### ✅ `01-schema.sql` (Schema Base Completo)
**Ahora incluye todo lo necesario para v2.0:**

#### Columnas v2.0
- `api_performance_logs.endpoint_base` - Endpoint sin IDs ni query params

#### Vistas v2.0
- `services_unified` - Vista unificada (LLM models + API endpoints)
- `detailed_metrics_hourly` - Métricas por hora con percentiles (p50, p95, p99)
- `top_endpoints_view` - Top endpoints por volumen
- `slowest_endpoints_view` - Endpoints más lentos
- `activity_log_view` - Log de actividades del sistema

#### Triggers v2.0
- `normalize_functionality` - Normaliza nombres automáticamente
  - `fraude` → `fraud_detection`
  - `textosql` → `text_to_sql`
  - `rag` → `rag_documents`
  - `chat` → `chatbot`
  
- `update_endpoint_base` - Genera endpoint_base automáticamente
  - `/api/fraud/analyze/123` → `/api/fraud/analyze/[id]`
  - `/api/sql/query?db=banco` → `/api/sql/query`

#### Índices v2.0
- `idx_api_logs_endpoint_base` - Para queries por endpoint base
- `idx_api_logs_time_func` - Para queries por tiempo + funcionalidad
- `idx_api_logs_time_endpoint` - Para queries por tiempo + endpoint
- `idx_api_logs_request_id` - Para tracking de requests

### ✅ `00-master-init.sh`
**Revertido a su forma original:** solo ejecuta `01-schema.sql`

### ✅ Código de Stats API (Sin cambios)
Los siguientes archivos ya estaban listos y **no necesitan cambios**:
- `stats/app.py` - Integrado con v2.0 endpoints
- `stats/endpoints_v2.py` - 10 endpoints v2.0 completos
- `stats/middleware.py` - Genera `endpoint_base` automáticamente
- `stats/database.py` - Acepta `endpoint_base` en insert_api_log()

## 🚀 Despliegue en Máquina Virgen

```bash
# 1. Clonar repositorio
git clone <repo-url>
cd IBM-AI-Platform-Back

# 2. Ejecutar setup.sh (hace TODO automáticamente)
./setup.sh

# 3. Verificar que Stats API está funcionando
docker ps | grep stats-api
curl http://localhost:8003/health

# 4. Probar endpoints v2.0 en Swagger
# Abre: http://localhost:8003/docs
```

## ✨ Lo que sucede automáticamente

1. ✅ `setup.sh` instala Docker y dependencias
2. ✅ `docker-compose up -d` inicia contenedores
3. ✅ PostgreSQL ejecuta `00-master-init.sh`
4. ✅ `01-schema.sql` crea:
   - Tablas con `endpoint_base`
   - 10 vistas (5 base + 5 v2.0)
   - 2 triggers automáticos
   - 7 índices optimizados
5. ✅ Stats API inicia con endpoints v2.0 disponibles
6. ✅ Middleware captura métricas automáticamente
7. ✅ Triggers normalizan datos en tiempo real

## 📊 Endpoints Disponibles (v2.0)

```
GET  /api/stats/v2/dashboard-summary         # Resumen del dashboard
GET  /api/stats/v2/services-status           # Estado de servicios
GET  /api/stats/v2/system-resources          # Recursos del sistema
GET  /api/stats/v2/hourly-trends             # Tendencias por hora
GET  /api/stats/v2/functionality-performance # Performance por funcionalidad
GET  /api/stats/v2/recent-errors             # Errores recientes
GET  /api/stats/v2/active-alerts             # Alertas activas
POST /api/stats/v2/resolve-alert/{id}        # Resolver alerta
GET  /api/stats/v2/activity-log              # Log de actividades
GET  /api/stats/v2/detailed-metrics          # Métricas detalladas
```

## 🎯 Características v2.0 Incluidas

✅ **Percentiles en métricas** (p50, p95, p99)  
✅ **Vista unificada** de servicios (LLM + APIs)  
✅ **Timestamps UTC** con formato ISO 8601 + 'Z'  
✅ **Success rate** como porcentaje (0-100)  
✅ **Endpoint base** normalizado automáticamente  
✅ **Funcionalidades normalizadas** (fraud_detection, text_to_sql, etc.)  
✅ **Activity log** generado desde system_alerts  
✅ **Request ID** para tracking completo  

## 📋 Verificación Post-Despliegue

```bash
# 1. Verificar vistas v2.0
docker exec postgres psql -U postgres -d ai_platform_stats -c "
SELECT table_name FROM information_schema.views 
WHERE table_schema = 'public' 
ORDER BY table_name;"

# Expected output:
# - services_unified
# - detailed_metrics_hourly
# - top_endpoints_view
# - slowest_endpoints_view
# - activity_log_view
# + vistas base existentes

# 2. Verificar triggers
docker exec postgres psql -U postgres -d ai_platform_stats -c "\dy"

# Expected output:
# - normalize_functionality
# - update_endpoint_base

# 3. Verificar columna endpoint_base
docker exec postgres psql -U postgres -d ai_platform_stats -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'api_performance_logs' 
  AND column_name = 'endpoint_base';"

# Expected: endpoint_base | character varying

# 4. Test endpoint v2.0
curl http://localhost:8003/api/stats/v2/dashboard-summary
```

## 🔥 Para Máquinas en Producción (Con Datos Existentes)

Si ya tienes una máquina con datos y quieres aplicar v2.0:

```bash
# ⚠️ ADVERTENCIA: Esto borra todos los datos
docker-compose down -v
docker-compose up -d

# La base de datos se recreará desde cero con v2.0 incluido
```

Si necesitas **preservar datos**, contacta al equipo de DevOps para migración manual.

## 📚 Documentación Adicional

- `VIRGIN_MACHINE_SETUP.md` - Guía de provisión en máquinas nuevas
- `stats/README_V2_IMPLEMENTATION.md` - Detalles técnicos de implementación
- `stats/STATS_V2_COMPLETE_SUMMARY.md` - Resumen completo de v2.0
- `stats/INTEGRATION_V2.py` - Ejemplo de integración

---

**✅ LISTO PARA DESPLIEGUE EN MÁQUINAS VÍRGENES**

Un solo comando (`./setup.sh`) despliega toda la plataforma con Stats API v2.0 completamente funcional.
