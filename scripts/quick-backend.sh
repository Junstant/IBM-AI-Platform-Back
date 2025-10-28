#!/bin/bash
# ========================================================================
# 🔧 RESTART RÁPIDO BACKEND - Solo APIs
# ========================================================================
# Script ultra-rápido para reiniciar solo las APIs del backend

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

echo -e "${GREEN}🔧 Reinicio rápido del Backend...${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yaml" ]; then
    echo -e "${RED}❌ No se encontró docker-compose.yaml${NC}"
    exit 1
fi

# Parar APIs
echo -e "${YELLOW}🛑 Deteniendo APIs...${NC}"
docker-compose stop stats-api fraude-api textosql-api

# Reconstruir solo si hay cambios (más rápido)
echo -e "${CYAN}🔨 Reconstruyendo APIs...${NC}"
docker-compose build stats-api fraude-api textosql-api

# Iniciar APIs
echo -e "${GREEN}🚀 Iniciando APIs...${NC}"
docker-compose up -d stats-api fraude-api textosql-api

# Verificación rápida
echo -e "${YELLOW}⏳ Verificando servicios...${NC}"
sleep 10

# Mostrar estado
echo -e "${CYAN}📊 Estado:${NC}"
docker-compose ps stats-api fraude-api textosql-api

echo ""
echo -e "${GREEN}✅ Backend reiniciado!${NC}"
echo -e "${WHITE}🌐 URLs disponibles:${NC}"
echo -e "${GRAY}  • Stats API: http://localhost:8003/docs${NC}"
echo -e "${GRAY}  • Fraude API: http://localhost:8001/docs${NC}"  
echo -e "${GRAY}  • TextoSQL API: http://localhost:8000/docs${NC}"