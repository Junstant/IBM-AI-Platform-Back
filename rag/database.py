"""
Gestor de base de datos con pgvector
"""
import psycopg2
from psycopg2.extras import RealDictCursor
from sqlalchemy import create_engine, text
from typing import List, Dict, Any, Tuple
import logging
from config import config

logger = logging.getLogger(__name__)

class RAGDatabase:
    """Gestor de base de datos para RAG con pgvector"""
    
    def __init__(self):
        self.engine = create_engine(config.get_database_url())
        self._ensure_database_exists()
        self._initialize_schema()
    
    def _ensure_database_exists(self):
        """Crear base de datos RAG si no existe"""
        try:
            # Conectar a postgres para crear la BD
            conn = psycopg2.connect(
                host=config.DB_HOST,
                port=config.DB_PORT,
                user=config.DB_USER,
                password=config.DB_PASSWORD,
                database="postgres"
            )
            conn.autocommit = True
            cursor = conn.cursor()
            
            # Verificar si existe
            cursor.execute(
                "SELECT 1 FROM pg_database WHERE datname = %s",
                (config.DB_NAME,)
            )
            
            if not cursor.fetchone():
                cursor.execute(f"CREATE DATABASE {config.DB_NAME}")
                logger.info(f"✅ Base de datos {config.DB_NAME} creada")
            
            cursor.close()
            conn.close()
            
        except Exception as e:
            logger.error(f"Error creando base de datos: {e}")
    
    def _initialize_schema(self):
        """Inicializar esquema con pgvector"""
        with self.engine.connect() as conn:
            # Crear extensión pgvector
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            
            # Tabla de documentos
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS documents (
                    id SERIAL PRIMARY KEY,
                    filename VARCHAR(500) NOT NULL,
                    content_type VARCHAR(100),
                    file_size INTEGER,
                    total_chunks INTEGER DEFAULT 0,
                    metadata JSONB DEFAULT '{}'::jsonb,
                    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # Tabla de chunks con embeddings
            conn.execute(text(f"""
                CREATE TABLE IF NOT EXISTS document_chunks (
                    id SERIAL PRIMARY KEY,
                    document_id INTEGER REFERENCES documents(id) ON DELETE CASCADE,
                    chunk_index INTEGER NOT NULL,
                    content TEXT NOT NULL,
                    embedding vector({config.EMBEDDING_DIMENSION}),
                    metadata JSONB DEFAULT '{{}}'::jsonb,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """))
            
            # Índice para búsqueda vectorial eficiente
            conn.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_chunks_embedding 
                ON document_chunks 
                USING ivfflat (embedding vector_cosine_ops)
                WITH (lists = 100)
            """))
            
            # Índices adicionales
            conn.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_chunks_document 
                ON document_chunks(document_id)
            """))
            
            conn.commit()
            logger.info("✅ Esquema RAG inicializado con pgvector")
    
    def insert_document(self, filename: str, content_type: str, 
                       file_size: int, metadata: Dict = None) -> int:
        """Insertar nuevo documento"""
        with self.engine.connect() as conn:
            result = conn.execute(
                text("""
                    INSERT INTO documents (filename, content_type, file_size, metadata)
                    VALUES (:filename, :content_type, :file_size, :metadata::jsonb)
                    RETURNING id
                """),
                {
                    "filename": filename,
                    "content_type": content_type,
                    "file_size": file_size,
                    "metadata": metadata or {}
                }
            )
            conn.commit()
            return result.fetchone()[0]
    
    def insert_chunks(self, document_id: int, chunks: List[Tuple[int, str, List[float], Dict]]):
        """Insertar chunks con embeddings"""
        with self.engine.connect() as conn:
            for chunk_index, content, embedding, metadata in chunks:
                conn.execute(
                    text("""
                        INSERT INTO document_chunks 
                        (document_id, chunk_index, content, embedding, metadata)
                        VALUES (:doc_id, :idx, :content, :embedding::vector, :metadata::jsonb)
                    """),
                    {
                        "doc_id": document_id,
                        "idx": chunk_index,
                        "content": content,
                        "embedding": str(embedding),
                        "metadata": metadata or {}
                    }
                )
            
            # Actualizar contador de chunks
            conn.execute(
                text("UPDATE documents SET total_chunks = :count WHERE id = :id"),
                {"count": len(chunks), "id": document_id}
            )
            conn.commit()
    
    def similarity_search(self, query_embedding: List[float], top_k: int = 5) -> List[Dict]:
        """Búsqueda por similitud coseno"""
        with self.engine.connect() as conn:
            result = conn.execute(
                text("""
                    SELECT 
                        dc.id,
                        dc.document_id,
                        dc.chunk_index,
                        dc.content,
                        d.filename,
                        d.metadata as doc_metadata,
                        dc.metadata as chunk_metadata,
                        1 - (dc.embedding <=> :embedding::vector) as similarity
                    FROM document_chunks dc
                    JOIN documents d ON dc.document_id = d.id
                    ORDER BY dc.embedding <=> :embedding::vector
                    LIMIT :limit
                """),
                {
                    "embedding": str(query_embedding),
                    "limit": top_k
                }
            )
            
            return [dict(row._mapping) for row in result]
    
    def get_all_documents(self) -> List[Dict]:
        """Listar todos los documentos"""
        with self.engine.connect() as conn:
            result = conn.execute(text("""
                SELECT 
                    id, filename, content_type, file_size, 
                    total_chunks, metadata, uploaded_at
                FROM documents
                ORDER BY uploaded_at DESC
            """))
            
            return [dict(row._mapping) for row in result]
    
    def delete_document(self, document_id: int) -> bool:
        """Eliminar documento y sus chunks"""
        with self.engine.connect() as conn:
            result = conn.execute(
                text("DELETE FROM documents WHERE id = :id"),
                {"id": document_id}
            )
            conn.commit()
            return result.rowcount > 0
    
    def get_document_stats(self) -> Dict:
        """Estadísticas de documentos"""
        with self.engine.connect() as conn:
            result = conn.execute(text("""
                SELECT 
                    COUNT(*) as total_documents,
                    SUM(total_chunks) as total_chunks,
                    SUM(file_size) as total_size_bytes
                FROM documents
            """))
            
            return dict(result.fetchone()._mapping)
