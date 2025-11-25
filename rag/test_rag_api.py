#!/usr/bin/env python3
"""
Script de prueba para RAG API
"""
import requests
import json
import time
from pathlib import Path

RAG_API_URL = "http://localhost:8004"

def test_health():
    """Probar health check"""
    print("\n🏥 Probando health check...")
    try:
        response = requests.get(f"{RAG_API_URL}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"✅ RAG API está saludable")
            print(f"   Documentos: {data.get('documents', 0)}")
            print(f"   Modelo: {data.get('embeddings_model', 'N/A')}")
            return True
        else:
            print(f"❌ Health check falló: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_stats():
    """Probar estadísticas"""
    print("\n📊 Obteniendo estadísticas...")
    try:
        response = requests.get(f"{RAG_API_URL}/stats", timeout=10)
        if response.status_code == 200:
            stats = response.json()
            print(f"✅ Estadísticas:")
            print(f"   Total documentos: {stats['total_documents']}")
            print(f"   Total chunks: {stats['total_chunks']}")
            print(f"   Tamaño total: {stats['total_size_mb']} MB")
            print(f"   Modelo: {stats['embedding_model']}")
            print(f"   Dimensión: {stats['embedding_dimension']}")
            return True
        else:
            print(f"❌ Stats falló: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_upload_text():
    """Probar upload de documento de texto"""
    print("\n📤 Probando upload de documento...")
    
    # Crear documento de prueba
    test_content = """
# Guía de RAG (Retrieval-Augmented Generation)

## ¿Qué es RAG?

RAG es una técnica que combina la búsqueda de información con la generación de texto.
Permite a los modelos de lenguaje acceder a información actualizada y específica.

## Componentes principales

1. **Retrieval (Recuperación)**: Busca información relevante en documentos
2. **Augmentation (Aumento)**: Agrega contexto al prompt
3. **Generation (Generación)**: El LLM genera una respuesta basada en el contexto

## Ventajas de RAG

- Acceso a información actualizada
- Respuestas basadas en fuentes confiables
- Reducción de alucinaciones del modelo
- Escalable a grandes cantidades de documentos

## Implementación

Nuestro sistema RAG utiliza:
- **pgvector**: Almacenamiento de embeddings vectoriales
- **sentence-transformers**: Generación de embeddings
- **PostgreSQL**: Base de datos relacional
- **Gemma-2B**: Modelo de lenguaje para generación
"""
    
    try:
        files = {
            "file": ("test_rag_guide.txt", test_content.encode('utf-8'), "text/plain")
        }
        
        response = requests.post(
            f"{RAG_API_URL}/documents/upload",
            files=files,
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Documento subido exitosamente")
            print(f"   ID: {data['document_id']}")
            print(f"   Chunks: {data['chunks_created']}")
            print(f"   Tamaño: {data['file_size']} bytes")
            return data['document_id']
        else:
            print(f"❌ Upload falló: {response.status_code}")
            print(f"   Respuesta: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return None

def test_query(question: str):
    """Probar consulta RAG"""
    print(f"\n💬 Consultando: '{question}'...")
    
    try:
        response = requests.post(
            f"{RAG_API_URL}/query",
            json={
                "question": question,
                "top_k": 3
            },
            timeout=120
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"\n✅ Respuesta generada:")
            print(f"\n{data['answer']}\n")
            print(f"📚 Fuentes ({data['num_sources']}):")
            for i, source in enumerate(data['sources'], 1):
                print(f"   {i}. {source['filename']} (similitud: {source['similarity']:.2f})")
                print(f"      Preview: {source['preview'][:100]}...")
            return True
        else:
            print(f"❌ Query falló: {response.status_code}")
            print(f"   Respuesta: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_list_documents():
    """Probar listado de documentos"""
    print("\n📋 Listando documentos...")
    
    try:
        response = requests.get(f"{RAG_API_URL}/documents", timeout=10)
        
        if response.status_code == 200:
            docs = response.json()
            print(f"✅ Total documentos: {len(docs)}")
            for doc in docs:
                print(f"   - ID {doc['id']}: {doc['filename']} ({doc['total_chunks']} chunks)")
            return docs
        else:
            print(f"❌ List falló: {response.status_code}")
            return []
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return []

def main():
    """Ejecutar todas las pruebas"""
    print("=" * 60)
    print("🧪 PRUEBAS DE RAG API")
    print("=" * 60)
    
    # 1. Health check
    if not test_health():
        print("\n❌ RAG API no está disponible. Verifica que esté corriendo.")
        return
    
    # Esperar un poco para asegurar que esté completamente iniciado
    time.sleep(2)
    
    # 2. Estadísticas iniciales
    test_stats()
    
    # 3. Upload de documento
    doc_id = test_upload_text()
    if not doc_id:
        print("\n⚠️ No se pudo subir documento, omitiendo pruebas de query")
    else:
        # Esperar procesamiento
        print("\n⏳ Esperando que se procesen los embeddings...")
        time.sleep(3)
        
        # 4. Pruebas de queries
        test_query("¿Qué es RAG?")
        time.sleep(2)
        
        test_query("¿Cuáles son las ventajas de usar RAG?")
        time.sleep(2)
        
        test_query("¿Qué tecnologías usa esta implementación?")
    
    # 5. Listar documentos
    test_list_documents()
    
    # 6. Estadísticas finales
    test_stats()
    
    print("\n" + "=" * 60)
    print("✅ PRUEBAS COMPLETADAS")
    print("=" * 60)
    print("\n💡 Puedes probar más consultas en: http://localhost:8004/docs")

if __name__ == "__main__":
    main()
