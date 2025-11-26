# 📋 Requerimientos Frontend para RAG API v2.0 con Milvus

## 🎯 Endpoints Disponibles

### Base URL
```
http://localhost:8004
```

---

## 📡 **API Endpoints**

### 1. **GET `/models`** - Obtener Modelos Disponibles

**Descripción**: Lista todos los modelos de embeddings y LLM disponibles.

**Request**:
```javascript
GET /models
```

**Response**:
```json
{
  "embedding_models": [
    {
      "id": "nomic-embed-text",
      "name": "Nomic Embed Text",
      "description": "Modelo de embeddings optimizado para búsqueda semántica",
      "dimensions": 768
    }
  ],
  "llm_models": [
    {
      "id": "gemma-2b",
      "name": "Gemma 2B",
      "description": ""
    },
    {
      "id": "gemma-4b",
      "name": "Gemma 4B",
      "description": ""
    }
  ],
  "current": {
    "embedding_model": "gemma-2b",
    "llm_model": "gemma-2b"
  }
}
```

**Código React**:
```javascript
const fetchModels = async () => {
  const response = await fetch('/api/rag/models');
  const data = await response.json();
  setAvailableEmbeddingModels(data.embedding_models);
  setAvailableLlmModels(data.llm_models);
  setCurrentModels(data.current);
};
```

---

### 2. **GET `/health`** - Health Check

**Descripción**: Verificar estado del servicio RAG y Milvus.

**Request**:
```javascript
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "service": "RAG API v2 with Milvus",
  "version": "2.0.0",
  "features": {
    "vector_database": "Milvus",
    "embeddings": "enabled",
    "llm": "enabled",
    "vector_search": "HNSW (ultra-fast semantic search)"
  },
  "database": "Milvus connected",
  "milvus_host": "milvus-standalone:19530",
  "embedding_model": "gemma-2b",
  "embedding_dimension": 768,
  "llm_model": "gemma-2b"
}
```

---

### 3. **POST `/upload`** - Subir Documento

**Descripción**: Sube un documento y genera embeddings automáticamente.

**Request**:
```javascript
POST /upload
Content-Type: multipart/form-data

FormData:
  - file: File (REQUERIDO)
  - embedding_model: string (OPCIONAL) - ID del modelo de embeddings
  - llm_model: string (OPCIONAL) - ID del modelo LLM
```

**Ejemplo React**:
```javascript
const uploadDocument = async (file, embeddingModel, llmModel) => {
  const formData = new FormData();
  formData.append('file', file);
  
  // Opcional: especificar modelos
  if (embeddingModel) formData.append('embedding_model', embeddingModel);
  if (llmModel) formData.append('llm_model', llmModel);
  
  const response = await fetch('/api/rag/upload', {
    method: 'POST',
    body: formData
  });
  
  return await response.json();
};
```

**Response**:
```json
{
  "id": 123456789,
  "filename": "documento.pdf",
  "content_type": "application/pdf",
  "file_size": 245760,
  "total_chunks": 14,
  "uploaded_at": "2025-11-26T16:30:00"
}
```

**Formatos Soportados**:
- PDF (`.pdf`)
- Word (`.docx`)
- Texto (`.txt`)
- CSV (`.csv`)
- Excel (`.xlsx`)
- Markdown (`.md`)

---

### 4. **POST `/query`** - Consulta RAG

**Descripción**: Realiza búsqueda semántica y genera respuesta con LLM.

**Request**:
```javascript
POST /query
Content-Type: application/json

{
  "query": "¿Cuál es el tema principal del documento?",
  "top_k": 5  // Número de chunks relevantes (1-20)
}
```

**Ejemplo React**:
```javascript
const queryRAG = async (question, topK = 5) => {
  const response = await fetch('/api/rag/query', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      query: question,
      top_k: topK
    })
  });
  
  return await response.json();
};
```

**Response**:
```json
{
  "answer": "El documento trata sobre arquitectura de software...",
  "sources": [
    {
      "filename": "documento.pdf",
      "content": "La arquitectura de software es...",
      "similarity": 0.89,
      "chunk_index": 3
    },
    {
      "filename": "documento.pdf",
      "content": "Los principios fundamentales incluyen...",
      "similarity": 0.82,
      "chunk_index": 7
    }
  ],
  "query": "¿Cuál es el tema principal del documento?"
}
```

**Campos**:
- `answer`: Respuesta generada por el LLM
- `sources`: Array de chunks relevantes encontrados
  - `similarity`: Score de similitud (0.0 - 1.0, mayor es más relevante)
  - `chunk_index`: Índice del chunk en el documento original

---

### 5. **GET `/documents`** - Listar Documentos

**Descripción**: Obtiene lista de todos los documentos subidos.

**Request**:
```javascript
GET /documents
```

**Response**:
```json
[
  {
    "id": 123456789,
    "filename": "documento1.pdf",
    "content_type": "application/pdf",
    "file_size": 245760,
    "total_chunks": 14,
    "uploaded_at": "2025-11-26T16:30:00"
  },
  {
    "id": 987654321,
    "filename": "documento2.docx",
    "content_type": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "file_size": 102400,
    "total_chunks": 8,
    "uploaded_at": "2025-11-26T15:20:00"
  }
]
```

---

### 6. **DELETE `/documents/{id}`** - Eliminar Documento

**Descripción**: Elimina un documento y todos sus chunks de Milvus.

**Request**:
```javascript
DELETE /documents/123456789
```

**Response**:
```json
{
  "message": "Documento 123456789 eliminado correctamente"
}
```

**Ejemplo React**:
```javascript
const deleteDocument = async (docId) => {
  const response = await fetch(`/api/rag/documents/${docId}`, {
    method: 'DELETE'
  });
  
  if (response.ok) {
    console.log('Documento eliminado');
  }
};
```

---

### 7. **GET `/stats`** - Estadísticas

**Descripción**: Obtiene estadísticas del sistema Milvus.

**Request**:
```javascript
GET /stats
```

**Response**:
```json
{
  "total_documents": 5,
  "total_chunks": 73,
  "total_size_bytes": 1024000
}
```

---

## 🎨 **Componente React Ejemplo**

```javascript
import React, { useState, useEffect } from 'react';

const RAGDocumentAnalysis = () => {
  const [models, setModels] = useState({ embedding: [], llm: [] });
  const [selectedEmbedding, setSelectedEmbedding] = useState('');
  const [selectedLLM, setSelectedLLM] = useState('');
  const [documents, setDocuments] = useState([]);
  const [query, setQuery] = useState('');
  const [result, setResult] = useState(null);
  const [isLoading, setIsLoading] = useState(false);

  // Cargar modelos disponibles
  useEffect(() => {
    fetchModels();
    fetchDocuments();
  }, []);

  const fetchModels = async () => {
    const response = await fetch('/api/rag/models');
    const data = await response.json();
    setModels({
      embedding: data.embedding_models,
      llm: data.llm_models
    });
    setSelectedEmbedding(data.current.embedding_model);
    setSelectedLLM(data.current.llm_model);
  };

  const fetchDocuments = async () => {
    const response = await fetch('/api/rag/documents');
    const data = await response.json();
    setDocuments(data);
  };

  const handleUpload = async (file) => {
    setIsLoading(true);
    const formData = new FormData();
    formData.append('file', file);
    formData.append('embedding_model', selectedEmbedding);
    formData.append('llm_model', selectedLLM);

    try {
      const response = await fetch('/api/rag/upload', {
        method: 'POST',
        body: formData
      });

      if (response.ok) {
        await fetchDocuments();
        alert('Documento subido exitosamente');
      }
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuery = async () => {
    setIsLoading(true);
    try {
      const response = await fetch('/api/rag/query', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          query: query,
          top_k: 5
        })
      });

      const data = await response.json();
      setResult(data);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleDelete = async (docId) => {
    if (confirm('¿Eliminar documento?')) {
      await fetch(`/api/rag/documents/${docId}`, { method: 'DELETE' });
      await fetchDocuments();
    }
  };

  return (
    <div className="rag-container">
      <h1>🧠 RAG - Document Analysis</h1>

      {/* Selector de Modelos */}
      <div className="model-selector">
        <div>
          <label>Embedding Model:</label>
          <select 
            value={selectedEmbedding} 
            onChange={(e) => setSelectedEmbedding(e.target.value)}
          >
            {models.embedding.map(m => (
              <option key={m.id} value={m.id}>
                {m.name} ({m.dimensions}D)
              </option>
            ))}
          </select>
        </div>

        <div>
          <label>LLM Model:</label>
          <select 
            value={selectedLLM} 
            onChange={(e) => setSelectedLLM(e.target.value)}
          >
            {models.llm.map(m => (
              <option key={m.id} value={m.id}>{m.name}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Upload */}
      <div className="upload-section">
        <input 
          type="file" 
          onChange={(e) => handleUpload(e.target.files[0])}
          accept=".pdf,.docx,.txt,.csv,.xlsx,.md"
        />
      </div>

      {/* Documents List */}
      <div className="documents-list">
        <h3>📚 Documentos ({documents.length})</h3>
        {documents.map(doc => (
          <div key={doc.id} className="document-item">
            <span>{doc.filename}</span>
            <span>{doc.total_chunks} chunks</span>
            <button onClick={() => handleDelete(doc.id)}>🗑️</button>
          </div>
        ))}
      </div>

      {/* Query */}
      <div className="query-section">
        <h3>💬 Hacer Pregunta</h3>
        <input
          type="text"
          placeholder="Escribe tu pregunta..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <button onClick={handleQuery} disabled={isLoading}>
          {isLoading ? 'Buscando...' : 'Buscar'}
        </button>
      </div>

      {/* Results */}
      {result && (
        <div className="results">
          <h3>🤖 Respuesta</h3>
          <p>{result.answer}</p>

          <h4>📖 Fuentes ({result.sources.length})</h4>
          {result.sources.map((source, idx) => (
            <div key={idx} className="source-item">
              <strong>{source.filename}</strong>
              <span>Similitud: {(source.similarity * 100).toFixed(1)}%</span>
              <p>{source.content}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default RAGDocumentAnalysis;
```

---

## ⚙️ **Configuración Nginx (nginx.conf)**

```nginx
# RAG API Proxy
location /api/rag/ {
    rewrite ^/api/rag/(.*) /$1 break;
    proxy_pass http://rag-api:8004;
    
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    
    # Timeouts para uploads grandes
    proxy_read_timeout 120s;
    proxy_connect_timeout 120s;
    proxy_send_timeout 120s;
    
    # Max body size para uploads
    client_max_body_size 50M;
}
```

---

## 🚀 **Performance**

### Tiempos Esperados:
- **Upload**: 2-5 segundos (depende del tamaño del documento)
- **Query (búsqueda)**: < 10ms (búsqueda vectorial Milvus)
- **Query (total con LLM)**: 3-8 segundos (incluye generación de respuesta)

### Límites:
- **Tamaño máximo de archivo**: 50MB
- **Top-K máximo**: 20 chunks
- **Chunk size**: 500 caracteres con overlap de 50

---

## 🔧 **Testing**

### Test con curl:
```bash
# Health
curl http://localhost:8004/health

# Modelos
curl http://localhost:8004/models

# Upload
curl -X POST http://localhost:8004/upload \
  -F "file=@documento.pdf"

# Query
curl -X POST http://localhost:8004/query \
  -H "Content-Type: application/json" \
  -d '{"query": "¿Qué es RAG?", "top_k": 5}'

# Stats
curl http://localhost:8004/stats
```

---

## 📊 **Estados y Errores**

### Códigos HTTP:
- `200 OK`: Operación exitosa
- `400 Bad Request`: Parámetros inválidos o archivo no soportado
- `404 Not Found`: Documento no existe
- `500 Internal Server Error`: Error del servidor (Milvus, embeddings, LLM)

### Mensajes de Error Comunes:
```json
{
  "detail": "Servicio de embeddings no disponible"
}
```

```json
{
  "detail": "Tipo de archivo no soportado: .exe"
}
```

```json
{
  "detail": "Documento no encontrado"
}
```

---

## ✅ **Checklist de Integración**

- [ ] Configurar proxy `/api/rag/` en nginx.conf
- [ ] Agregar selector de modelos de embeddings
- [ ] Agregar selector de modelos LLM
- [ ] Implementar upload con FormData
- [ ] Implementar query con top_k configurable
- [ ] Mostrar similarity scores en resultados
- [ ] Agregar indicador de estado de Milvus
- [ ] Manejar errores y timeouts apropiadamente
- [ ] Agregar loading states para operaciones largas
- [ ] Implementar delete de documentos
- [ ] Mostrar estadísticas del sistema

---

## 🎉 **Ventajas de la Integración**

✅ **Búsqueda ultra rápida** (< 10ms con Milvus)  
✅ **Escalabilidad** (billones de vectores)  
✅ **Múltiples formatos** de documento  
✅ **Respuestas contextualizadas** con LLM  
✅ **Selección de modelos** en tiempo real  
✅ **API REST** completa y documentada
