"""
Configuración del servicio RAG
"""
import os
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv(dotenv_path=os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env'))

class Config:
    """Configuración centralizada para RAG"""
    
    # PostgreSQL (usa el existente)
    DB_HOST = os.getenv("DB_HOST", "postgres")
    DB_PORT = os.getenv("DB_PORT", "5432")
    DB_USER = os.getenv("DB_USER", "postgres")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "root")
    DB_NAME = "ai_platform_rag"  # Nueva base de datos para RAG
    
    # LLM Configuration (usa Gemma-2B por defecto)
    LLM_HOST = os.getenv("LLM_HOST", "gemma-2b")
    LLM_PORT = os.getenv("LLM_PORT", "8080")
    
    # Embeddings Model
    EMBEDDING_MODEL = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    EMBEDDING_DIMENSION = 384  # Dimensión del modelo elegido
    
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
    
    @classmethod
    def get_database_url(cls):
        """Construir URL de conexión a PostgreSQL"""
        return f"postgresql://{cls.DB_USER}:{cls.DB_PASSWORD}@{cls.DB_HOST}:{cls.DB_PORT}/{cls.DB_NAME}"

config = Config()
