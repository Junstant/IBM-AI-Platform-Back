#!/bin/bash
# 01-create-databases.sql
# Script para crear las bases de datos necesarias para la plataforma AI

set -e

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🗄️  Iniciando creación de bases de datos..."

# Crear base de datos para TextoSQL
log "📊 Creando base de datos: banco_global"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE banco_global;
    GRANT ALL PRIVILEGES ON DATABASE banco_global TO $POSTGRES_USER;
EOSQL

# Crear base de datos para detección de fraude
log "🔍 Creando base de datos: bank_transactions"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE bank_transactions;
    GRANT ALL PRIVILEGES ON DATABASE bank_transactions TO $POSTGRES_USER;
EOSQL

# Crear base de datos de pruebas adicional
log "🧪 Creando base de datos: demo_retail"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE demo_retail;
    GRANT ALL PRIVILEGES ON DATABASE demo_retail TO $POSTGRES_USER;
EOSQL

log "✅ Bases de datos creadas exitosamente"