# 🤖 IBM AI Platform Backend

Plataforma backend de inteligencia artificial empresarial con **múltiples modelos LLM**, **PostgreSQL** y **APIs especializadas**.

## 🏗️ Arquitectura Avanzada

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   5 LLM Models  │    │   APIs Backend  │
│   (Port 8070)   │    │   (8085-8089)   │    │ Fraude: 8001    │
│                 │    │                 │    │ TextSQL: 8000   │
│ • banco_global  │    │ • Gemma 2B      │    │ Frontend: 2012  │
│ • bank_trans... │    │ • Gemma 4B      │    │                 │
│ • 5000+ clients │    │ • Gemma 12B     │    │                 │
│ • 15000+ trans  │    │ • Mistral 7B    │    │                 │
│                 │    │ • DeepSeek 8B   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## ✨ Características Principales

- 🧠 **5 Modelos LLM**: Gemma (2B, 4B, 12B), Mistral 7B, DeepSeek 8B
- 🛡️ **Detección de Fraude**: ML avanzado con Random Forest (+20 características)
- 🔍 **TextoSQL**: Conversión de lenguaje natural a SQL con múltiples modelos
- 📊 **Datos Masivos**: 5000+ clientes, 8000+ cuentas, 15000+ transacciones
- 🐳 **Docker Completo**: Orquestación automática de todos los servicios
- 🌐 **Frontend React**: Interfaz web completa incluida
- 🔄 **Auto-configuración**: Detección inteligente de entorno y recursos

## ⚡ Instalación Rápida

### 1. Prerequisitos
```bash
# Docker y Docker Compose deben estar instalados
docker --version
docker-compose --version

# Recursos mínimos requeridos:
# • RAM: 8GB+ (recomendado 16GB)
# • Disco: 20GB+ libres
# • CPU: 4+ cores recomendado
```

### 2. Clonar e Instalar
```bash
# Clonar repositorio
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back

# Ejecutar instalación automática
chmod +x setup.sh
./setup.sh
```

### 3. Configurar Token de HuggingFace (Opcional)
```bash
# Editar archivo .env para acelerar descarga de modelos
nano .env
# Agregar: TOKEN_HUGGHINGFACE=tu_token_aqui
```

### 4. Iniciar Todos los Servicios
```bash
# Iniciar plataforma completa
docker-compose up -d

# Verificar estado de servicios
docker-compose ps
```

### 5. Descargar Modelos LLM
Los modelos se descargan automáticamente al iniciar, pero puedes verificar:
```bash
# Ver progreso de descarga
docker-compose logs -f model-downloader

# Verificar modelos descargados
docker-compose exec gemma-2b ls -la /models/
```

## 🎯 Servicios Disponibles

### 🌐 Frontend Web
- **Aplicación React**: `http://localhost:2012`
  - Interfaz completa para todas las funcionalidades
  - Gestión de transacciones y consultas SQL
  - Selección dinámica de modelos LLM

### 🛡️ API de Detección de Fraude
- **Endpoint**: `http://localhost:8001/docs`
  - Machine Learning con Random Forest
  - Análisis individual y masivo de transacciones
  - +20 características de detección automática
  - Precisión >90% en detección de fraudes

### 🔍 API TextoSQL
- **Endpoint**: `http://localhost:8000/docs`
  - Conversión de lenguaje natural a SQL
  - 6 modelos LLM disponibles para selección
  - Soporte para múltiples bases de datos
  - Ejecución directa de consultas generadas

### � API de Estadísticas
- **Endpoint**: `http://localhost:8003/docs`
  - Dashboard de métricas en tiempo real
  - Monitoreo automático de modelos IA
  - Sistema de alertas proactivo
  - Performance y uso de recursos

### �🗄️ Base de Datos PostgreSQL
- **Host**: `localhost:8070`
  - Usuario: `postgres` / Contraseña: `root`
  - **banco_global**: Datos maestros (5000+ clientes, 8000+ cuentas)
  - **bank_transactions**: Transacciones (15000+ registros con fraudes)
  - **ai_platform_stats**: Métricas y estadísticas del sistema

### 🧠 Modelos LLM Disponibles
| Modelo | Puerto | Tamaño | Especialidad |
|--------|--------|---------|--------------|
| **Gemma 2B** | 8085 | ~1.5GB | Respuestas rápidas |
| **Gemma 4B** | 8086 | ~3GB | Equilibrio velocidad/calidad |
| **Gemma 12B** | 8087 | ~8GB | Alta precisión |
| **Mistral 7B** | 8088 | ~5GB | Tareas generales |
| **DeepSeek 8B** | 8089 | ~6GB | Razonamiento lógico |

## 🛠️ Gestión del Sistema

### Comandos Docker Principales
```bash
# Iniciar todos los servicios
docker-compose up -d

# Ver estado de todos los contenedores
docker-compose ps

# Ver logs de servicios específicos
docker-compose logs -f [postgres|fraude-api|textosql-api|stats-api|frontend]
docker-compose logs -f [gemma-2b|gemma-4b|mistral-7b|deepseek-8b]

# Reiniciar servicio específico
docker-compose restart [nombre-servicio]

# Parar todos los servicios
docker-compose down

# Parar y limpiar volúmenes (CUIDADO: borra datos)
docker-compose down -v
```

### Monitoreo y Diagnóstico
```bash
# Ver uso de recursos
docker stats

# Dashboard de estadísticas
curl http://localhost:8003/api/stats/dashboard-summary

# Estado de modelos IA
curl http://localhost:8003/api/stats/models-status

# Diagnóstico completo del sistema
./scripts/diagnose.sh

# Verificar conectividad entre servicios
docker-compose exec textosql-api curl http://gemma-4b:8080/health
docker-compose exec fraude-api curl http://postgres_db:5432

# Ver logs específicos de modelos LLM
docker-compose logs -f gemma-4b | grep -i "error\|ready\|loaded"
```

### Gestión de Modelos
```bash
# Ver estado de descarga de modelos
docker-compose logs model-downloader

# Verificar modelos disponibles
docker volume inspect aipl_models_volume

# Limpiar y re-descargar modelos
docker-compose down
docker volume rm aipl_models_volume
docker-compose up -d
```

## 🔧 Configuración

### Archivo .env (Variables Principales)
```env
# === CONFIGURACIÓN DE BASE DE DATOS ===
DB_PORT=8070                    # Puerto externo PostgreSQL
DB_USER=postgres
DB_PASSWORD=root
DB1_NAME=banco_global          # Base para TextoSQL
DB2_NAME=bank_transactions     # Base para Fraude

# === PUERTOS DE APIS ===
FRAUDE_API_PORT=8001          # API Detección de Fraude
TEXTOSQL_API_PORT=8000        # API Texto a SQL
STATS_PORT=8003               # API de Estadísticas
NGINX_PORT=2012               # Frontend React

# === PUERTOS DE MODELOS LLM ===
GEMMA_2B_PORT=8085           # Modelo Gemma 2B
GEMMA_4B_PORT=8086           # Modelo Gemma 4B  
GEMMA_12B_PORT=8087          # Modelo Gemma 12B
MISTRAL_PORT=8088            # Modelo Mistral 7B
DEEPSEEK_8B_PORT=8089        # Modelo DeepSeek 8B

# === CONFIGURACIÓN HUGGINGFACE ===
TOKEN_HUGGHINGFACE=tu_token_aqui   # Para descarga acelerada
```

### Configuración de Red Docker
Todos los servicios se ejecutan en la red `ai_platform_network`:
- Comunicación inter-container por nombre de servicio
- Puertos internos estándar (8000, 8080, 5432)
- Puertos externos mapeados según configuración

### Personalización de Recursos
Para ajustar recursos según tu hardware:
```yaml
# En docker-compose.yaml, agregar a cada servicio:
deploy:
  resources:
    limits:
      memory: 4G      # Ajustar según RAM disponible
      cpus: '2.0'     # Ajustar según CPU disponible
```

## 💡 Requisitos del Sistema y Optimización

### 💾 Requisitos Mínimos y Recomendados

| Componente | Mínimo | Recomendado | Óptimo |
|------------|---------|-------------|---------|
| **RAM** | 8GB | 16GB | 32GB+ |
| **Disco** | 20GB | 50GB | 100GB+ |
| **CPU** | 4 cores | 8 cores | 16+ cores |
| **GPU** | No requerida | Recomendada | RTX 3080+ |

```
IBM-AI-Platform-Back/
├── 📄 docker-compose.yaml      # Orquestación completa de servicios
├── 📄 setup.sh                 # Script de instalación automática
├── 📄 .env                     # Variables de configuración centralizadas
├── 📄 .gitignore              # Archivos ignorados por Git
├── 📄 README.md               # Esta documentación
├── 
├── 📁 database/               # Configuración PostgreSQL
│   ├── 📄 Dockerfile          # Imagen personalizada PostgreSQL
│   ├── 📄 postgresql.conf     # Configuración optimizada
│   ├── 📄 pg_hba.conf         # Configuración de autenticación
│   └── 📁 init-scripts/       # Scripts de inicialización automática
│       ├── 📄 00-master-init.sh
│       ├── 📄 01-create-databases.sql
│       └── 📁 databases/      # Esquemas y datos por BD
│           ├── 📁 banco_global/
│           └── 📁 bank_transactions/
├── 
├── 📁 fraude/                 # API de Detección de Fraude
│   ├── 📄 app.py              # Aplicación FastAPI + ML
│   ├── 📄 config.py           # Configuración específica
│   ├── 📄 requirements.txt    # Dependencias Python
│   ├── 📄 Dockerfile          # Imagen de la API
│   ├── 📄 .gitignore         # Archivos ignorados
│   └── 📄 README.md          # Documentación específica
├── 
├── 📁 textoSql/              # API de Texto a SQL
│   ├── 📄 app.py              # Aplicación FastAPI principal
│   ├── 📄 config.py           # Configuración de modelos LLM
│   ├── 📄 smart_config.py     # Configuración inteligente BD
│   ├── 📄 llama_interface.py  # Interfaz con modelos LLM
│   ├── 📄 database_analyzer.py # Análisis de esquemas BD
│   ├── 📄 connection_manager.py # Gestión de conexiones
│   ├── 📄 llm_semantic_analyzer.py # Análisis semántico
│   ├── 📄 utils.py           # Utilidades de procesamiento
│   ├── 📄 requirements.txt    # Dependencias Python
│   ├── 📄 Dockerfile          # Imagen de la API
│   ├── 📄 .gitignore         # Archivos ignorados
│   ├── 📄 test_databases.py   # Script de pruebas
│   └── 📄 README.md          # Documentación específica
├── 
├── 📁 schemas/               # Esquemas SQL de respaldo
│   ├── 📄 banco_global_schema.sql
│   ├── 📄 bank_transactions_schema.sql
│   ├── 📄 empresa_agronomia_schema.sql
│   ├── 📄 empresa_minera_schema.sql
│   ├── 📄 petrolera_schema.sql
│   ├── 📄 rentalco_schema.sql
│   └── 📄 supermercado_schema.sql
└── 
└── 📁 scripts/              # Utilidades del sistema
    └── 📄 diagnose.sh       # Script de diagnóstico completo
```

### 🔗 Dependencias Externas
- **Frontend**: Repositorio separado `IBM-AI-Platform-Front`
- **Modelos LLM**: Descarga automática desde HuggingFace
- **Datos**: Generación automática en primera ejecución

### 🛠️ Comandos de Diagnóstico
```bash
# Diagnóstico completo automático
./scripts/diagnose.sh

# Verificar todos los servicios
docker-compose ps

# Verificar conectividad completa
docker-compose exec textosql-api curl http://gemma-4b:8080/health
docker-compose exec fraude-api curl http://postgres_db:5432

# Ver uso de recursos
docker stats --no-stream

# Verificar logs de errores
docker-compose logs | grep -i error
```

### 🚀 Comandos de Emergencia
```bash
# Reinicio limpio total (CUIDADO: borra datos)
docker-compose down -v
docker system prune -af
docker volume prune -f
rm -rf ./models/*  # Solo si hay problemas con modelos
./setup.sh

# Reinicio conservando datos
docker-compose down
docker-compose up -d

# Verificar y reparar volúmenes
docker volume ls
docker volume inspect aipl_models_volume
```

## 🌟 Características Avanzadas

### 🛡️ Detección de Fraude con ML
- **Algoritmo**: Random Forest con 20+ características derivadas
- **Precisión**: >90% en detección de patrones fraudulentos
- **Velocidad**: <50ms por predicción individual
- **Capacidades**:
  - Análisis individual de transacciones
  - Procesamiento masivo desde base de datos
  - Feature engineering automático
  - Detección de patrones temporales, geográficos y comportamentales

### 🔍 Conversión Inteligente de Texto a SQL
- **Modelos**: 6 LLMs especializados para diferentes casos de uso
- **Bases de Datos**: Soporte multi-esquema simultáneo
- **Funcionalidades**:
  - Análisis semántico de consultas en lenguaje natural
  - Generación de SQL optimizado
  - Ejecución directa y segura de consultas
  - Selección dinámica de modelo según complejidad

### 📊 Datos Empresariales Realistas
- **banco_global**: 5000+ clientes, 8000+ cuentas, productos financieros
- **bank_transactions**: 15000+ transacciones con patrones de fraude realistas
- **Características**:
  - Datos sintéticos pero estadísticamente válidos
  - Patrones de fraude complejos y variados
  - Relaciones realistas entre entidades

### 🔧 Configuración Inteligente
- **Detección de Entorno**: Automática entre Docker y desarrollo local
- **Balanceador de Modelos**: Failover automático entre LLMs disponibles
- **Optimización de Recursos**: Configuración dinámica según hardware disponible

## 🆘 Soporte y URLs de Acceso

### 🌐 Interfaces Web
- 🏠 **Frontend Principal**: `http://localhost:2012`
- 📊 **API Fraude (Swagger)**: `http://localhost:8001/docs`
- 🔍 **API TextoSQL (Swagger)**: `http://localhost:8000/docs`

### 🧠 Endpoints de Modelos LLM
- 🔹 **Gemma 2B**: `http://localhost:8085` (Rápido, ideal para desarrollo)
- 🔹 **Gemma 4B**: `http://localhost:8086` (Balanceado, recomendado para producción)
- 🔹 **Gemma 12B**: `http://localhost:8087` (Alta precisión)
- 🔹 **Mistral 7B**: `http://localhost:8088` (Versátil, excelente calidad)
- 🔹 **DeepSeek 8B**: `http://localhost:8089` (Razonamiento lógico)

### 🗄️ Acceso a Base de Datos
- **Host**: `localhost:8070`
- **Usuario**: `postgres`
- **Contraseña**: `root`
- **Herramientas recomendadas**: pgAdmin, DBeaver, psql

### 📞 Soporte Técnico
- 🔗 **Repositorio**: https://github.com/Junstant/IBM-AI-Platform-Back
- 📖 **Documentación**: Ver README.md en cada directorio de servicio
- 🐛 **Issues**: Reportar problemas en GitHub Issues
- 📧 **Contacto**: Crear issue para soporte directo

## 🤝 Contribución y Desarrollo

### 🔧 Configuración de Desarrollo
```bash
# Clonar repositorio para desarrollo
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back

# Configurar hooks de pre-commit
pip install pre-commit
pre-commit install

# Desarrollar con hot-reload
docker-compose -f docker-compose.dev.yaml up
```

### 📝 Guía de Contribución
1. **Fork** del repositorio principal
2. **Crear rama**: `git checkout -b feature/nueva-funcionalidad`
3. **Desarrollar** siguiendo las convenciones del proyecto
4. **Probar** con `docker-compose up` y verificar todas las APIs
5. **Commit**: `git commit -am 'feat: nueva funcionalidad'`
6. **Push**: `git push origin feature/nueva-funcionalidad`
7. **Pull Request** con descripción detallada

### 🧪 Pruebas Automatizadas
```bash
# Probar APIs de fraude
cd fraude && python -m pytest

# Probar APIs de textoSQL
cd textoSql && python test_databases.py

# Probar conectividad completa
./scripts/diagnose.sh
```

## 📄 Licencia y Legal

Este proyecto está bajo la **Licencia MIT**.

### 🏢 Información Corporativa
- **Desarrollado para**: IBM AI Platform Initiative
- **Mantenido por**: Equipo de Desarrollo IBM AI Backend
- **Versión**: 2.0.0 (Octubre 2024)
- **Soporte**: Disponible a través de GitHub Issues

### ⚖️ Términos de Uso
- Uso libre para desarrollo, testing y producción
- Contribuciones bienvenidas bajo los mismos términos
- Sin garantías explícitas, usar bajo propio riesgo
- Datos sintéticos incluidos solo para demostración

---

### 🚀 Inicio Rápido en 3 Comandos:
```bash
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back && chmod +x setup.sh && ./setup.sh
docker-compose up -d
```
---

*Construido con ❤️ para la transformación digital empresarial*