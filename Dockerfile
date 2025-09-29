# Usa la imagen original como base
FROM quay.io/daniel_casali/llama.cpp-mma:v5

# Instala wget para poder descargar archivos
# (Usa apk porque la imagen base probablemente es Alpine Linux)
RUN apk add --no-cache wget

# Copia tu script de inicio dentro de la imagen
COPY entrypoint.sh /entrypoint.sh

# Dale permisos de ejecución al script
RUN chmod +x /entrypoint.sh

# Establece el script como el punto de entrada del contenedor
ENTRYPOINT ["/entrypoint.sh"]