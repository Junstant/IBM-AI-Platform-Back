"""
Configuración base compartida para toda la plataforma AI

Este módulo proporciona configuración centralizada que se lee del archivo .env
y detecta automáticamente si está corriendo en Docker o localmente.
"""

import os
from typing import Optional, Dict, Any
from pathlib import Path


class BaseConfig:
    """Configuración base para toda la plataforma"""
    
    def __init__(self):
        """Inicializar configuración desde variables de entorno"""
        # Detectar si estamos en Docker
        self.is_docker = self._detect_docker_environment()
        
        # Configuración general
        self.environment = os.getenv("ENVIRONMENT", "production")
        self.debug = os.getenv("DEBUG", "false").lower() == "true"
        self.log_level = os.getenv("LOG_LEVEL", "INFO")
        
        # Directorios
        self.front_dir = os.getenv("FRONT_DIR", "/root/FrontAI")
        self.back_dir = os.getenv("BACK_DIR", "/root/BackAI")
        
        # Repositorios
        self.repo_front_url = os.getenv("REPO_FRONT_URL", "https://github.com/Junstant/IBM-AI-Platform-Front.git")
        self.repo_back_url = os.getenv("REPO_BACK_URL", "https://github.com/Junstant/IBM-AI-Platform-Back.git")
        
        # Tokens y secrets
        self.hf_token = os.getenv("TOKEN_HUGGHINGFACE", "")
        
        # Configuración de Docker Compose
        self.compose_project_name = os.getenv("COMPOSE_PROJECT_NAME", "aipl")
        
    def _detect_docker_environment(self) -> bool:
        """
        Detectar si estamos corriendo dentro de Docker
        
        Returns:
            bool: True si está en Docker, False si es local
        """
        # Método 1: Verificar archivo .dockerenv
        if os.path.exists('/.dockerenv'):
            return True
        
        # Método 2: Variable de entorno explícita
        if os.getenv('DOCKER_ENV', '').lower() == 'true':
            return True
        
        # Método 3: Verificar cgroup (funciona en Linux)
        try:
            with open('/proc/1/cgroup', 'r') as f:
                return 'docker' in f.read()
        except:
            pass
        
        return False
    
    def get_host(self, service_name: str, external_host: str = "localhost") -> str:
        """
        Obtener el hostname correcto según el entorno
        
        Args:
            service_name: Nombre del servicio/contenedor en Docker
            external_host: Host a usar fuera de Docker (default: localhost)
            
        Returns:
            str: Hostname apropiado para el entorno
        """
        return service_name if self.is_docker else external_host
    
    def get_internal_port(self, service_type: str) -> int:
        """
        Obtener puerto interno según el tipo de servicio
        
        Args:
            service_type: Tipo de servicio ('llm', 'api', 'db', 'web')
            
        Returns:
            int: Puerto interno del servicio
        """
        port_mapping = {
            'llm': int(os.getenv("LLM_INTERNAL_PORT", "8080")),
            'api': int(os.getenv("API_INTERNAL_PORT", "8000")),
            'db': int(os.getenv("DB_INTERNAL_PORT", "5432")),
            'web': 80,
            'milvus': 19530,
            'minio': 9000
        }
        return port_mapping.get(service_type, 8000)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convertir configuración a diccionario"""
        return {
            'is_docker': self.is_docker,
            'environment': self.environment,
            'debug': self.debug,
            'log_level': self.log_level,
            'compose_project_name': self.compose_project_name
        }
    
    def __repr__(self) -> str:
        env_type = "Docker" if self.is_docker else "Local"
        return f"<BaseConfig environment={env_type} debug={self.debug}>"


# Instancia global de configuración
_config_instance: Optional[BaseConfig] = None


def get_config() -> BaseConfig:
    """
    Obtener instancia singleton de configuración
    
    Returns:
        BaseConfig: Instancia de configuración global
    """
    global _config_instance
    if _config_instance is None:
        _config_instance = BaseConfig()
    return _config_instance
