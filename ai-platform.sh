#!/bin/bash

# Script maestro para gestionar AI Platform con descarga automática de modelos
echo "🚀 AI PLATFORM - GESTOR MAESTRO"
echo "==============================="

cd "$(dirname "$0")/.."

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Función para mostrar menú
show_menu() {
    clear
    echo "🚀 AI PLATFORM - MENÚ PRINCIPAL"
    echo "==============================="
    echo ""
    echo "📋 OPCIONES DISPONIBLES:"
    echo "========================"
    echo ""
    echo "🔧 GESTIÓN BÁSICA:"
    echo "  1) Iniciar servicios básicos (PostgreSQL + APIs + Modelos pequeños)"
    echo "  2) Iniciar todos los servicios"
    echo "  3) Detener todos los servicios"
    echo "  4) Reinicio limpio completo"
    echo ""
    echo "📥 GESTIÓN DE MODELOS:"
    echo "  5) Descargar modelos manualmente"
    echo "  6) Ver estado de modelos"
    echo "  7) Limpiar modelos descargados"
    echo ""
    echo "🔍 DIAGNÓSTICO:"
    echo "  8) Diagnóstico completo del sistema"
    echo "  9) Ver logs de servicios"
    echo "  10) Ver estado actual"
    echo ""
    echo "⚙️ CONFIGURACIÓN:"
    echo "  11) Recrear archivos de configuración"
    echo "  12) Verificar requisitos del sistema"
    echo ""
    echo "  0) Salir"
    echo ""
}

# Función para verificar requisitos
check_requirements() {
    log "🔍 Verificando requisitos del sistema..."
    
    # Verificar Docker
    if ! docker --version > /dev/null 2>&1; then
        log "❌ Docker no está instalado"
        return 1
    fi
    log "✅ Docker disponible"
    
    # Verificar Docker Compose
    if ! docker-compose --version > /dev/null 2>&1; then
        log "❌ Docker Compose no está disponible"
        return 1
    fi
    log "✅ Docker Compose disponible"
    
    # Verificar espacio en disco
    available_space=$(df . | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 10485760 ]; then  # 10GB en KB
        log "⚠️ Espacio en disco bajo (menos de 10GB disponibles)"
    else
        log "✅ Espacio en disco suficiente"
    fi
    
    # Verificar memoria
    available_memory=$(free -m | awk 'NR==2{print $7}')
    if [ "$available_memory" -lt 4096 ]; then  # 4GB
        log "⚠️ Memoria disponible baja (menos de 4GB)"
    else
        log "✅ Memoria suficiente"
    fi
    
    return 0
}

# Función para ver logs
view_logs() {
    echo "📋 LOGS DE SERVICIOS"
    echo "==================="
    echo ""
    echo "Selecciona el servicio:"
    echo "1) PostgreSQL"
    echo "2) TextoSQL API"
    echo "3) Fraude API"
    echo "4) Mistral 7B"
    echo "5) Granite 8B"
    echo "6) Gemma 2B"
    echo "7) Todos los servicios"
    echo ""
    read -p "Opción: " log_choice
    
    case $log_choice in
        1) docker-compose logs -f postgres ;;
        2) docker-compose logs -f textosql-api ;;
        3) docker-compose logs -f fraude-api ;;
        4) docker-compose logs -f mistral-td-server ;;
        5) docker-compose logs -f granite-td-server ;;
        6) docker-compose logs -f gemma2b-td-server ;;
        7) docker-compose logs -f ;;
        *) echo "❌ Opción no válida" ;;
    esac
}

# Función para limpiar modelos
clean_models() {
    echo "🧹 LIMPIEZA DE MODELOS"
    echo "====================="
    echo ""
    echo "⚠️ ADVERTENCIA: Esto eliminará todos los modelos descargados"
    echo "Tendrás que descargarlos nuevamente para usar los servicios LLM"
    echo ""
    read -p "¿Estás seguro? (s/N): " confirm
    
    if [[ $confirm =~ ^[Ss]$ ]]; then
        log "🧹 Limpiando modelos..."
        rm -rf models/*
        log "✅ Modelos eliminados"
        du -sh models/ 2>/dev/null || echo "📁 Directorio models vacío"
    else
        log "❌ Operación cancelada"
    fi
}

# Función para recrear configuración
recreate_config() {
    log "⚙️ Recreando archivos de configuración..."
    
    # Recrear .env si no existe
    if [ ! -f .env ]; then
        log "📝 Creando archivo .env..."
        cat > .env << 'EOF'
# Configuración de la base de datos
DB_HOST=postgres
DB_PORT=8070
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=postgres

# APIs
FRAUDE_API_PORT=8000
TEXTOSQL_API_PORT=8001

# Modelos LLM
MISTRAL_PORT=8096
GRANITE_PORT=8095
GEMMA2B_PORT=9470
GEMMA_4B_PORT=8094
GEMMA_12B_PORT=2005
DEEPSEEK_1_5B_PORT=8091
DEEPSEEK_8B_PORT=8092
DEEPSEEK_14B_PORT=8090
GRANITE_2B_PORT=8097
GPT_OSS_20B_PORT=8098

# Configuración general
COMPOSE_PROJECT_NAME=platform_ai_lj
NGINX_PORT=2012
EOF
        log "✅ Archivo .env creado"
    else
        log "✅ Archivo .env ya existe"
    fi
    
    # Crear directorio de modelos
    mkdir -p models
    log "✅ Directorio models verificado"
    
    # Verificar permisos de scripts
    chmod +x scripts/*.sh
    log "✅ Permisos de scripts verificados"
}

# Menú principal
while true; do
    show_menu
    read -p "Selecciona una opción (0-12): " choice
    
    case $choice in
        1)
            log "🚀 Iniciando servicios básicos..."
            ./scripts/start-basic-models.sh
            ;;
        2)
            log "🚀 Iniciando todos los servicios..."
            docker-compose up -d
            echo "⏳ Los modelos se descargarán automáticamente en el primer uso"
            echo "📊 Estado actual:"
            docker-compose ps
            ;;
        3)
            log "🛑 Deteniendo todos los servicios..."
            docker-compose down
            ;;
        4)
            log "🔄 Ejecutando reinicio limpio..."
            ./scripts/restart-clean.sh
            ;;
        5)
            ./scripts/download-models.sh
            ;;
        6)
            log "📊 Estado de modelos descargados:"
            if [ -d models ] && [ "$(ls -A models)" ]; then
                ls -lh models/
                echo ""
                echo "💾 Espacio total usado:"
                du -sh models/
            else
                echo "📁 No hay modelos descargados"
            fi
            ;;
        7)
            clean_models
            ;;
        8)
            ./scripts/diagnose.sh
            ;;
        9)
            view_logs
            ;;
        10)
            log "📊 Estado actual de servicios:"
            docker-compose ps
            echo ""
            log "🔗 URLs de acceso:"
            echo "   PostgreSQL:     http://localhost:8070"
            echo "   TextoSQL API:   http://localhost:8001/docs"
            echo "   Fraude API:     http://localhost:8000/docs"
            echo "   Mistral 7B:     http://localhost:8096"
            echo "   Granite 8B:     http://localhost:8095"
            echo "   Gemma 2B:       http://localhost:9470"
            ;;
        11)
            recreate_config
            ;;
        12)
            check_requirements
            ;;
        0)
            log "👋 ¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "❌ Opción no válida. Por favor selecciona 0-12."
            ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
done