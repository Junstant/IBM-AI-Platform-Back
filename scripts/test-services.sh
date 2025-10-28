#!/bin/bash
# ========================================================================
# 🧪 TEST RÁPIDO - Verificar que todos los servicios funcionan
# ========================================================================
# Script para probar que todos los servicios responden correctamente

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

echo -e "${CYAN}🧪 Probando servicios de IBM AI Platform...${NC}"
echo ""

# Función para probar un endpoint
test_endpoint() {
    local name="$1"
    local url="$2"
    local icon="$3"
    
    echo -n -e "${WHITE}$icon $name:${NC} "
    
    if curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC}"
        return 1
    fi
}

# Función para probar servicios con timeout
test_service() {
    local name="$1"
    local url="$2"
    local icon="$3"
    
    echo -n -e "${WHITE}$icon $name:${NC} "
    
    if timeout 5 curl -s -f "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ FAIL (timeout o error)${NC}"
        return 1
    fi
}

# Contador de servicios
total=0
passed=0

echo -e "${YELLOW}📊 Probando APIs del Backend:${NC}"

# Stats API
((total++))
if test_service "Stats API Health" "http://localhost:8003/health" "📊"; then
    ((passed++))
fi

((total++))
if test_service "Stats API Docs" "http://localhost:8003/docs" "📋"; then
    ((passed++))
fi

# Fraude API
((total++))
if test_service "Fraude API Health" "http://localhost:8001/health" "🛡️"; then
    ((passed++))
fi

((total++))
if test_service "Fraude API Docs" "http://localhost:8001/docs" "📋"; then
    ((passed++))
fi

# TextoSQL API
((total++))
if test_service "TextoSQL API Health" "http://localhost:8000/health" "🔍"; then
    ((passed++))
fi

((total++))
if test_service "TextoSQL API Docs" "http://localhost:8000/docs" "📋"; then
    ((passed++))
fi

echo ""
echo -e "${YELLOW}🌐 Probando Frontend:${NC}"

# Frontend
((total++))
if test_service "Frontend React App" "http://localhost:2012" "🌐"; then
    ((passed++))
fi

echo ""
echo -e "${YELLOW}🗄️ Probando Base de Datos:${NC}"

# PostgreSQL (indirectamente a través de docker)
echo -n -e "${WHITE}🗄️ PostgreSQL:${NC} "
if docker-compose exec postgres pg_isready -U postgres > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
    ((total++))
    ((passed++))
else
    echo -e "${RED}❌ FAIL${NC}"
    ((total++))
fi

# Resumen
echo ""
echo "========================================="
if [ $passed -eq $total ]; then
    echo -e "${GREEN}🎉 ¡Todos los servicios funcionan correctamente!${NC}"
    echo -e "${GREEN}✅ $passed/$total tests pasaron${NC}"
else
    echo -e "${YELLOW}⚠️ Algunos servicios tienen problemas${NC}"
    echo -e "${YELLOW}📊 $passed/$total tests pasaron${NC}"
    
    echo ""
    echo -e "${WHITE}💡 Para diagnosticar problemas:${NC}"
    echo -e "${GRAY}  • Ver logs: docker-compose logs <servicio>${NC}"
    echo -e "${GRAY}  • Estado: docker-compose ps${NC}"
    echo -e "${GRAY}  • Reiniciar: ./quick-backend.sh${NC}"
fi

echo ""
echo -e "${WHITE}🔗 URLs útiles:${NC}"
echo -e "${GRAY}  • Frontend: http://localhost:2012${NC}"
echo -e "${GRAY}  • Stats API: http://localhost:8003/docs${NC}"
echo -e "${GRAY}  • Fraude API: http://localhost:8001/docs${NC}"
echo -e "${GRAY}  • TextoSQL API: http://localhost:8000/docs${NC}"