#!/bin/bash
# 00-master-init.sh
# Script maestro de inicialización limpio y organizado
set -e

echo "🚀 Iniciando configuración de bases de datos..."

# Paso 0: Esperar a que PostgreSQL esté listo
echo "🔄 Esperando a que PostgreSQL esté completamente listo..."
until pg_isready -h localhost -U "$POSTGRES_USER"; do
  echo "   ⏳ PostgreSQL iniciando... esperando 2s"
  sleep 2
done
echo "✅ PostgreSQL está listo y acepta conexiones"

# Paso 1: Crear bases de datos
echo "📊 Creando bases de datos..."
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/01-create-databases.sql

# Paso 2: Configurar banco_global desde estructura organizada
echo "🏦 Configurando banco_global..."
echo "   📄 Ejecutando esquema de banco_global..."
psql -U "$POSTGRES_USER" -d banco_global -f /docker-entrypoint-initdb.d/databases/banco_global/01-schema.sql
echo "   📊 Cargando datos iniciales de banco_global..."
psql -U "$POSTGRES_USER" -d banco_global -f /docker-entrypoint-initdb.d/databases/banco_global/02-seed-data.sql

# Paso 3: Configurar bank_transactions desde estructura organizada
echo "🔍 Configurando bank_transactions..."
echo "   📄 Ejecutando esquema de bank_transactions..."
psql -U "$POSTGRES_USER" -d bank_transactions -f /docker-entrypoint-initdb.d/databases/bank_transactions/01-schema.sql
echo "   📊 Cargando datos básicos de bank_transactions..."
psql -U "$POSTGRES_USER" -d bank_transactions -f /docker-entrypoint-initdb.d/databases/bank_transactions/02-seed-data.sql
echo "   🚨 Generando 10,000+ fraudes para entrenamiento de IA..."
psql -U "$POSTGRES_USER" -d bank_transactions -f /docker-entrypoint-initdb.d/databases/bank_transactions/03-fraud-samples.sql

# Paso 4: Configurar ai_platform_stats desde estructura organizada
echo "📊 Configurando ai_platform_stats..."
echo "   📄 Ejecutando esquema de ai_platform_stats..."
psql -U "$POSTGRES_USER" -d ai_platform_stats -f /docker-entrypoint-initdb.d/databases/ai_platform_stats/01-schema.sql

# Paso 5: Configurar ai_platform_rag con pgvector
echo "🧠 Configurando ai_platform_rag (RAG con pgvector)..."
echo "   📄 Ejecutando esquema de ai_platform_rag con extensión pgvector..."
psql -U "$POSTGRES_USER" -d ai_platform_rag -f /docker-entrypoint-initdb.d/databases/ai_platform_rag/01-schema.sql

echo "✅ Configuración completa finalizada exitosamente"
echo ""
echo "📋 Bases de datos configuradas:"
echo "  🏦 banco_global (TextoSQL) - Esquema limpio + datos básicos"
echo "  🔍 bank_transactions (Detección de Fraude) - Esquema + muestras de fraude"
echo "  📊 ai_platform_stats (Stats API) - Esquema de métricas"
echo "  🧠 ai_platform_rag (RAG API) - Pgvector para embeddings"