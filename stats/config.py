"""
Configuración global para el servicio de estadísticas
"""

import os
from typing import Optional, List, Dict

try:
    from pydantic_settings import BaseSettings
except ImportError:
    from pydantic import BaseSettings

class Settings(BaseSettings):
    """Configuración de la aplicación"""
    
    # Configuración del servidor
    host: str = "0.0.0.0"
    port: int = 8003
    debug: bool = False
    
    # Base de datos
    db_host: str = "localhost"
    db_port: int = 5432
    db_user: str = "postgres"
    db_password: str = "postgres"
    db_name: str = "ai_platform_stats"
    
    # Configuración de entorno Docker
    is_docker: bool = False
    docker_db_host: str = "postgres"
    docker_db_port: int = 5432
    
    # Puertos de modelos LLM (desde .env)
    gemma_2b_port: int = 8085
    gemma_4b_port: int = 8086
    arctic_text2sql_port: int = 8087
    mistral_port: int = 8088
    deepseek_8b_port: int = 8089
    
    # Puertos de APIs (desde .env)
    fraud_api_port: int = 8001
    textosql_api_port: int = 8000
    frontend_port: int = 2012
    stats_port: int = 8003
    
    # Nombres de contenedores Docker (desde .env)
    postgres_container_name: str = "postgres"
    fraud_api_container_name: str = "fraude-api"
    textosql_api_container_name: str = "textosql-api"
    frontend_container_name: str = "frontend"
    
    # Puertos internos Docker (desde .env)
    llm_internal_port: int = 8080
    api_internal_port: int = 8000
    
    # Configuración de monitoreo (desde .env)
    health_check_interval: int = 300
    metrics_collection_interval: int = 60
    alert_check_interval: int = 120
    
    # Umbrales de alertas (desde .env)
    model_timeout_threshold: int = 30
    api_error_rate_threshold: float = 10.0
    memory_usage_threshold: float = 90.0
    cpu_usage_threshold: float = 90.0
    
    # Configuración de limpieza (desde .env)
    log_retention_days: int = 30
    cleanup_hour: int = 2
    
    # Logging (desde .env)
    log_level: str = "INFO"
    
    class Config:
        env_file = ".env"
        protected_namespaces = ()
        env_file_encoding = "utf-8"
        case_sensitive = False
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        # Detectar entorno Docker
        self.is_docker = os.getenv("DOCKER_ENV", "false").lower() == "true"
    
    @property
    def database_url(self) -> str:
        """Construir URL de base de datos según el entorno"""
        host = self.postgres_container_name if self.is_docker else self.db_host
        port = self.docker_db_port if self.is_docker else self.db_port
        
        return (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{host}:{port}/{self.db_name}"
        )
    
    @property
    def models_config(self) -> Dict[str, Dict]:
        """Configuración dinámica de modelos desde .env"""
        return {
            "gemma-2b": {
                "port": self.gemma_2b_port,
                "type": "llm",
                "size": "2B",
                "container_name": "gemma-2b"
            },
            "gemma-4b": {
                "port": self.gemma_4b_port,
                "type": "llm",
                "size": "4B",
                "container_name": "gemma-4b"
            },
            "arctic-text2sql-7b": {
                "port": self.arctic_text2sql_port,
                "type": "llm",
                "size": "7B",
                "container_name": "arctic-text2sql-7b"
            },
            "mistral-7b": {
                "port": self.mistral_port,
                "type": "llm",
                "size": "7B",
                "container_name": "mistral-7b"
            },
            "deepseek-8b": {
                "port": self.deepseek_8b_port,
                "type": "llm",
                "size": "8B",
                "container_name": "deepseek-8b"
            },
            "fraud-api": {
                "port": self.fraud_api_port,
                "type": "fraud",
                "size": None,
                "container_name": self.fraud_api_container_name
            },
            "textosql-api": {
                "port": self.textosql_api_port,
                "type": "textosql",
                "size": None,
                "container_name": self.textosql_api_container_name
            }
        }
    
    def get_model_urls(self) -> Dict[str, str]:
        """Obtener URLs de modelos según el entorno"""
        urls = {}
        
        for model_name, config in self.models_config.items():
            if self.is_docker:
                # En Docker, usar nombres de contenedores
                if config["type"] == "llm":
                    urls[model_name] = f"http://{config['container_name']}:{self.llm_internal_port}"
                else:  # APIs (fraud, textosql)
                    urls[model_name] = f"http://{config['container_name']}:{self.api_internal_port}"
            else:
                # En localhost, usar puertos externos
                urls[model_name] = f"http://localhost:{config['port']}"
        
        return urls
    
    def get_service_urls(self) -> Dict[str, str]:
        """Obtener URLs de servicios según el entorno"""
        if self.is_docker:
            return {
                "fraud_api": f"http://{self.fraud_api_container_name}:{self.api_internal_port}",
                "textosql_api": f"http://{self.textosql_api_container_name}:{self.api_internal_port}",
                "frontend": f"http://{self.frontend_container_name}:80"
            }
        else:
            return {
                "fraud_api": f"http://localhost:{self.fraud_api_port}",
                "textosql_api": f"http://localhost:{self.textosql_api_port}",
                "frontend": f"http://localhost:{self.frontend_port}"
            }

# Instancia global de configuración
settings = Settings()