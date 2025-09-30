#!/bin/bash
# Script de diagnóstico simplificado para AI Platform

echo "🔍 DIAGNÓSTICO SIMPLIFICADO DE AI PLATFORM"
echo "=========================================="

# Cambiar al directorio del proyecto
cd "$(dirname "$0")/.."

echo ""
echo "📊 ESTADO DE CONTENEDORES:"
echo "-------------------------"
docker-compose ps

echo ""
echo "💾 USO DE RECURSOS:"
echo "------------------"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" 2>/dev/null || echo "No hay contenedores ejecutándose"

echo ""
echo "🐘 POSTGRESQL:"
echo "-------------"
if docker ps | grep -q postgres_ai_platform; then
    echo "Estado: ✅ Ejecutándose"
    if docker exec postgres_ai_platform pg_isready -U postgres 2>/dev/null; then
        echo "Conexión: ✅ OK"
        echo "Bases de datos:"
        docker exec postgres_ai_platform psql -U postgres -c "\l" 2>/dev/null | grep -E "(banco_global|bank_transactions|demo_retail)" || echo "  Bases de datos inicializándose..."
    else
        echo "Conexión: ❌ Error"
    fi
    echo ""
    echo "Últimos 10 logs:"
    docker logs --tail=10 postgres_ai_platform
else
    echo "Estado: ❌ No ejecutándose"
fi

echo ""
echo "🌐 APIs:"
echo "-------"

# Fraude API
echo "Fraude API (puerto 8000):"
if curl -s -f http://localhost:8000/health >/dev/null 2>&1; then
    echo "  Estado: ✅ Funcionando"
else
    echo "  Estado: ❌ No responde"
    if docker ps | grep -q fraude-api; then
        echo "  Últimos 5 logs:"
        docker logs --tail=5 fraude-api 2>/dev/null | sed 's/^/    /'
    fi
fi

# TextoSQL API
echo "TextoSQL API (puerto 8001):"
if curl -s -f http://localhost:8001/health >/dev/null 2>&1; then
    echo "  Estado: ✅ Funcionando"
else
    echo "  Estado: ❌ No responde"
    if docker ps | grep -q textosql-api; then
        echo "  Últimos 5 logs:"
        docker logs --tail=5 textosql-api 2>/dev/null | sed 's/^/    /'
    fi
fi

echo ""
echo "🧠 SERVIDOR LLM:"
echo "---------------"
echo "LLM Server (puerto 8080):"

if docker ps | grep -q llm-server; then
    if curl -s -f http://localhost:8080/health >/dev/null 2>&1; then
        echo "  Estado: ✅ Funcionando"
    elif curl -s http://localhost:8080 >/dev/null 2>&1; then
        echo "  Estado: 🔄 Iniciando"
    else
        echo "  Estado: ❌ No responde"
        echo "  Últimos 5 logs:"
        docker logs --tail=5 llm-server 2>/dev/null | sed 's/^/    /'
    fi
else
    echo "  Estado: ❌ No ejecutándose"
fi

echo ""
echo "📁 ARCHIVOS DE MODELOS:"
echo "----------------------"
if [ -d "./models" ]; then
    echo "Modelos disponibles:"
    if ls ./models/*.gguf >/dev/null 2>&1; then
        ls -lh ./models/*.gguf | awk '{print "  " $9 " (" $5 ")"}'
        echo ""
        echo "Espacio usado en /models:"
        du -sh ./models 2>/dev/null || echo "  No se pudo acceder al directorio"
    else
        echo "  ❌ No hay modelos descargados"
        echo "  💡 Use: ./ai-platform.sh (opción 4) para descargar Gemma 2B"
    fi
else
    echo "❌ Directorio ./models no encontrado"
fi

echo ""
echo "🔧 CONFIGURACIÓN:"
echo "----------------"
if [ -f ".env" ]; then
    echo "Archivo .env: ✅ Presente"
    echo "Variables principales:"
    grep -E "^(DB_|.*_PORT|LLM_)" .env 2>/dev/null | sed 's/^/  /'
else
    echo "Archivo .env: ❌ No encontrado"
    echo "💡 Use: ./ai-platform.sh (opción 10) para crearlo"
fi

echo ""
echo "💻 SISTEMA:"
echo "----------"
if command -v free &> /dev/null; then
    echo "Memoria total: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Memoria libre: $(free -h | awk '/^Mem:/ {print $7}')"
fi
echo "Espacio en disco:"
df -h . | tail -1 | awk '{print "  Usado: " $3 " / " $2 " (" $5 ")"}'

echo ""
echo "🔍 COMANDOS ÚTILES:"
echo "------------------"
echo "  Gestión completa:           ./ai-platform.sh"
echo "  Ver logs de un servicio:    docker-compose logs -f [servicio]"
echo "  Reiniciar un servicio:      docker-compose restart [servicio]"
echo "  Parar todo:                 docker-compose down"
echo "  Estado actual:              docker-compose ps"