# 📋 Configuración Centralizada - Guía de Uso

## 🎯 Visión General

Este módulo proporciona **configuración centralizada** para toda la plataforma AI, eliminando valores hardcodeados y permitiendo fácil gestión de entornos (Docker vs Local).

**Modelos LLM disponibles:** Gemma 2B, Gemma 4B, Gemma 12B, Mistral 7B, DeepSeek 8B

## 📁 Estructura

```
shared/config/
├── __init__.py          # Punto de entrada principal
├── base.py              # Configuración base y detección de entorno
├── database.py          # Configuración de bases de datos
├── models.py            # Configuración de modelos LLM
└── services.py          # Configuración de APIs y servicios
```

## 🚀 Uso Básico

### Importar Configuración

```python
from shared.config import get_config, DatabaseConfig, ModelsConfig, ServicesConfig

# Configuración base
config = get_config()
print(f"Entorno: {'Docker' if config.is_docker else 'Local'}")

# Configuración de bases de datos
db_config = DatabaseConfig()
banco_url = db_config.get_database_url('banco_global')

# Configuración de modelos
models_config = ModelsConfig()
all_models = models_config.get_all_models()

# Configuración de servicios
services_config = ServicesConfig()
textosql_url = services_config.get_service_config('textosql')['url']
```

## 📚 Ejemplos por Servicio

### 1. TextoSQL API

**Antes (hardcodeado):**
```python
if os.path.exists('/.dockerenv'):
    host = "gemma-2b"
    port = "8080"
else:
    host = "localhost"
    port = "8085"
```

**Después (usando configuración centralizada):**
```python
from shared.config import ModelsConfig

models_config = ModelsConfig()
gemma_config = models_config.get_model_config('gemma-2b')

host = gemma_config['host']
port = gemma_config['internal_port'] if models_config.base_config.is_docker else gemma_config['external_port']
url = gemma_config['url']  # Ya construido automáticamente
```

### 2. Fraud API

**Antes (hardcodeado):**
```python
DB_HOST = os.getenv('DB_HOST', 'localhost')
DB_PORT = os.getenv('DB_PORT', '8070')
DB_NAME = 'bank_transactions'
```

**Después (usando configuración centralizada):**
```python
from shared.config import DatabaseConfig

db_config = DatabaseConfig()
database_url = db_config.get_database_url(db_config.bank_transactions_db)
# postgresql://postgres:root@postgres:5432/bank_transactions (en Docker)
# postgresql://postgres:root@localhost:8070/bank_transactions (en local)
```

### 3. Stats API

**Antes (hardcodeado):**
```python
models_config = {
    "gemma-2b": {"port": 8085, "type": "llm", "size": "2B"},
    "fraud-api": {"port": 8001, "type": "fraud", "size": None},
}
```

**Después (usando configuración centralizada):**
```python
from shared.config import ModelsConfig, ServicesConfig

# Modelos LLM
models_config = ModelsConfig()
all_models = models_config.get_all_models()  # Lista completa con URLs correctas

# Servicios/APIs
services_config = ServicesConfig()
all_services = services_config.get_all_services()  # Dict con todas las APIs
```

### 4. RAG API

**Antes (hardcodeado):**
```python
MILVUS_HOST = "localhost" if not in_docker else "milvus"
MILVUS_PORT = 19530
POSTGRES_HOST = "localhost"
```

**Después (usando configuración centralizada):**
```python
from shared.config import DatabaseConfig

db_config = DatabaseConfig()

# Milvus
milvus_config = db_config.get_milvus_config()
milvus_host = milvus_config['host']
milvus_port = milvus_config['port']

# PostgreSQL
postgres_url = db_config.get_database_url(db_config.rag_db)
```

## 🔧 Configuración del .env

Todas las variables están centralizadas en `.env`:

```env
# === CONFIGURACIÓN DE ENTORNO ===
ENVIRONMENT=production
DEBUG=false
DOCKER_ENV=true

# === NOMBRES DE CONTENEDORES ===
POSTGRES_CONTAINER_NAME=postgres
FRAUD_API_CONTAINER_NAME=fraude-api
TEXTOSQL_API_CONTAINER_NAME=textosql-api
STATS_CONTAINER_NAME=stats-api
RAG_CONTAINER_NAME=rag-api
FRONTEND_CONTAINER_NAME=frontend

# === PUERTOS INTERNOS DOCKER ===
DB_INTERNAL_PORT=5432
LLM_INTERNAL_PORT=8080
API_INTERNAL_PORT=8000

# === PUERTOS EXTERNOS ===
GEMMA_2B_PORT=8085
FRAUD_API_PORT=8001
STATS_PORT=8003
# ... etc
```

## ✅ Beneficios

1. **Sin hardcoding**: Todos los valores vienen del `.env`
2. **Detección automática**: Docker vs Local
3. **URLs correctas**: Se construyen automáticamente según el entorno
4. **Fácil mantenimiento**: Cambios solo en `.env`
5. **Type hints**: Autocompletado en IDEs
6. **Documentado**: Cada función tiene docstrings

## 🔄 Migración

Para migrar un servicio existente:

1. **Instalar** el módulo de configuración:
   ```bash
   # El módulo está en shared/config/
   ```

2. **Importar** en tu servicio:
   ```python
   from shared.config import DatabaseConfig, ModelsConfig, ServicesConfig
   ```

3. **Reemplazar** valores hardcodeados:
   ```python
   # Antes
   DB_HOST = "postgres_db"
   
   # Después
   db_config = DatabaseConfig()
   DB_HOST = db_config.get_postgres_host()
   ```

4. **Probar** en ambos entornos (Docker y local)

## 🎯 API Reference

### BaseConfig

- `is_docker: bool` - True si está en Docker
- `get_host(service_name, external_host)` - Obtiene host correcto
- `get_internal_port(service_type)` - Obtiene puerto interno

### DatabaseConfig

- `get_postgres_host()` - Host de PostgreSQL
- `get_database_url(db_name)` - URL completa de conexión
- `get_milvus_config()` - Configuración de Milvus

### ModelsConfig

- `get_all_models()` - Lista de todos los modelos
- `get_model_config(model_id)` - Configuración de un modelo específico
- `get_models_by_size(size_range)` - Filtrar por tamaño

### ServicesConfig

- `get_all_services()` - Dict de todos los servicios
- `get_service_config(service_id)` - Configuración de un servicio
- `get_api_services()` - Solo servicios tipo API

## 📝 Notas

- Todos los módulos detectan automáticamente si están en Docker
- Las URLs se construyen correctamente para cada entorno
- Los puertos internos y externos se manejan automáticamente
- Compatible con todos los servicios existentes
