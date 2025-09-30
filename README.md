# AI Platform Simplificado

Plataforma de inteligencia artificial simplificada con **1 modelo LLM**, **PostgreSQL** y **2 APIs**.

## 🏗️ Arquitectura Simplificada

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │   LLM Server    │    │      APIs       │
│   (Port 8070)   │    │   (Port 8080)   │    │ Fraude: 8000    │
│                 │    │                 │    │ TextSQL: 8001   │
│ • banco_global  │    │ • Gemma 2B      │    │                 │
│ • demo_retail   │    │   (~1.5GB)      │    │                 │
│ • bank_trans... │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## ⚡ Instalación Rápida

### 1. Prerequisitos
```bash
# Docker y Docker Compose deben estar instalados
docker --version
docker-compose --version
```

### 2. Instalación
```bash
# Clonar repositorio
git clone https://github.com/Junstant/IBM-AI-Platform-Back.git
cd IBM-AI-Platform-Back

# Ejecutar instalación
chmod +x setup.sh
./setup.sh
```

### 3. Descargar Modelo LLM
```bash
# Usar el menú interactivo
./ai-platform.sh
# Seleccionar opción 4: Descargar modelo Gemma 2B
```

### 4. Iniciar Servicios
```bash
# Usar el menú interactivo
./ai-platform.sh
# Seleccionar opción 1: Iniciar todos los servicios
```

## 🎯 Servicios Disponibles

### 📊 APIs
- **Fraude API**: `http://localhost:8000/docs`
  - Detección de transacciones fraudulentas
  - Machine Learning integrado
  
- **TextoSQL API**: `http://localhost:8001/docs`
  - Conversión de texto natural a SQL
  - Integrado con LLM

### 🗄️ Base de Datos
- **PostgreSQL**: `localhost:8070`
  - Usuario: `postgres`
  - Contraseña: `postgres`
  - Base principal: `banco_global`

### 🧠 Modelo LLM
- **LLM Server**: `http://localhost:8080`
  - Modelo: Gemma 2B (Google)
  - Tamaño: ~1.5GB
  - Propósito: Procesamiento de lenguaje natural

## 🛠️ Gestión del Sistema

### Script Principal
```bash
./ai-platform.sh
```

**Opciones disponibles:**
1. ✅ Iniciar todos los servicios
2. ⏹️ Detener todos los servicios  
3. 🔄 Reinicio limpio completo
4. 📥 Descargar modelo Gemma 2B
5. 📋 Ver otros modelos disponibles
6. 📊 Ver estado de modelos
7. 🧹 Limpiar modelos descargados
8. 🔍 Ver estado actual
9. 📜 Ver logs de servicios
10. ⚙️ Crear archivo .env

### Comandos Docker Útiles
```bash
# Ver estado de contenedores
docker-compose ps

# Ver logs de un servicio
docker-compose logs -f [postgres|llm-server|fraude-api|textosql-api]

# Reiniciar un servicio específico
docker-compose restart [servicio]

# Parar todos los servicios
docker-compose down

# Diagnóstico completo
./scripts/diagnose.sh
```

## 🔧 Configuración

### Archivo .env
El archivo `.env` contiene todas las configuraciones:
```env
# Base de datos
DB_HOST=postgres_ai_platform
DB_PORT=8070
DB_USER=postgres
DB_PASSWORD=postgres

# APIs
FRAUDE_API_PORT=8000
TEXTOSQL_API_PORT=8001

# LLM
LLM_PORT=8080
LLM_HOST=llm-server
```

## 💡 Consejos y Mejores Prácticas

### 💾 Requisitos del Sistema
- **RAM**: Mínimo 4GB, recomendado 8GB+
- **Disco**: Mínimo 5GB libres
- **CPU**: 2+ cores recomendado

### 🚀 Optimización
- **Gemma 2B** es el modelo más eficiente para empezar
- Los datos de PostgreSQL persisten entre reinicios
- Use `docker-compose down` para parar servicios sin perder datos

### 🔍 Solución de Problemas
```bash
# Diagnóstico completo
./scripts/diagnose.sh

# Ver logs detallados
docker-compose logs -f

# Reinicio limpio si hay problemas
./ai-platform.sh -> Opción 3
```

## 📁 Estructura del Proyecto

```
├── docker-compose.yaml      # Configuración de servicios
├── setup.sh                 # Script de instalación
├── ai-platform.sh          # Script de gestión principal
├── .env                     # Variables de configuración
├── models/                  # Modelos LLM descargados
├── database/                # Configuración PostgreSQL
│   ├── init-scripts/        # Scripts de inicialización
│   └── Dockerfile
├── fraude/                  # API de detección de fraudes
│   ├── app.py
│   ├── requirements.txt
│   └── Dockerfile
├── textoSql/               # API de texto a SQL
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
└── scripts/
    └── diagnose.sh         # Script de diagnóstico
```

## 🆘 Soporte

### URLs de Acceso Rápido
- 📊 **Fraude API Docs**: http://localhost:8000/docs
- 🔍 **TextoSQL API Docs**: http://localhost:8001/docs  
- 🧠 **LLM Server**: http://localhost:8080
- 🗄️ **PostgreSQL**: localhost:8070

### Comandos de Emergencia
```bash
# Si algo no funciona:
docker-compose down
docker system prune -f
./ai-platform.sh # Opción 3: Reinicio limpio

# Para empezar desde cero:
rm -rf models/*
./setup.sh
```

---

**¡Listo para usar!** 🎉 La plataforma AI simplificada está diseñada para ser fácil de instalar y gestionar.