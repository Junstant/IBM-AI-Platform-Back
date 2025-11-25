#!/bin/bash
# 00-master-init.sh
# Script maestro de inicialización limpio y organizado

echo "🚀 Iniciando configuración de bases de datos..."

# Paso 1: Crear bases de datos
echo "📊 Creando bases de datos..."
psql -U postgres -f /docker-entrypoint-initdb.d/01-create-databases.sql

# Paso 2: Configurar banco_global desde estructura organizada
echo "🏦 Configurando banco_global..."
psql -U postgres -f /docker-entrypoint-initdb.d/databases/banco_global/01-schema.sql
psql -U postgres -f /docker-entrypoint-initdb.d/databases/banco_global/02-seed-data.sql

# Paso 3: Configurar bank_transactions desde estructura organizada
echo "🔍 Configurando bank_transactions..."
psql -U postgres -f /docker-entrypoint-initdb.d/databases/bank_transactions/01-schema.sql
psql -U postgres -f /docker-entrypoint-initdb.d/databases/bank_transactions/02-seed-data.sql
psql -U postgres -f /docker-entrypoint-initdb.d/databases/bank_transactions/03-fraud-samples.sql

# Paso 4: Configurar ai_platform_stats desde estructura organizada
echo "📊 Configurando ai_platform_stats..."
psql -U postgres -f /docker-entrypoint-initdb.d/databases/ai_platform_stats/01-schema.sql

# Paso 5: Configurar ai_platform_rag con pgvector
echo "🧠 Configurando ai_platform_rag (RAG con pgvector)..."
psql -U postgres -f /docker-entrypoint-initdb.d/databases/ai_platform_rag/01-schema.sql

echo "✅ Configuración completa finalizada exitosamente"
echo ""
echo "📋 Bases de datos configuradas:"
echo "  🏦 banco_global (TextoSQL) - Esquema limpio + datos básicos"
echo "  🔍 bank_transactions (Detección de Fraude) - Esquema + muestras de fraude"
echo "  📊 ai_platform_stats (Stats API) - Esquema de métricas"
echo "  🧠 ai_platform_rag (RAG API) - Pgvector para embeddings"