#!/bin/bash
# Script automático para aplicar todos los esquemas SQL
# Se ejecuta automáticamente al iniciar PostgreSQL por primera vez
# IMPORTANTE: No usar set -e para que continúe aunque fallen los datos de prueba
set +e  # Desactivar salida en error para que continúe aplicando esquemas

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 INICIANDO CONFIGURACIÓN AUTOMÁTICA DE PLATAFORMA AI"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Directorio base donde están los esquemas
INIT_DIR="/docker-entrypoint-initdb.d/databases"

# ================================================================
# PASO 1: CREAR BASES DE DATOS
# ================================================================
echo ""
echo "📊 PASO 1/5: Creando bases de datos..."

# Usar ON_ERROR_STOP=0 para que continúe aunque una BD ya exista
psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
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
echo "📊 PASO 2/5: Aplicando esquema ai_platform_stats..."

if [ -f "$INIT_DIR/ai_platform_stats/01-schema.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ai_platform_stats" -f "$INIT_DIR/ai_platform_stats/01-schema.sql" && \
    echo "✅ Esquema ai_platform_stats aplicado correctamente" || \
    echo "⚠️  Error aplicando esquema ai_platform_stats (continuando...)"
else
    echo "⚠️  Archivo ai_platform_stats/01-schema.sql no encontrado"
fi

# ================================================================
# PASO 3: APLICAR ESQUEMA BANCO_GLOBAL
# ================================================================
echo ""
echo "📊 PASO 3/5: Aplicando esquema banco_global..."

if [ -f "$INIT_DIR/banco_global/01-schema.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "banco_global" -f "$INIT_DIR/banco_global/01-schema.sql" && \
    echo "✅ Esquema banco_global aplicado" || \
    echo "⚠️  Error aplicando esquema banco_global (continuando...)"
fi

# Los datos de prueba pueden fallar - NO detener el script
if [ -f "$INIT_DIR/banco_global/02-seed-data.sql" ]; then
    psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "banco_global" -f "$INIT_DIR/banco_global/02-seed-data.sql" && \
    echo "✅ Datos banco_global cargados" || \
    echo "⚠️  Algunos datos de banco_global fallaron (continuando de todas formas...)"
fi

# ================================================================
# PASO 4: APLICAR ESQUEMA BANK_TRANSACTIONS (CRÍTICO PARA FRAUDE)
# ================================================================
echo ""
echo "📊 PASO 4/5: Aplicando esquema bank_transactions..."

if [ -f "$INIT_DIR/bank_transactions/01-schema.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "bank_transactions" -f "$INIT_DIR/bank_transactions/01-schema.sql" && \
    echo "✅ Esquema bank_transactions aplicado" || \
    echo "❌ ERROR CRÍTICO: Esquema bank_transactions FALLÓ"
fi

# Los datos de prueba pueden fallar - NO detener el script
if [ -f "$INIT_DIR/bank_transactions/02-seed-data.sql" ]; then
    psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "bank_transactions" -f "$INIT_DIR/bank_transactions/02-seed-data.sql" && \
    echo "✅ Datos bank_transactions cargados" || \
    echo "⚠️  Algunos datos de bank_transactions fallaron (continuando...)"
fi

if [ -f "$INIT_DIR/bank_transactions/03-fraud-samples.sql" ]; then
    psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "bank_transactions" -f "$INIT_DIR/bank_transactions/03-fraud-samples.sql" && \
    echo "✅ Muestras de fraude cargadas" || \
    echo "⚠️  Algunas muestras de fraude fallaron (continuando...)"
fi

# ================================================================
# PASO 5: APLICAR ESQUEMA AI_PLATFORM_RAG
# ================================================================
echo ""
echo "📊 PASO 5/5: Aplicando esquema ai_platform_rag (pgvector)..."

if [ -f "$INIT_DIR/ai_platform_rag/01-schema.sql" ]; then
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "ai_platform_rag" -f "$INIT_DIR/ai_platform_rag/01-schema.sql" && \
    echo "✅ Esquema ai_platform_rag aplicado" || \
    echo "⚠️  Error aplicando esquema ai_platform_rag (continuando...)"
fi

# ================================================================
# VERIFICACIÓN FINAL
# ================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 VERIFICACIÓN FINAL DE ESQUEMAS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for db in ai_platform_stats banco_global bank_transactions ai_platform_rag; do
    TABLE_COUNT=$(psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" --dbname "$db" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public'" 2>/dev/null || echo "0")
    if [ "$TABLE_COUNT" -gt 0 ]; then
        echo "✅ $db: $TABLE_COUNT tablas"
    else
        echo "❌ $db: SIN TABLAS (FALLÓ)"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 INICIALIZACIÓN COMPLETADA"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  NOTA: Si algún esquema falló, revisar logs arriba"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
