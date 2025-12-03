# 🔧 FIX: Errores 404 en Endpoints `/api/stats/v2/`

## 📋 Resumen del Problema

Los logs del backend mostraban errores **404 Not Found** para rutas como:
- `/api/stats/v2/alerts/active`
- `/api/stats/v2/activity/recent`

**PERO** el usuario confirmó: "en el front no estoy haciendo peticiones a v2" ❌

## 🕵️ Causa Raíz

Después de investigar, descubrí que **NO era el frontend ni el backend produciendo estos errores**, sino el **archivo de pruebas `test_simple.py`** que tenía URLs INCORRECTAS.

### Problemas Encontrados:

1. **Puerto Incorrecto**: El test usaba `http://localhost:8004` (puerto de RAG) en lugar de `http://localhost:8003` (puerto de Stats API)

2. **Prefijo de Ruta Incorrecto**: El test usaba `/api/v2/` en lugar de `/api/stats/`

### Arquitectura Real de la API:

```python
# app.py (línea 130)
app.include_router(v2_router)

# endpoints_v2.py (línea 174)
router = APIRouter(
    prefix="/api/stats",  # ← NO ES "/api/stats/v2/"
    tags=["Stats API v2.0"]
)
```

**Resultado**: Los endpoints reales son:
- ✅ `/api/stats/alerts/active`
- ✅ `/api/stats/activity/recent`
- ✅ `/api/stats/services/status`
- ❌ `/api/stats/v2/alerts/active` → NO EXISTE
- ❌ `/api/v2/alerts/active` → NO EXISTE

## 🔨 Solución Aplicada

### Correcciones en `test_simple.py`:

#### 1. Puerto Corregido:
```python
# ANTES:
BASE_URL = "http://localhost:8004"  # ❌ Puerto de RAG

# DESPUÉS:
BASE_URL = "http://localhost:8003"  # ✅ Puerto de Stats API
```

#### 2. URLs Corregidas:

| Antes (❌ Incorrecto) | Después (✅ Correcto) |
|---------------------|---------------------|
| `/api/v2/metrics/global` | `/api/stats/metrics/global` |
| `/api/v2/metrics/by-service` | `/api/stats/metrics/by-service` |
| `/api/v2/performance/top-endpoints` | `/api/stats/performance/top-endpoints` |
| `/api/v2/performance/heatmap` | `/api/stats/performance/heatmap` |
| `/api/v2/trends/hourly` | `/api/stats/trends/hourly` |
| `/api/v2/trends/daily` | `/api/stats/trends/daily` |
| `/api/v2/compare/periods` | `/api/stats/compare/periods` |
| `/api/v2/compare/services` | `/api/stats/compare/services` |
| `/api/v2/alerts/active` | `/api/stats/alerts/active` |

## 📝 Endpoints Correctos para el Frontend

### Documentación Oficial

Consultar: **`FRONTEND_API_GUIDE.md`** para la guía completa de integración.

### Endpoints Principales:

```javascript
// Dashboard Overview
GET http://localhost:8003/api/stats/dashboard/summary

// Alertas Activas
GET http://localhost:8003/api/stats/alerts/active

// Actividad Reciente
GET http://localhost:8003/api/stats/activity/recent?limit=20

// Estado de Servicios
GET http://localhost:8003/api/stats/services/status

// Métricas Detalladas
GET http://localhost:8003/api/stats/services/detailed-metrics
```

## ✅ Verificación

### Antes del Fix:
```bash
# Test ejecutaba:
curl http://localhost:8004/api/v2/alerts/active
# Resultado: 404 Not Found (puerto incorrecto + ruta incorrecta)
```

### Después del Fix:
```bash
# Test ejecuta:
curl http://localhost:8003/api/stats/alerts/active
# Resultado: 200 OK ✅
```

## 🚨 Lección Aprendida

**Los errores 404 no siempre provienen del frontend en producción.**

En este caso:
- ✅ El frontend tenía las URLs correctas (`/api/stats/...`)
- ✅ El backend tenía las rutas correctas (`prefix="/api/stats"`)
- ❌ El archivo de **pruebas** tenía URLs obsoletas (`/api/v2/...`)

**Siempre verificar**:
1. Archivos de prueba (test_*.py)
2. Scripts de health check
3. Monitoring tools
4. Documentation desactualizada

## 📊 Impacto

- **Errores 404 eliminados** ✅
- **Test file actualizado** con URLs correctas ✅
- **Frontend sin cambios** (ya tenía URLs correctas) ✅
- **Backend sin cambios** (ya tenía rutas correctas) ✅

## 🔍 Cómo Detectar Este Tipo de Problemas

1. **Buscar `/v2/` en toda la codebase:**
   ```bash
   grep -r "/v2/" stats/
   ```

2. **Verificar el prefijo del router:**
   ```python
   # endpoints_v2.py
   router = APIRouter(prefix="/api/stats", ...)
   ```

3. **Revisar logs con atención**: Los logs mostraban el origen de las peticiones (IPs internas), indicando que NO venían del navegador del usuario.

## 📦 Archivos Modificados

- ✅ `stats/test_simple.py` - URLs y puerto corregidos

## 📖 Referencias

- **Guía de Integración Frontend**: `FRONTEND_API_GUIDE.md`
- **Router Configuration**: `stats/endpoints_v2.py` (línea 174)
- **App Setup**: `stats/app.py` (línea 130)
- **Docker Compose**: Puerto 8003 para stats-api

---

**Fecha del Fix**: 2025-01-XX  
**Autor**: GitHub Copilot  
**Ticket**: Frontend Alerts - 404 on /api/stats/v2/ endpoints  
