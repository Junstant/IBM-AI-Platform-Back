FROM python:3.10-slim
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    gcc \
    libpq-dev \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements
COPY requirements.txt .

# Instalar dependencias Python desde repositorio IBM Power
RUN pip install --upgrade pip && \
    pip install --no-cache-dir \
    --extra-index-url https://repo.fury.io/mgiessing \
    --prefer-binary \
    -r requirements.txt

# Copiar código de la aplicación
COPY . .

# Crear directorio para documentos
RUN mkdir -p /app/documents

# Exponer puerto
EXPOSE 8004

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8004/health || exit 1

# Comando de ejecución
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8004"]
