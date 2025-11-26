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
        """Llamar a la API de embeddings con procesamiento por lotes optimizado"""
        try:
            headers = {
                "accept": "application/json",
                "Content-Type": "application/json"
            }
            
            # Procesar en lotes más pequeños para evitar timeouts
            batch_size = 1  # Procesar de a uno para mayor estabilidad
            embeddings = []
            
            logger.info(f"🔄 Generando embeddings para {len(texts)} chunks...")
            
            for i, text in enumerate(texts, 1):
                try:
                    # Truncar texto si es muy largo (máximo ~2000 caracteres por chunk)
                    truncated_text = text[:2000] if len(text) > 2000 else text
                    
                    payload = {"content": truncated_text}
                    
                    response = requests.post(
                        f"{self.endpoint}/embedding",
                        data=json.dumps(payload),
                        headers=headers,
                        timeout=120  # Mayor timeout para textos largos
                    )
                    response.raise_for_status()
                    
                    data = response.json()
                    embedding = data.get('embedding', [])
                    
                    if embedding and len(embedding) > 0:
                        embeddings.append(np.array(embedding, dtype=np.float32).tolist())
                        if i % 5 == 0:
                            logger.info(f"   ✓ Procesados {i}/{len(texts)} chunks")
                    else:
                        logger.warning(f"⚠️ Embedding vacío para chunk {i}, usando ceros")
                        # Crear embedding de ceros como fallback
                        embeddings.append([0.0] * config.EMBEDDING_DIMENSION)
                        
                except Exception as e:
                    logger.warning(f"⚠️ Error en chunk {i}/{len(texts)}: {e}")
                    # Continuar con embedding de ceros en caso de error
                    embeddings.append([0.0] * config.EMBEDDING_DIMENSION)
                    
            logger.info(f"✅ Embeddings generados: {len(embeddings)}/{len(texts)}")
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
