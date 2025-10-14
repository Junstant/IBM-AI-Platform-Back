"""
Configuración inteligente para detectar si estamos en Docker o local
"""
import os
from dotenv import load_dotenv

# Cargar .env desde el directorio padre del proyecto
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=env_path)

def get_database_config():
    """
    Detecta automáticamente si estamos en Docker o ejecutando localmente
    y devuelve la configuración apropiada de base de datos
    """
    
    # Detectar si estamos en Docker
    is_docker = (
        os.path.exists('/.dockerenv') or  # Archivo que existe en contenedores
        os.getenv('RUNNING_IN_DOCKER', '').lower() == 'true' or
        os.getenv('DOCKER_CONTAINER', '').lower() == 'true' or
        os.path.exists('/proc/self/cgroup') and 'docker' in open('/proc/self/cgroup').read()
    )
    
    # También verificar si DB_HOST está configurado como 'postgres' (indicador de Docker)
    db_host_env = os.getenv("DB_HOST", "localhost")
    if db_host_env == "postgres":
        is_docker = True
    
    if is_docker:
        # Configuración para Docker (usar nombres de contenedores)
        config = {
            "host": os.getenv("DB_HOST", "postgres"),  # Nombre del contenedor
            "port": os.getenv("DB_INTERNAL_PORT", "5432"),  # Puerto interno
            "user": os.getenv("DB_USER", "postgres"),
            "password": os.getenv("DB_PASSWORD", "root"),
        }
        print("🐳 Detectado entorno Docker - usando configuración interna")
    else:
        # Configuración para ejecución local/servidor
        config = {
            "host": "localhost",  # Siempre localhost para ejecución local
            "port": os.getenv("DB_PORT", "8070"),  # Puerto expuesto
            "user": os.getenv("DB_USER", "postgres"),
            "password": os.getenv("DB_PASSWORD", "root"),
        }
        print("💻 Detectado entorno local/servidor - usando localhost")
    
    print(f"📊 Configuración DB: {config['host']}:{config['port']}")
    return config

# Configuración global
DATABASE_CONFIG = get_database_config()

# Nombres de las bases de datos
DB1_NAME = os.getenv("DB1_NAME", "banco_global")
DB2_NAME = os.getenv("DB2_NAME", "bank_transactions")

def get_db_connection_params(database_name=None):
    """Obtiene parámetros de conexión completos para una base de datos específica"""
    params = DATABASE_CONFIG.copy()
    if database_name:
        params["dbname"] = database_name
    return params