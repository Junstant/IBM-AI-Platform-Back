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
    DROP DATABASE IF EXISTS banco_global;
    CREATE DATABASE banco_global WITH OWNER = $POSTGRES_USER ENCODING = 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE banco_global TO $POSTGRES_USER;
    
    -- Crear base de datos para detección de fraude
    DROP DATABASE IF EXISTS bank_transactions;
    CREATE DATABASE bank_transactions WITH OWNER = $POSTGRES_USER ENCODING = 'UTF8';
    GRANT ALL PRIVILEGES ON DATABASE bank_transactions TO $POSTGRES_USER;
    
    -- Crear base de datos de pruebas
    DROP DATABASE IF EXISTS demo_retail;
    CREATE DATABASE demo_retail WITH OWNER = $POSTGRES_USER ENCODING = 'UTF8';
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

# 6.1. Crear esquemas faltantes para bases de datos existentes
log "🔧 Paso 6.1: Creando esquemas faltantes..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/12-create-missing-schemas.sql

# 7. Poblar base de datos petrolera
log "⛽ Paso 7: Poblando base de datos petrolera..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "petrolera" -f /docker-entrypoint-initdb.d/07-populate-petrolera.sql

# 8. Poblar base de datos banco_global con datos masivos
log "🏦 Paso 8: Poblando banco_global con datos masivos..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "banco_global" -f /docker-entrypoint-initdb.d/08-populate-banco-global.sql

# 9. Poblar base de datos empresa_minera
log "⛏️ Paso 9: Poblando base de datos empresa_minera..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "empresa_minera" -f /docker-entrypoint-initdb.d/09-populate-empresa-minera.sql

# 10. Poblar base de datos supermercado
log "🛒 Paso 10: Poblando base de datos supermercado..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "supermercado" -f /docker-entrypoint-initdb.d/10-populate-supermercado.sql

# 12. Poblar base de datos empresa_agronomia
log "🌾 Paso 12: Poblando base de datos empresa_agronomia..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "empresa_agronomia" -f /docker-entrypoint-initdb.d/11-populate-empresa-agronomia.sql

# 13. Verificar que todas las consultas funcionen
log "🔍 Paso 13: Verificando consultas requeridas..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/13-verify-queries.sql

log "✅ Inicialización completada exitosamente"
log "📊 Resumen de bases de datos creadas:"
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname;"

log "🎉 Sistema listo para usar con credenciales:"
log "   Usuario: $POSTGRES_USER"
log "   Contraseña: [configurada desde variables de entorno]"
log "📊 Bases de datos pobladas con datos masivos:"
log "   - petrolera: ~1,311,500 registros"
log "   - banco_global: ~602,105 registros" 
log "   - empresa_minera: ~1,745,380 registros"
log "   - supermercado: ~945,610 registros"
log "   - empresa_agronomia: ~945,610 registros"
log "   - bank_transactions: configurada para detección de fraude"
log "   - demo_retail: configurada para pruebas adicionales"
log ""
log "✅ TODAS LAS CONSULTAS REQUERIDAS HAN SIDO VERIFICADAS:"
log "📈 Petrolera: ✓ 100 pozos más productivos, ✓ equipos fuera de servicio"
log "🏦 Banco Global: ✓ préstamos activos altos, ✓ transacciones grandes, ✓ cuenta con más transacciones"
log "⛏️ Empresa Minera: ✓ máquinas productivas, ✓ extracciones nocturnas, ✓ minerales más vendidos"
log "🛒 Supermercado: ✓ ventas por sucursal, ✓ día con más ventas, ✓ valor inventario"
log "🌾 Empresa Agronomía: ✓ superficie por cultivo, ✓ insumo más gastado, ✓ historial insumo 36"