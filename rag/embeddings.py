""""""

Generador de embeddings usando API externa (compatible con OpenAI)Generador de embeddings usando API externa (compatible con OpenAI)

Usa Nomic Embed Text v1.5 con llama.cpp en modo --embedding"""

"""import json

import jsonimport logging

import loggingfrom typing import List

from typing import Listimport requests

import requestsimport numpy as np

import numpy as npfrom config import config

from config import config

logger = logging.getLogger(__name__)

logger = logging.getLogger(__name__)

class EmbeddingsGenerator:

class EmbeddingsGenerator:    """Generador de embeddings usando API externa"""

    """Generador de embeddings usando API externa (Nomic vía llama.cpp)"""    

        def __init__(self):

    def __init__(self):        self.endpoint = f"http://{config.EMBEDDING_SERVICE_HOST}:{config.EMBEDDING_SERVICE_PORT}"

        self.endpoint = f"http://{config.EMBEDDING_SERVICE_HOST}:{config.EMBEDDING_SERVICE_PORT}"        self.model = config.EMBEDDING_MODEL

        self.model = config.EMBEDDING_MODEL        self.max_tokens = config.EMBEDDING_MAX_TOKENS

        self.max_tokens = config.EMBEDDING_MAX_TOKENS        logger.info(f"🔗 Embeddings API: {self.endpoint}")

        logger.info(f"🔗 Embeddings API: {self.endpoint}")        logger.info(f"📦 Modelo: {self.model} (dim: {config.EMBEDDING_DIMENSION})")

        logger.info(f"📦 Modelo: {self.model} (dim: {config.EMBEDDING_DIMENSION})")    

        def generate_embedding(self, text: str) -> List[float]:

    def generate_embedding(self, text: str) -> List[float]:        """Generar embedding para un texto"""

        """Generar embedding para un texto"""        embeddings = self._post_embedding([text])

        embeddings = self._post_embedding([text])        return embeddings[0] if embeddings else []

        return embeddings[0] if embeddings else []    

        def generate_embeddings_batch(self, texts: List[str]) -> List[List[float]]:

    def generate_embeddings_batch(self, texts: List[str]) -> List[List[float]]:        """Generar embeddings para múltiples textos (más eficiente)"""

        """Generar embeddings para múltiples textos (más eficiente)"""        return self._post_embedding(texts)

        return self._post_embedding(texts)    

        def _post_embedding(self, texts: List[str]) -> List[List[float]]:

    def _post_embedding(self, texts: List[str]) -> List[List[float]]:        """Llamar a API de embeddings usando endpoint estándar OpenAI de llama.cpp"""

        """        try:

        Llamar a API de embeddings usando endpoint estándar OpenAI de llama.cpp            # Usar endpoint OpenAI-compatible de llama.cpp con --embedding activado

                    payload = {

        IMPORTANTE: Requiere llama.cpp con flags --embedding y --pooling mean                "input": texts,  # Soporta tanto lista como string

        Usa el endpoint /v1/embeddings compatible con OpenAI                "model": self.model

        """            }

        try:            

            # Payload compatible con OpenAI embeddings API            headers = {

            payload = {                "accept": "application/json",

                "input": texts,  # Soporta tanto lista como string individual                "Content-Type": "application/json"

                "model": self.model            }

            }            

                        logger.info(f"🔄 Generando embeddings para {len(texts)} chunks usando {self.model}...")

            headers = {            

                "accept": "application/json",            response = requests.post(

                "Content-Type": "application/json"                f"{self.endpoint}/v1/embeddings",

            }                json=payload,

                            headers=headers,

            logger.info(f"🔄 Generando embeddings para {len(texts)} chunks usando {self.model}...")                timeout=120

                        )

            response = requests.post(            response.raise_for_status()

                f"{self.endpoint}/v1/embeddings",            

                json=payload,            data = response.json()

                headers=headers,            embeddings = [item['embedding'] for item in data['data']]

                timeout=120            

            )            # Validar dimensión esperada

            response.raise_for_status()            if embeddings and len(embeddings[0]) != config.EMBEDDING_DIMENSION:

                            logger.warning(

            data = response.json()                    f"⚠️ Dimensión recibida: {len(embeddings[0])}, "

                                f"esperada: {config.EMBEDDING_DIMENSION}"

            # Extraer embeddings del formato OpenAI                )

            # Formato esperado: {"data": [{"embedding": [...], "index": 0}, ...]}            

            embeddings = [item['embedding'] for item in data['data']]            logger.info(f"✅ {len(embeddings)} embeddings generados correctamente")

                        

            # Validar dimensión esperada            # Convertir a numpy arrays float32 y luego a listas

            if embeddings and len(embeddings[0]) != config.EMBEDDING_DIMENSION:            return [np.array(e, dtype=np.float32).tolist() for e in embeddings]

                logger.warning(                    

                    f"⚠️ Dimensión recibida: {len(embeddings[0])}, "                    response = requests.post(

                    f"esperada: {config.EMBEDDING_DIMENSION}"                        f"{self.endpoint}/embedding",

                )                        data=json.dumps(payload),

                                    headers=headers,

            logger.info(f"✅ {len(embeddings)} embeddings generados correctamente (dim={len(embeddings[0])})")                        timeout=120  # Mayor timeout para textos largos

                                )

            # Convertir a numpy arrays float32 y luego a listas                    response.raise_for_status()

            return [np.array(e, dtype=np.float32).tolist() for e in embeddings]                    

                                data = response.json()

        except requests.exceptions.RequestException as e:                    embedding = data.get('embedding', [])

            logger.error(f"❌ Error llamando API de embeddings: {e}")                    

            if hasattr(e, 'response') and e.response is not None:                    if embedding and len(embedding) > 0:

                logger.error(f"   Respuesta: {e.response.text}")                        embeddings.append(np.array(embedding, dtype=np.float32).tolist())

            raise                        if i % 5 == 0:

        except Exception as e:                            logger.info(f"   ✓ Procesados {i}/{len(texts)} chunks")

            logger.error(f"❌ Error procesando embeddings: {e}")                    else:

            raise                        logger.warning(f"⚠️ Embedding vacío para chunk {i}, usando ceros")

                        # Crear embedding de ceros como fallback

# Instancia global (singleton)                        embeddings.append([0.0] * config.EMBEDDING_DIMENSION)

_embeddings_generator = None                        

                except Exception as e:

def get_embeddings_generator() -> EmbeddingsGenerator:                    logger.warning(f"⚠️ Error en chunk {i}/{len(texts)}: {e}")

    """Obtener instancia del generador de embeddings"""                    # Continuar con embedding de ceros en caso de error

    global _embeddings_generator                    embeddings.append([0.0] * config.EMBEDDING_DIMENSION)

    if _embeddings_generator is None:                    

        _embeddings_generator = EmbeddingsGenerator()            logger.info(f"✅ Embeddings generados: {len(embeddings)}/{len(texts)}")

    return _embeddings_generator            return embeddings

            
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
