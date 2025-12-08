# TextoSQL API

Conversor de lenguaje natural a SQL con múltiples modelos LLM.

## Características

- 6 modelos LLM: Gemma (2B, 4B), Mistral 7B, DeepSeek 8B, Arctic text 2sql 7b
- Soporte multi-base de datos PostgreSQL
- Análisis semántico de consultas
- Ejecución automática de SQL generado

## Endpoints

**Puerto**: `http://localhost:8000/docs`

- `POST /query` - Convertir lenguaje natural a SQL y ejecutar
- `GET /databases` - Listar bases de datos disponibles
- `GET /models` - Listar modelos LLM disponibles

## Uso

```bash
# Ejemplo de consulta
curl -X POST http://localhost:8000/query \
  -H "Content-Type: application/json" \
  -d '{"question": "¿Cuántos clientes tenemos?", "database": "banco_global", "model": "gemma-4b"}'
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