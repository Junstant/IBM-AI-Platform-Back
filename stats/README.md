# 📊 AI Platform Stats API

Sistema completo de métricas y estadísticas para la plataforma IBM AI Backend.

## 🎯 Características Principales

### 🔍 Middleware Automático de Métricas
- ✅ **Intercepta TODAS las requests automáticamente**
- ✅ **Logging automático** en `api_performance_logs`  
- ✅ **Tiempo de respuesta real** por endpoint
- ✅ **Status codes y errores** detallados
- ✅ **Tamaño de request/response**
- ✅ **IP del cliente y User-Agent**
- ✅ **Request ID único** para tracking

### 🏥 Health Checks de Modelos IA
- ✅ **Verificación automática** cada 5 minutos
- ✅ **Estado de modelos** en `ai_models_metrics`
- ✅ **Ping a puertos** de Ollama/llama.cpp
- ✅ **Tiempo de respuesta** de modelos
- ✅ **Detección de modelos** caídos/cargando
- ✅ **Memoria/CPU usage** por modelo
- ✅ **Conteo de tokens** procesados

### 📊 Métricas de Performance por Funcionalidad
- ✅ **TextToSQL**: complejidad de query, tiempo SQL execution
- ✅ **Fraud Detection**: risk score, precisión
- ✅ **Chatbot**: tokens usados, duración conversación
- ✅ **Actualización en tiempo real** de `functionality_metrics`

### 🚨 Sistema de Alertas Automático
- ✅ **Modelos que no responden** > 30 segundos
- ✅ **APIs con error rate** > 10%
- ✅ **Memoria/CPU** > 90%
- ✅ **Inserción automática** en `system_alerts`
- ✅ **Detección proactiva** de problemas

### 🎯 Métricas de Precisión/Calidad
- ✅ **TextToSQL**: validar sintaxis SQL generada
- ✅ **Fraud**: comparar con resultados esperados
- ✅ **Actualización de** `accuracy_metrics` por modelo

### 🌐 APIs para Dashboard
```
GET /api/stats/dashboard-summary      # Resumen principal
GET /api/stats/models-status          # Estado de modelos
GET /api/stats/functionality-performance  # Performance por funcionalidad
GET /api/stats/recent-errors          # Errores recientes
GET /api/stats/hourly-trends          # Tendencias por hora
GET /api/stats/system-resources       # Recursos del sistema
GET /api/stats/alerts                 # Alertas activas
```

### 🔧 Limpieza y Mantenimiento
- ✅ **Función** `cleanup_old_logs()` ejecutada diariamente
- ✅ **Función** `calculate_daily_metrics()` ejecutada cada hora
- ✅ **Compactación** de métricas antiguas

## 🚀 Instalación

### 📋 Prerequisitos
```bash
# Python 3.11+
python --version

# PostgreSQL corriendo en puerto 8070
# Base de datos ai_platform_stats creada
```

### 🔧 Configuración Local
```bash
# 1. Instalar dependencias
cd stats/
pip install -r requirements.txt

# 2. Configurar variables de entorno (.env)
DB_HOST=localhost
DB_PORT=8070
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=ai_platform_stats

# Configuración de modelos
GEMMA_2B_PORT=8085
GEMMA_4B_PORT=8086
MISTRAL_7B_PORT=8088
FRAUD_API_PORT=8001
TEXTOSQL_API_PORT=8000

# 3. Ejecutar aplicación
python app.py
```

### 🐳 Docker (Recomendado)
```bash
# Construir imagen
docker build -t ai-platform-stats .

# Ejecutar contenedor
docker run -d \
  --name stats-api \
  -p 8003:8003 \
  --network ai_platform_network \
  -e DOCKER_ENV=true \
  ai-platform-stats
```

## 📡 Endpoints Principales

### 🏠 Health & Info
```bash
GET /                    # Info básica del servicio
GET /health             # Health check completo
GET /docs               # Documentación Swagger
```

### 📊 Dashboard APIs
```bash
GET /api/stats/dashboard-summary
# Retorna: active_models, daily_queries, avg_response_time, etc.

GET /api/stats/models-status  
# Retorna: estado detallado de todos los modelos IA

GET /api/stats/functionality-performance
# Retorna: métricas por funcionalidad (últimos 7 días)

GET /api/stats/recent-errors
# Retorna: top errores (últimas 24 horas)

GET /api/stats/hourly-trends
# Retorna: tendencias por hora

GET /api/stats/system-resources?hours=24
# Retorna: uso de CPU, RAM, disco

GET /api/stats/alerts?resolved=false&severity=4
# Retorna: alertas activas filtradas
```

### 🔧 Administración
```bash
POST /api/admin/cleanup-logs
# Ejecuta limpieza de logs antiguos

POST /api/admin/calculate-metrics  
# Calcula métricas diarias manualmente

POST /api/admin/refresh-models
# Refresca estado de modelos

POST /api/admin/resolve-alert/{alert_id}
# Resuelve una alerta específica
```

### 📈 Métricas Específicas
```bash
GET /api/metrics/model/{model_name}
# Métricas de un modelo específico

GET /api/metrics/functionality/{functionality}/history?days=7
# Historial de una funcionalidad
```

## 🎛️ Configuración

### ⚙️ Variables de Entorno
```bash
# Servidor
HOST=0.0.0.0
PORT=8003
DEBUG=false

# Base de datos
DATABASE_URL=postgresql://user:pass@host:port/db
DB_HOST=localhost
DB_PORT=8070
DB_NAME=ai_platform_stats

# Umbrales de alertas
MODEL_TIMEOUT_THRESHOLD=30      # segundos
API_ERROR_RATE_THRESHOLD=10.0   # porcentaje  
MEMORY_USAGE_THRESHOLD=90.0     # porcentaje
CPU_USAGE_THRESHOLD=90.0        # porcentaje

# Intervalos de monitoreo
HEALTH_CHECK_INTERVAL=300       # 5 minutos
METRICS_COLLECTION_INTERVAL=60  # 1 minuto
ALERT_CHECK_INTERVAL=120        # 2 minutos

# Retención de datos
LOG_RETENTION_DAYS=30
```

### 🔗 Integración con Otros Servicios

#### Para TextoSQL API
```python
from middleware import add_functionality_context, add_complexity_score, add_sql_execution_time

@app.post("/api/textosql/query")
async def process_query(request: Request, query: QueryRequest):
    # Agregar contexto
    add_functionality_context(request, "textosql", "gemma-2b")
    add_complexity_score(request, calculate_complexity(query.text))
    
    # Procesar query
    start_time = time.time()
    sql_result = await execute_sql(generated_sql)
    sql_time = time.time() - start_time
    
    # Agregar tiempo de ejecución SQL
    add_sql_execution_time(request, sql_time)
    
    return result
```

#### Para Fraud Detection API  
```python
from middleware import add_functionality_context, add_fraud_score

@app.post("/api/fraud/detect")
async def detect_fraud(request: Request, transaction: TransactionData):
    # Agregar contexto
    add_functionality_context(request, "fraud-detection", "fraud-model")
    
    # Procesar detección
    risk_score = await analyze_fraud(transaction)
    
    # Agregar score de riesgo
    add_fraud_score(request, risk_score)
    
    return {"risk_score": risk_score}
```

## 🗄️ Estructura de Base de Datos

### 📋 Tablas Principales
- **`ai_models_metrics`**: Estado y performance de modelos IA
- **`functionality_metrics`**: Métricas agregadas por funcionalidad  
- **`api_performance_logs`**: Logs detallados de APIs
- **`accuracy_metrics`**: Métricas de precisión y calidad
- **`system_resources`**: Uso de recursos del sistema
- **`database_metrics`**: Métricas de base de datos
- **`system_alerts`**: Alertas y eventos del sistema

### 🔍 Vistas Optimizadas
- **`dashboard_summary`**: Resumen principal para dashboard
- **`functionality_performance`**: Performance por funcionalidad  
- **`models_status_detailed`**: Estado detallado de modelos
- **`top_errors_recent`**: Top errores recientes
- **`hourly_performance_trends`**: Tendencias por hora

## 🔍 Monitoreo y Alertas

### 🚨 Tipos de Alertas
1. **Modelos no responsivos** (Crítico)
2. **APIs con alta tasa de error** (Alto)  
3. **Uso de recursos crítico** (Crítico)
4. **Tiempos de respuesta lentos** (Medio)
5. **Errores consecutivos** (Alto)

### 📊 Métricas Monitoreadas
- ✅ **Response time** de modelos y APIs
- ✅ **Error rates** por endpoint
- ✅ **CPU, RAM, Disco** del sistema
- ✅ **Conexiones** de base de datos activas
- ✅ **Contenedores Docker** corriendo
- ✅ **Tokens procesados** por modelos LLM

## 🐳 Docker Compose Integration

```yaml
services:
  stats-api:
    build:
      context: ./stats
      dockerfile: Dockerfile
    container_name: stats-api
    restart: always
    ports:
      - "${STATS_PORT:-8003}:8003"
    environment:
      - DOCKER_ENV=true
      - DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@postgres:5432/ai_platform_stats
    depends_on:
      - postgres
    networks:
      - ai_platform_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8003/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

## 📝 Logging y Debugging

### 📋 Logs Estructurados
```bash
# Ver logs en tiempo real
docker logs -f stats-api

# Logs con nivel DEBUG
export LOG_LEVEL=DEBUG
python app.py
```

### 🔍 Debugging Health Checks
```python
# Verificar manualmente un modelo
curl http://localhost:8003/api/admin/refresh-models

# Ver estado de modelo específico  
curl http://localhost:8003/api/metrics/model/gemma-2b

# Ver alertas activas
curl http://localhost:8003/api/stats/alerts?resolved=false
```

## 🚀 Performance y Escalabilidad

- ✅ **Pool de conexiones** AsyncPG optimizado
- ✅ **Índices estratégicos** en todas las tablas  
- ✅ **Limpieza automática** de datos antiguos
- ✅ **Métricas agregadas** por hora/día
- ✅ **Health checks paralelos** para modelos
- ✅ **Middleware asíncrono** sin bloqueos

---

**🎯 Sistema completo de observabilidad para la plataforma IBM AI Backend**

*Monitoreo automático, alertas proactivas y métricas detalladas para máxima visibilidad del sistema* 🚀