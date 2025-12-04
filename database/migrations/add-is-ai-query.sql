-- ================================================================
-- MIGRACIÓN v2.1: Agregar campo is_ai_query
-- ================================================================
-- Propósito: Filtrar queries AI válidas de requests de monitoreo
-- Fecha: 2024
-- ================================================================

\c ai_platform_stats;

-- 1. Agregar columna is_ai_query
ALTER TABLE api_performance_logs 
ADD COLUMN IF NOT EXISTS is_ai_query BOOLEAN DEFAULT FALSE;

-- 2. Comentario explicativo
COMMENT ON COLUMN api_performance_logs.is_ai_query IS 
'v2.1: TRUE solo para queries a demos AI (excluye endpoints de monitoreo/stats/admin)';

-- 3. Crear índice para optimizar queries
CREATE INDEX IF NOT EXISTS idx_api_logs_is_ai_query 
ON api_performance_logs(is_ai_query);

-- 4. Crear índice compuesto para dashboard queries
CREATE INDEX IF NOT EXISTS idx_api_logs_ai_time 
ON api_performance_logs(is_ai_query, timestamp DESC) 
WHERE is_ai_query = TRUE;

-- 5. Actualizar registros históricos (marcar queries AI basado en endpoint)
-- SOLO ejecutar si hay datos históricos que quieras preservar
UPDATE api_performance_logs
SET is_ai_query = TRUE
WHERE method = 'POST'
  AND (
    endpoint LIKE '%/proxy/%' OR
    endpoint LIKE '%/api/rag/query%' OR
    endpoint LIKE '%/api/rag/upload%' OR
    endpoint LIKE '%/api/fraude/predict%' OR
    endpoint LIKE '%/api/textosql/generate%'
  )
  AND endpoint NOT LIKE '%/api/stats/%'
  AND endpoint NOT LIKE '%/api/admin/%'
  AND endpoint NOT LIKE '%/health%';

-- 6. Verificar resultado
SELECT 
    is_ai_query,
    COUNT(*) as total_requests,
    COUNT(DISTINCT endpoint_base) as unique_endpoints
FROM api_performance_logs
GROUP BY is_ai_query;

-- ================================================================
-- FIN MIGRACIÓN
-- ================================================================
