# 🧠 RAG API v2.0 - Retrieval-Augmented Generation with Milvus

Sistema RAG de alto rendimiento con **Milvus** como base de datos vectorial.

## ✨ Características

- 🚀 **Milvus Vector Database**: Base de datos vectorial de nivel producción
- ⚡ **HNSW Index**: Búsqueda ultra rápida (< 10ms) con índice HNSW
- 🎯 **Embeddings Vectoriales**: Búsqueda semántica de alta precisión
- 📊 **Escalabilidad**: Soporta billones de vectores
- 📄 **Multi-formato**: PDF, DOCX, TXT, CSV, XLSX, MD
- 🤖 **LLM Integration**: Respuestas contextualizadas con Gemma/Mistral
- 🔧 **API REST Completa**: FastAPI con documentación Swagger
- 💻 **PowerPC Compatible**: Arquitectura optimizada para IBM Power

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         RAG WORKFLOW                                │
└─────────────────────────────────────────────────────────────────────┘

1. INDEXING (Upload):
   Usuario → PDF/DOCX → [Text Extraction] → [Chunking] → [Embeddings API]
                                                                ↓
                                              [Milvus: Store Vectors + HNSW Index]

2. RETRIEVAL (Query):
   Usuario → Query → [Query Embedding] → [Milvus Vector Search]
                                                ↓
                                          [Top-K Similar Chunks]
                                                ↓
                                          [LLM Context] → Respuesta

Technology Stack:
- Vector DB: Milvus v2.3 (etcd + MinIO)
- Index: HNSW (Hierarchical Navigable Small World)
- Embeddings: nomic-embed-text (768D)
- LLM: Gemma-2B/4B/12B, Mistral-7B, DeepSeek-8B
```

## 📡 Endpoints

### 📤 Upload Document
```bash
curl -X POST http://localhost:8004/upload \
  -F "file=@documento.pdf"
```

### 🔍 Query Documents (RAG)
```bash
curl -X POST http://localhost:8004/query \
  -H "Content-Type: application/json" \
  -d '{"query": "¿Qué es RAG?", "top_k": 5}'
```

### 📚 List Documents
```bash
curl http://localhost:8004/documents
```

### 🗑️ Delete Document
```bash
curl -X DELETE http://localhost:8004/documents/1
```

### 📊 Stats
```bash
curl http://localhost:8004/stats
```

## 🚀 Uso desde Python

```python
import requests

# 1. Subir documento
with open("mi_documento.pdf", "rb") as f:
    response = requests.post(
        "http://localhost:8004/upload",
        files={"file": f}
    )
    doc_info = response.json()
    print(f"✅ Documento subido: ID {doc_info['id']}, {doc_info['total_chunks']} chunks")

# 2. Hacer preguntas (RAG)
response = requests.post(
    "http://localhost:8004/query",
    json={
        "query": "¿Cuáles son los puntos principales del documento?",
        "top_k": 3
    }
)

result = response.json()
print(f"\n🤖 Respuesta: {result['answer']}")
print(f"\n📚 Fuentes ({len(result['sources'])}):")
for i, source in enumerate(result['sources'], 1):
    print(f"  {i}. {source['filename']} (similarity: {source['similarity']:.2f})")
```

## 🔧 Configuración

Variables de entorno en `.env`:

```bash
# Milvus Vector Database
MILVUS_HOST=milvus-standalone
MILVUS_PORT=19530

# Embeddings Service
EMBEDDING_SERVICE_HOST=gemma-2b
EMBEDDING_SERVICE_PORT=8080
ENABLE_EMBEDDINGS=true

# LLM Service
LLM_HOST=gemma-2b
LLM_PORT=8080
```

## 🚀 Despliegue

```bash
# 1. Construir y levantar servicios
docker compose up -d milvus-standalone rag-api

# 2. Verificar estado
docker ps | grep milvus
docker logs -f rag-api

# 3. Probar API
curl http://localhost:8004/health

# 4. Acceder a documentación
open http://localhost:8004/docs
```

## 📊 Stack Tecnológico

| Componente | Tecnología | Propósito |
|------------|------------|-----------|
| **Vector DB** | Milvus v2.3 | Almacenamiento y búsqueda vectorial |
| **Metadata Store** | etcd | Coordinación y metadata Milvus |
| **Object Storage** | MinIO | Almacenamiento de datos Milvus |
| **Embeddings** | nomic-embed-text (768D) | Vectorización de texto |
| **LLM** | Gemma-2B/4B/12B | Generación de respuestas |
| **Index** | HNSW | Búsqueda aproximada ultra rápida |
| **Metric** | Cosine Similarity | Medida de similitud semántica |

## 🎯 Performance

- **Latencia**: < 10ms para búsquedas vectoriales
- **Escalabilidad**: Billones de vectores
- **Precisión**: 95%+ recall con HNSW
- **Throughput**: 10K+ QPS

## 🎯 Casos de Uso

1. **Chatbot Corporativo**: Responde preguntas sobre documentación interna
2. **Análisis de Documentos**: Extrae insights de PDFs y reports
3. **Asistente de Conocimiento**: Base de conocimiento inteligente
4. **Research Assistant**: Búsqueda semántica en papers y artículos

## 📖 Documentación Interactiva

Accede a Swagger UI: `http://localhost:8004/docs`
