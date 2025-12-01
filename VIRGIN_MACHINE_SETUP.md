# 🚀 CONFIGURACIÓN EN MÁQUINA VIRGEN

## ✅ Todo está integrado en el schema base

**NO hay migraciones separadas.** Todo lo necesario para Stats API v2.0 está incluido en `01-schema.sql`.

## 📋 Provisión Automática

Cuando ejecutas `setup.sh` en una máquina nueva:

```bash
./setup.sh
```

**El script automáticamente:**
1. ✅ Instala Docker y dependencias
2. ✅ Inicia contenedores (`docker-compose up -d`)
3. ✅ PostgreSQL ejecuta `00-master-init.sh`
4. ✅ Se crea `ai_platform_stats` con `01-schema.sql` (incluye v2.0)

## 🎯 Lo que incluye 01-schema.sql

### Tablas Base
- `api_performance_logs` con columna **`endpoint_base`** (v2.0)
- `ai_models_metrics`, `functionality_metrics`, `system_alerts`, etc.

### Vistas v2.0
- `services_unified` - Vista unificada de LLM models + API endpoints
- `detailed_metrics_hourly` - Métricas por hora con percentiles (p50, p95, p99)
- `top_endpoints_view` - Top endpoints por volumen
- `slowest_endpoints_view` - Endpoints más lentos
- `activity_log_view` - Log de actividades

### Triggers Automáticos
- `normalize_functionality` - Normaliza nombres (fraud_detection, text_to_sql, etc.)
- `update_endpoint_base` - Genera endpoint_base automáticamente

### Índices Optimizados
- `idx_api_logs_endpoint_base` - Para queries por endpoint base
- `idx_api_logs_time_func` - Para queries por tiempo + funcionalidad
- `idx_api_logs_time_endpoint` - Para queries por tiempo + endpoint

## 🔧 Endpoints v2.0 Disponibles

Después del despliegue, Stats API expone automáticamente:

```
GET /api/stats/v2/dashboard-summary      # Resumen del dashboard
GET /api/stats/v2/services-status        # Estado de servicios
GET /api/stats/v2/system-resources       # Recursos del sistema
GET /api/stats/v2/hourly-trends          # Tendencias por hora
GET /api/stats/v2/functionality-performance  # Performance por funcionalidad
GET /api/stats/v2/recent-errors          # Errores recientes
GET /api/stats/v2/active-alerts          # Alertas activas
POST /api/stats/v2/resolve-alert/{id}    # Resolver alerta
GET /api/stats/v2/activity-log           # Log de actividades
GET /api/stats/v2/detailed-metrics       # Métricas detalladas
```

## 📊 Verificación Post-Despliegue

```bash
# 1. Verificar que Stats API está corriendo
docker ps | grep stats-api

# 2. Verificar que la base de datos tiene las vistas v2.0
docker exec postgres psql -U postgres -d ai_platform_stats -c "\dv"

# 3. Verificar que los triggers están activos
docker exec postgres psql -U postgres -d ai_platform_stats -c "\dy"

# 4. Probar endpoints en Swagger UI
# Abre: http://localhost:8003/docs
```

## 🎉 Resultado Final

✅ **Máquina virgen → `setup.sh` → Stats API v2.0 funcionando**

Sin pasos manuales, sin migraciones separadas, sin configuración adicional.

---

**Nota:** Si ya tienes una máquina en producción con datos antiguos, necesitas recrear la base de datos para aplicar los cambios:

```bash
# ⚠️ ADVERTENCIA: Esto borra todos los datos
docker-compose down -v
docker-compose up -d
```

Si necesitas **preservar datos existentes**, contacta al equipo de DevOps para migración manual.
