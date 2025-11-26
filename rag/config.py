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
        "nomic-embed-text": {
            "host": "gemma-2b", 
            "port": "8080", 
            "name": "Nomic Embed Text",
            "description": "Modelo de embeddings optimizado para búsqueda semántica",
            "dimensions": 768
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
    # Por defecto usa el mismo servidor que el LLM seleccionado
    EMBEDDING_SERVICE_HOST = os.getenv("EMBEDDING_SERVICE_HOST", "gemma-2b")
    EMBEDDING_SERVICE_PORT = os.getenv("EMBEDDING_SERVICE_PORT", "8080")
    EMBEDDING_MODEL = "gemma-2b-embeddings"  # Usando embeddings del LLM
    EMBEDDING_DIMENSION = 2048  # Dimensión de embeddings de Gemma-2B
    EMBEDDING_MAX_TOKENS = 8192  # Tokens máximos por embedding
    ENABLE_EMBEDDINGS = os.getenv("ENABLE_EMBEDDINGS", "true").lower() == "true"
    
    # Document Processing
    MAX_FILE_SIZE_MB = 50
    ALLOWED_EXTENSIONS = {'.pdf', '.docx', '.txt', '.csv', '.xlsx', '.md'}
    CHUNK_SIZE = 500
    CHUNK_OVERLAP = 50
    
    # RAG Settings
    TOP_K_RESULTS = 5  # Documentos relevantes a recuperar
    MAX_CONTEXT_LENGTH = 4000  # Tokens máximos de contexto
    
    # Paths
    UPLOAD_DIR = "/app/documents"

config = Config()
