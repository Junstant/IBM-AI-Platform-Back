"""
Configuración del servicio RAG
"""
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

class Config:
    """Configuración centralizada para RAG"""
    
    # Milvus Vector Database
    MILVUS_HOST = os.getenv("MILVUS_HOST", "milvus-standalone")
    MILVUS_PORT = int(os.getenv("MILVUS_PORT", "19530"))
    
    # Modelos de embeddings disponibles (API externa)
    AVAILABLE_EMBEDDING_MODELS = {
        "mistral-7b-embeddings": {
            "host": "mistral-7b", 
            "port": "8080", 
            "name": "Mistral 7B Embeddings",
            "description": "Embeddings de alta capacidad con Mistral 7B - Soporta documentos grandes",
            "dimensions": 4096
        },
        "gemma-2b-embeddings": {
            "host": "gemma-2b",
            "port": "8080",
            "name": "Gemma 2B Embeddings",
            "description": "Embeddings rápidos con Gemma 2B - Para documentos pequeños",
            "dimensions": 2048
        }
    }
    
    # Modelos LLM disponibles (mismos que TextoSQL)
    AVAILABLE_LLM_MODELS = {
        "gemma-2b": {"host": "gemma-2b", "port": "8080", "name": "Gemma 2B"},
        "gemma-4b": {"host": "gemma-4b", "port": "8080", "name": "Gemma 4B"},
        "gemma-12b": {"host": "gemma-12b", "port": "8080", "name": "Gemma 12B"},
        "mistral-7b": {"host": "mistral-7b", "port": "8080", "name": "Mistral 7B"},
        "deepseek-8b": {"host": "deepseek-8b", "port": "8080", "name": "DeepSeek 8B"}
    }
    
    # LLM Configuration (por defecto Gemma-2B)
    DEFAULT_LLM_MODEL = "gemma-2b"
    LLM_HOST = os.getenv("LLM_HOST", "gemma-2b")
    LLM_PORT = os.getenv("LLM_PORT", "8080")
    
    # Embeddings Service (usando llama.cpp /embedding endpoint)
    # Usando Mistral 7B para mejor capacidad de procesamiento
    EMBEDDING_SERVICE_HOST = os.getenv("EMBEDDING_SERVICE_HOST", "mistral-7b")
    EMBEDDING_SERVICE_PORT = os.getenv("EMBEDDING_SERVICE_PORT", "8080")
    EMBEDDING_MODEL = "mistral-7b-embeddings"  # Mistral 7B para embeddings más robustos
    EMBEDDING_DIMENSION = 4096  # Dimensión de embeddings de Mistral 7B
    EMBEDDING_MAX_TOKENS = 8192  # Tokens máximos por embedding
    ENABLE_EMBEDDINGS = os.getenv("ENABLE_EMBEDDINGS", "true").lower() == "true"
    
    # Document Processing
    MAX_FILE_SIZE_MB = 100  # Aumentado a 100MB para documentos grandes
    ALLOWED_EXTENSIONS = {'.pdf', '.docx', '.txt', '.csv', '.xlsx', '.md'}
    CHUNK_SIZE = 512  # Optimizado para Mistral 7B (mejor capacidad)
    CHUNK_OVERLAP = 64  # Mayor overlap para mejor contexto
    
    # RAG Settings
    TOP_K_RESULTS = 5  # Documentos relevantes a recuperar
    MAX_CONTEXT_LENGTH = 4000  # Tokens máximos de contexto
    
    # Paths
    UPLOAD_DIR = "/app/documents"

config = Config()
