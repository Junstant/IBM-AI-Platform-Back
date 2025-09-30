#!/bin/bash

# Script para iniciar servicios básicos paso a paso
echo "🚀 INICIANDO SERVICIOS BÁSICOS DE AI PLATFORM"
echo "============================================="

cd "$(dirname "$0")/.."

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Función para verificar si un servicio está listo
check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=${3:-10}
    
    for i in $(seq 1 $max_attempts); do
        if curl -s -f "$url" > /dev/null 2>&1; then
            log "✅ $service_name está listo"
            return 0
        else
            log "⏳ $service_name no está listo, esperando... ($i/$max_attempts)"
            sleep 10
        fi
    done
    
    log "❌ $service_name no respondió después de $max_attempts intentos"
    return 1
}

# 1. Iniciar PostgreSQL
log "🐘 Iniciando PostgreSQL..."
docker-compose up -d postgres

log "⏳ Esperando PostgreSQL..."
check_service "PostgreSQL" "http://localhost:8070" 15

# 2. Iniciar modelo pequeño primero (Gemma 2B)
log "🧠 Iniciando modelo Gemma 2B..."
docker-compose up -d gemma2b-td-server

log "⏳ Esperando Gemma 2B..."
check_service "Gemma 2B" "http://localhost:9470/health" 20

# 3. Iniciar APIs
log "🔌 Iniciando APIs..."
docker-compose up -d textosql-api fraude-api

log "⏳ Esperando APIs..."
check_service "TextoSQL API" "http://localhost:8001/health" 10 &
check_service "Fraude API" "http://localhost:8000/" 10 &
wait

# 4. Iniciar modelo mediano (Granite 2B)
log "🧠 Iniciando modelo Granite 2B..."
docker-compose up -d granite-2b-server

log "⏳ Esperando Granite 2B..."
check_service "Granite 2B" "http://localhost:8097/health" 20

# 5. Mostrar estado
log "📊 Estado actual de servicios básicos:"
docker-compose ps

log "🎉 Servicios básicos iniciados. Para agregar más modelos:"
echo "   - Modelo Granite 8B:    docker-compose up -d granite-td-server"
echo "   - Modelo Mistral 7B:    docker-compose up -d mistral-td-server" 
echo "   - Modelo DeepSeek 1.5B: docker-compose up -d deepseek1.5B-td-server"
echo "   - Todos los modelos:    docker-compose up -d"

log "🌐 URLs de acceso:"
echo "   - PostgreSQL:     http://localhost:8070"
echo "   - TextoSQL API:   http://localhost:8001/docs"
echo "   - Fraude API:     http://localhost:8000/docs"
echo "   - Gemma 2B:       http://localhost:9470"
echo "   - Granite 2B:     http://localhost:8097"