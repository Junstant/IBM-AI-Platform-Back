"""
🧠 RAG API - Retrieval-Augmented Generation con pgvector
=======================================================
Sistema de consulta de documentos usando RAG con PostgreSQL
"""
import os
import logging
from typing import List, Optional
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, HTTPException, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Importar componentes locales
from config import config
from database import RAGDatabase
from document_processor import DocumentProcessor
from embeddings import get_embeddings_generator
from llm_client import get_llm_client

# Configurar logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# =====================================================
# MODELOS PYDANTIC
# =====================================================

class QueryRequest(BaseModel):
    """Modelo para consulta RAG"""
    question: str = Field(..., min_length=3, description="Pregunta del usuario")
    top_k: int = Field(5, ge=1, le=20, description="Número de documentos a recuperar")
    model: Optional[str] = Field(None, description="Modelo LLM a usar (opcional)")

class QueryResponse(BaseModel):
    """Respuesta de consulta RAG"""
    answer: str
    sources: List[dict]
    context_used: str
    num_sources: int

class DocumentInfo(BaseModel):
    """Información de documento"""
    id: int
    filename: str
    content_type: str
    file_size: int
    total_chunks: int
    metadata: dict
    uploaded_at: str

class StatsResponse(BaseModel):
    """Estadísticas del sistema"""
    total_documents: int
    total_chunks: int
    total_size_mb: float
    embedding_model: str
    embedding_dimension: int

# =====================================================
# APLICACIÓN FASTAPI
# =====================================================

app = FastAPI(
    title="🧠 RAG API - Retrieval-Augmented Generation",
    description="Sistema de consulta de documentos usando embeddings vectoriales y LLM",
    version="1.0.0"
)

# Configurar CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# GESTORES GLOBALES
# =====================================================

db: Optional[RAGDatabase] = None
processor = DocumentProcessor()

# =====================================================
# EVENTOS DE CICLO DE VIDA
# =====================================================

@app.on_event("startup")
async def startup():
    """Inicializar componentes al arrancar"""
    global db
    
    logger.info("🚀 Iniciando RAG API...")
    
    try:
        # Inicializar base de datos
        db = RAGDatabase()
        logger.info("✅ Base de datos inicializada")
        
        # Pre-cargar modelo de embeddings
        get_embeddings_generator()
        logger.info("✅ Modelo de embeddings cargado")
        
        # Crear directorio de uploads
        os.makedirs(config.UPLOAD_DIR, exist_ok=True)
        
        logger.info("✅ RAG API lista!")
        
    except Exception as e:
        logger.error(f"❌ Error en startup: {e}")
        raise

@app.on_event("shutdown")
async def shutdown():
    """Limpiar recursos al cerrar"""
    logger.info("🛑 Cerrando RAG API...")

# =====================================================
# ENDPOINTS
# =====================================================

@app.get("/health")
async def health_check():
    """Verificar estado del servicio"""
    try:
        stats = db.get_document_stats()
        return {
            "status": "healthy",
            "service": "RAG API",
            "database": "connected",
            "documents": stats.get("total_documents", 0),
            "embeddings_model": config.EMBEDDING_MODEL
        }
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Service unhealthy: {str(e)}")

@app.post("/documents/upload")
async def upload_document(
    file: UploadFile = File(...),
    metadata: Optional[str] = Form(None)
):
    """Subir y procesar documento"""
    try:
        # Validar extensión
        file_ext = Path(file.filename).suffix.lower()
        if file_ext not in config.ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=400,
                detail=f"Tipo de archivo no permitido. Permitidos: {config.ALLOWED_EXTENSIONS}"
            )
        
        # Leer contenido
        content = await file.read()
        file_size = len(content)
        
        # Validar tamaño
        if file_size > config.MAX_FILE_SIZE_MB * 1024 * 1024:
            raise HTTPException(
                status_code=400,
                detail=f"Archivo muy grande. Máximo: {config.MAX_FILE_SIZE_MB}MB"
            )
        
        logger.info(f"Procesando documento: {file.filename} ({file_size} bytes)")
        
        # Extraer texto
        text = processor.extract_text(content, file.filename)
        
        # Dividir en chunks
        chunks = processor.chunk_text(
            text,
            chunk_size=config.CHUNK_SIZE,
            overlap=config.CHUNK_OVERLAP
        )
        
        if not chunks:
            raise HTTPException(
                status_code=400,
                detail="No se pudo extraer texto del documento"
            )
        
        logger.info(f"Documento dividido en {len(chunks)} chunks")
        
        # Generar embeddings
        embeddings_gen = get_embeddings_generator()
        embeddings = embeddings_gen.generate_embeddings_batch(chunks)
        
        logger.info(f"Embeddings generados: {len(embeddings)}")
        
        # Guardar en base de datos
        doc_id = db.insert_document(
            filename=file.filename,
            content_type=file.content_type,
            file_size=file_size,
            metadata={"original_metadata": metadata} if metadata else {}
        )
        
        # Insertar chunks con embeddings
        chunks_data = [
            (i, chunk, emb, {"chunk_size": len(chunk)})
            for i, (chunk, emb) in enumerate(zip(chunks, embeddings))
        ]
        db.insert_chunks(doc_id, chunks_data)
        
        logger.info(f"✅ Documento {doc_id} guardado con {len(chunks)} chunks")
        
        return {
            "status": "success",
            "document_id": doc_id,
            "filename": file.filename,
            "chunks_created": len(chunks),
            "file_size": file_size
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error procesando documento: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/query", response_model=QueryResponse)
async def query_documents(request: QueryRequest):
    """Consultar documentos usando RAG"""
    try:
        logger.info(f"Consulta: {request.question}")
        
        # Generar embedding de la pregunta
        embeddings_gen = get_embeddings_generator()
        query_embedding = embeddings_gen.generate_embedding(request.question)
        
        # Búsqueda de similitud
        results = db.similarity_search(query_embedding, top_k=request.top_k)
        
        if not results:
            return QueryResponse(
                answer="No encontré documentos relevantes para tu pregunta.",
                sources=[],
                context_used="",
                num_sources=0
            )
        
        # Construir contexto
        context_parts = []
        for i, result in enumerate(results, 1):
            context_parts.append(
                f"[Documento {i}: {result['filename']}]\n{result['content']}"
            )
        
        context = "\n\n".join(context_parts)
        
        # Generar respuesta con LLM
        llm = get_llm_client()
        answer = await llm.generate_rag_response(request.question, context)
        
        # Preparar fuentes
        sources = [
            {
                "document_id": r["document_id"],
                "filename": r["filename"],
                "chunk_index": r["chunk_index"],
                "similarity": float(r["similarity"]),
                "preview": r["content"][:200] + "..."
            }
            for r in results
        ]
        
        return QueryResponse(
            answer=answer,
            sources=sources,
            context_used=context[:500] + "...",
            num_sources=len(results)
        )
        
    except Exception as e:
        logger.error(f"Error en consulta: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/documents", response_model=List[DocumentInfo])
async def list_documents():
    """Listar todos los documentos"""
    try:
        docs = db.get_all_documents()
        return [
            DocumentInfo(
                id=doc["id"],
                filename=doc["filename"],
                content_type=doc["content_type"],
                file_size=doc["file_size"],
                total_chunks=doc["total_chunks"],
                metadata=doc["metadata"],
                uploaded_at=str(doc["uploaded_at"])
            )
            for doc in docs
        ]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/documents/{document_id}")
async def delete_document(document_id: int):
    """Eliminar documento"""
    try:
        success = db.delete_document(document_id)
        if not success:
            raise HTTPException(status_code=404, detail="Documento no encontrado")
        
        return {"status": "success", "message": f"Documento {document_id} eliminado"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/stats", response_model=StatsResponse)
async def get_stats():
    """Obtener estadísticas del sistema"""
    try:
        stats = db.get_document_stats()
        
        return StatsResponse(
            total_documents=stats.get("total_documents", 0),
            total_chunks=stats.get("total_chunks", 0),
            total_size_mb=round(stats.get("total_size_bytes", 0) / (1024 * 1024), 2),
            embedding_model=config.EMBEDDING_MODEL,
            embedding_dimension=config.EMBEDDING_DIMENSION
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# =====================================================
# ENDPOINT RAÍZ
# =====================================================

@app.get("/")
async def root():
    """Información del servicio"""
    return {
        "service": "RAG API",
        "version": "1.0.0",
        "description": "Retrieval-Augmented Generation con pgvector",
        "endpoints": {
            "upload": "POST /documents/upload",
            "query": "POST /query",
            "list": "GET /documents",
            "delete": "DELETE /documents/{id}",
            "stats": "GET /stats",
            "health": "GET /health"
        }
    }
