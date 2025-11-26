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
        """Llamar a la API de embeddings con fallback a embedding endpoint"""
        try:
            # Intentar primero con el endpoint estándar de embeddings
            payload = {
                "content": texts if len(texts) > 1 else texts[0],
            }
            headers = {
                "accept": "application/json",
                "Content-Type": "application/json"
            }
            
            # Usar el endpoint /embedding de llama.cpp
            response = requests.post(
                f"{self.endpoint}/embedding",
                data=json.dumps(payload),
                headers=headers,
                timeout=60
            )
            response.raise_for_status()
            
            r = response.json()
            
            # Si es una lista de textos, el resultado es un solo embedding promedio
            # Para múltiples textos, debemos hacer llamadas individuales
            if len(texts) == 1:
                embedding = r.get('embedding', [])
                return [np.array(embedding, dtype=np.float32).tolist()]
            else:
                # Procesar cada texto individualmente
                embeddings = []
                for text in texts:
                    single_payload = {"content": text}
                    single_response = requests.post(
                        f"{self.endpoint}/embedding",
                        data=json.dumps(single_payload),
                        headers=headers,
                        timeout=60
                    )
                    single_response.raise_for_status()
                    single_data = single_response.json()
                    embedding = single_data.get('embedding', [])
                    embeddings.append(np.array(embedding, dtype=np.float32).tolist())
                return embeddings
            
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
