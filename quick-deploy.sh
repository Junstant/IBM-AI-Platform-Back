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

case "${1:-menu}" in
    "backend"|"back"|"b")
        log "🔧 Actualizando Backend..."
        git pull origin main
        docker compose stop stats-api fraude-api textosql-api
        docker compose build --no-cache stats-api fraude-api textosql-api
        docker compose up -d stats-api fraude-api textosql-api
        sleep 15
        log "✅ Backend actualizado!"
        echo -e "${WHITE}📊 Stats: http://localhost:8003/docs${NC}"
        echo -e "${WHITE}🛡️ Fraude: http://localhost:8001/docs${NC}"
        echo -e "${WHITE}🔍 TextSQL: http://localhost:8000/docs${NC}"
        ;;
        
    "frontend"|"front"|"f")
        log "🌐 Actualizando Frontend..."
        # El frontend está en el mismo repo actualmente
        git pull origin main
        docker compose stop frontend
        docker compose build --no-cache frontend
        docker compose up -d frontend
        sleep 20
        log "✅ Frontend actualizado!"
        echo -e "${WHITE}🌐 URL: http://localhost:2012${NC}"
        ;;
        
    "full"|"all"|"a")
        log "🔄 Actualizando todo el stack..."
        git pull origin main
        
        # Detener servicios pero NO PostgreSQL
        warn "Deteniendo servicios (manteniendo PostgreSQL)..."
        docker compose stop stats-api fraude-api textosql-api frontend
        
        # Rebuild y levantar servicios
        docker compose build --no-cache frontend stats-api fraude-api textosql-api
        docker compose up -d stats-api fraude-api textosql-api frontend
        
        sleep 30
        log "✅ Stack actualizado manteniendo datos!"
        echo -e "${WHITE}🌐 Frontend: http://localhost:2012${NC}"
        echo -e "${WHITE}📊 Stats: http://localhost:8003/docs${NC}"
        echo -e "${WHITE}🛡️ Fraude: http://localhost:8001/docs${NC}"
        echo -e "${WHITE}🔍 TextSQL: http://localhost:8000/docs${NC}"
        ;;
        
    "reset"|"r")
        warn "🗑️ REINICIO COMPLETO - Eliminando todos los datos..."
        read -p "¿Estás seguro? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose down -v
            docker compose build --no-cache
            docker compose up -d
            sleep 60
            log "✅ Sistema reiniciado con datos frescos!"
        else
            log "Operación cancelada"
        fi
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
        
        test_url "Frontend    " "http://localhost:2012"
        test_url "Stats API   " "http://localhost:8003/health"
        test_url "Fraude API  " "http://localhost:8001/health"
        test_url "TextSQL API " "http://localhost:8000/health"
        test_url "PostgreSQL  " "http://localhost:8070" 2>/dev/null || echo -e "${WHITE}PostgreSQL  :${NC} ${YELLOW}⚠️${NC}"
        
        log "✅ Test completado!"
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
        echo ""
        echo -e "${WHITE}Aliases disponibles:${NC}"
        echo -e "  ${YELLOW}backend${NC} = back, b"
        echo -e "  ${YELLOW}frontend${NC} = front, f"  
        echo -e "  ${YELLOW}full${NC} = all, a"
        echo -e "  ${YELLOW}reset${NC} = r"
        echo -e "  ${YELLOW}test${NC} = t"
        echo ""
        echo -e "${WHITE}💡 Para más opciones usa: ${GREEN}./deploy-manager.sh${NC}"
        ;;
esac