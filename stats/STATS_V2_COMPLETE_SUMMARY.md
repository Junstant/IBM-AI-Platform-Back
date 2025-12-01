# 📊 STATS API V2.0 - IMPLEMENTACIÓN COMPLETA

## 🎯 Resumen Ejecutivo

Se ha completado exitosamente la implementación de **Stats API v2.0** cumpliendo con las especificaciones del frontend. La implementación incluye:

- ✅ **13 secciones de migración SQL** con vistas, triggers e índices
- ✅ **Middleware mejorado** con tracking automático de endpoint_base y normalización de funcionalidades
- ✅ **10 endpoints v2.0** completamente implementados con percentiles (p50, p95, p99)
- ✅ **Vista unificada** de servicios (LLM models + API endpoints)
- ✅ **Activity log** generado automáticamente desde system_alerts
- ✅ **Formato estandarizado** con timestamps UTC ISO 8601 (suffix 'Z')

---

## 📁 Archivos Creados/Modificados

### ✅ Archivos Completados

| Archivo | Estado | Descripción |
|---------|--------|-------------|
| `database/init-scripts/databases/ai_platform_stats/02-migration-v2.sql` | ✅ Creado | Migración completa con 13 secciones (344 líneas) |
| `stats/endpoints_v2.py` | ✅ Creado | 10 endpoints v2.0 con Pydantic models (800+ líneas) |
| `stats/middleware.py` | ✅ Modificado | Agregado `_extract_endpoint_base()` y normalización |
| `stats/database.py` | ✅ Modificado | `insert_api_log()` actualizado con `endpoint_base` |
| `stats/README_V2_IMPLEMENTATION.md` | ✅ Creado | Guía paso a paso de implementación |
| `stats/INTEGRATION_V2.py` | ✅ Creado | Instrucciones detalladas de integración |

### ⚠️ Archivos Pendientes de Modificación

| Archivo | Acción Requerida |
|---------|------------------|
| `stats/app.py` | Agregar 3 líneas de integración (ver README_V2_IMPLEMENTATION.md) |

---

## 🗄️ Cambios en Base de Datos

### Nuevas Columnas

```sql
-- api_performance_logs
ALTER TABLE api_performance_logs 
  ADD COLUMN endpoint_base VARCHAR(200);  -- Endpoint sin parámetros de ruta

-- Índices para performance
CREATE INDEX idx_endpoint_base ON api_performance_logs(endpoint_base);
CREATE INDEX idx_api_logs_timestamp_functionality 
  ON api_performance_logs(timestamp DESC, functionality);
```

### Nuevas Vistas

#### 1. `services_unified` - Vista Unificada de Servicios
```sql
-- Combina ai_models_metrics (LLM models + API endpoints)
SELECT service_name, display_name, service_type, status, 
       last_health_check, uptime_seconds, total_requests, 
       successful_requests, failed_requests, avg_latency_ms, 
       metadata
FROM ai_models_metrics;
```

**Uso:** Endpoint `/api/stats/services/status`

#### 2. `detailed_metrics_hourly` - Métricas con Percentiles
```sql
-- Agregación horaria con percentiles calculados
SELECT DATE_TRUNC('hour', timestamp) as hour,
       functionality,
       COUNT(*) as total_requests,
       ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP ...) as median_response_time_ms,
       ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP ...) as p95_response_time_ms,
       ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP ...) as p99_response_time_ms,
       success_rate, error_rate
FROM api_performance_logs
GROUP BY hour, functionality;
```

**Uso:** Endpoints `/api/stats/trends/hourly` y `/api/stats/metrics/detailed`

#### 3. `top_endpoints_view` - Endpoints Más Usados
```sql
-- Top 20 endpoints por número de requests (últimas 24h)
SELECT endpoint_base, functionality, requests, 
       avg_response_time_ms, p95_response_time_ms, success_rate
FROM (SELECT ... WHERE requests >= 5)
ORDER BY requests DESC LIMIT 20;
```

**Uso:** Endpoint `/api/stats/metrics/detailed` (campo `top_endpoints`)

#### 4. `slowest_endpoints_view` - Endpoints Más Lentos
```sql
-- Top 20 endpoints por tiempo de respuesta promedio
SELECT endpoint_base, functionality, requests,
       avg_response_time_ms, p95_response_time_ms
FROM (SELECT ... WHERE requests >= 5)
ORDER BY avg_response_time_ms DESC LIMIT 20;
```

**Uso:** Endpoint `/api/stats/metrics/detailed` (campo `slowest_endpoints`)

#### 5. `activity_log_view` - Log de Actividad del Sistema
```sql
-- Genera actividad desde system_alerts
SELECT 'alert_' || id::text as activity_id,
       created_at as timestamp,
       CASE alert_type ... END as activity_type,
       severity, title, message as description,
       'system' as user, metadata
FROM system_alerts
WHERE created_at >= NOW() - INTERVAL '7 days'
ORDER BY created_at DESC LIMIT 100;
```

**Uso:** Endpoint `/api/stats/activity/recent`

### Triggers Automáticos

#### 1. `update_endpoint_base` - Extracción Automática
```sql
CREATE FUNCTION update_endpoint_base() RETURNS TRIGGER AS $$
BEGIN
    NEW.endpoint_base := TRIM(TRAILING '/' FROM SPLIT_PART(NEW.endpoint, '?', 1));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_endpoint_base
    BEFORE INSERT ON api_performance_logs
    FOR EACH ROW EXECUTE FUNCTION update_endpoint_base();
```

**Función:** Extrae automáticamente `endpoint_base` de `endpoint` eliminando query params

#### 2. `normalize_functionality` - Normalización de Nombres
```sql
CREATE FUNCTION normalize_functionality() RETURNS TRIGGER AS $$
BEGIN
    NEW.functionality := CASE 
        WHEN NEW.functionality IN ('fraud-detection', 'fraude') THEN 'fraud_detection'
        WHEN NEW.functionality IN ('textosql', 'sql') THEN 'text_to_sql'
        WHEN NEW.functionality = 'rag' THEN 'rag_documents'
        WHEN NEW.functionality IN ('chat', 'bot') THEN 'chatbot'
        ELSE COALESCE(NEW.functionality, 'general')
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

**Función:** Normaliza automáticamente nombres de funcionalidades según especificación

### Funciones de Utilidad

```sql
-- Analizar tablas para mejor performance
CREATE FUNCTION refresh_stats_cache() RETURNS void AS $$
BEGIN
    ANALYZE api_performance_logs;
    ANALYZE ai_models_metrics;
    ANALYZE functionality_metrics;
    ANALYZE system_alerts;
    ANALYZE system_resources;
END;
$$ LANGUAGE plpgsql;

-- Limpiar cache expirado
CREATE FUNCTION cleanup_expired_cache() RETURNS void AS $$
BEGIN
    DELETE FROM metrics_cache WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql;
```

---

## 🔌 Endpoints Implementados

### 1. 📊 Dashboard Summary
```
GET /api/stats/dashboard/summary
```

**Response:**
```json
{
  "active_models": 5,
  "active_apis": 4,
  "total_queries_24h": 15420,
  "avg_accuracy": 94.8
}
```

**Cálculos:**
- `active_models`: COUNT de `ai_models_metrics` WHERE `model_type = 'llm'` AND `status = 'online'`
- `active_apis`: COUNT DISTINCT `functionality` con requests en últimos 5 minutos
- `total_queries_24h`: COUNT de `api_performance_logs` últimas 24h
- `avg_accuracy`: Success rate global (requests exitosas / total * 100)

---

### 2. 🔍 Services Status
```
GET /api/stats/services/status
```

**Response:**
```json
[
  {
    "service_name": "gemma-2b",
    "display_name": "Gemma 2B",
    "service_type": "llm_model",
    "status": "online",
    "uptime_seconds": 86400,
    "last_check": "2025-01-15T10:30:45.123Z",
    "latency_ms": 245.5,
    "success_rate": 98.2,
    "metadata": {
      "port": 8085,
      "model_version": "2B",
      "type": "llm",
      "host": "gemma-2b"
    }
  }
]
```

**Fuente:** Vista `services_unified` (combina LLM models + APIs)

---

### 3. 💻 System Resources
```
GET /api/stats/system/resources
```

**Response:**
```json
{
  "timestamp": "2025-01-15T10:30:45.123Z",
  "cpu_percent": 45.2,
  "memory_used_mb": 8192.5,
  "memory_total_mb": 16384.0,
  "memory_percent": 50.0,
  "disk_used_gb": 128.4,
  "disk_total_gb": 512.0,
  "disk_percent": 25.1,
  "network_sent_mb": 1024.8,
  "network_received_mb": 2048.3
}
```

**Fuente:** `psutil` (monitoreo en tiempo real del sistema)

---

### 4. 📈 Hourly Trends
```
GET /api/stats/trends/hourly?hours=24
```

**Query Parameters:**
- `hours` (optional): Número de horas hacia atrás (default: 24, max: 168)

**Response:**
```json
[
  {
    "hour": "2025-01-15T10:00:00.000Z",
    "functionality": "fraud_detection",
    "total_requests": 1250,
    "successful_requests": 1225,
    "failed_requests": 25,
    "avg_response_time_ms": 145.2,
    "median_response_time_ms": 120.5,
    "p95_response_time_ms": 320.8,
    "p99_response_time_ms": 450.3,
    "success_rate": 98.0,
    "error_rate": 2.0
  }
]
```

**Fuente:** Vista `detailed_metrics_hourly`

---

### 5. 🎯 Functionality Performance
```
GET /api/stats/functionality/performance
```

**Response:**
```json
[
  {
    "functionality": "fraud_detection",
    "total_requests": 15420,
    "avg_response_time_ms": 145.2,
    "success_rate": 98.0,
    "error_rate": 2.0,
    "median_response_time_ms": 120.5,
    "p95_response_time_ms": 320.8
  },
  {
    "functionality": "text_to_sql",
    "total_requests": 8930,
    "avg_response_time_ms": 220.4,
    "success_rate": 96.5,
    "error_rate": 3.5,
    "median_response_time_ms": 180.2,
    "p95_response_time_ms": 450.6
  }
]
```

**Cálculos:** Agregación por `functionality` con `PERCENTILE_CONT` para p50 y p95

---

### 6. ⚠️ Recent Errors
```
GET /api/stats/errors/recent?limit=20
```

**Query Parameters:**
- `limit` (optional): Número de errores (default: 20, max: 100)

**Response:**
```json
[
  {
    "timestamp": "2025-01-15T10:30:45.123Z",
    "endpoint": "/api/fraud/analyze",
    "functionality": "fraud_detection",
    "status_code": 500,
    "error_message": "Database connection timeout",
    "error_type": "timeout",
    "request_id": "550e8400-e29b-41d4-a716-446655440000"
  }
]
```

**Fuente:** `api_performance_logs` WHERE `status_code >= 400` ORDER BY `timestamp DESC`

---

### 7. 🚨 Active Alerts
```
GET /api/stats/alerts/active
```

**Response:**
```json
[
  {
    "alert_id": 42,
    "timestamp": "2025-01-15T10:30:45.123Z",
    "severity": "warning",
    "title": "High Error Rate Detected",
    "message": "Fraud Detection API showing 5% error rate in last 5 minutes",
    "component": "api",
    "component_name": "fraud-api"
  }
]
```

**Fuente:** `system_alerts` WHERE `resolved = false`

---

### 8. ✅ Resolve Alert
```
POST /api/stats/alerts/{alert_id}/resolve
```

**Path Parameters:**
- `alert_id`: ID de la alerta a resolver

**Response:**
```json
{
  "success": true,
  "message": "Alert 42 resolved successfully",
  "alert_id": 42
}
```

**Acción:** UPDATE `system_alerts` SET `resolved = true` WHERE `id = alert_id`

---

### 9. 📜 Recent Activity
```
GET /api/stats/activity/recent?limit=10
```

**Query Parameters:**
- `limit` (optional): Número de actividades (default: 10, max: 50)

**Response:**
```json
[
  {
    "activity_id": "alert_123",
    "timestamp": "2025-01-15T10:30:45.123Z",
    "activity_type": "model_health_check",
    "severity": "info",
    "title": "Model Health Check",
    "description": "Gemma 2B model health check passed",
    "user": "system",
    "metadata": {
      "component": "llm",
      "component_name": "gemma-2b",
      "alert_type": "health_check",
      "severity": 2
    }
  }
]
```

**Fuente:** Vista `activity_log_view`

---

### 10. 📊 Detailed Metrics
```
GET /api/stats/metrics/detailed
```

**Response:**
```json
{
  "total_requests": 35280,
  "successful_requests": 34150,
  "failed_requests": 1130,
  "success_rate": 96.8,
  "error_rate": 3.2,
  "avg_response_time_ms": 175.4,
  "median_response_time_ms": 145.2,
  "p95_response_time_ms": 380.5,
  "p99_response_time_ms": 620.8,
  "top_endpoints": [
    {
      "endpoint": "/api/fraud/analyze",
      "functionality": "fraud_detection",
      "requests": 15420,
      "avg_response_time_ms": 145.2,
      "p95_response_time_ms": 320.8,
      "success_rate": 98.0
    }
  ],
  "slowest_endpoints": [
    {
      "endpoint": "/api/textosql/execute",
      "functionality": "text_to_sql",
      "requests": 8930,
      "avg_response_time_ms": 450.6,
      "p95_response_time_ms": 820.3
    }
  ]
}
```

**Fuentes:**
- Métricas globales: Agregación directa de `api_performance_logs`
- `top_endpoints`: Vista `top_endpoints_view`
- `slowest_endpoints`: Vista `slowest_endpoints_view`

---

## 🔧 Middleware Mejorado

### Funciones Agregadas

#### `_extract_endpoint_base(endpoint: str) -> str`
```python
# Ejemplos:
"/api/fraud/analyze/123" → "/api/fraud/analyze"
"/api/stats/alerts/42" → "/api/stats/alerts"
"/api/textosql/execute?debug=true" → "/api/textosql/execute"
```

**Lógica:**
1. Remover query parameters (`?...`)
2. Identificar segmentos de ruta que son IDs (números, UUIDs, patterns como `session_123`)
3. Reconstruir endpoint sin IDs

#### `_detect_functionality(endpoint: str) -> str`
```python
# Mapeo según especificación v2.0:
"/api/fraud/..." → "fraud_detection"
"/api/textosql/..." → "text_to_sql"
"/api/rag/..." → "rag_documents"
"/api/chat/..." → "chatbot"
```

**Cambios:**
- `fraud-detection` → `fraud_detection`
- `textosql` → `text_to_sql`
- `rag` → `rag_documents`

### Campos Capturados Automáticamente

Cada request captura:
- `endpoint`: URL completa con parámetros
- `endpoint_base`: URL sin IDs ni query params ✨ **NUEVO**
- `method`: HTTP method (GET, POST, etc.)
- `functionality`: Funcionalidad detectada (normalizada) ✨ **MEJORADO**
- `model_used`: Modelo LLM usado (si aplica)
- `request_size_bytes`: Tamaño de la request
- `response_size_bytes`: Tamaño de la response
- `response_time`: Tiempo de respuesta en segundos
- `status_code`: Código HTTP de respuesta
- `error_message`: Mensaje de error (si aplica)
- `error_type`: Tipo de error (timeout, server_error, client_error)
- `user_agent`: User agent del cliente
- `client_ip`: IP del cliente (considerando proxies)
- `request_id`: UUID único de la request

---

## 📊 Formato de Respuesta Estandarizado

### Timestamps UTC ISO 8601
```python
def to_utc_iso(dt: datetime) -> str:
    """Convertir datetime a formato UTC ISO 8601 con 'Z'"""
    return dt.strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'

# Ejemplo: "2025-01-15T10:30:45.123Z"
```

### Success Rates
```python
def calculate_success_rate(successful: int, total: int) -> float:
    """Calcular tasa de éxito en porcentaje (0-100)"""
    if total == 0:
        return 0.0
    return round((successful / total) * 100, 2)

# Ejemplo: 980 exitosas / 1000 total = 98.0%
```

### Percentiles
```sql
-- Cálculo usando PostgreSQL PERCENTILE_CONT
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY response_time)  -- Mediana (p50)
PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time) -- p95
PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time) -- p99
```

---

## 🚀 Próximos Pasos

### Paso 1: Integrar en app.py
```bash
# Editar stats/app.py y agregar 3 líneas:
# 1. Import: from endpoints_v2 import router as v2_router, set_db_manager
# 2. En lifespan después de db_manager.initialize(): set_db_manager(db_manager)
# 3. Después de crear app: app.include_router(v2_router)
```

**Referencia:** Ver `stats/README_V2_IMPLEMENTATION.md` sección "PASO 2"

### Paso 2: Ejecutar Migración
```bash
# Opción A: Docker
docker exec -it database psql -U postgres -d ai_platform_stats -f /docker-entrypoint-initdb.d/databases/ai_platform_stats/02-migration-v2.sql

# Opción B: Local
psql -U postgres -h localhost -d ai_platform_stats -f database/init-scripts/databases/ai_platform_stats/02-migration-v2.sql
```

### Paso 3: Reiniciar Stats API
```bash
docker-compose restart stats
docker logs -f stats  # Verificar que levantó correctamente
```

### Paso 4: Probar Endpoints
```bash
# Abrir Swagger UI
open http://localhost:8084/docs

# O probar manualmente
curl http://localhost:8084/api/stats/dashboard/summary
curl http://localhost:8084/api/stats/services/status
curl http://localhost:8084/api/stats/system/resources
```

### Paso 5: Actualizar Frontend
- Cambiar URLs de endpoints antiguos a v2.0
- Adaptar parseo de timestamps (ya vienen en ISO 8601)
- Aprovechar nuevos campos (percentiles, activity log, vista unificada)

---

## 📚 Documentación de Referencia

| Documento | Ubicación | Descripción |
|-----------|-----------|-------------|
| Guía de Implementación | `stats/README_V2_IMPLEMENTATION.md` | Pasos detallados para activar v2.0 |
| Instrucciones de Integración | `stats/INTEGRATION_V2.py` | Código de ejemplo para integrar en app.py |
| Endpoints v2.0 | `stats/endpoints_v2.py` | Implementación completa con comentarios |
| Migración SQL | `database/.../02-migration-v2.sql` | Script de migración con 13 secciones |
| Middleware | `stats/middleware.py` | Tracking automático mejorado |
| Database Manager | `stats/database.py` | Métodos de inserción actualizados |

---

## 🎉 Estado de Implementación

| Componente | Estado | Cobertura |
|------------|--------|-----------|
| **SQL Migration** | ✅ Completo | 100% (13/13 secciones) |
| **Middleware** | ✅ Completo | 100% (endpoint_base + normalización) |
| **Database Manager** | ✅ Completo | 100% (insert_api_log actualizado) |
| **Endpoints v2.0** | ✅ Completo | 100% (10/10 endpoints) |
| **Pydantic Models** | ✅ Completo | 100% (10 response models) |
| **Dependency Injection** | ✅ Completo | 100% (FastAPI Depends) |
| **Documentación** | ✅ Completo | 100% (guías + ejemplos) |
| **Integración en app.py** | ⚠️ Pendiente | 0% (3 líneas faltantes) |
| **Testing** | ⚠️ Pendiente | 0% (ejecutar migración + probar endpoints) |

---

## ✅ Checklist de Activación

- [x] Crear migración SQL con vistas y triggers
- [x] Actualizar middleware con endpoint_base
- [x] Actualizar database manager
- [x] Implementar 10 endpoints v2.0
- [x] Configurar dependency injection
- [x] Crear documentación completa
- [ ] Integrar en app.py (3 líneas)
- [ ] Ejecutar migración SQL
- [ ] Probar endpoints en Swagger UI
- [ ] Validar formato de respuestas
- [ ] Performance testing
- [ ] Actualizar frontend

---

## 🔗 Enlaces Útiles

- **Swagger UI:** http://localhost:8084/docs
- **ReDoc:** http://localhost:8084/redoc
- **Health Check:** http://localhost:8084/health
- **Prometheus Metrics:** http://localhost:8084/metrics (si está configurado)

---

## 👥 Créditos

**Implementado por:** AI Assistant (GitHub Copilot)  
**Fecha:** 2025-01-15  
**Versión:** 2.0.0  
**Especificación:** Frontend Dashboard Requirements v2.0

---

¡Stats API v2.0 lista para activarse! 🚀
