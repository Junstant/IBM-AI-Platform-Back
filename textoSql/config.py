# config.py
"""
Configuración centralizada para múltiples modelos LLM y bases de datos
"""

import os
from dotenv import load_dotenv

# Cargar .env desde el directorio padre del proyecto
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=env_path)

# Obtener configuración desde variables de entorno
DEFAULT_HOST = os.getenv("VITE_API_HOST", "150.230.11.162")  # Usar la IP del servidor
DB_HOST = os.getenv("DB_HOST")

# Configuración de modelos LLM disponibles - ACTUALIZADA
LLM_MODELS = {
    "mistral-7b": {
        "name": "Mistral 7B",
        "host": DEFAULT_HOST,
        "port": os.getenv("MISTRAL_PORT", "8088"),  # Cambiado de 8096 a 8088
        "description": "Modelo Mistral 7B optimizado para tareas generales"
    },
    "gemma-2b": {
        "name": "Google Gemma 2B",
        "host": DEFAULT_HOST,
        "port": os.getenv("GEMMA_2B_PORT", "8085"),  # Cambiado de 9470 a 8085
        "description": "Modelo ligero Google Gemma 2B"
    },
    "gemma-4b": {
        "name": "Google Gemma 4B",
        "host": DEFAULT_HOST,
        "port": os.getenv("GEMMA_4B_PORT", "8086"),  # Cambiado de 8094 a 8086
        "description": "Modelo Google Gemma 4B balanceado"
    },
    "gemma-12b": {
        "name": "Google Gemma 12B",
        "host": DEFAULT_HOST,
        "port": os.getenv("GEMMA_12B_PORT", "8087"),  # Cambiado de 2005 a 8087
        "description": "Modelo Google Gemma 12B de alta capacidad"
    },
    "deepseek-8b": {
        "name": "DeepSeek 8B", 
        "host": DEFAULT_HOST,
        "port": os.getenv("DEEPSEEK_8B_PORT", "8089"),  # Cambiado de 8092 a 8089
        "description": "Modelo DeepSeek 8B equilibrado"
    },
    "deepseek-14b": {
        "name": "DeepSeek 14B",
        "host": DEFAULT_HOST,
        "port": os.getenv("DEEPSEEK_14B_PORT", "8090"),  # Mantiene 8090
        "description": "Modelo DeepSeek 14B de alta capacidad"
    }
}

# Configuración de la base de datos PostgreSQL
DATABASE_CONFIG = {
    "host": DB_HOST,
    "port": os.getenv("DB_PORT", "8070"),  # Cambiado de 5432 a 8070
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "root")
}

def get_available_models():
    """
    Configuración usando variables de entorno - ACTUALIZADA
    """
    # Usar la IP del servidor para todos los modelos LLM
    host_ip = DEFAULT_HOST or "150.230.11.162"
    
    return [
        {
            "id": "mistral-7b",
            "name": "Mistral 7B",
            "description": "Modelo Mistral 7B optimizado para tareas generales",
            "host": host_ip,
            "port": os.getenv("MISTRAL_PORT", "8088"),  # Actualizado
            "container_name": "mistral-7b"
        },
        {
            "id": "gemma-2b",
            "name": "Gemma 2B",
            "description": "Modelo Gemma 2B ligero y rápido",
            "host": host_ip,
            "port": os.getenv("GEMMA_2B_PORT", "8085"),  # Actualizado
            "container_name": "gemma-2b"
        },
        {
            "id": "gemma-4b",
            "name": "Google Gemma 4B",
            "description": "Modelo Google Gemma 4B balanceado", 
            "host": host_ip,
            "port": os.getenv("GEMMA_4B_PORT", "8086"),  # Actualizado
            "container_name": "gemma-4b"
        },
        {
            "id": "gemma-12b",
            "name": "Google Gemma 12B", 
            "description": "Modelo Google Gemma 12B de alta capacidad",
            "host": host_ip,
            "port": os.getenv("GEMMA_12B_PORT", "8087"),  # Actualizado
            "container_name": "gemma-12b"
        },
        {
            "id": "deepseek-8b",
            "name": "DeepSeek 8B",
            "description": "Modelo DeepSeek 8B equilibrado",
            "host": host_ip,
            "port": os.getenv("DEEPSEEK_8B_PORT", "8089"),  # Actualizado
            "container_name": "deepseek-8b"
        },
        {
            "id": "deepseek-14b",
            "name": "DeepSeek 14B", 
            "description": "Modelo DeepSeek 14B de alta capacidad",
            "host": host_ip,
            "port": os.getenv("DEEPSEEK_14B_PORT", "8090"),  # Mantiene
            "container_name": "deepseek-14b"
        }
    ]

def get_model_config(model_id: str):
    """Obtiene la configuración de un modelo específico"""
    if model_id not in LLM_MODELS:
        raise ValueError(f"Modelo '{model_id}' no encontrado")
    return LLM_MODELS[model_id]