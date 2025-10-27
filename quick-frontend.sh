#!/bin/bash
# ========================================================================
# 🌐 RESTART RÁPIDO FRONTEND - Solo React + Nginx
# ========================================================================
# Script ultra-rápido para reiniciar solo el frontend

# Colores
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🌐 Reinicio rápido del Frontend...${NC}"

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yaml" ]; then
    echo -e "${RED}❌ No se encontró docker-compose.yaml${NC}"
    exit 1
fi

# Parar frontend
echo -e "${YELLOW}🛑 Deteniendo frontend...${NC}"
docker-compose stop frontend

# Reconstruir frontend
echo -e "${YELLOW}🔨 Reconstruyendo frontend...${NC}"
docker-compose build --no-cache frontend

# Iniciar frontend
echo -e "${BLUE}🚀 Iniciando frontend...${NC}"
docker-compose up -d frontend

# Verificación
echo -e "${YELLOW}⏳ Verificando servicio...${NC}"
sleep 15

# Mostrar estado
echo -e "${BLUE}📊 Estado:${NC}"
docker-compose ps frontend

echo ""
echo -e "${GREEN}✅ Frontend reiniciado!${NC}"
echo -e "${WHITE}🌐 URL: http://localhost:2012${NC}"

# Opcional: Mostrar logs en tiempo real
read -p "¿Ver logs del frontend? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GRAY}Presiona Ctrl+C para salir de los logs${NC}"
    docker-compose logs -f frontend
fi