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
# Nota: Solo compilar el .so (sin bitcode) - clang-19 no disponible en Alpine ppc64le
# Usar curl para descargar tarball (más confiable que git clone en redes restrictivas)
RUN cd /tmp && \
    curl -fsSL -o pgvector.tar.gz https://github.com/pgvector/pgvector/archive/refs/tags/v0.8.1.tar.gz && \
    tar -xzf pgvector.tar.gz && \
    cd pgvector-0.8.1 && \
    make OPTFLAGS="" vector.so && \
    cp vector.so $(pg_config --pkglibdir)/ && \
    cp sql/vector.sql $(pg_config --sharedir)/extension/vector--0.8.1.sql && \
    cp vector.control $(pg_config --sharedir)/extension/ && \
    cd / && \
    rm -rf /tmp/pgvector* && \
    echo "✅ pgvector v0.8.1 instalado (solo shared library, sin bitcode/JIT)"

# Verificar instalación de pgvector
RUN ls -la $(pg_config --pkglibdir) | grep vector || echo "⚠️ pgvector no encontrado en $(pg_config --pkglibdir)"

# Crear directorio para scripts de inicialización
RUN mkdir -p /docker-entrypoint-initdb.d

# Copiar scripts de inicialización
COPY init-scripts/ /docker-entrypoint-initdb.d/

# Asegurar permisos de ejecución y orden de ejecución
# PostgreSQL ejecuta scripts en orden alfabético
RUN chmod +r /docker-entrypoint-initdb.d/*.sql 2>/dev/null || true && \
    echo "✅ Scripts de inicialización configurados"

# Copiar configuración personalizada de PostgreSQL
COPY postgresql.conf /etc/postgresql/postgresql.conf
COPY pg_hba.conf /etc/postgresql/pg_hba.conf

# Crear directorio para backups
RUN mkdir -p /backups && chmod 755 /backups

# Exponer puerto estándar de PostgreSQL
EXPOSE 5432

# Punto de montaje para datos persistentes
VOLUME ["/var/lib/postgresql/data", "/backups"]

# Healthcheck personalizado
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U $POSTGRES_USER -d $POSTGRES_DB || exit 1

# Usar el entrypoint por defecto de PostgreSQL (no custom script)
# El entrypoint original de postgres:17-alpine maneja correctamente los permisos
CMD ["postgres"]