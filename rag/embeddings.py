"""
Generador de embeddings usando API externa (compatible con OpenAI)
Usa Nomic Embed Text v1.5 con llama.cpp en modo --embedding
"""
import json
import logging
from typing import List
import requests
import numpy as np
from config import config

logger = logging.getLogger(__name__)

class EmbeddingsGenerator:
    """Generador de embeddings usando API externa (Nomic vía llama.cpp)"""
    
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
        """
        Llamar a API de embeddings usando endpoint estándar OpenAI de llama.cpp
        
        IMPORTANTE: Requiere llama.cpp con flags --embedding y --pooling mean
        Usa el endpoint /v1/embeddings compatible con OpenAI
        
        Procesa en lotes pequeños (batch_size=2) para evitar "input is too large"
        """
        try:
            headers = {
                "accept": "application/json",
                "Content-Type": "application/json"
            }
            
            logger.info(f"🔄 Generando embeddings para {len(texts)} chunks usando {self.model}...")
            
            # CRÍTICO: Procesar de a 1 texto para evitar "input is too large"
            # El servidor tiene límite físico de batch processing en PPC64le
            all_embeddings = []
            
            for i, text in enumerate(texts):
                # Truncar texto si excede max_tokens (aprox 4 chars por token)
                max_chars = self.max_tokens * 4
                if len(text) > max_chars:
                    logger.warning(f"⚠️ Chunk {i+1} truncado: {len(text)} -> {max_chars} chars")
                    text = text[:max_chars]
                
                payload = {
                    "input": [text],  # Siempre array de 1 elemento
                    "model": self.model
                }
                
                try:
                    response = requests.post(
                        f"{self.endpoint}/v1/embeddings",
                        json=payload,
                        headers=headers,
                        timeout=120
                    )
                    response.raise_for_status()
                    
                    data = response.json()
                    embedding = data['data'][0]['embedding']
                    all_embeddings.append(embedding)
                    
                    if (i + 1) % 5 == 0 or (i + 1) == len(texts):
                        logger.info(f"   Procesado {i+1}/{len(texts)} chunks")
                        
                except requests.exceptions.RequestException as chunk_error:
                    logger.error(f"❌ Error en chunk {i+1}/{len(texts)}: {chunk_error}")
                    if hasattr(chunk_error, 'response') and chunk_error.response is not None:
                        logger.error(f"   Respuesta: {chunk_error.response.text}")
                    # Re-lanzar para que falle el upload completo
                    raise
            
            # Validar dimensión esperada
            if all_embeddings and len(all_embeddings[0]) != config.EMBEDDING_DIMENSION:
                logger.warning(
                    f"⚠️ Dimensión recibida: {len(all_embeddings[0])}, "
                    f"esperada: {config.EMBEDDING_DIMENSION}"
                )
            
            logger.info(f"✅ {len(all_embeddings)} embeddings generados correctamente (dim={len(all_embeddings[0])})")
            
            # Convertir a numpy arrays float32 y luego a listas
            return [np.array(e, dtype=np.float32).tolist() for e in all_embeddings]
            
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
