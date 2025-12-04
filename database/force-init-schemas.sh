#!/bin/bash
# ================================================================
# SCRIPT DE EMERGENCIA: FORZAR CREACIÓN DE ESQUEMAS
# ================================================================
# Usa este script si los init scripts no se ejecutaron correctamente
# Ejecutar: docker exec -i postgres_db bash < force-init-schemas.sh
# O desde el host: ./database/force-init-schemas.sh
# ================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️${NC} $1"; }

# Detectar si estamos dentro del contenedor o fuera
if [ -f "/.dockerenv" ]; then
    IN_CONTAINER=true
    BASE_PATH="/docker-entrypoint-initdb.d/databases"
else
    IN_CONTAINER=false
    # Encontrar el contenedor de PostgreSQL
    POSTGRES_CONTAINER=$(docker ps --filter "name=postgres" --format "{{.Names}}" | head -n1)
    
    if [ -z "$POSTGRES_CONTAINER" ]; then
        error "No se encontró contenedor de PostgreSQL en ejecución"
        exit 1
    fi
    
    log "🐳 Contenedor PostgreSQL: $POSTGRES_CONTAINER"
fi

apply_schema() {
    local db_name="$1"
    local schema_path="$2"
    
    log "📝 Aplicando esquema a: $db_name"
    
    if [ "$IN_CONTAINER" = true ]; then
        psql -U postgres -d "$db_name" -f "$schema_path"
    else
        docker exec -i "$POSTGRES_CONTAINER" psql -U postgres -d "$db_name" < "$schema_path"
    fi
    
    if [ $? -eq 0 ]; then
        log "✅ Esquema $db_name aplicado exitosamente"
        return 0
    else
        error "Error aplicando esquema $db_name"
        return 1
    fi
}

check_database_exists() {
    local db_name="$1"
    
    if [ "$IN_CONTAINER" = true ]; then
        psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'" | grep -q 1
    else
        docker exec "$POSTGRES_CONTAINER" psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$db_name'" | grep -q 1
    fi
}

# ================================================================
# MAIN
# ================================================================
log "🚀 Iniciando aplicación forzada de esquemas SQL..."

# Directorio base de esquemas
if [ "$IN_CONTAINER" = true ]; then
    SCHEMAS_DIR="/docker-entrypoint-initdb.d/databases"
else
    SCHEMAS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/init-scripts/databases" && pwd)"
fi

log "📁 Usando directorio de esquemas: $SCHEMAS_DIR"

# 1. ai_platform_stats (CRÍTICO)
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "1️⃣  AI PLATFORM STATS"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! check_database_exists "ai_platform_stats"; then
    error "Base de datos ai_platform_stats no existe. Ejecutar primero: 01-create-databases.sql"
    exit 1
fi

if [ "$IN_CONTAINER" = true ]; then
    TABLE_COUNT=$(psql -U postgres -d ai_platform_stats -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")
else
    TABLE_COUNT=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -d ai_platform_stats -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'")
fi

if [ "$TABLE_COUNT" -gt 0 ]; then
    warn "ai_platform_stats ya tiene $TABLE_COUNT tablas. ¿Recrear? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log "⏭️  Saltando ai_platform_stats"
    else
        if [ "$IN_CONTAINER" = true ]; then
            psql -U postgres -d ai_platform_stats -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
        else
            docker exec "$POSTGRES_CONTAINER" psql -U postgres -d ai_platform_stats -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
        fi
        apply_schema "ai_platform_stats" "$SCHEMAS_DIR/ai_platform_stats/01-schema.sql"
    fi
else
    apply_schema "ai_platform_stats" "$SCHEMAS_DIR/ai_platform_stats/01-schema.sql"
fi

# 2. banco_global
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "2️⃣  BANCO GLOBAL"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if check_database_exists "banco_global"; then
    apply_schema "banco_global" "$SCHEMAS_DIR/banco_global/01-schema.sql"
    apply_schema "banco_global" "$SCHEMAS_DIR/banco_global/02-seed-data.sql"
else
    warn "Base de datos banco_global no existe"
fi

# 3. bank_transactions
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "3️⃣  BANK TRANSACTIONS"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if check_database_exists "bank_transactions"; then
    apply_schema "bank_transactions" "$SCHEMAS_DIR/bank_transactions/01-schema.sql"
    apply_schema "bank_transactions" "$SCHEMAS_DIR/bank_transactions/02-seed-data.sql"
    apply_schema "bank_transactions" "$SCHEMAS_DIR/bank_transactions/03-fraud-samples.sql"
else
    warn "Base de datos bank_transactions no existe"
fi

# 4. ai_platform_rag
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "4️⃣  AI PLATFORM RAG (pgvector)"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if check_database_exists "ai_platform_rag"; then
    apply_schema "ai_platform_rag" "$SCHEMAS_DIR/ai_platform_rag/01-schema.sql"
else
    warn "Base de datos ai_platform_rag no existe"
fi

# Verificación final
log ""
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "✅ VERIFICACIÓN FINAL"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for db in ai_platform_stats banco_global bank_transactions ai_platform_rag; do
    if [ "$IN_CONTAINER" = true ]; then
        count=$(psql -U postgres -d "$db" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null || echo "0")
    else
        count=$(docker exec "$POSTGRES_CONTAINER" psql -U postgres -d "$db" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null || echo "0")
    fi
    
    log "   $db: $count tablas"
done

log ""
log "🎉 ¡Esquemas aplicados exitosamente!"
