"""
Configuración global para el servicio de estadísticas
"""

import os
from typing import Optional, List

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
    database_url: str = "postgresql://postgres:postgres@localhost:8070/ai_platform_stats"
    db_host: str = "localhost"
    db_port: int = 8070
    db_user: str = "postgres"
    db_password: str = "postgres"
    db_name: str = "ai_platform_stats"
    
    # Configuración de modelos IA
    models_config: dict = {
        "gemma-2b": {"port": 8085, "type": "llm", "size": "2B"},
        "gemma-4b": {"port": 8086, "type": "llm", "size": "4B"},
        "gemma-12b": {"port": 8087, "type": "llm", "size": "12B"},
        "mistral-7b": {"port": 8088, "type": "llm", "size": "7B"},
        "deepseek-8b": {"port": 8089, "type": "llm", "size": "8B"},
        "deepseek-14b": {"port": 8090, "type": "llm", "size": "14B"},
        "fraud-api": {"port": 8001, "type": "fraud", "size": None},
        "textosql-api": {"port": 8000, "type": "textosql", "size": None}
    }
    
    # Configuración de monitoreo
    health_check_interval: int = 300  # 5 minutos
    metrics_collection_interval: int = 60  # 1 minuto
    alert_check_interval: int = 120  # 2 minutos
    
    # Umbrales de alertas
    model_timeout_threshold: int = 30  # segundos
    api_error_rate_threshold: float = 10.0  # porcentaje
    memory_usage_threshold: float = 90.0  # porcentaje
    cpu_usage_threshold: float = 90.0  # porcentaje
    
    # Configuración de limpieza
    log_retention_days: int = 30
    cleanup_hour: int = 2  # 2 AM
    
    # Logging
    log_level: str = "INFO"
    log_format: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Configuración de entorno Docker
    is_docker: bool = os.getenv("DOCKER_ENV", "false").lower() == "true"
    
    # URLs de servicios externos
    fraud_api_url: str = "http://localhost:8001"
    textosql_api_url: str = "http://localhost:8000"
    frontend_url: str = "http://localhost:2012"
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        
        # Ajustar configuración para Docker
        if self.is_docker:
            self.db_host = "postgres"
            self.fraud_api_url = "http://fraude-api:8001"
            self.textosql_api_url = "http://textosql-api:8000"
            self.frontend_url = "http://frontend:80"
        
        # Construir URL de base de datos
        self.database_url = (
            f"postgresql://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )
    
    def get_model_urls(self) -> dict:
        """Obtener URLs de modelos según el entorno"""
        urls = {}
        for model_name, config in self.models_config.items():
            if self.is_docker:
                # En Docker, usar nombres de contenedores
                host = model_name if config["type"] == "llm" else model_name
            else:
                host = "localhost"
            
            urls[model_name] = f"http://{host}:{config['port']}"
        
        return urls