#!/bin/sh

# Detiene el script si hay un error
set -e

# Verifica si el archivo del modelo NO existe
if [ ! -f "$MODEL_PATH" ]; then
  echo "Modelo no encontrado en $MODEL_PATH."
  echo "Descargando desde $MODEL_URL..."
  
  # Descarga el modelo usando wget y lo guarda en la ruta correcta
  wget -O "$MODEL_PATH" "$MODEL_URL"
  
  echo "Descarga completa."
else
  echo "Modelo encontrado en $MODEL_PATH. Omitiendo descarga."
fi

# Ejecuta el comando original que le pases desde docker-compose
# Esto iniciará el servidor de llama.cpp
echo "Iniciando el servidor..."
exec "$@"