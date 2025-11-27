#!/bin/bash
# ========================================================================
# 🔍 DIAGNÓSTICO DE EMBEDDINGS API
# ========================================================================
# Script para diagnosticar problemas con el servicio de embeddings
# ========================================================================

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

log() { echo -e "[$(date +'%H:%M:%S')] ${GREEN}✓ $1${NC}"; }
warn() { echo -e "[$(date +'%H:%M:%S')] ${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "[$(date +'%H:%M:%S')] ${RED}❌ $1${NC}"; }
info() { echo -e "[$(date +'%H:%M:%S')] ${CYAN}ℹ️  $1${NC}"; }

echo "========================================================================"
echo "🔍 DIAGNÓSTICO DEL SERVICIO DE EMBEDDINGS"
echo "========================================================================"
echo ""

# 1. Verificar contenedor
info "1️⃣ Verificando estado del contenedor embeddings-api..."
if docker ps | grep -q embeddings-api; then
    log "Contenedor embeddings-api está CORRIENDO"
    docker ps --filter "name=embeddings-api" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
else
    error "Contenedor embeddings-api NO está corriendo"
    exit 1
fi
echo ""

# 2. Verificar logs del contenedor
info "2️⃣ Últimas 30 líneas de logs del contenedor..."
docker logs --tail 30 embeddings-api
echo ""

# 3. Verificar modelo descargado
info "3️⃣ Verificando si el modelo Nomic está descargado..."
if docker exec embeddings-api ls -lh /models/nomic-embed-text-v1.5.Q4_K_M.gguf 2>/dev/null; then
    log "Modelo Nomic encontrado en el volumen"
else
    error "Modelo Nomic NO encontrado en /models/"
    warn "Listando todos los modelos disponibles:"
    docker exec embeddings-api ls -lh /models/ 2>/dev/null || echo "No se pudo listar /models/"
fi
echo ""

# 4. Verificar puerto interno
info "4️⃣ Verificando proceso en puerto 8080 (interno)..."
docker exec embeddings-api sh -c "netstat -tlnp 2>/dev/null | grep :8080 || ss -tlnp | grep :8080" || \
    warn "No se pudo verificar puerto 8080 (puede que netstat/ss no estén instalados)"
echo ""

# 5. Test de conectividad DESDE el contenedor RAG
info "5️⃣ Probando conectividad desde rag-api → embeddings-api..."
if docker exec rag-api curl -s -m 5 http://embeddings-api:8080/health > /dev/null 2>&1; then
    log "✓ RAG puede conectarse a embeddings-api internamente"
else
    error "✗ RAG NO puede conectarse a embeddings-api"
    warn "Probando conectividad básica..."
    docker exec rag-api ping -c 2 embeddings-api || echo "Ping falló"
fi
echo ""

# 6. Test de health check externo
info "6️⃣ Probando health check desde el host (puerto 8091)..."
if curl -s -m 5 http://localhost:8091/health > /dev/null 2>&1; then
    log "✓ Health check exitoso en puerto 8091"
    curl -s http://localhost:8091/health | head -20
else
    error "✗ Health check falló en puerto 8091"
    warn "Verificando qué está escuchando en 8091..."
    netstat -tlnp | grep 8091 || ss -tlnp | grep 8091 || echo "Puerto 8091 no está en uso"
fi
echo ""

# 7. Test de generación de embedding
info "7️⃣ Probando generación de embedding (test real)..."
RESPONSE=$(curl -s -X POST http://localhost:8091/embedding \
    -H "Content-Type: application/json" \
    -d '{"content": "Hello world"}' \
    --max-time 30)

if echo "$RESPONSE" | grep -q "embedding"; then
    log "✓ Embedding generado exitosamente"
    echo "$RESPONSE" | head -10
else
    error "✗ No se pudo generar embedding"
    echo "Respuesta recibida:"
    echo "$RESPONSE"
fi
echo ""

# 8. Verificar configuración del RAG
info "8️⃣ Verificando configuración del RAG..."
if docker exec rag-api env | grep -E "EMBEDDING_SERVICE_HOST|EMBEDDING_SERVICE_PORT|ENABLE_EMBEDDINGS"; then
    log "Variables de entorno del RAG configuradas"
else
    warn "No se encontraron variables de embeddings en RAG"
fi
echo ""

# 9. Verificar red de Docker
info "9️⃣ Verificando red de Docker..."
NETWORK=$(docker inspect embeddings-api --format '{{range .NetworkSettings.Networks}}{{.NetworkID}}{{end}}')
if [ -n "$NETWORK" ]; then
    log "Embeddings-api está en la red: $NETWORK"
    docker network inspect "$NETWORK" | grep -A 5 "embeddings-api\|rag-api"
else
    error "No se pudo determinar la red"
fi
echo ""

# RESUMEN
echo "========================================================================"
echo "📊 RESUMEN DEL DIAGNÓSTICO"
echo "========================================================================"
echo ""

# Verificaciones finales
CHECKS=0
PASSED=0

# Check 1: Contenedor corriendo
CHECKS=$((CHECKS + 1))
if docker ps | grep -q embeddings-api; then
    log "✓ Contenedor corriendo"
    PASSED=$((PASSED + 1))
else
    error "✗ Contenedor NO corriendo"
fi

# Check 2: Modelo existe
CHECKS=$((CHECKS + 1))
if docker exec embeddings-api ls /models/nomic-embed-text-v1.5.Q4_K_M.gguf > /dev/null 2>&1; then
    log "✓ Modelo Nomic descargado"
    PASSED=$((PASSED + 1))
else
    error "✗ Modelo Nomic NO encontrado"
fi

# Check 3: Puerto accesible externamente
CHECKS=$((CHECKS + 1))
if curl -s -m 5 http://localhost:8091/health > /dev/null 2>&1; then
    log "✓ Puerto 8091 accesible"
    PASSED=$((PASSED + 1))
else
    error "✗ Puerto 8091 NO accesible"
fi

# Check 4: Conectividad interna
CHECKS=$((CHECKS + 1))
if docker exec rag-api curl -s -m 5 http://embeddings-api:8080/health > /dev/null 2>&1; then
    log "✓ Conectividad interna OK"
    PASSED=$((PASSED + 1))
else
    error "✗ Conectividad interna FALLA"
fi

echo ""
echo "========================================================================"
if [ "$PASSED" -eq "$CHECKS" ]; then
    log "✅ TODOS LOS CHECKS PASARON ($PASSED/$CHECKS)"
    echo ""
    echo "El servicio de embeddings está funcionando correctamente."
    echo "Puedes probarlo con:"
    echo ""
    echo "  curl -X POST http://localhost:8091/embedding \\"
    echo "    -H 'Content-Type: application/json' \\"
    echo "    -d '{\"content\": \"Hello world\"}'"
else
    error "❌ ALGUNOS CHECKS FALLARON ($PASSED/$CHECKS pasaron)"
    echo ""
    echo "Sugerencias:"
    echo "  1. Si el modelo no existe, ejecuta: docker compose up -d model-downloader"
    echo "  2. Si el puerto no es accesible, verifica el .env (EMBEDDINGS_PORT=8091)"
    echo "  3. Si la conectividad interna falla, reinicia los contenedores:"
    echo "     docker compose restart embeddings-api rag-api"
fi
echo "========================================================================"
