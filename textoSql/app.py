# main.py

import os
import textwrap
from datetime import datetime
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from fastapi.middleware.cors import CORSMiddleware

# --- Importa tus clases y utilidades ---
from database_analyzer import DatabaseAnalyzer
from llama_interface import LlamaInterface
from utils import extract_sql_from_response
from connection_manager import connection_manager
from config import get_available_models
from smart_config import get_db_connection_params, DB1_NAME

# Carga las variables de entorno
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=env_path)

# --- Modelos Pydantic ---
class QueryRequest(BaseModel):
    question: str = Field(..., min_length=3, description="La pregunta del usuario.")

class DynamicQueryRequest(BaseModel):
    database_id: str = Field(..., description="ID de la base de datos")
    model_id: str = Field(..., description="ID del modelo LLM")
    question: str = Field(..., min_length=3, description="La pregunta del usuario.")

class SQLExecuteRequest(BaseModel):
    sql_query: str = Field(..., description="Consulta SQL directa.")

class DynamicSQLExecuteRequest(BaseModel):
    database_id: str = Field(..., description="ID de la base de datos")
    sql_query: str = Field(..., description="Consulta SQL directa.")

class QueryResponse(BaseModel):
    question: str
    sql_query: str
    results: List[Dict[str, Any]]
    explanation: Optional[str] = None
    error: Optional[str] = None
    database_used: Optional[str] = None
    model_used: Optional[str] = None

# --- Generador SQL Maestro (Optimizado para Mistral 7B) ---

class SQLGenerator:
    """Encapsula la lógica de 'Golden Prompt' para generación SQL de alta precisión."""
    def __init__(self, llm_interface: LlamaInterface, db_schema: str):
        self.llm_interface = llm_interface
        self.db_schema = db_schema

    def _build_system_prompt(self, schema: str, custom_examples: str = "") -> str:
        current_date = datetime.now().strftime("%Y-%m-%d")
        
        # Prompt diseñado para Mistral 7B: Estructura clara, reglas negativas y CoT implícito.
        return textwrap.dedent(f"""
        ### ROLE
        You are a Senior PostgreSQL Architect. Your goal is to generate precise, read-only SQL queries.

        ### DATABASE SCHEMA
        Only use the tables and columns defined below:
        {schema}

        ### CONTEXT
        - Today's Date: {current_date}
        - Dialect: PostgreSQL

        ### CRITICAL RULES (MANDATORY)
        1. **Output Format**: Return ONLY the raw SQL code inside ```sql``` blocks. No explanations.
        2. **Safety**: NEVER generate INSERT, UPDATE, DELETE, or DROP operations.
        3. **Text Search**: Always use `ILIKE '%term%'` for text matching (case-insensitive).
        4. **Joins**: Use explicit JOINs based on foreign keys defined in the schema.
        5. **Ambiguity**: Use table aliases (e.g., `t.column`) to avoid ambiguous column errors.
        6. **Limits**: Add `LIMIT 50` if the query implies a list, unless a specific number is requested.

        {custom_examples}

        ### THINKING PROCESS
        Before answering, think: Which tables do I need? How do I join them? Do I need to group?
        Then, write the SQL.
        """)

    async def generate_sql_async(self, question: str) -> str:
        # Prompt construcción
        system_prompt = self._build_system_prompt(self.db_schema)
        full_prompt = f"{system_prompt}\n\n### USER QUESTION\n{question}\n\n### SQL QUERY\n```sql"
        
        # Llamada al LLM
        response = await self.llm_interface.get_llama_response_async(full_prompt)
        
        # Extracción y Validación
        sql_query = extract_sql_from_response(response)
        if not sql_query:
            # Fallback: Intentar limpiar la respuesta si Mistral fue verborrágico fuera de los backticks
            sql_query = response.replace("```sql", "").replace("```", "").strip()
            if not sql_query.upper().startswith("SELECT"):
                 raise ValueError("El LLM no generó una consulta SELECT válida.")

        self._validate_security(sql_query)
        return sql_query

    @staticmethod
    def _validate_security(sql_query: str):
        dangerous_keywords = ['INSERT', 'UPDATE', 'DELETE', 'DROP', 'TRUNCATE', 'ALTER', 'CREATE', 'GRANT', 'REVOKE']
        sql_upper = sql_query.upper()
        for keyword in dangerous_keywords:
            # Verificación simple de palabra completa para evitar falsos positivos dentro de strings
            if f" {keyword} " in f" {sql_upper} " or sql_upper.startswith(keyword):
                raise ValueError(f"Security Alert: Operación prohibida '{keyword}' detectada.")

# --- Aplicación FastAPI ---

app = FastAPI(
    title="🤖 API de Consulta a Base de Datos con IA (Master Edition)",
    description="API optimizada para Text-to-SQL con arquitectura cognitiva para Mistral 7B.",
    version="2.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Middleware de Stats
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

# --- Ciclo de Vida ---

@app.on_event("startup")
async def startup_event():
    # Inicialización estándar para la BD por defecto
    db_params = get_db_connection_params(DB1_NAME)
    db_analyzer = DatabaseAnalyzer(**db_params)
    
    if db_analyzer.connect()[0]:
        db_analyzer.analyze_schema()
        # Inicializar el generador por defecto en el estado
        # Nota: Asumimos que LlamaInterface se inicializa en otro lugar o aquí si es necesario
        # app.state.sql_generator = SQLGenerator(llama_interface_default, db_analyzer.schema_info)
        app.state.db_analyzer = db_analyzer
        print("✅ Sistema central iniciado correctamente.")
    else:
        print("⚠️ Advertencia: No se pudo conectar a la BD principal al inicio.")

@app.on_event("shutdown")
def shutdown_event():
    if hasattr(app.state, 'db_analyzer'):
        app.state.db_analyzer.close()
    connection_manager.close_all_connections()
    print("👋 Sistema apagado.")

# --- Endpoints ---

@app.get("/health", tags=["✅ Estado"])
async def health_check():
    if not hasattr(app.state, 'db_analyzer') or not app.state.db_analyzer.check_connection_health():
        raise HTTPException(status_code=503, detail="Database connection unhealthy")
    return {"status": "ok", "system": "operational"}

@app.get("/databases", tags=["📚 Recursos"])
async def get_databases():
    dbs = connection_manager.get_available_databases()
    return {"databases": dbs, "total_count": len(dbs)}

@app.get("/models", tags=["📚 Recursos"])
async def get_models():
    models = connection_manager.get_available_models()
    return {"models": models, "total_count": len(models)}

@app.get("/schema/{database_id}", tags=["📚 Recursos"])
async def get_schema_for_database(database_id: str):
    try:
        # Aseguramos que el schema esté actualizado
        schema = connection_manager.get_database_schema(database_id)
        return {"database_id": database_id, "schema": schema}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

# --- Endpoints Principales de Consulta ---

@app.post("/query/ask", response_model=QueryResponse, tags=["💬 Consultas"])
async def ask_question(request: QueryRequest):
    # Endpoint Legacy wrapper
    return await process_query_logic(
        question=request.question,
        db_analyzer=app.state.db_analyzer,
        # Asumiendo que existe un LLM default en app.state o config
        llm_interface=app.state.sql_generator.llm_interface 
    )

@app.post("/query/ask-dynamic", response_model=QueryResponse, tags=["💬 Consultas Dinámicas"])
async def ask_question_dynamic(request: DynamicQueryRequest):
    """
    Motor de decisión dinámica optimizado.
    Selecciona contexto y estrategia según la base de datos solicitada.
    """
    try:
        # 1. Recuperación de recursos
        db_analyzer = connection_manager.get_database_analyzer(request.database_id)
        llm_interface = connection_manager.get_llm_interface(request.model_id)
        db_schema = connection_manager.get_database_schema(request.database_id)

        # 2. Inyección de conocimiento específico (Few-Shot avanzado)
        custom_examples = ""
        if request.database_id == "ferreteria_weitzler":
            custom_examples = textwrap.dedent("""
            ### REFERENCE EXAMPLES (Use similar logic)
            
            User: "¿Productos con stock bajo?"
            SQL:
            ```sql
            SELECT p.nombre, p.stock_actual, p.stock_minimo 
            FROM productos p 
            WHERE p.stock_actual < p.stock_minimo 
            ORDER BY p.stock_actual ASC LIMIT 50;
            ```
            
            User: "¿Ventas totales de Makita?"
            SQL:
            ```sql
            SELECT SUM(v.total) as total_ventas
            FROM ventas v
            JOIN productos p ON v.producto_id = p.id
            JOIN marcas m ON p.marca_id = m.id
            WHERE m.nombre ILIKE '%Makita%';
            ```
            """)

        # 3. Construcción del Generador al vuelo
        generator = SQLGenerator(llm_interface, db_schema)
        
        # 4. Generación y Validación del Prompt
        # Usamos un método privado manual para inyectar los ejemplos específicos
        system_prompt = generator._build_system_prompt(db_schema, custom_examples)
        full_prompt = f"{system_prompt}\n\n### USER QUESTION\n{request.question}\n\n### SQL QUERY\n```sql"
        
        # 5. Ejecución LLM
        response = await llm_interface.get_llama_response_async(full_prompt)
        sql_query = extract_sql_from_response(response)
        
        if not sql_query: 
             # Fallback simple para cuando el modelo olvida los backticks
             if "SELECT" in response:
                 sql_query = response[response.find("SELECT"):]
             else:
                 raise ValueError("No SQL found in response")

        generator._validate_security(sql_query)

        # 6. Ejecución SQL
        results, _ = db_analyzer.execute_query(sql_query)

        # 7. Explicación (Opcional: se puede hacer asíncrona para velocidad)
        explanation = await llm_interface.explain_results_async(request.question, sql_query, results)

        return QueryResponse(
            question=request.question,
            sql_query=sql_query,
            results=results,
            explanation=explanation,
            database_used=request.database_id,
            model_used=request.model_id
        )

    except Exception as e:
        # Manejo de errores robusto
        return QueryResponse(
            question=request.question,
            sql_query="",
            results=[],
            explanation=f"Error en el procesamiento cognitivo: {str(e)}",
            error=str(e),
            database_used=request.database_id,
            model_used=request.model_id
        )

# --- Endpoints de Ejecución Directa ---

@app.post("/query/execute", tags=["💬 Consultas"])
async def execute_raw_sql(request: SQLExecuteRequest):
    try:
        results, columns = app.state.db_analyzer.execute_query(request.sql_query)
        return {"sql_query": request.sql_query, "columns": columns, "results": results}
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/query/execute-dynamic", tags=["💬 Consultas Dinámicas"])
async def execute_raw_sql_dynamic(request: DynamicSQLExecuteRequest):
    try:
        db_analyzer = connection_manager.get_database_analyzer(request.database_id)
        results, columns = db_analyzer.execute_query(request.sql_query)
        return {
            "database_id": request.database_id,
            "sql_query": request.sql_query, 
            "columns": columns, 
            "results": results
        }
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.post("/test-connections", tags=["✅ Diagnóstico"])
async def test_connections(database_id: str, model_id: str):
    db_success, db_msg = connection_manager.test_database_connection(database_id)
    model_success, model_msg = connection_manager.test_model_connection(model_id)
    
    return {
        "database": {"id": database_id, "success": db_success, "message": db_msg},
        "model": {"id": model_id, "success": model_success, "message": model_msg},
        "overall_success": db_success and model_success
    }