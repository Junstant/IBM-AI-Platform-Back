"""
Cliente para comunicarse con los modelos LLM (usa llama.cpp)
"""
import httpx
import logging
from typing import Dict, List
from config import config

logger = logging.getLogger(__name__)

class LLMClient:
    """Cliente para interactuar con modelos LLM"""
    
    def __init__(self, host: str = None, port: int = None):
        self.host = host or config.LLM_HOST
        self.port = port or config.LLM_PORT
        self.base_url = f"http://{self.host}:{self.port}"
        logger.info(f"LLM Client inicializado: {self.base_url}")
    
    async def generate(self, prompt: str, max_tokens: int = 1000, 
                      temperature: float = 0.3) -> str:
        """Generar respuesta del LLM"""
        try:
            async with httpx.AsyncClient(timeout=300) as client:
                response = await client.post(
                    f"{self.base_url}/completion",
                    json={
                        "prompt": prompt,
                        "n_predict": max_tokens,
                        "temperature": temperature,
                        "stop": ["</s>", "Human:", "User:"],
                        "stream": False
                    }
                )
                
                if response.status_code != 200:
                    logger.error(f"LLM error: {response.status_code} - {response.text}")
                    raise Exception(f"LLM returned status {response.status_code}")
                
                data = response.json()
                return data.get("content", "").strip()
                
        except Exception as e:
            logger.error(f"Error generando respuesta: {e}")
            raise
    
    async def generate_rag_response(self, question: str, context: str) -> str:
        """Generar respuesta usando contexto de documentos"""
        prompt = f"""Eres un asistente AI especializado en responder preguntas basándote en documentos.

Contexto de documentos relevantes:
{context}

Pregunta del usuario: {question}

Instrucciones:
- Responde SOLO basándote en la información del contexto proporcionado
- Si la respuesta no está en el contexto, indica "No encuentro esa información en los documentos"
- Sé claro, conciso y directo
- Cita los documentos cuando sea relevante

Respuesta:"""

        return await self.generate(prompt, max_tokens=800, temperature=0.2)

# Instancia global
_llm_client = None

def get_llm_client() -> LLMClient:
    """Obtener instancia del cliente LLM"""
    global _llm_client
    if _llm_client is None:
        _llm_client = LLMClient()
    return _llm_client
