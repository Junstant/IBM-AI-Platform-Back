"""
Generador de embeddings usando sentence-transformers
"""
import logging
from typing import List
from sentence_transformers import SentenceTransformer
from config import config

logger = logging.getLogger(__name__)

class EmbeddingsGenerator:
    """Generador de embeddings para RAG"""
    
    def __init__(self):
        logger.info(f"Cargando modelo de embeddings: {config.EMBEDDING_MODEL}")
        self.model = SentenceTransformer(
            config.EMBEDDING_MODEL,
            device='cpu'  # Power PC usa CPU
        )
        logger.info(f"✅ Modelo cargado (dimensión: {config.EMBEDDING_DIMENSION})")
    
    def generate_embedding(self, text: str) -> List[float]:
        """Generar embedding para un texto"""
        embedding = self.model.encode(text, convert_to_numpy=True)
        return embedding.tolist()
    
    def generate_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Generar embeddings para múltiples textos (más eficiente)"""
        embeddings = self.model.encode(
            texts,
            convert_to_numpy=True,
            batch_size=32,
            show_progress_bar=True
        )
        return [emb.tolist() for emb in embeddings]

# Instancia global (singleton)
_embeddings_generator = None

def get_embeddings_generator() -> EmbeddingsGenerator:
    """Obtener instancia del generador de embeddings"""
    global _embeddings_generator
    if _embeddings_generator is None:
        _embeddings_generator = EmbeddingsGenerator()
    return _embeddings_generator
