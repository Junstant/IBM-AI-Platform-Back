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
# embeddings y llm_client deshabilitados (requieren ML libraries no disponibles en PowerPC)
# from embeddings import get_embeddings_generator
# from llm_client import get_llm_client

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
        
        # Pre-cargar modelo de embeddings (DESHABILITADO - no disponible en PowerPC)
        # get_embeddings_generator()
        logger.info("⚠️ Embeddings deshabilitados (PowerPC - sin ML libraries)")
        
        # Crear directorio de uploads
        os.makedirs(config.UPLOAD_DIR, exist_ok=True)
        
        logger.info("✅ RAG API lista (modo básico sin embeddings)!")
        
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
            "service": "RAG API (Basic Mode)",
            "mode": "document_storage_only",
            "note": "Embeddings disabled (PowerPC compatibility)",
            "database": "connected",
            "documents": stats.get("total_documents", 0)
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
        
        # Generar embeddings (DESHABILITADO - PowerPC sin ML)
        # embeddings_gen = get_embeddings_generator()
        # embeddings = embeddings_gen.generate_embeddings_batch(chunks)
        logger.info(f"⚠️ Embeddings deshabilitados (modo básico)")
        
        # Crear embeddings vacíos como placeholder
        empty_embeddings = [[0.0] * config.EMBEDDING_DIMENSION for _ in chunks]
        
        # Guardar en base de datos
        doc_id = db.insert_document(
            filename=file.filename,
            content_type=file.content_type,
            file_size=file_size,
            metadata={"original_metadata": metadata, "mode": "basic_no_embeddings"} if metadata else {"mode": "basic_no_embeddings"}
        )
        
        # Insertar chunks con embeddings vacíos
        chunks_data = [
            (i, chunk, emb, {"chunk_size": len(chunk)})
            for i, (chunk, emb) in enumerate(zip(chunks, empty_embeddings))
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
    """Consultar documentos (DESHABILITADO - requiere embeddings)"""
    # Esta funcionalidad requiere sentence-transformers que no está disponible en PowerPC
    return QueryResponse(
        answer="❌ Función de búsqueda deshabilitada: requiere embeddings ML no disponibles en PowerPC. Use endpoints /documents para gestión básica de documentos.",
        sources=[],
        context_used="",
        num_sources=0
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
            embedding_model="disabled (PowerPC compatibility)",
            embedding_dimension=0
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
        "service": "RAG API (Basic Mode)",
        "version": "1.0.0",
        "mode": "document_storage_only",
        "note": "Embeddings & query disabled (PowerPC compatibility - ML libraries unavailable)",
        "description": "Document storage and management (RAG features disabled)",
        "endpoints": {
            "upload": "POST /documents/upload (stores documents without embeddings)",
            "query": "POST /query (DISABLED - requires ML)",
            "list": "GET /documents",
            "delete": "DELETE /documents/{id}",
            "stats": "GET /stats",
            "health": "GET /health"
        }
    }
