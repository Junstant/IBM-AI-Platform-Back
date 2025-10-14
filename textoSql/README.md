### **🤖 TextoSQL: Conversor de Lenguaje Natural a SQL**

TextoSQL es un microservicio inteligente que actúa como un **traductor avanzado entre el lenguaje humano y el lenguaje de bases de datos SQL**. Su propósito es permitir que los usuarios realicen consultas complejas a bases de datos simplemente haciendo preguntas en su idioma, eliminando la necesidad de escribir código SQL. Forma parte de la plataforma IBM AI Backend.

-----

### ✨ **Características Destacadas**

  * 🧠 **Inteligencia Multi-Modelo**: Soporta **6 modelos de lenguaje (LLM) diferentes** (incluyendo Mistral, Gemma y DeepSeek), permitiendo al usuario elegir el más adecuado para cada tarea, equilibrando velocidad y precisión.
  * 🗄️ **Conectividad Multi-Base de Datos**: Puede conectarse y operar con múltiples bases de datos **PostgreSQL** de forma simultánea, permitiendo consultas a diferentes fuentes de datos desde una única interfaz.
  * 🔧 **Configuración Automática**: El sistema es capaz de detectar si está corriendo en un **entorno Docker o de forma local**, ajustando automáticamente las configuraciones de red y conexión para funcionar sin intervención manual.
  * ⚡ **Flujo de Ejecución Completo**: Realiza todo el proceso: recibe una pregunta en lenguaje natural, la convierte a una consulta SQL, la ejecuta directamente en la base de datos y devuelve los resultados listos para usar.
  * 🌐 **API REST Completa**: Ofrece una API bien documentada, ideal para ser consumida por aplicaciones frontend (como las construidas con React) y para integrarse con otros microservicios.
  * 🐳 **Preparado para Contenedores (Docker Ready)**: Incluye un `Dockerfile` y la configuración necesaria para un despliegue rápido, aislado y consistente utilizando Docker.

-----

### 🚀 **Instalación y Puesta en Marcha**

#### **Opción 1: Usando Docker (Recomendado)**

Este método es el más sencillo y previene problemas de configuración entre entornos. Desde el directorio raíz del proyecto, ejecuta el siguiente comando:

```bash
docker-compose up textosql
```

Docker gestionará la construcción de la imagen, la instalación de dependencias y la comunicación en red con la base de datos y otros servicios.

#### **Opción 2: Instalación en Entorno Local**

1.  **Instalar Dependencias**: Abre una terminal en la carpeta `textoSql` y ejecuta:
    ```bash
    pip install -r requirements.txt
    ```
2.  **Configurar Variables de Entorno**: Es necesario crear un archivo `.env` en la raíz del proyecto para definir los datos de conexión a la base de datos, los puertos y los nombres de las bases de datos a utilizar.
    ```env
    # Ejemplo de configuración para entorno local
    DB_HOST=localhost
    DB_PORT=5432
    DB_USER=postgres
    DB_PASSWORD=root
    DB1_NAME=banco_global
    TEXTOSQL_PORT=8002
    ```
3.  **Ejecutar la Aplicación**:
    ```bash
    python app.py
    ```

Una vez iniciada, la API estará disponible en `http://localhost:8002`.

-----

### 📋 **Endpoints Principales de la API**

Puedes explorar y probar todos los endpoints de forma interactiva a través de la documentación de Swagger en `http://localhost:8002/docs`.

  * `GET /models`

      * **Función**: Devuelve una lista con los nombres y detalles de todos los modelos de lenguaje (LLM) disponibles.

  * `GET /databases`

      * **Función**: Devuelve una lista de todas las bases de datos a las que el servicio está conectado.

  * `POST /query_dynamic`

      * **Función**: Este es el endpoint principal. Recibe una pregunta, el ID del modelo a usar y el ID de la base de datos. Procesa la pregunta, genera el SQL, lo ejecuta y retorna el resultado.
      * **Ejemplo de Petición**:
        ```json
        {
          "database_id": "banco_global",
          "model_id": "gemma-4b",
          "question": "¿Cuántos clientes hay registrados?"
        }
        ```

  * `POST /execute_sql_dynamic`

      * **Función**: Permite ejecutar una consulta SQL que se envíe directamente en el cuerpo de la petición sobre una base de datos específica.
      * **Ejemplo de Petición**:
        ```json
        {
          "database_id": "bank_transactions",
          "sql_query": "SELECT COUNT(*) FROM transacciones WHERE es_fraude = 1"
        }
        ```

  * `GET /database/{database_id}/schema`

      * **Función**: Muestra la estructura (tablas, columnas, tipos de datos y relaciones) de la base de datos especificada. Es útil para entender el contexto que usa el LLM.