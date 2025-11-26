# Dockerfile para PostgreSQL con configuración personalizada
FROM postgres:17-alpine

# Metadatos
LABEL maintainer="LucasAI Platform"
LABEL description="PostgreSQL personalizado para plataforma AI con esquemas preconfigurados"

# Variables de entorno que serán sobrescritas por docker-compose
ENV POSTGRES_DB=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=root
ENV PGDATA=/var/lib/postgresql/data

# Instalar herramientas adicionales y pgvector
RUN apk add --no-cache \
    curl \
    bash \
    postgresql-contrib \
    git \
    make \
    gcc \
    g++ \
    musl-dev \
    postgresql-dev

# Compilar e instalar pgvector (v0.8.1 con soporte ppc64le)
# Nota: NO_JIT=1 desactiva la compilación JIT que requiere clang-19 (no disponible en ppc64le)
RUN cd /tmp && \
    git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make NO_JIT=1 && \
    make NO_JIT=1 install && \
    cd / && \
    rm -rf /tmp/pgvector && \
    echo "✅ pgvector v0.8.1 compilado exitosamente (sin JIT)"

# Verificar instalación de pgvector
RUN ls -la $(pg_config --pkglibdir) | grep vector || echo "⚠️ pgvector no encontrado en $(pg_config --pkglibdir)"

# Crear directorio para scripts de inicialización
RUN mkdir -p /docker-entrypoint-initdb.d

# Copiar scripts de inicialización
COPY init-scripts/ /docker-entrypoint-initdb.d/

# Copiar configuración personalizada de PostgreSQL
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf

# Crear directorio para backups
RUN mkdir -p /backups && chmod 755 /backups

# Script personalizado de entrada
COPY docker-entrypoint-custom.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

# Exponer puerto estándar de PostgreSQL
EXPOSE 5432

# Punto de montaje para datos persistentes
VOLUME ["/var/lib/postgresql/data", "/backups"]

# Healthcheck personalizado
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1

# Usar el script personalizado como punto de entrada
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-custom.sh"]
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]