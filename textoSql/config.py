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

# Configuración de modelos LLM disponibles
LLM_MODELS = {
    "mistral-7b": {
        "name": "Mistral 7B",
        "host": DEFAULT_HOST,
        "port": os.getenv("MISTRAL_PORT", "8096"),
        "description": "Modelo Mistral 7B optimizado para tareas generales"
    },
    "gemma-2b": {
        "name": "Google Gemma 2B",
        "host": DEFAULT_HOST,
        "port": os.getenv("GEMMA_2B_PORT", "9470"),
        "description": "Modelo ligero Google Gemma 2B"
    },
    "gemma-4b": {
        "name": "Google Gemma 4B",
        "host": DEFAULT_HOST,
        "port": os.getenv("GEMMA_4B_PORT", "8094"), 
        "description": "Modelo Google Gemma 4B balanceado"
    },
    "gemma-12b": {
        "name": "Google Gemma 12B",
        "host": DEFAULT_HOST,
        "port": os.getenv("GEMMA_12B_PORT", "2005"),
        "description": "Modelo Google Gemma 12B de alta capacidad"
    },
    "gemma-test": {
        "name": "Gemma Test",
        "host": DEFAULT_HOST,
        "port": os.getenv("GEMMA_TEST_PORT", "8099"),
        "description": "Modelo Gemma en modo test"
    },
    "deepseek-1.5b": {
        "name": "DeepSeek 1.5B",
        "host": DEFAULT_HOST,
        "port": os.getenv("DEEPSEEK_1_5B_PORT", "8091"),
        "description": "Modelo DeepSeek 1.5B ultraligero"
    },
    "deepseek-8b": {
        "name": "DeepSeek 8B", 
        "host": DEFAULT_HOST,
        "port": os.getenv("DEEPSEEK_8B_PORT", "8092"),
        "description": "Modelo DeepSeek 8B equilibrado"
    },
    "deepseek-14b": {
        "name": "DeepSeek 14B",
        "host": DEFAULT_HOST,
        "port": os.getenv("DEEPSEEK_14B_PORT", "8090"),
        "description": "Modelo DeepSeek 14B de alta capacidad"
    },
    "granite": {
        "name": "IBM Granite",
        "host": DEFAULT_HOST,
        "port": os.getenv("GRANITE_PORT", "8095"), 
        "description": "Modelo IBM Granite para código y análisis"
    },
    "benja-gpt": {
        "name": "Benja GPT",
        "host": DEFAULT_HOST,
        "port": os.getenv("BENJA_GPT_PORT", "9476"),
        "description": "Modelo personalizado Benja GPT"
    }
}

# Configuración de la base de datos PostgreSQL
DATABASE_CONFIG = {
    "host": DB_HOST,
    "port": os.getenv("DB_PORT", "5432"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "root")
}

def get_available_models():
    """
    Configuración usando variables de entorno
    """
    # Usar la IP del servidor para todos los modelos LLM
    host_ip = DEFAULT_HOST or "150.230.11.162"
    
    return [
        {
            "id": "mistral-7b",
            "name": "Mistral 7B",
            "description": "Modelo Mistral 7B optimizado para tareas generales",
            "host": host_ip,
            "port": os.getenv("MISTRAL_PORT", "8096"),
            "container_name": "mistral-td-server"
        },
        {
            "id": "gemma-test", 
            "name": "Gemma Test",
            "description": "Modelo Gemma en pruebas",
            "host": host_ip,
            "port": os.getenv("GEMMA_TEST_PORT", "8099"),
            "container_name": "gemma-test"
        },
        {
            "id": "benja-gpt",
            "name": "Benja GPT",
            "description": "Modelo personalizado Benja",
            "host": host_ip, 
            "port": os.getenv("BENJA_GPT_PORT", "9476"),
            "container_name": "benja_gpt"
        },
        {
            "id": "gemma-12b",
            "name": "Google Gemma 12B", 
            "description": "Modelo Google Gemma 12B de alta capacidad",
            "host": host_ip,
            "port": os.getenv("GEMMA_12B_PORT", "2005"),
            "container_name": "google_gemma12b-td-server"
        },
        {
            "id": "gemma-2b",
            "name": "Gemma 2B",
            "description": "Modelo Gemma 2B ligero y rápido",
            "host": host_ip,
            "port": os.getenv("GEMMA_2B_PORT", "9470"), 
            "container_name": "gemma2b-td-server"
        },
        {
            "id": "granite",
            "name": "IBM Granite",
            "description": "Modelo IBM Granite especializado en código",
            "host": host_ip,
            "port": os.getenv("GRANITE_PORT", "8095"),
            "container_name": "granite-td-server"
        },
        {
            "id": "gemma-4b",
            "name": "Google Gemma 4B",
            "description": "Modelo Google Gemma 4B balanceado", 
            "host": host_ip,
            "port": os.getenv("GEMMA_4B_PORT", "8094"),
            "container_name": "google_gemma4b-td-server"
        },
        {
            "id": "deepseek-8b",
            "name": "DeepSeek 8B",
            "description": "Modelo DeepSeek 8B equilibrado",
            "host": host_ip,
            "port": os.getenv("DEEPSEEK_8B_PORT", "8092"),
            "container_name": "deepseek8b-td-server"
        },
        {
            "id": "deepseek-1.5b", 
            "name": "DeepSeek 1.5B",
            "description": "Modelo DeepSeek 1.5B ultraligero",
            "host": host_ip,
            "port": os.getenv("DEEPSEEK_1_5B_PORT", "8091"),
            "container_name": "deepseek1.5B-td-server"
        },
        {
            "id": "deepseek-14b",
            "name": "DeepSeek 14B", 
            "description": "Modelo DeepSeek 14B de alta capacidad",
            "host": host_ip,
            "port": os.getenv("DEEPSEEK_14B_PORT", "8090"),
            "container_name": "deepseek14B-td-server"
        }
    ]

def get_model_config(model_id: str):
    """Obtiene la configuración de un modelo específico"""
    if model_id not in LLM_MODELS:
        raise ValueError(f"Modelo '{model_id}' no encontrado")
    return LLM_MODELS[model_id]