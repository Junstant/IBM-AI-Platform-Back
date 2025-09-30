#!/bin/bash
# 00-master-init.sh
# Script maestro que ejecuta todos los scripts de inicialización en el orden correcto

set -e

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "🚀 Iniciando inicialización completa de la base de datos..."

# Verificar variables de entorno
if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_PASSWORD" ]; then
    log "❌ ERROR: Variables de entorno POSTGRES_USER y POSTGRES_PASSWORD son requeridas"
    exit 1
fi

log "📋 Configuración actual:"
log "   Usuario: $POSTGRES_USER"
log "   Base de datos principal: $POSTGRES_DB"
log "   Host: $(hostname)"

# 1. Crear bases de datos
log "📊 Paso 1: Creando bases de datos..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Crear base de datos para TextoSQL
    SELECT 'CREATE DATABASE banco_global' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'banco_global')\gexec
    GRANT ALL PRIVILEGES ON DATABASE banco_global TO $POSTGRES_USER;
    
    -- Crear base de datos para detección de fraude
    SELECT 'CREATE DATABASE bank_transactions' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bank_transactions')\gexec
    GRANT ALL PRIVILEGES ON DATABASE bank_transactions TO $POSTGRES_USER;
    
    -- Crear base de datos de pruebas
    SELECT 'CREATE DATABASE demo_retail' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'demo_retail')\gexec
    GRANT ALL PRIVILEGES ON DATABASE demo_retail TO $POSTGRES_USER;
EOSQL

# 2. Configurar esquema banco_global
log "🏦 Paso 2: Configurando esquema banco_global..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "banco_global" -f /docker-entrypoint-initdb.d/02-banco-global-schema.sql

# 3. Insertar datos de ejemplo en banco_global
log "📈 Paso 3: Insertando datos en banco_global..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "banco_global" -f /docker-entrypoint-initdb.d/03-banco-global-data.sql

# 4. Configurar esquema bank_transactions
log "🔍 Paso 4: Configurando esquema bank_transactions..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "bank_transactions" -f /docker-entrypoint-initdb.d/04-bank-transactions-schema.sql

# 5. Insertar datos de ejemplo en bank_transactions
log "💳 Paso 5: Insertando datos de fraude..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "bank_transactions" -f /docker-entrypoint-initdb.d/06-insert-sample-fraud-data.sql

# 6. Configurar esquema demo_retail
log "🛍️ Paso 6: Configurando esquema demo_retail..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "demo_retail" -f /docker-entrypoint-initdb.d/05-demo-retail-schema.sql

log "✅ Inicialización completada exitosamente"
log "📊 Resumen de bases de datos creadas:"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname;"

log "🎉 Sistema listo para usar"