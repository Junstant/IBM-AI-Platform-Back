# connection_manager.py
"""
Administrador de conexiones dinámicas para múltiples bases de datos y modelos LLM
"""

import psycopg2
import psycopg2.extras
from typing import Dict, List, Tuple, Any, Optional
from llama_interface import LlamaInterface
from database_analyzer import DatabaseAnalyzer
from config import get_model_config, get_available_models
from smart_config import get_db_connection_params

class ConnectionManager:
    """Administra conexiones dinámicas a múltiples BDs y modelos LLM"""
    
    def __init__(self):
        self.db_connections = {}  # Cache de conexiones a BD
        self.llm_interfaces = {}  # Cache de interfaces LLM
        self.db_analyzers = {}    # Cache de analizadores de BD
        self.schemas_cache = {}   # Cache de esquemas de BD
        self.discovered_databases = []  # Bases de datos descubiertas
    
    def discover_databases(self) -> List[str]:
        """Descubre todas las bases de datos disponibles en el servidor PostgreSQL."""
        try:
            import psycopg2
            db_params = get_db_connection_params("postgres")
            conn = psycopg2.connect(**db_params)
            cursor = conn.cursor()
            cursor.execute("""
                SELECT datname
                FROM pg_database
                WHERE datistemplate = false
                ORDER BY datname;
            """)
            databases = [row[0] for row in cursor.fetchall()]
            cursor.close()
            conn.close()
            return databases
        except Exception as e:
            print(f"Error descubriendo bases de datos: {e}")
            return []

    def get_available_databases(self) -> List[str]:
        """Devuelve las bases de datos descubiertas."""
        if not hasattr(self, 'discovered_databases'):
            self.discovered_databases = self.discover_databases()
        return self.discovered_databases
    
    def get_available_models(self) -> List[Dict[str, Any]]:
        """Obtiene lista de modelos LLM disponibles"""
        return get_available_models()
    
    def get_database_analyzer(self, database_id: str) -> DatabaseAnalyzer:
        """Obtiene o crea un analizador para una base de datos específica"""
        if database_id not in self.db_analyzers:
            db_params = get_db_connection_params(database_id)
            analyzer = DatabaseAnalyzer(
                dbname=db_params["dbname"],
                user=db_params["user"],
                password=db_params["password"],
                host=db_params["host"],
                port=db_params["port"]
            )
            
            # Conectar y verificar
            success, message = analyzer.connect()
            if not success:
                raise Exception(f"No se pudo conectar a la BD '{database_id}': {message}")
            
            # Analizar esquema
            analyzer.analyze_schema()
            self.db_analyzers[database_id] = analyzer
            
        return self.db_analyzers[database_id]
    
    def get_llm_interface(self, model_id: str) -> LlamaInterface:
        """Obtiene o crea una interfaz LLM para un modelo específico"""
        if model_id not in self.llm_interfaces:
            # Buscar en los modelos disponibles primero
            models = get_available_models()
            model_config = None
            
            for model in models:
                if model["id"] == model_id:
                    model_config = model
                    break
            
            if not model_config:
                raise Exception(f"Modelo '{model_id}' no encontrado")
                
            # Crear nueva interfaz LLM
            interface = LlamaInterface(
                host=model_config["host"],
                port=model_config["port"]
            )
            self.llm_interfaces[model_id] = interface
            
        return self.llm_interfaces[model_id]
    
    def get_database_schema(self, database_id: str) -> str:
        """Obtiene el esquema de una base de datos (con cache)"""
        if database_id not in self.schemas_cache:
            analyzer = self.get_database_analyzer(database_id)
            schema = analyzer.generate_schema_for_llm()
            self.schemas_cache[database_id] = schema
            
        return self.schemas_cache[database_id]
    
    def test_model_connection(self, model_id: str) -> Tuple[bool, str]:
        """Prueba la conexión a un modelo LLM"""
        try:
            interface = self.get_llm_interface(model_id)
            # Hacer una prueba simple
            response = interface.get_llama_response("Test")
            return True, "Conexión exitosa"
        except Exception as e:
            return False, f"Error de conexión: {str(e)}"
    
    def test_database_connection(self, database_id: str) -> Tuple[bool, str]:
        """Prueba la conexión a una base de datos"""
        try:
            analyzer = self.get_database_analyzer(database_id)
            if analyzer.check_connection_health():
                return True, "Conexión exitosa"
            else:
                return False, "Conexión no saludable"
        except Exception as e:
            return False, f"Error de conexión: {str(e)}"
    
    def close_all_connections(self):
        """Cierra todas las conexiones activas"""
        for analyzer in self.db_analyzers.values():
            try:
                analyzer.close()
            except:
                pass
        
        self.db_connections.clear()
        self.llm_interfaces.clear()
        self.db_analyzers.clear()
        self.schemas_cache.clear()

# Instancia global del administrador de conexiones
connection_manager = ConnectionManager()