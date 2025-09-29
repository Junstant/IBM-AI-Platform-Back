# Dockerfile

# 1. Imagen Base
FROM python:3.10-slim

# 2. Directorio de Trabajo
WORKDIR /textoSql

# 3. Instalar Dependencias
COPY requirements.txt .

RUN pip install --no-cache-dir \
    --extra-index-url https://repo.fury.io/mgiessing \
    --prefer-binary \
    -r requirements.txt

# 4. Copiar el Código de la Aplicación
COPY . .

# 5. Exponer el Puerto
EXPOSE 8000

# 6. Comando de Ejecución
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]