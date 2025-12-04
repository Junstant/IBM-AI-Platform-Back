#!/bin/bash
# Script automático para aplicar todos los esquemas SQL
# Se ejecuta automáticamente al iniciar PostgreSQL por primera vez
set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 INICIANDO CONFIGURACIÓN AUTOMÁTICA DE PLATAFORMA AI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Directorio base donde están los esquemas
INIT_DIR="/docker-entrypoint-initdb.d/databases"

# ================================================================
# PASO 1: CREAR BASES DE DATOS
# ================================================================
echo ""
echo "📊 PASO 1/4: Creando bases de datos..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    SELECT 'CREATE DATABASE ai_platform_stats' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ai_platform_stats')\\gexec
    SELECT 'CREATE DATABASE banco_global' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'banco_global')\\gexec
    SELECT 'CREATE DATABASE bank_transactions' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bank_transactions')\\gexec
    SELECT 'CREATE DATABASE ai_platform_rag' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ai_platform_rag')\\gexec
EOSQL

echo "✅ Bases de datos creadas/verificadas"

# ================================================================
# PASO 2: APLICAR ESQUEMA AI_PLATFORM_STATS
# ================================================================
echo ""
echo "📊 PASO 2/4: Aplicando esquema ai_platform_stats..."

if [ -f "$INIT_DIR/ai_platform_stats/01-schema.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ai_platform_stats" -f "$INIT_DIR/ai_platform_stats/01-schema.sql"
    echo "✅ Esquema ai_platform_stats aplicado correctamente"
else
    echo "⚠️  Archivo ai_platform_stats/01-schema.sql no encontrado"
fi

# ================================================================
# PASO 3: APLICAR ESQUEMA BANCO_GLOBAL
# ================================================================
echo ""
echo "📊 PASO 3/4: Aplicando esquema banco_global..."

if [ -f "$INIT_DIR/banco_global/01-schema.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "banco_global" -f "$INIT_DIR/banco_global/01-schema.sql"
    echo "✅ Esquema banco_global aplicado"
fi

if [ -f "$INIT_DIR/banco_global/02-seed-data.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "banco_global" -f "$INIT_DIR/banco_global/02-seed-data.sql"
    echo "✅ Datos banco_global cargados"
fi

# ================================================================
# PASO 4: APLICAR ESQUEMA BANK_TRANSACTIONS
# ================================================================
echo ""
echo "📊 PASO 4/4: Aplicando esquema bank_transactions..."

if [ -f "$INIT_DIR/bank_transactions/01-schema.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "bank_transactions" -f "$INIT_DIR/bank_transactions/01-schema.sql"
    echo "✅ Esquema bank_transactions aplicado"
fi

if [ -f "$INIT_DIR/bank_transactions/02-seed-data.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "bank_transactions" -f "$INIT_DIR/bank_transactions/02-seed-data.sql"
    echo "✅ Datos bank_transactions cargados"
fi

if [ -f "$INIT_DIR/bank_transactions/03-fraud-samples.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "bank_transactions" -f "$INIT_DIR/bank_transactions/03-fraud-samples.sql"
    echo "✅ Muestras de fraude cargadas"
fi

# ================================================================
# PASO 5: APLICAR ESQUEMA AI_PLATFORM_RAG
# ================================================================
echo ""
echo "📊 PASO 5/5: Aplicando esquema ai_platform_rag (pgvector)..."

if [ -f "$INIT_DIR/ai_platform_rag/01-schema.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ai_platform_rag" -f "$INIT_DIR/ai_platform_rag/01-schema.sql"
    echo "✅ Esquema ai_platform_rag aplicado"
fi

# ================================================================
# VERIFICACIÓN FINAL
# ================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 VERIFICACIÓN FINAL DE ESQUEMAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for db in ai_platform_stats banco_global bank_transactions ai_platform_rag; do
    TABLE_COUNT=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$db" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'")
    echo "✅ $db: $TABLE_COUNT tablas"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 INICIALIZACIÓN COMPLETADA EXITOSAMENTE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
