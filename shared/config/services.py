"""
Configuración de servicios/APIs para toda la plataforma

Proporciona configuración centralizada para todas las APIs y servicios.
"""

import os
from typing import Dict, Optional
from .base import get_config


class ServicesConfig:
    """Configuración de servicios y APIs"""
    
    def __init__(self):
        """Inicializar configuración de servicios"""
        self.base_config = get_config()
        
        # Puertos externos
        self.textosql_api_port = int(os.getenv("TEXTOSQL_API_PORT", "8000"))
        self.fraud_api_port = int(os.getenv("FRAUD_API_PORT", "8001"))
        self.stats_port = int(os.getenv("STATS_PORT", "8003"))
        self.rag_api_port = int(os.getenv("RAG_API_PORT", "8004"))
        self.frontend_port = int(os.getenv("NGINX_PORT", "2012"))
        
        # Nombres de contenedores
        self.textosql_container = os.getenv("TEXTOSQL_API_CONTAINER_NAME", "textosql-api")
        self.fraud_container = os.getenv("FRAUD_API_CONTAINER_NAME", "fraude-api")
        self.stats_container = os.getenv("STATS_CONTAINER_NAME", "stats-api")
        self.rag_container = os.getenv("RAG_CONTAINER_NAME", "rag-api")
        self.frontend_container = os.getenv("FRONTEND_CONTAINER_NAME", "frontend")
        
        # Puerto interno de APIs
        self.api_internal_port = self.base_config.get_internal_port('api')
    
    def get_service_config(self, service_id: str) -> Optional[Dict]:
        """
        Obtener configuración de un servicio específico
        
        Args:
            service_id: ID del servicio ('textosql', 'fraud', 'stats', 'rag', 'frontend')
            
        Returns:
            dict: Configuración del servicio o None si no existe
        """
        services = self.get_all_services()
        return services.get(service_id)
    
    def get_all_services(self) -> Dict[str, Dict]:
        """
        Obtener configuración de todos los servicios
        
        Returns:
            dict: Diccionario con configuración de servicios
        """
        return {
            "textosql": {
                "id": "textosql",
                "name": "TextoSQL API",
                "description": "API de conversión de texto a SQL",
                "type": "api",
                "container_name": self.textosql_container,
                "external_port": self.textosql_api_port,
                "internal_port": self.api_internal_port,
                "host": self._get_service_host(self.textosql_container),
                "url": self._get_service_url(self.textosql_container, self.textosql_api_port),
                "docs_path": "/docs",
                "health_path": "/health"
            },
            "fraud": {
                "id": "fraud",
                "name": "Fraud Detection API",
                "description": "API de detección de fraude",
                "type": "api",
                "container_name": self.fraud_container,
                "external_port": self.fraud_api_port,
                "internal_port": self.api_internal_port,
                "host": self._get_service_host(self.fraud_container),
                "url": self._get_service_url(self.fraud_container, self.fraud_api_port),
                "docs_path": "/docs",
                "health_path": "/health"
            },
            "stats": {
                "id": "stats",
                "name": "Statistics API",
                "description": "API de estadísticas y métricas",
                "type": "api",
                "container_name": self.stats_container,
                "external_port": self.stats_port,
                "internal_port": self.stats_port,  # Stats usa puerto custom
                "host": self._get_service_host(self.stats_container),
                "url": self._get_service_url(self.stats_container, self.stats_port, custom_internal=self.stats_port),
                "docs_path": "/docs",
                "health_path": "/health"
            },
            "rag": {
                "id": "rag",
                "name": "RAG API",
                "description": "API de Retrieval Augmented Generation",
                "type": "api",
                "container_name": self.rag_container,
                "external_port": self.rag_api_port,
                "internal_port": self.api_internal_port,
                "host": self._get_service_host(self.rag_container),
                "url": self._get_service_url(self.rag_container, self.rag_api_port),
                "docs_path": "/docs",
                "health_path": "/health"
            },
            "frontend": {
                "id": "frontend",
                "name": "Frontend (Nginx)",
                "description": "Aplicación web frontend",
                "type": "web",
                "container_name": self.frontend_container,
                "external_port": self.frontend_port,
                "internal_port": 80,
                "host": self._get_service_host(self.frontend_container),
                "url": self._get_service_url(self.frontend_container, self.frontend_port, custom_internal=80),
                "health_path": "/health"
            }
        }
    
    def _get_service_host(self, container_name: str) -> str:
        """Obtener host del servicio según el entorno"""
        if self.base_config.is_docker:
            return container_name
        return "localhost"
    
    def _get_service_url(self, container_name: str, external_port: int, custom_internal: Optional[int] = None) -> str:
        """Construir URL completa del servicio"""
        if self.base_config.is_docker:
            port = custom_internal if custom_internal else self.api_internal_port
            return f"http://{container_name}:{port}"
        return f"http://localhost:{external_port}"
    
    def get_api_services(self) -> Dict[str, Dict]:
        """Obtener solo servicios de tipo API"""
        all_services = self.get_all_services()
        return {k: v for k, v in all_services.items() if v['type'] == 'api'}
    
    def get_external_urls(self) -> Dict[str, str]:
        """Obtener URLs externas de todos los servicios"""
        services = self.get_all_services()
        return {
            service_id: f"http://localhost:{config['external_port']}"
            for service_id, config in services.items()
        }
    
    def to_dict(self) -> Dict:
        """Convertir configuración a diccionario"""
        return {
            'environment': 'docker' if self.base_config.is_docker else 'local',
            'api_internal_port': self.api_internal_port,
            'services': self.get_all_services()
        }
    
    def __repr__(self) -> str:
        env = "Docker" if self.base_config.is_docker else "Local"
        return f"<ServicesConfig environment={env} services={len(self.get_all_services())}>"
