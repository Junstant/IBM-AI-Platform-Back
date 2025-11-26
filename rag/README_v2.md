# 🧠 RAG API v2.0 - Retrieval-Augmented Generation

Sistema completo de RAG con embeddings vectoriales y respuestas inteligentes generadas por LLM.

## ✨ Características

- ✅ **Embeddings Vectoriales**: Búsqueda semántica usando API externa de embeddings
- ✅ **Vector Database**: pgvector para búsqueda vectorial eficiente (HNSW index)
- ✅ **Multi-formato**: PDF, DOCX, TXT, CSV, XLSX
- ✅ **LLM Integration**: Respuestas contextualizadas y naturales
- ✅ **API REST Completa**: FastAPI con documentación interactiva
- ✅ **PowerPC Compatible**: Usa servicios externos en lugar de librerías ML locales

## 🏗️ Arquitectura

```
Usuario → Upload PDF → [Extracción de Texto] → [Chunking] → [Embeddings API]
                                                                    ↓
                                                            [PostgreSQL + pgvector]
                                                                    ↓
Usuario → Query → [Query Embedding] → [Vector Search] → [Top-K Chunks] → [LLM] → Respuesta
```

### 💻 **Soporte PowerPC (ppc64le)**

✅ **pgvector está oficialmente disponible para PowerPC**
- Fedora 43 ppc64le: `dnf install pgvector`
- Debian/Ubuntu ppc64el: `apt-get install postgresql-17-pgvector`
- Ver [`PGVECTOR_PPC64LE_INSTALL.md`](../PGVECTOR_PPC64LE_INSTALL.md) para detalles

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
# Embeddings Service
EMBEDDING_SERVICE_HOST=gemma-2b
EMBEDDING_SERVICE_PORT=8080
ENABLE_EMBEDDINGS=true

# LLM Service
LLM_HOST=gemma-2b
LLM_PORT=8080

# Database
DB_HOST=postgres
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=root
```

## 📊 Modelos

- **Embeddings**: `nomic-embed-text` (768 dimensiones)
- **LLM**: Gemma-2B (configurable)
- **Vector DB**: PostgreSQL + pgvector 0.5.1

## 🎯 Casos de Uso

1. **Chatbot Corporativo**: Responde preguntas sobre documentación interna
2. **Análisis de Documentos**: Extrae insights de PDFs y reports
3. **Asistente de Conocimiento**: Base de conocimiento inteligente
4. **Research Assistant**: Búsqueda semántica en papers y artículos

## 📖 Documentación Interactiva

Accede a Swagger UI: `http://localhost:8004/docs`
