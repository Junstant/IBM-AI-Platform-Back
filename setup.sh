#!/bin/bash
# Script simplificado de instalación para AI Platform

set -e

echo "🚀 INSTALACIÓN SIMPLIFICADA DE AI PLATFORM"
echo "=========================================="

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# ===== VERIFICAR REQUISITOS =====
check_requirements() {
    log "🔍 Verificando requisitos del sistema..."
    
    # Verificar sistema operativo
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log "✅ Sistema: Linux detectado"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log "✅ Sistema: macOS detectado"
    else
        log "⚠️ Sistema no reconocido, continuando..."
    fi
    
    # Verificar Docker
    if command -v docker &> /dev/null; then
        log "✅ Docker está instalado: $(docker --version)"
    else
        log "❌ Docker no está instalado"
        log "📋 Por favor instale Docker desde: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Verificar Docker Compose
    if command -v docker-compose &> /dev/null; then
        log "✅ Docker Compose está instalado: $(docker-compose --version)"
    else
        log "❌ Docker Compose no está instalado"
        log "📋 Por favor instale Docker Compose desde: https://docs.docker.com/compose/install/"
        exit 1
    fi
    
    # Verificar que Docker esté ejecutándose
    if docker ps &> /dev/null; then
        log "✅ Docker está ejecutándose"
    else
        log "❌ Docker no está ejecutándose"
        log "📋 Por favor inicie Docker y ejecute este script nuevamente"
        exit 1
    fi
    
    # Verificar espacio en disco (al menos 5GB)
    available_space=$(df . | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 5242880 ]; then  # 5GB en KB
        log "⚠️ Espacio en disco bajo (menos de 5GB disponibles)"
        log "💡 Se recomienda tener al menos 5GB libres para los modelos"
    else
        log "✅ Espacio en disco suficiente"
    fi
    
    # Verificar memoria RAM (al menos 4GB)
    if command -v free &> /dev/null; then
        available_memory=$(free -m | awk 'NR==2{print $2}')
        if [ "$available_memory" -lt 4096 ]; then  # 4GB
            log "⚠️ RAM total menor a 4GB. El rendimiento puede ser limitado"
        else
            log "✅ RAM suficiente: ${available_memory}MB"
        fi
    fi
}

# ===== PREPARAR PROYECTO =====
prepare_project() {
    log "🔧 Preparando estructura del proyecto..."
    
    # Crear directorio de modelos
    mkdir -p models
    log "✅ Directorio models creado"
    
    # Verificar permisos de scripts
    chmod +x ai-platform.sh
    chmod +x scripts/*.sh 2>/dev/null || true
    log "✅ Permisos de scripts configurados"
    
    # Crear archivo .env si no existe
    if [ ! -f .env ]; then
        log "📝 Creando archivo .env..."
        cat > .env << 'EOF'
# Configuración de la base de datos
DB_HOST=postgres_ai_platform
DB_PORT=8070
DB_USER=postgres
DB_PASSWORD=postgres
DB_NAME=postgres
DB_NAME_TEXTOSQL=banco_global

# APIs
FRAUDE_API_PORT=8000
TEXTOSQL_API_PORT=8001

# Modelo LLM
LLM_PORT=8080
LLM_HOST=llm-server

# Configuración general
COMPOSE_PROJECT_NAME=platform_ai_lj
EOF
        log "✅ Archivo .env creado"
    else
        log "✅ Archivo .env ya existe"
    fi
}

# ===== INSTALAR DEPENDENCIAS =====
install_dependencies() {
    log "📦 Verificando dependencias adicionales..."
    
    # Verificar curl
    if command -v curl &> /dev/null; then
        log "✅ curl está disponible"
    else
        log "❌ curl no está instalado"
        if command -v apt-get &> /dev/null; then
            log "📦 Instalando curl..."
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &> /dev/null; then
            log "📦 Instalando curl..."
            sudo yum install -y curl
        elif command -v brew &> /dev/null; then
            log "📦 Instalando curl..."
            brew install curl
        else
            log "⚠️ No se pudo instalar curl automáticamente. Instálelo manualmente."
        fi
    fi
    
    # Verificar git
    if command -v git &> /dev/null; then
        log "✅ git está disponible"
    else
        log "⚠️ git no está instalado (opcional para actualizaciones)"
    fi
}

# ===== CONSTRUIR IMÁGENES =====
build_images() {
    log "🔨 Construyendo imágenes Docker..."
    
    if docker-compose build; then
        log "✅ Imágenes construidas exitosamente"
    else
        log "❌ Error construyendo imágenes"
        exit 1
    fi
}

# ===== PROBAR CONEXIÓN DE BASE DE DATOS =====
test_database() {
    log "🧪 Probando base de datos..."
    
    # Iniciar solo PostgreSQL
    docker-compose up -d postgres
    
    # Esperar a que PostgreSQL esté listo
    for i in {1..30}; do
        if docker exec postgres_ai_platform pg_isready -U postgres 2>/dev/null; then
            log "✅ PostgreSQL está funcionando correctamente"
            docker-compose down
            return 0
        else
            log "⏳ Esperando PostgreSQL... ($i/30)"
            sleep 2
        fi
    done
    
    log "❌ PostgreSQL no responde después de 60 segundos"
    log "📋 Logs de PostgreSQL:"
    docker-compose logs postgres
    exit 1
}

# ===== MOSTRAR INFORMACIÓN FINAL =====
show_final_info() {
    log "🎉 ¡Instalación completada exitosamente!"
    echo ""
    echo "📋 PRÓXIMOS PASOS:"
    echo "=================="
    echo ""
    echo "1. Descargar el modelo LLM (recomendado):"
    echo "   ./ai-platform.sh"
    echo "   Opción 4: Descargar modelo Gemma 2B"
    echo ""
    echo "2. Iniciar todos los servicios:"
    echo "   ./ai-platform.sh"
    echo "   Opción 1: Iniciar todos los servicios"
    echo ""
    echo "3. Acceder a las aplicaciones:"
    echo "   • TextoSQL API: http://localhost:8001/docs"
    echo "   • Fraude API:   http://localhost:8000/docs"
    echo "   • LLM Server:   http://localhost:8080"
    echo "   • PostgreSQL:   localhost:8070"
    echo ""
    echo "📖 COMANDOS ÚTILES:"
    echo "==================="
    echo "• Gestión completa:     ./ai-platform.sh"
    echo "• Ver estado:           docker-compose ps"
    echo "• Ver logs:             docker-compose logs [servicio]"
    echo "• Parar servicios:      docker-compose down"
    echo ""
    echo "💡 CONSEJOS:"
    echo "============"
    echo "• El modelo Gemma 2B (~1.5GB) es recomendado para empezar"
    echo "• Asegúrese de tener suficiente RAM libre antes de iniciar"
    echo "• Los datos de PostgreSQL se mantienen entre reinicios"
    echo ""
}

# ===== FUNCIÓN PRINCIPAL =====
main() {
    echo ""
    log "🚀 Iniciando instalación de AI Platform..."
    echo ""
    
    # Verificar requisitos
    check_requirements
    echo ""
    
    # Preparar proyecto
    prepare_project
    echo ""
    
    # Instalar dependencias
    install_dependencies
    echo ""
    
    # Construir imágenes
    build_images
    echo ""
    
    # Probar base de datos
    test_database
    echo ""
    
    # Mostrar información final
    show_final_info
}

# Ejecutar función principal
main "$@"