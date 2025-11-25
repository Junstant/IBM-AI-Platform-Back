-- databases/ai_platform_rag/01-schema.sql
-- Esquema para RAG con pgvector

\echo '🧠 Configurando esquema para ai_platform_rag (RAG con pgvector)...'

\c ai_platform_rag;

-- Crear extensión pgvector
CREATE EXTENSION IF NOT EXISTS vector;

\echo '✅ Extensión pgvector instalada';

-- Nota: Las tablas se crearán automáticamente desde la aplicación RAG
-- Este archivo solo asegura que la extensión esté disponible

\echo '✅ Esquema ai_platform_rag configurado exitosamente';
