#!/bin/bash
# Script de diagnóstico para AI Platform

echo "🔍 DIAGNÓSTICO DE AI PLATFORM"
echo "=============================="

# Cambiar al directorio del proyecto
cd "$(dirname "$0")/.."

echo ""
echo "📊 ESTADO DE CONTENEDORES:"
echo "-------------------------"
docker-compose ps

echo ""
echo "💾 USO DE RECURSOS:"
echo "------------------"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "🔗 REDES DOCKER:"
echo "---------------"
docker network ls | grep -E "(NAME|platform_ai)"

echo ""
echo "📁 VOLÚMENES:"
echo "------------"
docker volume ls | grep -E "(NAME|postgres)"

echo ""
echo "🐘 POSTGRESQL:"
echo "-------------"
if docker ps | grep -q postgres_ai_platform; then
    echo "Estado: Ejecutándose"
    if docker exec postgres_ai_platform pg_isready -U postgres 2>/dev/null; then
        echo "Conexión: ✅ OK"
        echo "Bases de datos:"
        docker exec postgres_ai_platform psql -U postgres -c "\l" 2>/dev/null | grep -E "(banco_global|bank_transactions|demo_retail)"
    else
        echo "Conexión: ❌ Error"
    fi
    echo ""
    echo "Últimos 20 logs:"
    docker logs --tail=20 postgres_ai_platform
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
        echo "  Últimos 10 logs:"
        docker logs --tail=10 fraude-api
    fi
fi

# TextoSQL API
echo "TextoSQL API (puerto 8001):"
if curl -s -f http://localhost:8001/health >/dev/null 2>&1; then
    echo "  Estado: ✅ Funcionando"
else
    echo "  Estado: ❌ No responde"
    if docker ps | grep -q textosql-api; then
        echo "  Últimos 10 logs:"
        docker logs --tail=10 textosql-api
    fi
fi

echo ""
echo "🧠 SERVIDORES LLM:"
echo "-----------------"

# Lista de servicios LLM
llm_services=(
    "mistral-td-server:8096"
    "gemma2b-td-server:9470"
    "granite-td-server:8095"
    "google_gemma4b-td-server:8094"
    "deepseek8b-td-server:8092"
    "deepseek1.5B-td-server:8091"
    "deepseek14B-td-server:8090"
    "granite-2b-server:8097"
    "gpt-oss-20b-server:8098"
    "google_gemma12b-td-server:2005"
)

for service_port in "${llm_services[@]}"; do
    service=$(echo $service_port | cut -d: -f1)
    port=$(echo $service_port | cut -d: -f2)
    
    echo "$service (puerto $port):"
    
    if docker ps | grep -q $service; then
        if curl -s -f http://localhost:$port/health >/dev/null 2>&1; then
            echo "  Estado: ✅ Funcionando"
        elif curl -s http://localhost:$port >/dev/null 2>&1; then
            echo "  Estado: 🔄 Iniciando"
        else
            echo "  Estado: ❌ No responde"
            echo "  Últimos 5 logs:"
            docker logs --tail=5 $service 2>/dev/null | sed 's/^/    /'
        fi
    else
        echo "  Estado: ❌ No ejecutándose"
    fi
done

echo ""
echo "📁 ARCHIVOS DE MODELOS:"
echo "----------------------"
if [ -d "./models" ]; then
    echo "Modelos disponibles:"
    ls -lh ./models/*.gguf 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    echo ""
    echo "Espacio usado en /models:"
    du -sh ./models 2>/dev/null || echo "  No se pudo acceder al directorio"
else
    echo "❌ Directorio ./models no encontrado"
fi

echo ""
echo "🔧 CONFIGURACIÓN:"
echo "----------------"
if [ -f ".env" ]; then
    echo "Archivo .env: ✅ Presente"
    echo "Variables principales:"
    grep -E "^(DB_|POSTGRES_|.*_PORT)" .env 2>/dev/null | sed 's/^/  /'
else
    echo "Archivo .env: ❌ No encontrado"
fi

echo ""
echo "💻 SISTEMA:"
echo "----------"
echo "Memoria total: $(free -h | awk '/^Mem:/ {print $2}')"
echo "Memoria libre: $(free -h | awk '/^Mem:/ {print $7}')"
echo "Espacio en disco:"
df -h . | tail -1 | awk '{print "  Usado: " $3 " / " $2 " (" $5 ")"}'

echo ""
echo "🔍 COMANDOS ÚTILES:"
echo "------------------"
echo "  Ver logs de un servicio:    docker-compose logs -f [servicio]"
echo "  Reiniciar un servicio:      docker-compose restart [servicio]"
echo "  Parar todo:                 docker-compose down"
echo "  Reinicio limpio:            ./scripts/restart-clean.sh"
echo "  Estado actual:              docker-compose ps"