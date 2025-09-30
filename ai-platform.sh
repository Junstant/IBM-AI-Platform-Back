#!/bin/bash

# Scrip    echo "🔧 C    echo "🔧 Configuración y Administración:"
    echo "   1) 📥 Descargar modelo Mistral 7B"
    echo "   2) 🚀 Iniciar todos los servicios"
    echo "   3) 🛑 Detener todos los servicios" 
    echo "   4) 🔄 Reiniciar servicios"
    echo "   5) 📊 Ver estado de servicios"
    echo "   6) 📋 Ver logs en tiempo real"
    echo "   7) 🧹 Limpiar y eliminar contenedores"
    echo "   8) 🔍 Diagnóstico del sistema"
    echo "   9) 📚 Ver documentación de APIs"
    echo "  10) 🌍 Configurar variables de entorno"
    echo "   0) 🚪 Salir"y Administración:"
    echo "   1) 📥 Descargar modelo Mistral 7B"
    echo "   2) 🚀 Iniciar todos los servicios"
    echo "   3) 🛑 Detener todos los servicios" 
    echo "   4) 🔄 Reiniciar servicios"
    echo "          1)
            download_mistral_7b
            ;; 📊 Ver estado de servicios"
    echo "   6) 📋 Ver logs en tiempo real"
    echo "   7) 🧹 Limpiar y eliminar contenedores"
    echo "   8) 🔍 Diagnóstico del sistema"
    echo "   9) 📚 Ver documentación de APIs"
    echo "  10) 🌍 Configurar variables de entorno"
    echo "  11) ⚙️  Configuración ppc64le (PowerPC)"
    echo "   0) 🚪 Salir"o para gestionar AI Platform
echo "🚀 AI PLATFORM - GESTOR SIMPLIFICADO"
echo "===================================="

cd "$(dirname "$0")"

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Función para mostrar menú
show_menu() {
    clear
    echo "🚀 === IBM AI Platform Management === 🚀"
    echo ""
    echo "�️  Arquitectura detectada: $(uname -m)"
    echo ""
    echo "🔧 Configuración y Administración:"
    echo "   1) � Descargar modelo Gemma 2B"
    echo "   2) 🚀 Iniciar todos los servicios"
    echo "   3) 🛑 Detener todos los servicios" 
    echo "   4) 🔄 Reiniciar servicios"
    echo "   5) � Ver estado de servicios"
    echo "   6) 📋 Ver logs en tiempo real"
    echo "   7) 🧹 Limpiar y eliminar contenedores"
    echo "   8) 🔍 Diagnóstico del sistema"
    echo "   9) 📚 Ver documentación de APIs"
    echo "  10) 🌍 Configurar variables de entorno"
    echo "  11) ⚙️  Configuración ppc64le (PowerPC)"
    echo "   0) 🚪 Salir"
}

# Función para verificar requisitos
check_requirements() {
    log "🔍 Verificando requisitos..."
    
    # Verificar arquitectura
    local ARCH=$(uname -m)
    if [[ "$ARCH" == "ppc64le" ]]; then
        log "✅ Arquitectura ppc64le detectada"
    else
        log "⚠️ Arquitectura: $ARCH (este script está optimizado para ppc64le)"
    fi
    
    # Verificar Docker
    if ! docker --version > /dev/null 2>&1; then
        log "❌ Docker no está instalado"
        return 1
    fi
    
    # Verificar Docker Compose
    if ! docker-compose --version > /dev/null 2>&1; then
        log "❌ Docker Compose no está disponible"
        return 1
    fi
    
    log "✅ Requisitos verificados"
    return 0
}

# Función para descargar Mistral 7B
download_mistral_7b() {
    log "📥 Descargando modelo Mistral 7B..."
    
    # Crear directorio de modelos
    mkdir -p models
    
    local filename="mistral-7b-instruct-v0.3.Q4_K_M.gguf"
    local url="https://huggingface.co/SanctumAI/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/mistral-7b-instruct-v0.3.Q4_K_M.gguf"
    
    if [ -f "models/$filename" ]; then
        log "✅ Modelo Mistral 7B ya existe"
        ls -lh "models/$filename"
        return 0
    fi
    
    log "⏳ Descargando... (esto puede tomar varios minutos)"
    if curl -L --progress-bar -o "models/$filename" "$url"; then
        log "✅ Modelo Mistral 7B descargado exitosamente"
        ls -lh "models/$filename"
        return 0
    else
        log "❌ Error descargando Mistral 7B"
        rm -f "models/$filename"
        return 1
    fi
}

# Función para mostrar otros modelos disponibles
show_other_models() {
    echo ""
    echo "📋 OTROS MODELOS DISPONIBLES:"
    echo "============================"
    echo ""
    echo "Para usar otros modelos, necesitará:"
    echo "1. Descargar el modelo manualmente"
    echo "2. Modificar docker-compose.yaml para apuntar al nuevo modelo"
    echo ""
    echo "Modelos sugeridos:"
    echo "• Gemma 2B (~1.5GB): https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF"
    echo "• Granite 8B (~5GB): https://huggingface.co/bartowski/granite-3.3-8b-instruct-GGUF"
    echo "• Llama 3.2 3B (~2GB): https://huggingface.co/lmstudio-community/Llama-3.2-3B-Instruct-GGUF"
    echo ""
    echo "💡 Consejo: Mistral 7B está configurado por defecto para mejor compatibilidad"
    echo ""
    read -p "Presiona Enter para continuar..."
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
    echo "4) LLM Server (Mistral 7B)"
    echo "5) Todos los servicios"
    echo ""
    read -p "Opción: " log_choice
    
    case $log_choice in
        1) docker-compose logs -f postgres ;;
        2) docker-compose logs -f textosql-api ;;
        3) docker-compose logs -f fraude-api ;;
        4) docker-compose logs -f llm-server ;;
        5) docker-compose logs -f ;;
        *) echo "❌ Opción no válida" ;;
    esac
}

# Función para limpiar modelos
clean_models() {
    echo "🧹 LIMPIEZA DE MODELOS"
    echo "====================="
    echo ""
    echo "⚠️ ADVERTENCIA: Esto eliminará todos los modelos descargados"
    echo "Tendrás que descargarlos nuevamente para usar el servidor LLM"
    echo ""
    read -p "¿Estás seguro? (s/N): " confirm
    
    if [[ $confirm =~ ^[Ss]$ ]]; then
        log "🧹 Limpiando modelos..."
        rm -rf models/*
        log "✅ Modelos eliminados"
    else
        log "❌ Operación cancelada"
    fi
}

# Función para crear .env
create_env() {
    log "⚙️ Creando archivo .env..."
    
    if [ -f .env ]; then
        echo "⚠️ El archivo .env ya existe. ¿Desea sobrescribirlo?"
        read -p "(s/N): " confirm
        if [[ ! $confirm =~ ^[Ss]$ ]]; then
            log "❌ Operación cancelada"
            return
        fi
    fi
    
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
    
    log "✅ Archivo .env creado exitosamente"
    echo ""
    echo "📋 Contenido del archivo .env:"
    cat .env
}

# Función para reinicio limpio
clean_restart() {
    log "🔄 Ejecutando reinicio limpio..."
    
    log "🛑 Deteniendo servicios..."
    docker-compose down --remove-orphans
    
    log "🧹 Limpiando recursos Docker..."
    docker system prune -f
    
    log "🔨 Reconstruyendo imágenes..."
    docker-compose build --no-cache
    
    log "🚀 Iniciando servicios..."
    docker-compose up -d
    
    log "✅ Reinicio completado"
}

# Menú principal
while true; do
    show_menu
    read -p "Selecciona una opción (0-10): " choice
    
    case $choice in
        1)
            if ! check_requirements; then
                echo ""
                read -p "Presiona Enter para continuar..."
                continue
            fi
            
            log "🚀 Iniciando todos los servicios..."
            
            # Verificar si existe el modelo
            if [ ! -f "models/gemma-2-2b-it-Q4_K_S.gguf" ]; then
                echo "⚠️ Modelo no encontrado. El servidor LLM no funcionará."
                echo "💡 Use la opción 4 para descargar el modelo Gemma 2B"
                echo ""
                read -p "¿Continuar de todos modos? (s/N): " confirm
                if [[ ! $confirm =~ ^[Ss]$ ]]; then
                    continue
                fi
            fi
            
            docker-compose up -d
            echo ""
            echo "📊 Estado actual:"
            docker-compose ps
            ;;
        2)
            log "🛑 Deteniendo todos los servicios..."
            docker-compose down
            ;;
        3)
            clean_restart
            ;;
        4)
            download_gemma_2b
            ;;
        5)
            show_other_models
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
            log "📊 Estado actual de servicios:"
            docker-compose ps
            echo ""
            log "🔗 URLs de acceso:"
            echo "   PostgreSQL:     http://localhost:8070"
            echo "   TextoSQL API:   http://localhost:8001/docs"
            echo "   Fraude API:     http://localhost:8000/docs"
            echo "   LLM Server:     http://localhost:8080"
            ;;
        9)
            view_logs
            ;;
        10)
            create_env
            ;;
        0)
            log "👋 ¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "❌ Opción no válida. Por favor selecciona 0-10."
            ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
done