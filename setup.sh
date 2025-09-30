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
    
    # Verificar arquitectura
    local ARCH=$(uname -m)
    log "🏗️ Arquitectura detectada: $ARCH"
    
    if [[ "$ARCH" == "ppc64le" ]]; then
        log "⚡ Sistema Power PC detectado - aplicando optimizaciones"
        export USE_PPC_OPTIMIZATIONS=true
    else
        log "💻 Arquitectura estándar detectada"
    fi
    
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
    elif docker compose version &> /dev/null 2>&1; then
        log "✅ Docker Compose (plugin) está disponible"
        # Crear alias para compatibilidad
        echo 'alias docker-compose="docker compose"' >> ~/.bashrc
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
        log "📋 Por favor inicie Docker"
        exit 1
    fi
    
    # Verificar espacio en disco (al menos 10GB para Mistral)
    available_space=$(df . | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 10485760 ]; then  # 10GB en KB
        log "⚠️ Advertencia: Poco espacio en disco disponible"
        log "💡 Se recomienda tener al menos 10GB libres para el modelo Mistral"
    else
        log "✅ Espacio en disco suficiente"
    fi
    
    # Verificar memoria RAM (al menos 8GB para Mistral)
    if command -v free &> /dev/null; then
        local mem_gb=$(free -g | awk '/^Mem:/ {print $2}')
        if [ "$mem_gb" -lt 8 ]; then
            log "⚠️ Advertencia: Solo ${mem_gb}GB de RAM. Mistral requiere al menos 8GB"
        else
            log "✅ Memoria suficiente: ${mem_gb}GB"
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

# ===== DESCARGAR MODELO MISTRAL =====
download_mistral_model() {
    log "🧠 Descargando modelo Mistral 7B..."
    
    # Crear directorio de modelos
    mkdir -p models
    
    local filename="mistral-7b-instruct-v0.3.Q4_K_M.gguf"
    local url="https://huggingface.co/SanctumAI/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/mistral-7b-instruct-v0.3.Q4_K_M.gguf"
    
    if [ -f "models/$filename" ]; then
        log "✅ Modelo Mistral ya existe"
        ls -lh "models/$filename"
        return 0
    fi
    
    log "⏳ Descargando Mistral 7B (~4GB)... esto puede tomar varios minutos"
    log "📍 URL: $url"
    
    if curl -L --progress-bar -o "models/$filename" "$url"; then
        log "✅ Modelo Mistral descargado exitosamente"
        ls -lh "models/$filename"
        return 0
    else
        log "❌ Error descargando Mistral"
        rm -f "models/$filename"
        return 1
    fi
}

# ===== INSTALAR DEPENDENCIAS =====
install_dependencies() {
    log "📦 Configurando dependencias..."
    
    local ARCH=$(uname -m)
    
    # Configurar Python para ppc64le si es necesario
    if [[ "$ARCH" == "ppc64le" ]]; then
        log "⚡ Configurando repositorios optimizados para Power PC..."
        
        # Actualizar pip primero
        pip3 install --upgrade pip || true
        
        # Configurar pip para usar repositorios de wheels ppc64le
        mkdir -p ~/.pip
        cat > ~/.pip/pip.conf << 'EOF'
[global]
extra-index-url = https://repo.fury.io/mgiessing
prefer-binary = true
timeout = 300
break-system-packages = true
EOF
        log "✅ Configuración PPC64LE aplicada"
    fi
    
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
        elif command -v dnf &> /dev/null; then
            log "📦 Instalando curl..."
            sudo dnf install -y curl
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
    echo "1. Los modelos se descargan automáticamente durante la instalación"
    echo "   • Mistral 7B descargado y configurado"
    echo ""
    echo "2. Iniciar todos los servicios:"
    echo "   ./ai-platform.sh"
    echo "   Opción 2: Iniciar todos los servicios"
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
    echo "• Mistral 7B (~4GB) es un modelo potente y versátil"
    echo "• Requiere al menos 8GB de RAM para funcionar bien"
    echo "• Los datos de PostgreSQL se mantienen entre reinicios"
    echo "• Compatible con arquitectura ppc64le (Power PC)"
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
    
    # Descargar modelo Mistral
    download_mistral_model
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