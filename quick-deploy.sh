#!/bin/bash
# ========================================================================
# 🚀 QUICK DEPLOY - Script rápido para actualizaciones diarias
# ========================================================================
# Script simple para las operaciones más comunes:
#   • Pull de cambios + restart backend/frontend
#   • Test rápido de servicios
# 
# Uso: 
#   ./quick-deploy.sh backend    # Pull + restart backend
#   ./quick-deploy.sh frontend   # Pull + restart frontend  
#   ./quick-deploy.sh full       # Pull + restart todo
#   ./quick-deploy.sh test       # Solo test de servicios
# ========================================================================

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

log() { echo -e "[$(date +'%H:%M:%S')] ${GREEN}$1${NC}"; }
warn() { echo -e "[$(date +'%H:%M:%S')] ${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "[$(date +'%H:%M:%S')] ${RED}❌ $1${NC}"; exit 1; }

# Verificar docker-compose.yaml
[ ! -f "docker-compose.yaml" ] && error "Ejecutar desde el directorio raíz del proyecto"

# Cargar variables de entorno
if [ -f ".env" ]; then
    source .env
fi

case "${1:-menu}" in
    "backend"|"back"|"b")
        log "🔧 Actualizando Backend..."
        git pull origin main
        docker compose stop stats-api fraude-api textosql-api rag-api
        docker compose build --no-cache stats-api fraude-api textosql-api rag-api
        docker compose up -d stats-api fraude-api textosql-api rag-api
        sleep 15
        log "✅ Backend actualizado!"
        echo -e "${WHITE}📊 Stats: http://localhost:${STATS_PORT:-8003}/docs${NC}"
        echo -e "${WHITE}🛡️ Fraude: http://localhost:${FRAUDE_API_PORT:-8001}/docs${NC}"
        echo -e "${WHITE}🔍 TextSQL: http://localhost:${TEXTOSQL_API_PORT:-8000}/docs${NC}"
        echo -e "${WHITE}📚 RAG: http://localhost:${RAG_API_PORT:-8004}/docs${NC}"
        ;;
        
    "frontend"|"front"|"f")
        log "🌐 Actualizando Frontend..."
        
        # Verificar si el frontend está en el mismo repo o es externo
        if [ -d "../FrontAI" ]; then
            log "Actualizando desde repositorio externo..."
            cd ../FrontAI
            git pull origin main
            cd -
        else
            log "Frontend en el mismo repositorio..."
            git pull origin main
        fi
        
        docker compose stop frontend
        docker compose build --no-cache frontend
        docker compose up -d frontend
        sleep 20
        log "✅ Frontend actualizado!"
        echo -e "${WHITE}🌐 URL: http://localhost:${NGINX_PORT:-2012}${NC}"
        ;;
        
    "full"|"all"|"a")
        log "🔄 Actualizando todo el stack..."
        
        # Pull backend (repositorio actual)
        log "Actualizando Backend..."
        git pull origin main
        
        # Pull frontend (repositorio externo si existe)
        if [ -d "../FrontAI" ]; then
            log "Actualizando Frontend externo..."
            (cd ../FrontAI && git pull origin main)
        else
            log "Frontend en el mismo repositorio (ya actualizado)"
        fi
        
        # Detener servicios pero NO PostgreSQL ni LLMs
        warn "Deteniendo servicios (manteniendo PostgreSQL y LLMs)..."
        docker compose stop stats-api fraude-api textosql-api rag-api frontend
        
        # Rebuild y levantar servicios
        log "Reconstruyendo imágenes..."
        docker compose build --no-cache --parallel frontend stats-api fraude-api textosql-api rag-api
        
        log "Iniciando servicios..."
        docker compose up -d stats-api fraude-api textosql-api rag-api frontend
        
        sleep 30
        log "✅ Stack actualizado manteniendo datos!"
        echo ""
        echo -e "${WHITE}🎯 URLs de acceso:${NC}"
        echo -e "${WHITE}🌐 Frontend: http://localhost:${NGINX_PORT:-2012}${NC}"
        echo -e "${WHITE}📊 Stats: http://localhost:${STATS_PORT:-8003}/docs${NC}"
        echo -e "${WHITE}🛡️ Fraude: http://localhost:${FRAUDE_API_PORT:-8001}/docs${NC}"
        echo -e "${WHITE}🔍 TextSQL: http://localhost:${TEXTOSQL_API_PORT:-8000}/docs${NC}"
        echo -e "${WHITE}📚 RAG: http://localhost:${RAG_API_PORT:-8004}/docs${NC}"
        ;;
        
    "reset"|"r")
        warn "🗑️ REINICIO COMPLETO - Eliminando todos los datos..."
        read -p "¿Estás seguro? Esto borrará PostgreSQL y todos los volúmenes (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Deteniendo todos los contenedores..."
            docker compose down -v
            
            log "Reconstruyendo imágenes..."
            docker compose build --no-cache
            
            log "Iniciando sistema..."
            docker compose up -d
            
            log "Esperando inicialización (60s)..."
            sleep 60
            
            log "✅ Sistema reiniciado con datos frescos!"
        else
            log "Operación cancelada"
        fi
        ;;
    
    "models"|"llm"|"m")
        log "🤖 Gestionando modelos LLM..."
        echo ""
        echo -e "${WHITE}1)${NC} Reiniciar modelo específico"
        echo -e "${WHITE}2)${NC} Ver estado de modelos"
        echo -e "${WHITE}3)${NC} Cargar todos los modelos (perfil full)"
        echo -e "${WHITE}4)${NC} Detener modelos secundarios"
        echo ""
        read -p "Selecciona opción (1-4): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                echo -e "${WHITE}Modelos disponibles:${NC}"
                echo "  • gemma-2b"
                echo "  • gemma-4b"
                echo "  • gemma-12b"
                echo "  • mistral-7b"
                echo "  • deepseek-8b"
                echo "  • deepseek-14b"
                read -p "Nombre del modelo: " model_name
                log "Reiniciando $model_name..."
                docker compose restart "$model_name"
                ;;
            2)
                docker compose ps | grep -E "(gemma|mistral|deepseek)"
                ;;
            3)
                log "Cargando todos los modelos..."
                docker compose --profile full up -d
                ;;
            4)
                log "Deteniendo modelos secundarios..."
                docker compose stop gemma-4b gemma-12b mistral-7b deepseek-8b deepseek-14b
                ;;
        esac
        ;;
        
    "test"|"t")
        log "🧪 Probando servicios..."
        
        test_url() {
            local name="$1" url="$2"
            echo -n -e "${WHITE}$name:${NC} "
            if timeout 10 curl -s -f "$url" >/dev/null 2>&1; then
                echo -e "${GREEN}✅${NC}"
            else
                echo -e "${RED}❌${NC}"
            fi
        }
        
        test_url "Frontend    " "http://localhost:${NGINX_PORT:-2012}"
        test_url "Stats API   " "http://localhost:${STATS_PORT:-8003}/health"
        test_url "Fraude API  " "http://localhost:${FRAUDE_API_PORT:-8001}/health"
        test_url "TextSQL API " "http://localhost:${TEXTOSQL_API_PORT:-8000}/health"
        test_url "RAG API     " "http://localhost:${RAG_API_PORT:-8004}/health"
        test_url "Gemma 2B    " "http://localhost:${GEMMA_2B_PORT:-8085}/health"
        
        echo ""
        log "📊 Estado de contenedores:"
        docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        ;;
        
    "logs"|"l")
        log "📋 Mostrando logs recientes..."
        echo -e "${WHITE}Selecciona servicio:${NC}"
        echo "  • frontend"
        echo "  • stats-api"
        echo "  • fraude-api"
        echo "  • textosql-api"
        echo "  • rag-api"
        echo "  • postgres"
        echo "  • gemma-2b"
        read -p "Nombre del servicio: " service_name
        docker compose logs --tail=100 -f "$service_name"
        ;;
        
    "menu"|*)
        echo -e "${CYAN}🚀 Quick Deploy - IBM AI Platform${NC}"
        echo ""
        echo -e "${WHITE}Uso:${NC}"
        echo -e "  ${GREEN}./quick-deploy.sh backend${NC}   # 🔧 Pull + restart APIs"
        echo -e "  ${GREEN}./quick-deploy.sh frontend${NC}  # 🌐 Pull + restart frontend"
        echo -e "  ${GREEN}./quick-deploy.sh full${NC}      # 🔄 Pull + restart todo (mantiene DB)"
        echo -e "  ${GREEN}./quick-deploy.sh reset${NC}     # 🗑️ Reinicio completo (borra DB)"
        echo -e "  ${GREEN}./quick-deploy.sh test${NC}      # 🧪 Test servicios"
        echo -e "  ${GREEN}./quick-deploy.sh models${NC}    # 🤖 Gestionar modelos LLM"
        echo -e "  ${GREEN}./quick-deploy.sh logs${NC}      # 📋 Ver logs de servicio"
        echo ""
        echo -e "${WHITE}Aliases disponibles:${NC}"
        echo -e "  ${YELLOW}backend${NC} = back, b"
        echo -e "  ${YELLOW}frontend${NC} = front, f"  
        echo -e "  ${YELLOW}full${NC} = all, a"
        echo -e "  ${YELLOW}reset${NC} = r"
        echo -e "  ${YELLOW}test${NC} = t"
        echo -e "  ${YELLOW}models${NC} = llm, m"
        echo -e "  ${YELLOW}logs${NC} = l"
        echo ""
        echo -e "${WHITE}💡 Para más opciones usa: ${GREEN}./deploy-manager.sh${NC}"
        ;;
esac