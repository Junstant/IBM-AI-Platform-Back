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
        
        # Verificar stack de Milvus (necesario para RAG)
        if ! docker ps | grep -q milvus; then
            warn "Stack de Milvus no está corriendo. Iniciando..."
            docker compose up -d etcd minio
            sleep 15
            docker compose up -d milvus
            log "⏳ Esperando que Milvus esté listo (30s)..."
            sleep 30
        fi
        
        # Verificar PostgreSQL (necesario para Stats/TextoSQL/Fraude)
        if ! docker ps | grep -q postgres_db; then
            warn "PostgreSQL no está corriendo. Iniciando..."
            docker compose up -d postgres
            log "⏳ Esperando que PostgreSQL esté listo (15s)..."
            sleep 15
        fi
        
        docker compose stop stats-api fraude-api textosql-api rag-api
        docker compose build --no-cache stats-api fraude-api textosql-api rag-api
        docker compose up -d stats-api fraude-api textosql-api rag-api
        sleep 15
        log "✅ Backend actualizado!"
        echo -e "${WHITE}📊 Stats: http://localhost:${STATS_PORT:-8003}/docs${NC}"
        echo -e "${WHITE}🛡️ Fraude: http://localhost:${FRAUDE_API_PORT:-8001}/docs${NC}"
        echo -e "${WHITE}🔍 TextSQL: http://localhost:${TEXTOSQL_API_PORT:-8000}/docs${NC}"
        echo -e "${WHITE}🧠 RAG (Milvus): http://localhost:${RAG_API_PORT:-8004}/docs${NC}"
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
            log "Actualizando Frontend..."
            (cd ../FrontAI && git pull origin main)
        else
            log "Frontend en el mismo repositorio (ya actualizado)"
        fi
        
        # Verificar y levantar stack de Milvus si no está corriendo
        if ! docker ps | grep -q milvus; then
            log "🗄️ Iniciando stack de Milvus (etcd + MinIO + Milvus)..."
            docker compose up -d etcd minio
            sleep 15
            docker compose up -d milvus
            log "⏳ Esperando que Milvus esté listo (30s)..."
            sleep 30
        else
            log "✅ Milvus ya está corriendo"
        fi
        
        # Verificar y levantar PostgreSQL si no está corriendo
        if ! docker ps | grep -q postgres_db; then
            log "🗄️ Iniciando PostgreSQL..."
            docker compose up -d postgres
            log "⏳ Esperando que PostgreSQL esté listo (15s)..."
            sleep 15
        else
            log "✅ PostgreSQL ya está corriendo"
        fi
        
        # Detener servicios pero NO bases de datos ni LLMs
        warn "Deteniendo servicios (manteniendo PostgreSQL, Milvus y LLMs)..."
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
    
    "rag"|"milvus")
        log "🧠 Desplegando RAG API con Milvus..."
        
        # Paso 1: Verificar Gemma-2B
        if ! docker ps | grep -q gemma-2b; then
            warn "Gemma-2B no está corriendo, levantándolo..."
            docker compose up -d gemma-2b
            log "⏳ Esperando a que Gemma-2B esté listo (60s)..."
            sleep 60
        fi
        
        # Paso 2: Levantar stack de Milvus
        log "🚀 Desplegando stack de Milvus..."
        log "   1️⃣ etcd (metadata storage)..."
        docker compose up -d etcd
        sleep 10
        
        log "   2️⃣ MinIO (object storage)..."
        docker compose up -d minio
        sleep 15
        
        log "   3️⃣ Milvus (vector database)..."
        docker compose up -d milvus
        log "   ⏳ Esperando a que Milvus esté completamente listo..."
        sleep 30
        
        # Paso 3: Verificar salud de Milvus
        log "🔍 Verificando salud de Milvus..."
        for i in {1..12}; do
            if docker exec milvus curl -f http://localhost:9091/healthz > /dev/null 2>&1; then
                log "   ✅ Milvus está saludable"
                break
            else
                warn "   Intento $i/12: Milvus no está listo aún..."
                sleep 10
            fi
            if [ $i -eq 12 ]; then
                error "Milvus no respondió después de 2 minutos"
            fi
        done
        
        # Paso 4: Rebuildar y levantar RAG API
        log "🔧 Construyendo RAG API..."
        docker compose build --no-cache rag-api
        
        log "🚀 Levantando RAG API..."
        docker compose up -d rag-api
        
        log "⏳ Esperando a que RAG API esté listo..."
        sleep 20
        
        # Paso 5: Verificar salud de RAG API
        log "🔍 Verificando salud de RAG API..."
        for i in {1..10}; do
            if curl -f http://localhost:${RAG_API_PORT:-8004}/health > /dev/null 2>&1; then
                log "   ✅ RAG API está saludable"
                break
            else
                warn "   Intento $i/10: RAG API no está listo aún..."
                sleep 5
            fi
            if [ $i -eq 10 ]; then
                error "RAG API no respondió después de 50 segundos"
            fi
        done
        
        # Mostrar información
        echo ""
        echo -e "${CYAN}================================================================${NC}"
        echo -e "${GREEN}✅ RAG API CON MILVUS DESPLEGADO${NC}"
        echo -e "${CYAN}================================================================${NC}"
        echo ""
        echo -e "${WHITE}📊 Servicios:${NC}"
        echo -e "   🔹 etcd:       Metadata storage"
        echo -e "   🔹 MinIO:      Object storage (Console: ${CYAN}http://localhost:9001${NC})"
        echo -e "   🔹 Milvus:     Vector database (gRPC: ${CYAN}localhost:19530${NC})"
        echo -e "   🔹 RAG API:    REST API (Docs: ${CYAN}http://localhost:${RAG_API_PORT:-8004}/docs${NC})"
        echo ""
        echo -e "${WHITE}🔗 URLs:${NC}"
        echo -e "   📚 API Docs:      ${CYAN}http://localhost:${RAG_API_PORT:-8004}/docs${NC}"
        echo -e "   ❤️  Health:        ${CYAN}http://localhost:${RAG_API_PORT:-8004}/health${NC}"
        echo -e "   🗄️  MinIO Console: ${CYAN}http://localhost:9001${NC} (minioadmin/minioadmin)"
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
                docker compose stop gemma-4b gemma-12b mistral-7b deepseek-8b
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
        test_url "PostgreSQL  " "http://localhost:${DB_PORT:-8070}"
        test_url "Milvus      " "http://localhost:9091/healthz"
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
        echo "  • milvus-standalone"
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
        echo -e "  ${GREEN}./quick-deploy.sh rag${NC}       # 🧠 Deploy RAG con Milvus"
        echo -e "  ${GREEN}./quick-deploy.sh reset${NC}     # 🗑️ Reinicio completo (borra DB)"
        echo -e "  ${GREEN}./quick-deploy.sh test${NC}      # 🧪 Test servicios"
        echo -e "  ${GREEN}./quick-deploy.sh models${NC}    # 🤖 Gestionar modelos LLM"
        echo -e "  ${GREEN}./quick-deploy.sh logs${NC}      # 📋 Ver logs de servicio"
        echo ""
        echo -e "${WHITE}Aliases disponibles:${NC}"
        echo -e "  ${YELLOW}backend${NC} = back, b"
        echo -e "  ${YELLOW}frontend${NC} = front, f"  
        echo -e "  ${YELLOW}full${NC} = all, a"
        echo -e "  ${YELLOW}rag${NC} = milvus"
        echo -e "  ${YELLOW}reset${NC} = r"
        echo -e "  ${YELLOW}test${NC} = t"
        echo -e "  ${YELLOW}models${NC} = llm, m"
        echo -e "  ${YELLOW}logs${NC} = l"
        echo ""
        echo -e "${WHITE}💡 Ejemplo de uso:${NC}"
        echo -e "  ${CYAN}./quick-deploy.sh rag${NC}  → Despliega RAG API con Milvus Vector DB"
        ;;
esac