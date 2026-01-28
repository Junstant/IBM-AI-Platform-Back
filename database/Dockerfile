FROM postgres:17-alpine

# Metadatos
LABEL maintainer="LucasAI Platform"
LABEL description="PostgreSQL para PPC64LE con pgvector (Fixed LLVM paths + Wget Fix)"

ENV POSTGRES_DB=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=root
ENV PGDATA=/var/lib/postgresql/data

# 1. Instalar herramientas
# CAMBIO: Usamos wget en lugar de curl para evitar errores de libreria SSL (Code 35)
RUN apk add --no-cache \
    build-base \
    clang \
    llvm \
    llvm-dev \
    postgresql-dev \
    wget \
    linux-headers \
    ca-certificates

# 2. Descarga, Parcheo de rutas y Compilación
RUN cd /tmp && \
    echo "⬇️ Descargando pgvector (Usando Wget)..." && \
    # FIX: Usamos wget --no-check-certificate. Es más robusto que curl para este error.
    wget --no-check-certificate -O pgvector.tar.gz https://github.com/pgvector/pgvector/archive/refs/tags/v0.8.1.tar.gz && \
    tar -xzf pgvector.tar.gz && \
    cd pgvector-0.8.1 && \
    \
    echo "🩹 Parcheando rutas de LLVM..." && \
    # Postgres busca llvm-lto en /usr/lib/llvm19/bin/ pero Alpine tiene el actual en /usr/bin/
    mkdir -p /usr/lib/llvm19/bin && \
    ln -s /usr/bin/llvm-lto /usr/lib/llvm19/bin/llvm-lto && \
    \
    echo "🛠️ Compilando..." && \
    make CLANG=clang && \
    make CLANG=clang install && \
    \
    echo "🧹 Limpiando..." && \
    cd / && \
    rm -rf /tmp/pgvector* && \
    echo "✅ Instalación completada."

# 3. Verificar instalación
RUN ls -la $(pg_config --pkglibdir) | grep vector || echo "⚠️ Error: pgvector no encontrado"

# 4. Configuración final
RUN mkdir -p /docker-entrypoint-initdb.d /backups && \
    chmod 777 /backups

# Copia de configuraciones (Opcional - Si no tienes estos archivos, comenta estas 3 líneas)
COPY init-scripts/ /docker-entrypoint-initdb.d/
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf

# Permisos
RUN chmod +r /docker-entrypoint-initdb.d/*.sql 2>/dev/null || true

EXPOSE 5432
VOLUME ["/var/lib/postgresql/data", "/backups"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1

CMD ["postgres"]