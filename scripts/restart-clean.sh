#!/bin/bash
# Script de reinicio limpio para AI Platform

set -e

echo "🔄 Reinicio limpio de AI Platform..."

# Cambiar al directorio del proyecto
cd "$(dirname "$0")/.."

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🛑 Deteniendo todos los servicios..."
docker-compose down --remove-orphans

log "🧹 Limpiando recursos Docker..."
docker system prune -f
docker volume prune -f

log "🔧 Verificando permisos de scripts..."
chmod +x database/docker-entrypoint-custom.sh
chmod +x scripts/*.sh

log "🔨 Reconstruyendo imágenes..."
docker-compose build --no-cache postgres fraude-api textosql-api

log "🚀 Iniciando PostgreSQL..."
docker-compose up -d postgres

log "⏳ Esperando PostgreSQL (90s)..."
for i in {1..30}; do
    if docker exec postgres_ai_platform pg_isready -U postgres 2>/dev/null; then
        log "✅ PostgreSQL está listo"
        break
    else
        log "⏳ Esperando PostgreSQL... ($i/30)"
        sleep 3
    fi
done

# Verificar que PostgreSQL esté funcionando
if ! docker exec postgres_ai_platform pg_isready -U postgres 2>/dev/null; then
    log "❌ PostgreSQL no está respondiendo"
    log "📋 Logs de PostgreSQL:"
    docker logs --tail=50 postgres_ai_platform
    exit 1
fi

log "🚀 Iniciando APIs..."
docker-compose up -d fraude-api textosql-api

log "⏳ Esperando APIs (30s)..."
sleep 30

log "🧠 Iniciando servidores LLM uno por uno..."

# Iniciar solo los modelos más pequeños primero
log "🔹 Iniciando Granite 2B..."
docker-compose up -d granite-2b-server
sleep 15

log "🔹 Iniciando DeepSeek 1.5B..."
docker-compose up -d deepseek1.5B-td-server
sleep 15

log "🔹 Iniciando Gemma 2B..."
docker-compose up -d gemma2b-td-server
sleep 15

log "🔹 Iniciando Granite 8B..."
docker-compose up -d granite-td-server
sleep 20

log "🔹 Iniciando Gemma 4B..."
docker-compose up -d google_gemma4b-td-server
sleep 20

log "🔹 Iniciando DeepSeek 8B..."
docker-compose up -d deepseek8b-td-server
sleep 25

log "🔹 Iniciando Mistral 7B..."
docker-compose up -d mistral-td-server
sleep 30

# Modelos más grandes - solo si hay suficiente memoria
log "🔹 Iniciando modelos grandes..."
docker-compose up -d deepseek14B-td-server
sleep 30

docker-compose up -d google_gemma12b-td-server
sleep 30

docker-compose up -d gpt-oss-20b-server

log "✅ Reinicio completado"
log "📊 Estado de contenedores:"
docker-compose ps

log "🔍 Verificando servicios..."
sleep 10

# Verificar servicios
echo ""
echo "🏥 Estado de salud de servicios:"

# PostgreSQL
if docker exec postgres_ai_platform pg_isready -U postgres 2>/dev/null; then
    echo "✅ PostgreSQL: Funcionando"
else
    echo "❌ PostgreSQL: No responde"
fi

# APIs
if curl -f http://localhost:8000/health 2>/dev/null; then
    echo "✅ Fraude API: Funcionando"
else
    echo "⚠️  Fraude API: No responde (puede estar iniciando)"
fi

if curl -f http://localhost:8001/health 2>/dev/null; then
    echo "✅ TextoSQL API: Funcionando"
else
    echo "⚠️  TextoSQL API: No responde (puede estar iniciando)"
fi

echo ""
echo "📋 Para ver logs de un servicio específico:"
echo "   docker-compose logs -f [nombre-servicio]"
echo ""
echo "📋 Para verificar el estado:"
echo "   docker-compose ps"
echo ""
echo "📋 Para parar todo:"
echo "   docker-compose down"