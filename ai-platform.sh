#!/bin/bash#!/bin/bash



# Script para gestionar AI Platform con múltiples modelos# Scrip    echo "🔧 C    echo "🔧 Configuración y Administración:"

echo "🚀 AI PLATFORM - GESTOR MÚLTIPLES MODELOS"    echo "   1) 📥 Descargar modelo Mistral 7B"

echo "=========================================="    echo "   2) 🚀 Iniciar todos los servicios"

    echo "   3) 🛑 Detener todos los servicios" 

cd "$(dirname "$0")"    echo "   4) 🔄 Reiniciar servicios"

    echo "   5) 📊 Ver estado de servicios"

# Función para logging    echo "   6) 📋 Ver logs en tiempo real"

log() {    echo "   7) 🧹 Limpiar y eliminar contenedores"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"    echo "   8) 🔍 Diagnóstico del sistema"

}    echo "   9) 📚 Ver documentación de APIs"

    echo "  10) 🌍 Configurar variables de entorno"

# Función para mostrar menú    echo "   0) 🚪 Salir"y Administración:"

show_menu() {    echo "   1) 📥 Descargar modelo Mistral 7B"

    clear    echo "   2) 🚀 Iniciar todos los servicios"

    echo "🚀 === IBM AI Platform Management === 🚀"    echo "   3) 🛑 Detener todos los servicios" 

    echo ""    echo "   4) 🔄 Reiniciar servicios"

    echo "🏗️  Arquitectura detectada: $(uname -m)"    echo "          1)

    echo ""            download_mistral_7b

    echo "🔧 GESTIÓN BÁSICA:"            ;; 📊 Ver estado de servicios"

    echo "  1) 🚀 Iniciar todos los servicios"    echo "   6) 📋 Ver logs en tiempo real"

    echo "  2) 🛑 Detener todos los servicios"    echo "   7) 🧹 Limpiar y eliminar contenedores"

    echo "  3) 🔄 Reinicio limpio completo"    echo "   8) 🔍 Diagnóstico del sistema"

    echo ""    echo "   9) 📚 Ver documentación de APIs"

    echo "📥 GESTIÓN DE MODELOS:"    echo "  10) 🌍 Configurar variables de entorno"

    echo "  4) 📥 Descargar modelo Gemma 2B (ligero)"    echo "  11) ⚙️  Configuración ppc64le (PowerPC)"

    echo "  5) 📥 Descargar modelo Mistral 7B (potente)"    echo "   0) 🚪 Salir"o para gestionar AI Platform

    echo "  6) 📥 Descargar TODOS los modelos automáticamente"echo "🚀 AI PLATFORM - GESTOR SIMPLIFICADO"

    echo "  7) 📊 Ver estado de modelos"echo "===================================="

    echo "  8) 🧹 Limpiar modelos descargados"

    echo ""cd "$(dirname "$0")"

    echo "🔍 DIAGNÓSTICO:"

    echo "  9) 📊 Ver estado actual"# Función para logging

    echo " 10) 📋 Ver logs de servicios"log() {

    echo " 11) 🌐 Probar APIs de modelos"    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"

    echo ""}

    echo "⚙️ CONFIGURACIÓN:"

    echo " 12) 🌍 Crear archivo .env"# Función para mostrar menú

    echo " 13) ⚙️ Configuración específica para ppc64le"show_menu() {

    echo ""    clear

    echo "  0) 🚪 Salir"    echo "🚀 === IBM AI Platform Management === 🚀"

    echo ""    echo ""

}    echo "�️  Arquitectura detectada: $(uname -m)"

    echo ""

# Función para verificar requisitos    echo "🔧 Configuración y Administración:"

check_requirements() {    echo "   1) � Descargar modelo Gemma 2B"

    log "🔍 Verificando requisitos..."    echo "   2) 🚀 Iniciar todos los servicios"

        echo "   3) 🛑 Detener todos los servicios" 

    # Verificar arquitectura    echo "   4) 🔄 Reiniciar servicios"

    local ARCH=$(uname -m)    echo "   5) � Ver estado de servicios"

    if [[ "$ARCH" == "ppc64le" ]]; then    echo "   6) 📋 Ver logs en tiempo real"

        log "✅ Arquitectura ppc64le detectada"    echo "   7) 🧹 Limpiar y eliminar contenedores"

    else    echo "   8) 🔍 Diagnóstico del sistema"

        log "⚠️ Arquitectura: $ARCH (este script está optimizado para ppc64le)"    echo "   9) 📚 Ver documentación de APIs"

    fi    echo "  10) 🌍 Configurar variables de entorno"

        echo "  11) ⚙️  Configuración ppc64le (PowerPC)"

    # Verificar Docker    echo "   0) 🚪 Salir"

    if ! docker --version > /dev/null 2>&1; then}

        log "❌ Docker no está instalado"

        return 1# Función para verificar requisitos

    ficheck_requirements() {

        log "🔍 Verificando requisitos..."

    # Verificar Docker Compose    

    if ! docker-compose --version > /dev/null 2>&1; then    # Verificar arquitectura

        log "❌ Docker Compose no está disponible"    local ARCH=$(uname -m)

        return 1    if [[ "$ARCH" == "ppc64le" ]]; then

    fi        log "✅ Arquitectura ppc64le detectada"

        else

    log "✅ Requisitos verificados"        log "⚠️ Arquitectura: $ARCH (este script está optimizado para ppc64le)"

    return 0    fi

}    

    # Verificar Docker

# Función para descargar múltiples modelos automáticamente    if ! docker --version > /dev/null 2>&1; then

download_all_models() {        log "❌ Docker no está instalado"

    log "📥 Descargando TODOS los modelos automáticamente..."        return 1

        fi

    # Crear directorio de modelos    

    mkdir -p models    # Verificar Docker Compose

        if ! docker-compose --version > /dev/null 2>&1; then

    # Lista de modelos a descargar        log "❌ Docker Compose no está disponible"

    declare -A models=(        return 1

        ["gemma-2-2b-it-Q4_K_S.gguf"]="https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_S.gguf"    fi

        ["mistral-7b-instruct-v0.3.Q4_K_M.gguf"]="https://huggingface.co/SanctumAI/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/mistral-7b-instruct-v0.3.Q4_K_M.gguf"    

    )    log "✅ Requisitos verificados"

        return 0

    log "📋 Modelos a descargar: ${#models[@]}"}

    echo "• Gemma 2B (~1.5GB) - Ligero y eficiente"

    echo "• Mistral 7B (~4GB) - Potente y versátil"# Función para descargar Mistral 7B

    echo ""download_mistral_7b() {

        log "📥 Descargando modelo Mistral 7B..."

    for filename in "${!models[@]}"; do    

        local url="${models[$filename]}"    # Crear directorio de modelos

            mkdir -p models

        if [ -f "models/$filename" ]; then    

            log "✅ Modelo $filename ya existe"    local filename="mistral-7b-instruct-v0.3.Q4_K_M.gguf"

            ls -lh "models/$filename"    local url="https://huggingface.co/SanctumAI/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/mistral-7b-instruct-v0.3.Q4_K_M.gguf"

        else    

            log "⏳ Descargando $filename... (esto puede tomar varios minutos)"    if [ -f "models/$filename" ]; then

            if curl -L --progress-bar -o "models/$filename" "$url"; then        log "✅ Modelo Mistral 7B ya existe"

                log "✅ Modelo $filename descargado exitosamente"        ls -lh "models/$filename"

                ls -lh "models/$filename"        return 0

            else    fi

                log "❌ Error descargando $filename"    

                rm -f "models/$filename"    log "⏳ Descargando... (esto puede tomar varios minutos)"

            fi    if curl -L --progress-bar -o "models/$filename" "$url"; then

        fi        log "✅ Modelo Mistral 7B descargado exitosamente"

        echo ""        ls -lh "models/$filename"

    done        return 0

        else

    log "✅ Descarga de modelos completada"        log "❌ Error descargando Mistral 7B"

}        rm -f "models/$filename"

        return 1

# Función para descargar Gemma 2B    fi

download_gemma_2b() {}

    log "📥 Descargando modelo Gemma 2B (ligero y eficiente)..."

    # Función para mostrar otros modelos disponibles

    # Crear directorio de modelosshow_other_models() {

    mkdir -p models    echo ""

        echo "📋 OTROS MODELOS DISPONIBLES:"

    local filename="gemma-2-2b-it-Q4_K_S.gguf"    echo "============================"

    local url="https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_S.gguf"    echo ""

        echo "Para usar otros modelos, necesitará:"

    if [ -f "models/$filename" ]; then    echo "1. Descargar el modelo manualmente"

        log "✅ Modelo Gemma 2B ya existe"    echo "2. Modificar docker-compose.yaml para apuntar al nuevo modelo"

        ls -lh "models/$filename"    echo ""

        return 0    echo "Modelos sugeridos:"

    fi    echo "• Gemma 2B (~1.5GB): https://huggingface.co/lmstudio-community/gemma-2-2b-it-GGUF"

        echo "• Granite 8B (~5GB): https://huggingface.co/bartowski/granite-3.3-8b-instruct-GGUF"

    log "⏳ Descargando Gemma 2B (~1.5GB)... esto puede tomar varios minutos"    echo "• Llama 3.2 3B (~2GB): https://huggingface.co/lmstudio-community/Llama-3.2-3B-Instruct-GGUF"

    if curl -L --progress-bar -o "models/$filename" "$url"; then    echo ""

        log "✅ Modelo Gemma 2B descargado exitosamente"    echo "💡 Consejo: Mistral 7B está configurado por defecto para mejor compatibilidad"

        ls -lh "models/$filename"    echo ""

        return 0    read -p "Presiona Enter para continuar..."

    else}

        log "❌ Error descargando Gemma 2B"

        rm -f "models/$filename"# Función para ver logs

        return 1view_logs() {

    fi    echo "📋 LOGS DE SERVICIOS"

}    echo "==================="

    echo ""

# Función para descargar Mistral 7B    echo "Selecciona el servicio:"

download_mistral_7b() {    echo "1) PostgreSQL"

    log "📥 Descargando modelo Mistral 7B (potente y versátil)..."    echo "2) TextoSQL API"

        echo "3) Fraude API"

    # Crear directorio de modelos    echo "4) LLM Server (Mistral 7B)"

    mkdir -p models    echo "5) Todos los servicios"

        echo ""

    local filename="mistral-7b-instruct-v0.3.Q4_K_M.gguf"    read -p "Opción: " log_choice

    local url="https://huggingface.co/SanctumAI/Mistral-7B-Instruct-v0.3-GGUF/resolve/main/mistral-7b-instruct-v0.3.Q4_K_M.gguf"    

        case $log_choice in

    if [ -f "models/$filename" ]; then        1) docker-compose logs -f postgres ;;

        log "✅ Modelo Mistral 7B ya existe"        2) docker-compose logs -f textosql-api ;;

        ls -lh "models/$filename"        3) docker-compose logs -f fraude-api ;;

        return 0        4) docker-compose logs -f llm-server ;;

    fi        5) docker-compose logs -f ;;

            *) echo "❌ Opción no válida" ;;

    log "⏳ Descargando Mistral 7B (~4GB)... esto puede tomar varios minutos"    esac

    if curl -L --progress-bar -o "models/$filename" "$url"; then}

        log "✅ Modelo Mistral 7B descargado exitosamente"

        ls -lh "models/$filename"# Función para limpiar modelos

        return 0clean_models() {

    else    echo "🧹 LIMPIEZA DE MODELOS"

        log "❌ Error descargando Mistral 7B"    echo "====================="

        rm -f "models/$filename"    echo ""

        return 1    echo "⚠️ ADVERTENCIA: Esto eliminará todos los modelos descargados"

    fi    echo "Tendrás que descargarlos nuevamente para usar el servidor LLM"

}    echo ""

    read -p "¿Estás seguro? (s/N): " confirm

# Función para ver estado de modelos    

view_model_status() {    if [[ $confirm =~ ^[Ss]$ ]]; then

    echo "📊 ESTADO DE MODELOS"        log "🧹 Limpiando modelos..."

    echo "==================="        rm -rf models/*

    echo ""        log "✅ Modelos eliminados"

        else

    if [ -d "./models" ]; then        log "❌ Operación cancelada"

        echo "Modelos disponibles en ./models/:"    fi

        if ls ./models/*.gguf >/dev/null 2>&1; then}

            ls -lh ./models/*.gguf | awk '{print "  ✅ " $9 " (" $5 ")"}'

            echo ""# Función para crear .env

            echo "Espacio total usado:"create_env() {

            du -sh ./models 2>/dev/null || echo "  No se pudo calcular"    log "⚙️ Creando archivo .env..."

        else    

            echo "  ❌ No hay modelos descargados"    if [ -f .env ]; then

            echo "  💡 Use las opciones 4, 5 o 6 para descargar modelos"        echo "⚠️ El archivo .env ya existe. ¿Desea sobrescribirlo?"

        fi        read -p "(s/N): " confirm

    else        if [[ ! $confirm =~ ^[Ss]$ ]]; then

        echo "❌ Directorio ./models no encontrado"            log "❌ Operación cancelada"

    fi            return

            fi

    echo ""    fi

    echo "🐳 CONTENEDORES DE MODELOS:"    

    echo "• LLM Principal: puerto 8080"    cat > .env << 'EOF'

    echo "• Gemma 2B:      puerto 9470"  # Configuración de la base de datos

    echo "• Mistral 7B:    puerto 8096"DB_HOST=postgres_ai_platform

}DB_PORT=8070

DB_USER=postgres

# Función para probar APIs de modelosDB_PASSWORD=postgres

test_model_apis() {DB_NAME=postgres

    echo "🌐 PROBANDO APIs DE MODELOS"DB_NAME_TEXTOSQL=banco_global

    echo "=========================="

    echo ""# APIs

    FRAUDE_API_PORT=8000

    # Probar LLM principal (puerto 8080)TEXTOSQL_API_PORT=8001

    echo "🧠 LLM Principal (puerto 8080):"

    if curl -s -f http://localhost:8080/health >/dev/null 2>&1; then# Modelo LLM

        echo "  Estado: ✅ Funcionando"LLM_PORT=8080

    elif curl -s http://localhost:8080 >/dev/null 2>&1; thenLLM_HOST=llm-server

        echo "  Estado: 🔄 Iniciando"

    else# Configuración general

        echo "  Estado: ❌ No responde"COMPOSE_PROJECT_NAME=platform_ai_lj

    fiEOF

        

    # Probar Gemma 2B (puerto 9470)    log "✅ Archivo .env creado exitosamente"

    echo "🤖 Gemma 2B (puerto 9470):"    echo ""

    if curl -s -f http://localhost:9470/health >/dev/null 2>&1; then    echo "📋 Contenido del archivo .env:"

        echo "  Estado: ✅ Funcionando"    cat .env

    elif curl -s http://localhost:9470 >/dev/null 2>&1; then}

        echo "  Estado: 🔄 Iniciando"

    else# Función para reinicio limpio

        echo "  Estado: ❌ No responde"clean_restart() {

    fi    log "🔄 Ejecutando reinicio limpio..."

        

    # Probar Mistral 7B (puerto 8096)    log "🛑 Deteniendo servicios..."

    echo "🚀 Mistral 7B (puerto 8096):"    docker-compose down --remove-orphans

    if curl -s -f http://localhost:8096/health >/dev/null 2>&1; then    

        echo "  Estado: ✅ Funcionando"    log "🧹 Limpiando recursos Docker..."

    elif curl -s http://localhost:8096 >/dev/null 2>&1; then    docker system prune -f

        echo "  Estado: 🔄 Iniciando"    

    else    log "🔨 Reconstruyendo imágenes..."

        echo "  Estado: ❌ No responde"    docker-compose build --no-cache

    fi    

        log "🚀 Iniciando servicios..."

    echo ""    docker-compose up -d

    echo "💡 Comandos para probar generación de texto:"    

    echo "curl -X POST \"http://localhost:8080/completion\" -H \"Content-Type: application/json\" -d '{\"prompt\": \"Hola, ¿cómo estás?\", \"n_predict\": 50}'"    log "✅ Reinicio completado"

}}



# Función para ver logs# Menú principal

view_logs() {while true; do

    echo "📋 LOGS DE SERVICIOS"    show_menu

    echo "==================="    read -p "Selecciona una opción (0-10): " choice

    echo ""    

    echo "Selecciona el servicio:"    case $choice in

    echo "1) PostgreSQL"        1)

    echo "2) TextoSQL API"            if ! check_requirements; then

    echo "3) Fraude API"                echo ""

    echo "4) LLM Server Principal (puerto 8080)"                read -p "Presiona Enter para continuar..."

    echo "5) Gemma 2B Server (puerto 9470)"                continue

    echo "6) Mistral 7B Server (puerto 8096)"            fi

    echo "7) Todos los servicios"            

    echo ""            log "🚀 Iniciando todos los servicios..."

    read -p "Opción: " log_choice            

                # Verificar si existe el modelo

    case $log_choice in            if [ ! -f "models/gemma-2-2b-it-Q4_K_S.gguf" ]; then

        1) docker-compose logs -f postgres ;;                echo "⚠️ Modelo no encontrado. El servidor LLM no funcionará."

        2) docker-compose logs -f textosql-api ;;                echo "💡 Use la opción 4 para descargar el modelo Gemma 2B"

        3) docker-compose logs -f fraude-api ;;                echo ""

        4) docker-compose logs -f llm-server ;;                read -p "¿Continuar de todos modos? (s/N): " confirm

        5) docker-compose logs -f gemma2b-server ;;                if [[ ! $confirm =~ ^[Ss]$ ]]; then

        6) docker-compose logs -f mistral-server ;;                    continue

        7) docker-compose logs -f ;;                fi

        *) echo "❌ Opción no válida" ;;            fi

    esac            

}            docker-compose up -d

            echo ""

# Función para limpiar modelos            echo "📊 Estado actual:"

clean_models() {            docker-compose ps

    echo "🧹 LIMPIEZA DE MODELOS"            ;;

    echo "====================="        2)

    echo ""            log "🛑 Deteniendo todos los servicios..."

    echo "⚠️ ADVERTENCIA: Esto eliminará todos los modelos descargados"            docker-compose down

    echo "Tendrás que descargarlos nuevamente para usar los servidores LLM"            ;;

    echo ""        3)

    read -p "¿Estás seguro? (s/N): " confirm            clean_restart

                ;;

    if [[ $confirm =~ ^[Ss]$ ]]; then        4)

        log "🧹 Limpiando modelos..."            download_gemma_2b

        rm -rf models/*            ;;

        log "✅ Modelos eliminados"        5)

    else            show_other_models

        log "❌ Operación cancelada"            ;;

    fi        6)

}            log "📊 Estado de modelos descargados:"

            if [ -d models ] && [ "$(ls -A models)" ]; then

# Función para crear .env                ls -lh models/

create_env() {                echo ""

    log "⚙️ Creando archivo .env..."                echo "💾 Espacio total usado:"

                    du -sh models/

    if [ -f .env ]; then            else

        echo "⚠️ El archivo .env ya existe. ¿Desea sobrescribirlo?"                echo "📁 No hay modelos descargados"

        read -p "(s/N): " confirm            fi

        if [[ ! $confirm =~ ^[Ss]$ ]]; then            ;;

            log "❌ Operación cancelada"        7)

            return            clean_models

        fi            ;;

    fi        8)

                log "📊 Estado actual de servicios:"

    cat > .env << 'EOF'            docker-compose ps

# Configuración de la base de datos            echo ""

DB_HOST=postgres_ai_platform            log "🔗 URLs de acceso:"

DB_PORT=8070            echo "   PostgreSQL:     http://localhost:8070"

DB_USER=postgres            echo "   TextoSQL API:   http://localhost:8001/docs"

DB_PASSWORD=postgres            echo "   Fraude API:     http://localhost:8000/docs"

DB_NAME=postgres            echo "   LLM Server:     http://localhost:8080"

DB_NAME_TEXTOSQL=banco_global            ;;

        9)

# APIs            view_logs

FRAUDE_API_PORT=8000            ;;

TEXTOSQL_API_PORT=8001        10)

            create_env

# Modelo LLM Principal            ;;

LLM_PORT=8080        0)

LLM_HOST=llm-server            log "👋 ¡Hasta luego!"

            exit 0

# Puertos específicos de modelos            ;;

GEMMA2B_PORT=9470        *)

MISTRAL_PORT=8096            echo "❌ Opción no válida. Por favor selecciona 0-10."

            ;;

# Configuración general    esac

COMPOSE_PROJECT_NAME=platform_ai_lj    

EOF    echo ""

        read -p "Presiona Enter para continuar..."

    log "✅ Archivo .env creado exitosamente"done
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
    
    echo ""
    echo "📊 Estado de servicios después del reinicio:"
    sleep 5
    docker-compose ps
}

# Función para mostrar estado actual
show_status() {
    echo "📊 ESTADO ACTUAL DEL SISTEMA"
    echo "============================"
    echo ""
    
    echo "🐳 CONTENEDORES:"
    docker-compose ps
    
    echo ""
    echo "📁 MODELOS:"
    if [ -d "./models" ] && ls ./models/*.gguf >/dev/null 2>&1; then
        ls -lh ./models/*.gguf | awk '{print "  " $9 " (" $5 ")"}'
    else
        echo "  ❌ No hay modelos descargados"
    fi
    
    echo ""
    echo "💾 USO DE RECURSOS:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No hay contenedores ejecutándose"
}

# Menú principal
while true; do
    show_menu
    read -p "Selecciona una opción (0-13): " choice
    
    case $choice in
        1)
            if ! check_requirements; then
                echo "❌ Requisitos no cumplidos"
                continue
            fi
            
            log "🚀 Iniciando todos los servicios..."
            
            # Verificar si existen modelos
            if [ ! -d "./models" ] || ! ls ./models/*.gguf >/dev/null 2>&1; then
                echo "⚠️ No se encontraron modelos descargados"
                echo "💡 Use las opciones 4, 5 o 6 para descargar modelos primero"
                continue
            fi
            
            docker-compose up -d
            log "✅ Servicios iniciados"
            
            echo ""
            echo "🌐 URLs de acceso:"
            echo "• TextoSQL API: http://localhost:8001/docs"
            echo "• Fraude API:   http://localhost:8000/docs"
            echo "• LLM Principal: http://localhost:8080"
            echo "• Gemma 2B:     http://localhost:9470"
            echo "• Mistral 7B:   http://localhost:8096"
            ;;
        2)
            log "🛑 Deteniendo todos los servicios..."
            docker-compose down
            log "✅ Servicios detenidos"
            ;;
        3)
            clean_restart
            ;;
        4)
            download_gemma_2b
            ;;
        5)
            download_mistral_7b
            ;;
        6)
            download_all_models
            ;;
        7)
            view_model_status
            ;;
        8)
            clean_models
            ;;
        9)
            show_status
            ;;
        10)
            view_logs
            ;;
        11)
            test_model_apis
            ;;
        12)
            create_env
            ;;
        13)
            echo "⚙️ CONFIGURACIÓN PPC64LE"
            echo "========================"
            echo "Configuraciones específicas para arquitectura PowerPC aplicadas automáticamente"
            echo "• Optimizaciones VSX habilitadas"
            echo "• Repositorios de wheels específicos configurados"
            ;;
        0)
            log "👋 ¡Hasta luego!"
            exit 0
            ;;
        *)
            echo "❌ Opción no válida"
            ;;
    esac
    
    echo ""
    read -p "Presiona Enter para continuar..."
done