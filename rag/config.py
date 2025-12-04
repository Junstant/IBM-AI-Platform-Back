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
    
    # ✅ MODELO DE EMBEDDINGS - SOLO Nomic (especializado en vectorización)
    # ⚠️ CRÍTICO: Gemma/Mistral NO son modelos de embeddings - Son decoder-only
    AVAILABLE_EMBEDDING_MODELS = {
        "nomic-embed-text-v1.5": {
            "host": "embeddings-api", 
            "port": "8080", 
            "name": "Nomic Embed Text v1.5",
            "description": "Modelo encoder-only especializado en embeddings semánticos (768D ultra-rápido)",
            "dimensions": 768
        }
    }
    
    # ✅ MODELOS LLM - SOLO para generación de respuestas (NO para embeddings)
    AVAILABLE_LLM_MODELS = {
        "gemma-2b": {
            "host": "gemma-2b", 
            "port": "8080", 
            "name": "Gemma 2B",
            "description": "Rápido, baja latencia (<1s)"
        },
        "gemma-4b": {
            "host": "gemma-4b", 
            "port": "8080", 
            "name": "Gemma 4B",
            "description": "Balance velocidad/calidad"
        },
        "gemma-12b": {
            "host": "gemma-12b", 
            "port": "8080", 
            "name": "Gemma 12B",
            "description": "Alta calidad, más recursos"
        },
        "mistral-7b": {
            "host": "mistral-7b", 
            "port": "8080", 
            "name": "Mistral 7B",
            "description": "Máxima calidad para RAG (recomendado)"
        },
        "deepseek-8b": {
            "host": "deepseek-8b", 
            "port": "8080", 
            "name": "DeepSeek 8B",
            "description": "Especializado en razonamiento complejo"
        }
    }
    
    # LLM Configuration (por defecto Mistral-7B - SOLO para generación)
    DEFAULT_LLM_MODEL = "mistral-7b"  # Mistral mejor que Gemma para seguir instrucciones
    LLM_HOST = os.getenv("LLM_HOST", "mistral-7b")
    LLM_PORT = os.getenv("LLM_PORT", "8080")
    
    # Embeddings Service (DEDICADO - Nomic Embed Text v1.5)
    # ⚠️ CRÍTICO: Servidor especializado SOLO para embeddings - NO usar LLMs generativos
    EMBEDDING_SERVICE_HOST = os.getenv("EMBEDDING_SERVICE_HOST", "embeddings-api")
    EMBEDDING_SERVICE_PORT = os.getenv("EMBEDDING_SERVICE_PORT", "8080")
    EMBEDDING_MODEL = "nomic-embed-text-v1.5"  # Modelo encoder-only especializado
    EMBEDDING_DIMENSION = 768  # ⚠️ CRÍTICO: Nomic usa 768 (NO 2048, NO 4096)
    EMBEDDING_MAX_TOKENS = 2048  # Tokens máximos por chunk (servidor soporta -c 8192)
    ENABLE_EMBEDDINGS = os.getenv("ENABLE_EMBEDDINGS", "true").lower() == "true"
    
    # Document Processing
    MAX_FILE_SIZE_MB = 100  # Aumentado a 100MB para documentos grandes
    ALLOWED_EXTENSIONS = {'.pdf', '.docx', '.txt', '.csv', '.xlsx', '.md'}
    CHUNK_SIZE = 400  # ~100 tokens - Límite SEGURO para PPC64le (evita "input is too large")
    CHUNK_OVERLAP = 40  # 10% overlap para continuidad semántica
    
    # RAG Settings
    TOP_K_RESULTS = 5  # Documentos relevantes a recuperar
    MAX_CONTEXT_LENGTH = 4000  # Tokens máximos de contexto
    
    # Paths
    UPLOAD_DIR = "/app/documents"

config = Config()
