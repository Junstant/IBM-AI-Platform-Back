# config.py
"""
Configuración centralizada para múltiples modelos LLM y bases de datos
"""

import os
from dotenv import load_dotenv

# Cargar .env desde el directorio padre del proyecto
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(dotenv_path=env_path)

def get_available_models():
    """
    Configuración inteligente según el entorno
    """
    # DETECTAR SI ESTAMOS EN DOCKER
    is_docker = (
        os.path.exists('/.dockerenv') or
        os.getenv('RUNNING_IN_DOCKER', '').lower() == 'true' or
        os.getenv('DB_HOST', '').lower() == 'postgres_db'  # Indicador Docker
    )
    
    if is_docker:
        # DENTRO DE DOCKER - usar nombres de contenedores
        print("🐳 Detectado entorno Docker - usando nombres de contenedores")
        host_prefix = ""  # Usar nombres directos de contenedores
        models_config = [
            {
                "id": "mistral-7b",
                "name": "Mistral 7B",
                "description": "Modelo Mistral 7B optimizado para tareas generales",
                "host": "mistral-7b",  # ← Nombre del contenedor
                "port": "8080",        # ← Puerto interno del contenedor
                "container_name": "mistral-7b"
            },
            {
                "id": "gemma-2b",
                "name": "Gemma 2B",
                "description": "Modelo Gemma 2B ligero y rápido",
                "host": "gemma-2b",   # ← Nombre del contenedor
                "port": "8080",       # ← Puerto interno del contenedor
                "container_name": "gemma-2b"
            },
            {
                "id": "gemma-4b",
                "name": "Google Gemma 4B",
                "description": "Modelo Google Gemma 4B balanceado", 
                "host": "gemma-4b",   # ← Nombre del contenedor
                "port": "8080",       # ← Puerto interno del contenedor
                "container_name": "gemma-4b"
            },
            {
                "id": "gemma-12b",
                "name": "Google Gemma 12B", 
                "description": "Modelo Google Gemma 12B de alta capacidad",
                "host": "gemma-12b",  # ← Nombre del contenedor
                "port": "8080",       # ← Puerto interno del contenedor
                "container_name": "gemma-12b"
            },
            {
                "id": "deepseek-8b",
                "name": "DeepSeek 8B",
                "description": "Modelo DeepSeek 8B equilibrado",
                "host": "deepseek-8b", # ← Nombre del contenedor
                "port": "8080",        # ← Puerto interno del contenedor
                "container_name": "deepseek-8b"
            },
            {
                "id": "deepseek-14b",
                "name": "DeepSeek 14B", 
                "description": "Modelo DeepSeek 14B de alta capacidad",
                "host": "deepseek-14b", # ← Nombre del contenedor
                "port": "8080",         # ← Puerto interno del contenedor
                "container_name": "deepseek-14b"
            }
        ]
    else:
        # FUERA DE DOCKER - usar localhost con puertos externos
        print("💻 Detectado entorno local - usando localhost")
        models_config = [
            {
                "id": "mistral-7b",
                "name": "Mistral 7B",
                "description": "Modelo Mistral 7B optimizado para tareas generales",
                "host": "127.0.0.1",
                "port": os.getenv("MISTRAL_PORT", "8088"),
                "container_name": "mistral-7b"
            },
            {
                "id": "gemma-2b",
                "name": "Gemma 2B",
                "description": "Modelo Gemma 2B ligero y rápido",
                "host": "127.0.0.1",
                "port": os.getenv("GEMMA_2B_PORT", "8085"),
                "container_name": "gemma-2b"
            },
            {
                "id": "gemma-4b",
                "name": "Google Gemma 4B",
                "description": "Modelo Google Gemma 4B balanceado", 
                "host": "127.0.0.1",
                "port": os.getenv("GEMMA_4B_PORT", "8086"),
                "container_name": "gemma-4b"
            },
            {
                "id": "gemma-12b",
                "name": "Google Gemma 12B", 
                "description": "Modelo Google Gemma 12B de alta capacidad",
                "host": "127.0.0.1",
                "port": os.getenv("GEMMA_12B_PORT", "8087"),
                "container_name": "gemma-12b"
            },
            {
                "id": "deepseek-8b",
                "name": "DeepSeek 8B",
                "description": "Modelo DeepSeek 8B equilibrado",
                "host": "127.0.0.1",
                "port": os.getenv("DEEPSEEK_8B_PORT", "8089"),
                "container_name": "deepseek-8b"
            },
            {
                "id": "deepseek-14b",
                "name": "DeepSeek 14B", 
                "description": "Modelo DeepSeek 14B de alta capacidad",
                "host": "127.0.0.1",
                "port": os.getenv("DEEPSEEK_14B_PORT", "8090"),
                "container_name": "deepseek-14b"
            }
        ]
    
    return models_config

def get_model_config(model_id: str):
    """Obtiene la configuración de un modelo específico"""
    models = get_available_models()
    for model in models:
        if model["id"] == model_id:
            return model
    raise ValueError(f"Modelo '{model_id}' no encontrado")