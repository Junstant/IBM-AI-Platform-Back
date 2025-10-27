#!/bin/bash
# ========================================================================
# 🚀 SCRIPT DE DESARROLLO RÁPIDO - IBM AI Platform
# ========================================================================
# Uso: ./dev-quick-restart.sh [opcion]
# Opciones:
#   backend    - Solo reinicia servicios del backend (APIs)
#   frontend   - Solo reinicia el frontend
#   full       - Reinicia todo el stack
#   db         - Solo reinicia la base de datos
#   stats      - Solo reinicia el servicio de estadísticas
#   fraude     - Solo reinicia el servicio de detección de fraude
#   textosql   - Solo reinicia el servicio de TextoSQL
#   clean      - Limpia todo y reinicia desde cero

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Función para mostrar el menú
show_menu() {
    echo ""
    echo -e "${CYAN}🚀 IBM AI Platform - Desarrollo Rápido${NC}"
    echo -e "${CYAN}=======================================${NC}"
    echo -e "${GREEN}1. 🔧 Backend (todas las APIs)${NC}"
    echo -e "${BLUE}2. 🌐 Frontend (React + Nginx)${NC}"
    echo -e "${MAGENTA}3. 🔄 Full Stack (todo)${NC}"
    echo -e "${YELLOW}4. 🗄️  Base de Datos${NC}"
    echo -e "${CYAN}5. 📊 Stats API${NC}"
    echo -e "${RED}6. 🛡️  Fraude API${NC}"
    echo -e "${WHITE}7. 🔍 TextoSQL API${NC}"
    echo -e "${YELLOW}8. 🧹 Clean & Restart${NC}"
    echo -e "${GRAY}0. ❌ Salir${NC}"
    echo ""
}

# Función para verificar estado de servicios
check_services() {
    echo -e "${CYAN}📊 Estado actual de servicios:${NC}"
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
}

# Función para reiniciar backend APIs
restart_backend() {
    echo -e "${GREEN}🔧 Reiniciando servicios del Backend...${NC}"
    
    # Parar APIs
    docker-compose stop stats-api fraude-api textosql-api
    
    # Reconstruir si hay cambios
    echo -e "${YELLOW}🔨 Reconstruyendo servicios...${NC}"
    docker-compose build --no-cache stats-api fraude-api textosql-api
    
    # Iniciar servicios
    echo -e "${GREEN}🚀 Iniciando servicios...${NC}"
    docker-compose up -d stats-api fraude-api textosql-api
    
    # Verificar salud
    echo -e "${YELLOW}⏳ Verificando salud de servicios...${NC}"
    sleep 15
    check_services
    
    echo -e "${GREEN}✅ Backend reiniciado!${NC}"
    echo -e "${WHITE}🌐 URLs disponibles:${NC}"
    echo -e "${GRAY}  • Stats API: http://localhost:8003/docs${NC}"
    echo -e "${GRAY}  • Fraude API: http://localhost:8001/docs${NC}"
    echo -e "${GRAY}  • TextoSQL API: http://localhost:8000/docs${NC}"
}

# Función para reiniciar frontend
restart_frontend() {
    echo -e "${BLUE}🌐 Reiniciando Frontend...${NC}"
    
    # Parar frontend
    docker-compose stop frontend
    
    # Reconstruir
    echo -e "${YELLOW}🔨 Reconstruyendo frontend...${NC}"
    docker-compose build --no-cache frontend
    
    # Iniciar
    echo -e "${BLUE}🚀 Iniciando frontend...${NC}"
    docker-compose up -d frontend
    
    # Verificar
    sleep 10
    check_services
    
    echo -e "${GREEN}✅ Frontend reiniciado!${NC}"
    echo -e "${WHITE}🌐 URL: http://localhost:2012${NC}"
}

# Función para reiniciar todo
restart_full() {
    echo -e "${MAGENTA}🔄 Reiniciando todo el stack...${NC}"
    
    docker-compose down
    docker-compose build --no-cache
    docker-compose up -d
    
    echo -e "${YELLOW}⏳ Esperando que todos los servicios estén listos...${NC}"
    sleep 30
    
    check_services
    echo -e "${GREEN}✅ Stack completo reiniciado!${NC}"
}

# Función para reiniciar solo DB
restart_database() {
    echo -e "${YELLOW}🗄️ Reiniciando Base de Datos...${NC}"
    
    docker-compose stop postgres
    docker-compose up -d postgres
    
    echo -e "${YELLOW}⏳ Esperando que PostgreSQL esté listo...${NC}"
    sleep 20
    
    # Verificar postgres
    if docker-compose exec postgres pg_isready -U postgres > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PostgreSQL listo!${NC}"
    else
        echo -e "${RED}❌ Error con PostgreSQL. Verificando logs...${NC}"
        docker-compose logs --tail=20 postgres
    fi
}

# Función para servicio específico
restart_service() {
    local service_name="$1"
    local display_name="$2"
    local port="$3"
    local color="$4"
    
    echo -e "${color}🔄 Reiniciando $display_name...${NC}"
    
    docker-compose stop "$service_name"
    docker-compose build --no-cache "$service_name"
    docker-compose up -d "$service_name"
    
    sleep 10
    echo -e "${GREEN}✅ $display_name reiniciado!${NC}"
    echo -e "${WHITE}🌐 URL: http://localhost:$port/docs${NC}"
}

# Función para limpieza completa
clean_restart() {
    echo -e "${YELLOW}🧹 Limpieza completa y reinicio...${NC}"
    
    # Parar todo
    docker-compose down
    
    # Limpiar imágenes específicas
    echo -e "${YELLOW}🗑️ Limpiando imágenes del proyecto...${NC}"
    docker images | grep "aipl" | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
    
    # Limpiar cache
    docker builder prune -f
    
    # Reconstruir todo
    echo -e "${YELLOW}🔨 Reconstruyendo todo...${NC}"
    docker-compose build --no-cache
    
    # Iniciar
    echo -e "${GREEN}🚀 Iniciando servicios...${NC}"
    docker-compose up -d
    
    echo -e "${YELLOW}⏳ Esperando servicios...${NC}"
    sleep 45
    
    check_services
    echo -e "${GREEN}✅ Limpieza completa!${NC}"
}

# Función principal
main() {
    # Verificar que docker-compose existe
    if [ ! -f "docker-compose.yaml" ]; then
        echo -e "${RED}❌ No se encontró docker-compose.yaml en el directorio actual${NC}"
        exit 1
    fi
    
    # Si se pasó un parámetro, usarlo directamente
    if [ $# -gt 0 ]; then
        case "$1" in
            "backend") restart_backend ;;
            "frontend") restart_frontend ;;
            "full") restart_full ;;
            "db") restart_database ;;
            "stats") restart_service "stats-api" "Stats API" "8003" "${CYAN}" ;;
            "fraude") restart_service "fraude-api" "Fraude API" "8001" "${RED}" ;;
            "textosql") restart_service "textosql-api" "TextoSQL API" "8000" "${WHITE}" ;;
            "clean") clean_restart ;;
            *) 
                echo -e "${RED}❌ Opción inválida: $1${NC}"
                echo "Opciones válidas: backend, frontend, full, db, stats, fraude, textosql, clean"
                exit 1
                ;;
        esac
        return
    fi
    
    # Mostrar menú interactivo
    while true; do
        show_menu
        read -p "Selecciona una opción (0-8): " choice
        
        case $choice in
            1) restart_backend ;;
            2) restart_frontend ;;
            3) restart_full ;;
            4) restart_database ;;
            5) restart_service "stats-api" "Stats API" "8003" "${CYAN}" ;;
            6) restart_service "fraude-api" "Fraude API" "8001" "${RED}" ;;
            7) restart_service "textosql-api" "TextoSQL API" "8000" "${WHITE}" ;;
            8) clean_restart ;;
            0) 
                echo -e "${GREEN}👋 ¡Hasta luego!${NC}"
                exit 0 
                ;;
            *) 
                echo -e "${RED}❌ Opción inválida. Intenta de nuevo.${NC}" 
                ;;
        esac
        
        echo ""
        echo -e "${GRAY}Presiona Enter para continuar...${NC}"
        read
        clear
    done
}

# Ejecutar script
main "$@"