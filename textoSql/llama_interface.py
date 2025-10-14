import json
import httpx
import asyncio
import os
from typing import List, Dict, Any

class LlamaInterface:
    """Minimal interface for LLM Runtime API."""

    def __init__(self, host=None, port=None):
        """Initialize the LLM Runtime interface with host and port."""
        # CORREGIR ESTO - no usar puerto por defecto incorrecto
        self.host = host or "127.0.0.1"  # ← CAMBIAR de 150.230.11.162 a localhost
        self.port = port or "8086"  # ← OK, pero debe venir del config
        print(f"DEBUG: LlamaInterface inicializada - {self.host}:{self.port}")

    async def get_llama_response_async(self, prompt):
        """Get a response from the LLM Runtime API asynchronously."""
        json_data = {
            'prompt': prompt,
            'temperature': 0.1,
            'repetition_penalty': 1.18,
            'n_predict': 500,
            'stream': False,
        }

        try:
            print(f"DEBUG: Conectando a {self.host}:{self.port}")
            async with httpx.AsyncClient(timeout=300) as client:
                
                response = await client.post(
                    f'http://{self.host}:{self.port}/completion', 
                    json=json_data
                )
                
                print(f"DEBUG: Status code: {response.status_code}")
                
                if response.status_code != 200:
                    print(f"DEBUG: Error response: {response.text}")
                    raise Exception(f"LLM returned status {response.status_code}: {response.text}")
                
                # Parsear respuesta JSON directa (no streaming)
                data = response.json()
                print(f"DEBUG: Raw response keys: {list(data.keys())}")
                
                # Extraer el contenido
                content = data.get('content', '')
                print(f"DEBUG: Extracted content: {content[:200]}...")
                
                return content
                
        except Exception as e:
            print(f"DEBUG: Error en LLM request: {e}")
            raise Exception(f"Error connecting to LLM {self.host}:{self.port}: {e}")

    async def explain_results_async(self, question: str, sql_query: str, results: List[Dict[str, Any]], error: str = None) -> str:
        """Explain the results in natural language."""
        if error:
            prompt = f"""
Question: {question}

SQL Query: {sql_query}

Error: {error}

Please explain what went wrong with this query in simple terms and suggest how to fix it.
Be specific about any syntax errors or invalid references.
"""
        else:
            # Convert results to a string - limit to 10 results to manage context length
            results_str = str(results[:10]) if results else "No results found"

            prompt = f"""
Question: {question}

SQL Query: {sql_query}

Results: {results_str}

Provide a natural language explanation of these results that directly answers the original question.
Keep your explanation clear, concise, and focused on what the user actually asked.
If the results contain a lot of data, summarize the key points.
"""

        explanation = await self.get_llama_response_async(prompt)
        return explanation.strip()