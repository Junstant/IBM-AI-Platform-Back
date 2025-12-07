# main.py

import os
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

# --- Importa tus clases y utilidades ---
from database_analyzer import DatabaseAnalyzer
from llama_interface import LlamaInterface
from utils import extract_sql_from_response
from connection_manager import connection_manager
from config import get_available_models
from smart_config import get_db_connection_params, DB1_NAME

# Carga las variables de entorno del archivo .env desde el directorio padre
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=env_path)

# --- Modelos Pydantic para la validación de datos ---
# Definen la estructura esperada de las solicitudes (requests) y respuestas (responses)

class QueryRequest(BaseModel):
    """Modelo para una pregunta en lenguaje natural."""
    question: str = Field(..., min_length=3, description="La pregunta del usuario en lenguaje natural.")

class DynamicQueryRequest(BaseModel):
    """Modelo para consulta con selección de BD y modelo."""
    database_id: str = Field(..., description="ID de la base de datos a consultar")
    model_id: str = Field(..., description="ID del modelo LLM a usar")
    question: str = Field(..., min_length=3, description="La pregunta del usuario en lenguaje natural.")

class SQLExecuteRequest(BaseModel):
    """Modelo para ejecutar una consulta SQL directamente."""
    sql_query: str = Field(..., description="La consulta SQL a ejecutar.")

class DynamicSQLExecuteRequest(BaseModel):
    """Modelo para ejecutar SQL con selección de BD."""
    database_id: str = Field(..., description="ID de la base de datos a consultar")
    sql_query: str = Field(..., description="La consulta SQL a ejecutar.")

class QueryResponse(BaseModel):
    """Modelo para la respuesta completa de una consulta."""
    question: str
    sql_query: str
    results: List[Dict[str, Any]]
    explanation: Optional[str] = None
    error: Optional[str] = None
    database_used: Optional[str] = None
    model_used: Optional[str] = None

# --- Clase de ayuda para la generación de SQL ---

class SQLGenerator:
    """Encapsula la lógica para generar SQL a partir de lenguaje natural."""
    def __init__(self, llm_interface: LlamaInterface, db_schema: str):
        self.llm_interface = llm_interface
        self.db_schema = db_schema

    async def generate_sql_async(self, question: str) -> str:
        """Crea el prompt, inyecta fecha actual y contexto, llama al LLM."""
        import textwrap
        from datetime import datetime
        
        # Inyectar fecha actual para resolver "este mes", "ayer", "último año", etc.
        current_date = datetime.now().strftime("%Y-%m-%d")
        
        prompt = textwrap.dedent(f"""
        Eres un experto en PostgreSQL. Genera consultas SQL de solo lectura.
        
        Fecha actual: {current_date}
        
        Esquema:
        {self.db_schema}
        
        Reglas:
        1. Solo SELECT (no INSERT/UPDATE/DELETE/DROP)
        2. Para texto usa ILIKE '%valor%' (no =)
        3. Stock crítico: stock_actual < stock_minimo
        4. Añade LIMIT 50 por defecto
        5. ❌ NUNCA uses solo COUNT(*) cuando pregunten "¿Cuántos X?" - lista los detalles completos
        6. Para TOP N o favoritos usa subqueries con ORDER BY COUNT(*) DESC
        7. Lee el esquema: SOLO usa tablas/columnas que existen
        
        Ejemplos:
        
        P: "¿Cuántos productos de Makita tenemos?"
        SELECT p.codigo_sku, p.nombre, p.stock_actual, p.precio_venta, m.nombre AS marca
        FROM productos p JOIN marcas m ON p.id_marca = m.id_marca
        WHERE m.nombre ILIKE '%Makita%' ORDER BY p.stock_actual DESC LIMIT 50;
        
        P: "¿Top 3 clientes y su método de pago favorito?"
        SELECT c.nombre, SUM(v.total) AS total,
               (SELECT metodo_pago FROM ventas v2 WHERE v2.id_cliente = c.id_cliente 
                GROUP BY metodo_pago ORDER BY COUNT(*) DESC LIMIT 1) AS favorito
        FROM clientes c JOIN ventas v ON c.id_cliente = v.id_cliente
        GROUP BY c.id_cliente, c.nombre ORDER BY total DESC LIMIT 3;
        
        Pregunta: {question}
        
        SQL:
        ```sql
        """)
        
        # Llamar al LLM con el prompt mejorado
        response = await self.llm_interface.get_llama_response_async(prompt)
        
        # Extraer SQL de la respuesta del LLM
        sql_query = extract_sql_from_response(response)
        if not sql_query:
            raise ValueError("El LLM no pudo generar una consulta SQL válida.")
        
        # Validación de seguridad: rechazar operaciones de escritura
        dangerous_keywords = ['INSERT', 'UPDATE', 'DELETE', 'DROP', 'TRUNCATE', 'ALTER', 'CREATE']
        sql_upper = sql_query.upper()
        for keyword in dangerous_keywords:
            if keyword in sql_upper:
                raise ValueError(f"Operación no permitida: {keyword}. Solo se aceptan consultas de lectura (SELECT).")
        
        return sql_query

# --- Aplicación FastAPI ---

app = FastAPI(
    title="🤖 API de Consulta a Base de Datos con IA",
    description="Una API para interactuar con una base de datos PostgreSQL usando lenguaje natural.",
    version="1.0.0",
)

# ✅ Configurar CORS
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Agregar middleware de reporte de métricas a Stats API
import os
from stats_reporter import StatsReporterMiddleware

STATS_API_URL = os.getenv("STATS_API_URL", "http://stats-api:8003")
app.add_middleware(
    StatsReporterMiddleware,
    service_name="textosql",
    stats_api_url=STATS_API_URL,
    timeout=2.0,
    excluded_paths={'/health', '/docs', '/redoc', '/openapi.json', '/databases', '/models', '/schema'}
)
print(f"✅ Stats reporter middleware configurado: textosql → {STATS_API_URL}")

# --- Gestión del Ciclo de Vida de la Aplicación ---

@app.on_event("startup")
async def startup_event():
    """
    Se ejecuta cuando la aplicación se inicia.
    Inicializa los objetos principales y los almacena en el estado de la app.
    """
    # 1. Inicializar el analizador de la base de datos usando configuración inteligente
    db_params = get_db_connection_params(DB1_NAME)
    db_analyzer = DatabaseAnalyzer(
        dbname=db_params["dbname"],
        user=db_params["user"],
        password=db_params["password"],
        host=db_params["host"],
        port=db_params["port"],
    )
    
    # 2. Conectar a la BD y analizar el esquema
    success, message = db_analyzer.connect()
    if not success:
        raise RuntimeError(f"No se pudo conectar a la base de datos al iniciar: {message}")
    print(message)
    print("Analizando el esquema de la base de datos...")
    db_analyzer.analyze_schema()
    print("Análisis del esquema completado.")
    
    print(f"--- ESQUEMA GENERADO PARA EL LLM ---\n{db_analyzer.generate_schema_for_llm()}\n--- FIN DEL ESQUEMA ---")

    # Solo guardar el analizador de BD por compatibilidad con endpoints legacy
    app.state.db_analyzer = db_analyzer
    print("🚀 Aplicación iniciada y lista para recibir peticiones.")

@app.on_event("shutdown")
def shutdown_event():
    """Se ejecuta cuando la aplicación se apaga."""
    if hasattr(app.state, 'db_analyzer') and app.state.db_analyzer:
        message = app.state.db_analyzer.close()
        print(message)
    
    # Cerrar todas las conexiones del administrador
    connection_manager.close_all_connections()
    print("👋 Aplicación apagada.")

# --- Endpoints de la API ---

@app.get("/health", summary="Verifica el estado de la API", tags=["✅ Estado"])
async def health_check():
    """
    Endpoint de salud para verificar si la API está funcionando y conectada a la BD.
    """
    if not app.state.db_analyzer or not app.state.db_analyzer.check_connection_health():
        raise HTTPException(status_code=503, detail="La conexión a la base de datos no está saludable.")
    return {"status": "ok", "database_connection": "healthy"}

@app.get("/databases", summary="Lista las bases de datos disponibles", tags=["📚 Recursos"])
async def get_databases():
    """
    Devuelve una lista de todas las bases de datos disponibles en el servidor PostgreSQL.
    """
    try:
        print("🔍 Iniciando get_databases...")
        databases = connection_manager.get_available_databases()
        print(f"📊 Bases de datos encontradas: {len(databases)}")
        print(f"📊 Datos: {databases}")
        result = {
            "databases": databases,
            "total_count": len(databases)
        }
        print(f"📊 Resultado final: {result}")
        return result
    except Exception as e:
        print(f"❌ Error en get_databases: {e}")
        raise HTTPException(status_code=500, detail=f"Error al obtener las bases de datos: {e}")

@app.get("/models", summary="Lista los modelos LLM disponibles", tags=["📚 Recursos"])
async def get_models():
    """
    Devuelve una lista de todos los modelos LLM disponibles.
    """
    try:
        models = connection_manager.get_available_models()
        return {
            "models": models,
            "total_count": len(models)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al obtener los modelos: {e}")

@app.get("/schema", summary="Obtiene el esquema de la base de datos", tags=["📚 Esquema"])
async def get_schema():
    """
    Devuelve la estructura completa del esquema de la base de datos en formato JSON.
    """
    if not app.state.db_analyzer.schema_info:
        raise HTTPException(status_code=404, detail="El esquema no ha sido analizado o no está disponible.")
    return app.state.db_analyzer.schema_info

@app.post("/query/ask", response_model=QueryResponse, summary="Pregunta en lenguaje natural", tags=["💬 Consultas"])
async def ask_question(request: QueryRequest):
    """
    Procesa una pregunta, genera y ejecuta una consulta SQL, y devuelve los resultados con una explicación.
    """
    question = request.question
    sql_query = ""
    try:
        # 1. Generar la consulta SQL
        sql_query = await app.state.sql_generator.generate_sql_async(question)

        # 2. Ejecutar la consulta
        results, _ = app.state.db_analyzer.execute_query(sql_query)
        
        # 3. Explicar los resultados
        explanation = await app.state.llama_interface.explain_results_async(question, sql_query, results)

        return QueryResponse(
            question=question,
            sql_query=sql_query,
            results=results,
            explanation=explanation,
        )
    except Exception as e:
        # Si algo sale mal, intenta que el LLM explique el error
        error_message = str(e)
        explanation = "Error interno del servidor."
        
        try:
            # Intentar obtener explicación del LLM si está disponible
            explanation = await app.state.llama_interface.explain_results_async(
                question=question, sql_query=sql_query, results=[], error=error_message
            )
        except:
            # Si el LLM también falla, usar explicación por defecto
            explanation = f"Error procesando la consulta: {error_message}"
        
        # Devolver JSON válido en lugar de HTTPException
        return QueryResponse(
            question=question,
            sql_query=sql_query,
            results=[],
            explanation=explanation,
            error=error_message
        )

@app.post("/query/ask-dynamic", response_model=QueryResponse, summary="Consulta con BD y modelo seleccionables", tags=["💬 Consultas Dinámicas"])
async def ask_question_dynamic(request: DynamicQueryRequest):
    """
    Procesa una pregunta con selección dinámica de base de datos y modelo LLM.
    Permite al usuario elegir qué BD consultar y qué modelo usar para generar el SQL.
    """
    try:
        # 1. Obtener el analizador de BD específico
        db_analyzer = connection_manager.get_database_analyzer(request.database_id)
        
        # 2. Obtener la interfaz LLM específica
        llm_interface = connection_manager.get_llm_interface(request.model_id)
        
        # 3. Obtener el esquema de la BD
        db_schema = connection_manager.get_database_schema(request.database_id)
        
        # 4. Preparar contexto temporal y ejemplos específicos
        import textwrap
        from datetime import datetime
        
        current_date = datetime.now().strftime("%Y-%m-%d")
        
        ejemplos_especificos = ""
        if request.database_id == "ferreteria_weitzler":
            ejemplos_especificos = textwrap.dedent("""

            ### EJEMPLOS ESPECÍFICOS PARA ESTA BASE DE DATOS:

            **Stock bajo:**
            Pregunta: "¿Productos con stock bajo?"
            ```sql
            SELECT p.nombre, p.stock_actual, p.stock_minimo
            FROM productos p
            WHERE p.stock_actual < p.stock_minimo
            LIMIT 50;
            ```

            **Productos de una marca (usa ILIKE):**
            Pregunta: "¿Productos de Makita?"
            ```sql
            SELECT p.codigo_sku, p.nombre, p.stock_actual, m.nombre AS marca
            FROM productos p 
            JOIN marcas m ON p.id_marca = m.id_marca
            WHERE m.nombre ILIKE '%Makita%'
            LIMIT 50;
            ```
            ❌ NO uses "nombre_marca" - la columna correcta es `marcas.nombre`

            **Ventas recientes (usa fecha actual):**
            Pregunta: "¿Ventas de los últimos 30 días?"
            ```sql
            SELECT c.nombre, SUM(v.total) AS total_gastado
            FROM clientes c 
            JOIN ventas v ON c.id_cliente = v.id_cliente
            WHERE v.fecha >= CURRENT_DATE - INTERVAL '30 days'
            GROUP BY c.id_cliente, c.nombre
            ORDER BY total_gastado DESC;
            ```
            ❌ NO uses "total_ventas" - la columna correcta es `ventas.total`
            """)
        
        # 5. Crear prompt compacto
        prompt = textwrap.dedent(f"""
        Eres experto en PostgreSQL. Genera SQL de solo lectura.
        
        BD: {request.database_id}
        Fecha: {current_date}
        
        Esquema:
        {db_schema}
        {ejemplos_especificos}
        
        Reglas:
        1. Solo SELECT (no INSERT/UPDATE/DELETE/DROP)
        2. Texto: usa ILIKE '%valor%'
        3. Stock crítico: stock_actual < stock_minimo
        4. LIMIT 50 por defecto
        5. ❌ NUNCA COUNT(*) solo - lista detalles completos
        6. Lee esquema: SOLO tablas/columnas existentes
        
        Pregunta: {request.question}
        
        SQL:
        ```sql
        """)
        
        # 6. Generar SQL usando el modelo seleccionado
        response = await llm_interface.get_llama_response_async(prompt)
        sql_query = extract_sql_from_response(response)
        
        if not sql_query:
            raise ValueError("El LLM no pudo generar una consulta SQL válida.")
        
        # Validación de seguridad: rechazar operaciones de escritura
        dangerous_keywords = ['INSERT', 'UPDATE', 'DELETE', 'DROP', 'TRUNCATE', 'ALTER', 'CREATE']
        sql_upper = sql_query.upper()
        for keyword in dangerous_keywords:
            if keyword in sql_upper:
                raise ValueError(f"Operación no permitida: {keyword}. Solo se aceptan consultas de lectura (SELECT).")
        
        # 7. Ejecutar la consulta en la BD seleccionada
        results, _ = db_analyzer.execute_query(sql_query)
        
        # 8. Generar explicación usando el mismo modelo
        explanation = await llm_interface.explain_results_async(
            request.question, sql_query, results
        )
        
        return QueryResponse(
            question=request.question,
            sql_query=sql_query,
            results=results,
            explanation=explanation,
            database_used=request.database_id,
            model_used=request.model_id
        )
        
    except Exception as e:
        # Manejo de errores
        error_message = str(e)
        explanation = f"Error procesando la consulta en BD '{request.database_id}' con modelo '{request.model_id}': {error_message}"
        
        try:
            # Intentar obtener explicación del LLM si está disponible
            llm_interface = connection_manager.get_llm_interface(request.model_id)
            explanation = await llm_interface.explain_results_async(
                request.question, "", [], error=error_message
            )
        except:
            pass
        
        return QueryResponse(
            question=request.question,
            sql_query="",
            results=[],
            explanation=explanation,
            error=error_message,
            database_used=request.database_id,
            model_used=request.model_id
        )

@app.post("/query/execute", summary="Ejecuta una consulta SQL directamente", tags=["💬 Consultas"])
async def execute_raw_sql(request: SQLExecuteRequest):
    """
    Permite a un usuario avanzado ejecutar una consulta SQL directamente.
    """
    try:
        results, columns = app.state.db_analyzer.execute_query(request.sql_query)
        return {"sql_query": request.sql_query, "columns": columns, "results": results}
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error al ejecutar la consulta: {e}")

@app.post("/query/execute-dynamic", summary="Ejecuta SQL en BD seleccionable", tags=["💬 Consultas Dinámicas"])
async def execute_raw_sql_dynamic(request: DynamicSQLExecuteRequest):
    """
    Permite ejecutar una consulta SQL directamente en una base de datos específica.
    """
    try:
        # Obtener analizador de la BD específica
        db_analyzer = connection_manager.get_database_analyzer(request.database_id)
        
        # Ejecutar consulta
        results, columns = db_analyzer.execute_query(request.sql_query)
        
        return {
            "database_id": request.database_id,
            "sql_query": request.sql_query, 
            "columns": columns, 
            "results": results
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error al ejecutar la consulta en BD '{request.database_id}': {e}")

@app.get("/schema/{database_id}", summary="Obtiene esquema de BD específica", tags=["📚 Recursos"])
async def get_schema_for_database(database_id: str):
    """
    Devuelve la estructura del esquema de una base de datos específica.
    """
    try:
        db_analyzer = connection_manager.get_database_analyzer(database_id)
        return {
            "database_id": database_id,
            "schema": db_analyzer.schema_info
        }
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Error al obtener esquema de BD '{database_id}': {e}")

@app.post("/test-connections", summary="Prueba conexiones a BD y modelo", tags=["✅ Diagnóstico"])
async def test_connections(database_id: str, model_id: str):
    """
    Prueba las conexiones a una base de datos y modelo específicos.
    """
    results = {}
    
    # Probar BD
    db_success, db_message = connection_manager.test_database_connection(database_id)
    results["database"] = {
        "id": database_id,
        "success": db_success,
        "message": db_message
    }
    
    # Probar modelo
    model_success, model_message = connection_manager.test_model_connection(model_id)
    results["model"] = {
        "id": model_id,
        "success": model_success,
        "message": model_message
    }
    
    results["overall_success"] = db_success and model_success
    
    return results