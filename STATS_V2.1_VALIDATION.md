# Stats API v2.1 - Validación de Implementación

## Resumen de Cambios Implementados

### 1. ✅ Filtro de Query Counter (CRÍTICO)
**Problema resuelto:** `daily_queries` incrementaba con TODOS los requests, incluyendo endpoints de monitoreo

**Solución implementada:**
- Nuevo método `_should_count_as_ai_query()` en `middleware.py` (líneas 187-224)
- Filtro por método POST + endpoint pattern matching
- Excluye: `/api/stats/`, `/api/admin/`, `/api/metrics/`, `/health`
- Incluye: `/proxy/`, `/api/rag/query`, `/api/fraude/predict`, `/api/textosql/generate`

**Archivos modificados:**
- `stats/middleware.py`: Agregado método filtro y flag `is_ai_query`
- `stats/database.py`: Agregado parámetro `is_ai_query` a `insert_api_log()`
- `database/init-scripts/databases/ai_platform_stats/01-schema.sql`: Nueva columna `is_ai_query BOOLEAN`
- `stats/endpoints_v2.py`: Query de dashboard filtrada por `WHERE is_ai_query = TRUE`

**Validación:**
```bash
# Antes: 5 minutos dashboard abierto = 70+ queries
# Después: 5 minutos dashboard abierto = 0 queries (correcto)
python stats/test_query_counter_v2.py
```

### 2. ✅ Campo id en Alerts
**Problema:** Frontend requiere campo `id` como string, DB solo tenía `alert_id` numérico

**Solución:**
- Modelo `ActiveAlert` actualizado con campo `id: str`
- Query SELECT agrega `CAST(id AS TEXT) as id`
- Response incluye ambos campos: `alert_id` (int) e `id` (string)

**Archivo modificado:** `stats/endpoints_v2.py` (líneas 625-670)

### 3. ✅ Header X-AI-Query
**Nueva funcionalidad:** Indica si el request cuenta como query AI

**Respuesta incluye:**
```
X-AI-Query: true   # Cuenta para daily_queries
X-AI-Query: false  # No cuenta
```

### 4. ✅ Índices de Base de Datos
**Optimización para queries con filtro `is_ai_query`:**

```sql
CREATE INDEX idx_api_logs_is_ai_query ON api_performance_logs(is_ai_query);
CREATE INDEX idx_api_logs_ai_time ON api_performance_logs(is_ai_query, timestamp DESC) 
WHERE is_ai_query = TRUE;
```

## Validación contra Especificación Frontend

### Dashboard Summary (`/api/stats/v2.0/dashboard/summary`)
| Campo | Estado | Notas |
|-------|--------|-------|
| `daily_queries` | ✅ | Ahora cuenta SOLO queries AI (POST a demos) |
| `daily_successful_queries` | ✅ | Filtrado con `is_ai_query = TRUE` |
| `daily_failed_queries` | ✅ | Filtrado con `is_ai_query = TRUE` |
| `global_accuracy` | ✅ | Conversión `float()` aplicada |
| `avg_response_time` | ✅ | En milisegundos |
| `error_models` | ✅ | Formato arreglo de strings |
| `error_apis` | ✅ | Formato arreglo de strings |

### Active Alerts (`/api/stats/v2.0/alerts/active`)
| Campo | Estado | Notas |
|-------|--------|-------|
| `alert_id` | ✅ | Tipo `int` |
| `id` | ✅ | Tipo `string` (nuevo) |
| `severity` | ✅ | Valores: info, warning, critical, success |
| `timestamp` | ✅ | UTC ISO 8601 |

### Services Status (`/api/stats/v2.0/services/status`)
| Campo | Estado | Notas |
|-------|--------|-------|
| `service_type` | ✅ | Valores: llm, fraud, textosql, rag |
| `service_name` | ✅ | Nombres legibles |
| `status` | ✅ | online, offline, degraded, maintenance |

## Pruebas de Validación

### Test 1: Stats endpoints NO incrementan contador
```bash
curl http://localhost:8003/api/stats/v2.0/dashboard/summary -I | grep X-AI-Query
# Esperado: X-AI-Query: false

# Verificar que contador no cambia
curl http://localhost:8003/api/stats/v2.0/dashboard/summary | jq '.daily_queries'
# Hacer 10 requests más
for i in {1..10}; do curl -s http://localhost:8003/api/stats/v2.0/dashboard/summary > /dev/null; done
curl http://localhost:8003/api/stats/v2.0/dashboard/summary | jq '.daily_queries'
# Esperado: Mismo valor
```

### Test 2: Queries AI SÍ incrementan contador
```bash
# Obtener contador inicial
INITIAL=$(curl -s http://localhost:8003/api/stats/v2.0/dashboard/summary | jq '.daily_queries')

# Hacer query a LLM (demo AI)
curl -X POST http://localhost:8088/completion \
  -H "Content-Type: application/json" \
  -d '{"prompt":"test"}' \
  -I | grep X-AI-Query
# Esperado: X-AI-Query: true

# Verificar incremento
sleep 2
FINAL=$(curl -s http://localhost:8003/api/stats/v2.0/dashboard/summary | jq '.daily_queries')
echo "Incremento: $((FINAL - INITIAL))"
# Esperado: +1
```

### Test 3: GET requests NO incrementan
```bash
INITIAL=$(curl -s http://localhost:8003/api/stats/v2.0/dashboard/summary | jq '.daily_queries')
curl http://localhost:8003/api/stats/v2.0/services/status > /dev/null
curl http://localhost:8003/api/stats/v2.0/alerts/active > /dev/null
FINAL=$(curl -s http://localhost:8003/api/stats/v2.0/dashboard/summary | jq '.daily_queries')
echo "Diferencia: $((FINAL - INITIAL))"
# Esperado: 0
```

### Test 4: Alerts tienen campo id
```bash
curl http://localhost:8003/api/stats/v2.0/alerts/active | jq '.alerts[0] | {alert_id, id, id_type: (.id | type)}'
# Esperado:
# {
#   "alert_id": 123,
#   "id": "123",
#   "id_type": "string"
# }
```

### Test 5: Verificar datos históricos (migración)
```bash
docker exec postgres_db psql -U postgres -d ai_platform_stats -c "
SELECT 
  is_ai_query,
  COUNT(*) as total,
  COUNT(DISTINCT endpoint_base) as unique_endpoints
FROM api_performance_logs
GROUP BY is_ai_query;
"
# Esperado:
# is_ai_query | total | unique_endpoints
# ------------|-------|------------------
# f           | XXX   | YY  (requests de monitoreo)
# t           | ZZ    | WW  (queries AI reales)
```

## Deployment

### 1. Despliegue automático (setup.sh)
```bash
cd /home/lucasjung/IBM-AI-Platform-Back
git add stats/ database/
git commit -m "feat: Stats API v2.1 - filtro query counter y campo id en alerts"
git push origin main

# En servidor remoto
cd /root/BackAI
git pull
./setup.sh deploy
```

### 2. Migración manual (si DB ya existe)
```bash
docker exec -i postgres_db psql -U postgres < database/migrations/add-is-ai-query.sql
```

### 3. Verificación post-deploy
```bash
# Verificar columna agregada
docker exec postgres_db psql -U postgres -d ai_platform_stats -c "\d api_performance_logs" | grep is_ai_query

# Verificar índices
docker exec postgres_db psql -U postgres -d ai_platform_stats -c "\di" | grep is_ai_query

# Test endpoints
python stats/test_query_counter_v2.py
```

## Métricas Esperadas

### Antes de v2.1 (INCORRECTO)
- Dashboard abierto 5 min = 70+ queries
- Polling cada 10-30s incrementa contador
- Métricas infladas e inútiles

### Después de v2.1 (CORRECTO)
- Dashboard abierto 5 min = 0 queries
- Solo POST a demos AI incrementan contador
- Métricas reflejan uso real de la plataforma

## Compatibilidad

- ✅ PPC64le (IBM Power S1022)
- ✅ CentOS 9
- ✅ Docker deployment
- ✅ PostgreSQL 17
- ✅ Python 3.11+
- ✅ FastAPI + asyncpg
- ✅ Sin cambios breaking en API
- ✅ Retrocompatible (is_ai_query default FALSE)

## Documentación Actualizada

- [x] `STATS_API_DOCUMENTATION.md` - Especificación completa v2.1
- [x] `STATS_QUERY_COUNTER_FIX.md` - Problema y solución detallada
- [x] `database/migrations/add-is-ai-query.sql` - Script de migración
- [x] `stats/test_query_counter_v2.py` - Suite de tests automatizados
- [x] Este documento de validación

## Notas Importantes

1. **is_ai_query es inmutable:** Una vez guardado el log, el flag no cambia
2. **Migración retroactiva opcional:** Script disponible para marcar datos históricos
3. **Índice parcial optimizado:** `WHERE is_ai_query = TRUE` acelera queries de dashboard
4. **Header X-AI-Query:** Útil para debugging y monitoring
5. **Sin impacto en endpoints existentes:** Cambios internos, API externa sin cambios

## Aprobación

- [x] Schema SQL actualizado
- [x] Middleware con filtro implementado
- [x] Database manager con nuevo parámetro
- [x] Endpoints con queries filtradas
- [x] Tests automatizados creados
- [x] Migración documentada
- [x] Compatible con arquitectura PPC64le
- [x] Sin configuración manual requerida post-deploy

**Estado:** ✅ READY FOR DEPLOYMENT
