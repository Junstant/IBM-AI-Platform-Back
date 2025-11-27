"""
Configuración de modelos LLM para toda la plataforma

Proporciona configuración centralizada para todos los modelos de lenguaje.
"""

import os
from typing import Dict, List, Optional
from .base import get_config


class ModelsConfig:
    """Configuración de modelos LLM"""
    
    def __init__(self):
        """Inicializar configuración de modelos"""
        self.base_config = get_config()
        
        # Puertos externos (expuestos al host)
        self.gemma_2b_port = int(os.getenv("GEMMA_2B_PORT", "8085"))
        self.gemma_4b_port = int(os.getenv("GEMMA_4B_PORT", "8086"))
        self.gemma_12b_port = int(os.getenv("GEMMA_12B_PORT", "8087"))
        self.mistral_port = int(os.getenv("MISTRAL_PORT", "8088"))
        self.deepseek_8b_port = int(os.getenv("DEEPSEEK_8B_PORT", "8089"))
        
        # Puerto interno de LLM en Docker
        self.llm_internal_port = self.base_config.get_internal_port('llm')
    
    def get_model_config(self, model_id: str) -> Optional[Dict]:
        """
        Obtener configuración completa de un modelo específico
        
        Args:
            model_id: ID del modelo (ej: 'gemma-2b', 'mistral-7b')
            
        Returns:
            dict: Configuración del modelo o None si no existe
        """
        models = self.get_all_models()
        return next((m for m in models if m['id'] == model_id), None)
    
    def get_all_models(self) -> List[Dict]:
        """
        Obtener lista completa de modelos disponibles
        
        Returns:
            list: Lista de configuraciones de modelos
        """
        models = [
            {
                "id": "gemma-2b",
                "name": "Gemma 2B",
                "description": "Modelo Gemma 2B ligero y rápido",
                "size": "2B",
                "type": "llm",
                "container_name": "gemma-2b",
                "external_port": self.gemma_2b_port,
                "internal_port": self.llm_internal_port,
                "host": self._get_model_host("gemma-2b"),
                "url": self._get_model_url("gemma-2b", self.gemma_2b_port)
            },
            {
                "id": "gemma-4b",
                "name": "Gemma 4B",
                "description": "Modelo Gemma 4B balanceado",
                "size": "4B",
                "type": "llm",
                "container_name": "gemma-4b",
                "external_port": self.gemma_4b_port,
                "internal_port": self.llm_internal_port,
                "host": self._get_model_host("gemma-4b"),
                "url": self._get_model_url("gemma-4b", self.gemma_4b_port)
            },
            {
                "id": "gemma-12b",
                "name": "Gemma 12B",
                "description": "Modelo Gemma 12B de alta capacidad",
                "size": "12B",
                "type": "llm",
                "container_name": "gemma-12b",
                "external_port": self.gemma_12b_port,
                "internal_port": self.llm_internal_port,
                "host": self._get_model_host("gemma-12b"),
                "url": self._get_model_url("gemma-12b", self.gemma_12b_port)
            },
            {
                "id": "mistral-7b",
                "name": "Mistral 7B",
                "description": "Modelo Mistral 7B optimizado",
                "size": "7B",
                "type": "llm",
                "container_name": "mistral-7b",
                "external_port": self.mistral_port,
                "internal_port": self.llm_internal_port,
                "host": self._get_model_host("mistral-7b"),
                "url": self._get_model_url("mistral-7b", self.mistral_port)
            },
            {
                "id": "deepseek-8b",
                "name": "DeepSeek 8B",
                "description": "Modelo DeepSeek 8B equilibrado",
                "size": "8B",
                "type": "llm",
                "container_name": "deepseek-8b",
                "external_port": self.deepseek_8b_port,
                "internal_port": self.llm_internal_port,
                "host": self._get_model_host("deepseek-8b"),
                "url": self._get_model_url("deepseek-8b", self.deepseek_8b_port)
            }
        ]
        return models
    
    def _get_model_host(self, container_name: str) -> str:
        """Obtener host del modelo según el entorno"""
        if self.base_config.is_docker:
            return container_name
        return "localhost"
    
    def _get_model_url(self, container_name: str, external_port: int) -> str:
        """Construir URL completa del modelo"""
        if self.base_config.is_docker:
            return f"http://{container_name}:{self.llm_internal_port}"
        return f"http://localhost:{external_port}"
    
    def get_models_by_size(self, size_range: str = "all") -> List[Dict]:
        """
        Filtrar modelos por tamaño
        
        Args:
            size_range: 'small' (2-4B), 'medium' (7-8B), 'large' (12-14B), 'all'
            
        Returns:
            list: Lista filtrada de modelos
        """
        all_models = self.get_all_models()
        
        if size_range == "small":
            return [m for m in all_models if m['size'] in ['2B', '4B']]
        elif size_range == "medium":
            return [m for m in all_models if m['size'] in ['7B', '8B']]
        elif size_range == "large":
            return [m for m in all_models if m['size'] in ['12B', '14B']]
        else:
            return all_models
    
    def to_dict(self) -> Dict:
        """Convertir configuración a diccionario"""
        return {
            'environment': 'docker' if self.base_config.is_docker else 'local',
            'internal_port': self.llm_internal_port,
            'models': self.get_all_models()
        }
    
    def __repr__(self) -> str:
        env = "Docker" if self.base_config.is_docker else "Local"
        return f"<ModelsConfig environment={env} models={len(self.get_all_models())}>"
