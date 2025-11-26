"""
Generador de embeddings usando API externa (compatible con OpenAI)
"""
import json
import logging
from typing import List
import requests
import numpy as np
from config import config

logger = logging.getLogger(__name__)

class EmbeddingsGenerator:
    """Generador de embeddings usando API externa"""
    
    def __init__(self):
        self.endpoint = f"http://{config.EMBEDDING_SERVICE_HOST}:{config.EMBEDDING_SERVICE_PORT}"
        self.model = config.EMBEDDING_MODEL
        self.max_tokens = config.EMBEDDING_MAX_TOKENS
        logger.info(f"🔗 Embeddings API: {self.endpoint}")
        logger.info(f"📦 Modelo: {self.model} (dim: {config.EMBEDDING_DIMENSION})")
    
    def generate_embedding(self, text: str) -> List[float]:
        """Generar embedding para un texto"""
        embeddings = self._post_embedding([text])
        return embeddings[0] if embeddings else []
    
    def generate_embeddings_batch(self, texts: List[str]) -> List[List[float]]:
        """Generar embeddings para múltiples textos (más eficiente)"""
        return self._post_embedding(texts)
    
    def _post_embedding(self, texts: List[str]) -> List[List[float]]:
        """Llamar a la API de embeddings"""
        try:
            payload = {
                "input": texts,
                "model": self.model,
                "truncate_prompt_tokens": self.max_tokens - 1,
            }
            headers = {
                "accept": "application/json",
                "Content-Type": "application/json"
            }
            
            response = requests.post(
                f"{self.endpoint}/v1/embeddings",
                data=json.dumps(payload),
                headers=headers,
                timeout=60
            )
            response.raise_for_status()
            
            r = response.json()
            embeddings = [data['embedding'] for data in r['data']]
            
            # Convertir a numpy arrays float32 y luego a listas
            return [np.array(embed, dtype=np.float32).tolist() for embed in embeddings]
            
        except requests.exceptions.RequestException as e:
            logger.error(f"❌ Error llamando API de embeddings: {e}")
            if hasattr(e, 'response') and e.response is not None:
                logger.error(f"   Respuesta: {e.response.text}")
            raise
        except Exception as e:
            logger.error(f"❌ Error procesando embeddings: {e}")
            raise

# Instancia global (singleton)
_embeddings_generator = None

def get_embeddings_generator() -> EmbeddingsGenerator:
    """Obtener instancia del generador de embeddings"""
    global _embeddings_generator
    if _embeddings_generator is None:
        _embeddings_generator = EmbeddingsGenerator()
    return _embeddings_generator
