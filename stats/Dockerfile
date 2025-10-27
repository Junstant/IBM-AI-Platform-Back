FROM python:3.11-slim

# Configurar directorio de trabajo
WORKDIR /app

# Variables de entorno
ENV PYTHONPATH=/app
ENV DOCKER_ENV=true
ENV PYTHONUNBUFFERED=1

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements y instalar dependencias Python
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código de la aplicación
COPY . .

# Crear usuario no-root
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8003/health || exit 1

# Exponer puerto
EXPOSE 8003

# Comando por defecto
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8003"]