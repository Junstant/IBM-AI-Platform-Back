#!/bin/bash
# Script para iniciar solo servicios básicos (PostgreSQL + APIs + 1-2 LLMs)

set -e

echo "🚀 Iniciando servicios básicos de AI Platform..."

# Cambiar al directorio del proyecto
cd "$(dirname "$0")/.."

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🛑 Deteniendo servicios existentes..."
docker-compose down

log "🔨 Construyendo imágenes necesarias..."
docker-compose build postgres fraude-api textosql-api

log "🚀 Iniciando PostgreSQL..."
docker-compose up -d postgres

log "⏳ Esperando PostgreSQL..."
for i in {1..20}; do
    if docker exec postgres_ai_platform pg_isready -U postgres 2>/dev/null; then
        log "✅ PostgreSQL listo"
        break
    else
        log "⏳ Esperando PostgreSQL... ($i/20)"
        sleep 5
    fi
done

log "🚀 Iniciando APIs..."
docker-compose up -d fraude-api textosql-api

log "⏳ Esperando APIs..."
sleep 30

log "🧠 Iniciando modelo LLM básico (Granite 2B)..."
docker-compose up -d granite-2b-server

log "⏳ Esperando modelo..."
sleep 20

log "🧠 Iniciando segundo modelo (Gemma 2B)..."
docker-compose up -d gemma2b-td-server

log "✅ Servicios básicos iniciados"
log "📊 Estado:"
docker-compose ps

echo ""
echo "🌐 SERVICIOS DISPONIBLES:"
echo "========================"
echo "  PostgreSQL:     http://localhost:8070"
echo "  Fraude API:     http://localhost:8000/docs"
echo "  TextoSQL API:   http://localhost:8001/docs"
echo "  Granite 2B:     http://localhost:8097"
echo "  Gemma 2B:       http://localhost:9470"
echo ""
echo "🔧 Para iniciar más modelos:"
echo "  docker-compose up -d [nombre-servicio]"
echo ""
echo "📋 Servicios disponibles:"
echo "  mistral-td-server granite-td-server deepseek8b-td-server"
echo "  google_gemma4b-td-server deepseek1.5B-td-server"