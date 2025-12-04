# Usa una imagen base de Python ligera
FROM python:3.10-slim
ENV DEBIAN_FRONTEND=noninteractive

# Establece el directorio de trabajo dentro del contenedor
WORKDIR /app

# Instalar curl para health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copia el archivo de requisitos
COPY ./fraude/requirements.txt .

# Instala las dependencias usando los repositorios de wheels para PPC64LE
RUN pip install --no-cache-dir \
    --extra-index-url https://repo.fury.io/mgiessing \
    --prefer-binary \
    -r requirements.txt

# Copia el resto de tus archivos de la aplicación
COPY ./fraude .

# Expón el puerto que usará tu API
EXPOSE 8000

# Comando para ejecutar la API con Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]