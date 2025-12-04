-- databases/ai_platform_rag/01-schema.sql
-- Esquema para RAG con pgvector

\echo '🧠 Configurando esquema para ai_platform_rag (RAG con pgvector)...'


-- Crear extensión pgvector (v0.8.1 compilada)
CREATE EXTENSION IF NOT EXISTS vector;

\echo '✅ Extensión pgvector instalada';

-- Verificar versión de pgvector
SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';

-- Crear tabla de prueba para verificar funcionalidad
CREATE TABLE IF NOT EXISTS _pgvector_test (
    id SERIAL PRIMARY KEY,
    embedding vector(768)
);

-- Insertar vector de prueba
INSERT INTO _pgvector_test (embedding) VALUES (array_fill(0.0::real, ARRAY[768])::vector);

-- Limpiar tabla de prueba
DROP TABLE _pgvector_test;

\echo '✅ pgvector funcionando correctamente';

-- Nota: Las tablas de RAG se crearán automáticamente desde la aplicación
-- Este archivo solo asegura que la extensión esté disponible y funcional

\echo '✅ Esquema ai_platform_rag configurado exitosamente';
