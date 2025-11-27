"""
Módulo de configuración compartida para toda la plataforma AI
"""

from .base import BaseConfig, get_config
from .database import DatabaseConfig
from .models import ModelsConfig
from .services import ServicesConfig

__all__ = [
    'BaseConfig',
    'get_config',
    'DatabaseConfig',
    'ModelsConfig',
    'ServicesConfig'
]
