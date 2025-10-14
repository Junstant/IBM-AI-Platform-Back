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

    def get_available_databases(self) -> List[Dict[str, Any]]:
        """Devuelve las bases de datos descubiertas en formato estructurado."""
        if not hasattr(self, 'discovered_databases') or not self.discovered_databases:
            print("DEBUG: Descubriendo bases de datos...")
            self.discovered_databases = self.discover_databases()
        
        print(f"DEBUG: Procesando {len(self.discovered_databases)} bases de datos descubiertas")
        print(f"DEBUG: Lista de bases de datos: {self.discovered_databases}")
        
        # Convertir lista de nombres a objetos estructurados
        databases = []
        for db_name in self.discovered_databases:
            try:
                print(f"DEBUG: Procesando base de datos: {db_name}")
                # Intentar obtener información adicional de la BD
                db_params = get_db_connection_params(db_name)
                print(f"DEBUG: Parámetros de conexión para {db_name}: {db_params}")
                
                conn = psycopg2.connect(**db_params)
                cursor = conn.cursor()
                
                # Obtener número de tablas
                cursor.execute("""
                    SELECT COUNT(*) 
                    FROM information_schema.tables 
                    WHERE table_schema = 'public'
                """)
                table_count = cursor.fetchone()[0]
                
                # Obtener tamaño aproximado de la BD
                cursor.execute("""
                    SELECT pg_size_pretty(pg_database_size(%s))
                """, (db_name,))
                size = cursor.fetchone()[0]
                
                cursor.close()
                conn.close()
                
                db_info = {
                    "id": db_name,
                    "name": db_name,
                    "size": size,
                    "tables": table_count,
                    "description": f"Base de datos PostgreSQL con {table_count} tablas"
                }
                
                print(f"DEBUG: Info obtenida para {db_name}: {db_info}")
                databases.append(db_info)
                
            except Exception as e:
                # Si hay error, agregar info básica
                print(f"WARNING: No se pudo obtener info completa de {db_name}: {e}")
                print(f"DEBUG: Error completo: {type(e).__name__}: {str(e)}")
                
                db_info = {
                    "id": db_name,
                    "name": db_name,
                    "size": "Desconocido",
                    "tables": "?",
                    "description": "Base de datos PostgreSQL"
                }
                databases.append(db_info)
        
        print(f"DEBUG: Total de bases de datos procesadas: {len(databases)}")
        return databases
    
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
    
    async def test_model_connection_async(self, model_id: str) -> Tuple[bool, str]:
        """Prueba la conexión a un modelo LLM de forma asíncrona"""
        try:
            interface = self.get_llm_interface(model_id)
            # Hacer una prueba simple
            response = await interface.get_llama_response_async("Test")
            return True, "Conexión exitosa"
        except Exception as e:
            return False, f"Error de conexión: {str(e)}"
    
    def test_model_connection(self, model_id: str) -> Tuple[bool, str]:
        """Prueba la conexión a un modelo LLM (wrapper síncrono TEMPORAL)"""
        # USAR UN ENFOQUE DIFERENTE PARA EVITAR asyncio.run()
        try:
            interface = self.get_llm_interface(model_id)
            # Solo verificar que se puede crear la interfaz
            return True, f"Interfaz creada para {interface.host}:{interface.port}"
        except Exception as e:
            return False, f"Error de configuración: {str(e)}"
    
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