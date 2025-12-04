# 🤖 IBM AI Platform Backend

Plataforma de inteligencia artificial con múltiples modelos LLM, PostgreSQL y APIs especializadas.

## ⚡ Instalación

```bash
# Clonar repositorio
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back

# Crear archivo .env con configuración requerida
# (FRONT_DIR, BACK_DIR, DB_PASSWORD, TOKEN_HUGGHINGFACE, DEFAULT_PORTS)

# Ejecutar instalación automática
chmod +x setup.sh
sudo ./setup.sh full
```

## 🎯 Servicios

- **Frontend**: `http://localhost:2012`
- **API Fraude**: `http://localhost:8001/docs`
- **API TextoSQL**: `http://localhost:8000/docs`
- **API Stats**: `http://localhost:8003/docs`
- **API RAG**: `http://localhost:8004/docs`
- **PostgreSQL**: `localhost:8070`
- **Milvus**: `localhost:19530`

## 🧠 Modelos LLM

- Gemma 2B (puerto 8085)
- Gemma 4B (puerto 8086)
- Gemma 12B (puerto 8087)
- Mistral 7B (puerto 8088)
- DeepSeek 8B (puerto 8089)
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

## 📝 Comandos Útiles

```bash
# Ver logs de servicios
docker-compose logs -f [servicio]

# Reiniciar servicios
docker-compose restart

# Ver estado
docker-compose ps

# Parar servicios
docker-compose down
```