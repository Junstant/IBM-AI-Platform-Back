FROM python:3.10-slim
ENV DEBIAN_FRONTEND=noninteractive

# Directorio de trabajo
WORKDIR /app

# Instalar curl para health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Instalar dependencias
COPY ./textoSql/requirements.txt .

RUN pip install --no-cache-dir \
    --extra-index-url https://repo.fury.io/mgiessing \
    --prefer-binary \
    -r requirements.txt

# Copiar código de la aplicación
COPY ./textoSql .

# Copiar carpeta shared DESPUÉS para evitar que se sobrescriba
COPY ./shared /app/shared

# Exponer puerto
EXPOSE 8000

# Comando de ejecución
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]