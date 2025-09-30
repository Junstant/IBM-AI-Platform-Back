#!/bin/bash
set -e

# Script de entrada personalizado para PostgreSQL
# Combina la funcionalidad del script original con configuraciones específicas

echo "🐘 Iniciando PostgreSQL personalizado para Plataforma AI..."

# Función para logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Verificar variables de entorno requeridas
if [ -z "$POSTGRES_PASSWORD" ]; then
    log "❌ ERROR: POSTGRES_PASSWORD no está definida"
    exit 1
fi

# Configurar permisos del directorio de datos
if [ "$(id -u)" = '0' ]; then
    mkdir -p "$PGDATA"
    chown -R postgres:postgres "$PGDATA"
    chmod 700 "$PGDATA"
    
    # Configurar permisos para backups
    chown -R postgres:postgres /backups
    chmod 755 /backups
    
    # Cambiar a usuario postgres
    exec gosu postgres "$BASH_SOURCE" "$@"
fi

# Inicializar base de datos si no existe
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    log "📊 Inicializando nueva base de datos..."
    
    initdb --username="$POSTGRES_USER" --pwfile=<(echo "$POSTGRES_PASSWORD") --auth-local=trust --auth-host=md5
    
    # Configurar postgresql.conf personalizado
    if [ -f "/etc/postgresql/postgresql.conf" ]; then
        log "⚙️ Aplicando configuración personalizada..."
        cp /etc/postgresql/postgresql.conf "$PGDATA/postgresql.conf"
    fi
    
    # Configurar pg_hba.conf personalizado
    if [ -f "/etc/postgresql/pg_hba.conf" ]; then
        log "🔐 Aplicando configuración de autenticación..."
        cp /etc/postgresql/pg_hba.conf "$PGDATA/pg_hba.conf"
    fi
    
    log "✅ Base de datos inicializada correctamente"
fi

# Iniciar PostgreSQL normalmente para scripts de inicialización
if [ "$1" = 'postgres' ]; then
    # Verificar si hay scripts de inicialización pendientes
    if [ "$(ls -A /docker-entrypoint-initdb.d/ 2>/dev/null)" ] && [ ! -f "$PGDATA/.initialized" ]; then
        log "🚀 Iniciando PostgreSQL temporalmente para ejecutar scripts de inicialización..."
        
        # Iniciar servidor para ejecutar scripts
        pg_ctl -D "$PGDATA" -o "-c listen_addresses=''" -w start
        
        log "📋 Ejecutando scripts de inicialización..."
        
        # Ejecutar scripts en orden
        for f in /docker-entrypoint-initdb.d/*; do
            case "$f" in
                *.sh)
                    log "🔧 Ejecutando script: $(basename "$f")"
                    if [ -x "$f" ]; then
                        "$f"
                    else
                        bash "$f"
                    fi
                    ;;
                *.sql)
                    log "📄 Ejecutando SQL: $(basename "$f")"
                    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < "$f"
                    ;;
                *.sql.gz)
                    log "📦 Ejecutando SQL comprimido: $(basename "$f")"
                    gunzip -c "$f" | psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB"
                    ;;
                *)
                    log "⚠️ Ignorando archivo: $(basename "$f")"
                    ;;
            esac
        done
        
        # Detener servidor temporal
        pg_ctl -D "$PGDATA" -m fast -w stop
        
        log "✅ Scripts de inicialización completados"
        
        # Marcar como inicializado
        touch "$PGDATA/.initialized"
    fi
        
        # Marcar como inicializado
        touch "$PGDATA/.initialized"
    fi
    
    log "🎯 Iniciando PostgreSQL en modo producción..."
fi

# Ejecutar comando original
exec "$@"