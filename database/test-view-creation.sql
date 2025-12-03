-- Test manual de creación de vista services_unified
\c ai_platform_stats;

\echo 'Verificando tabla ai_models_metrics...';
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'ai_models_metrics' 
ORDER BY ordinal_position;

\echo '';
\echo 'Intentando crear vista services_unified...';

CREATE OR REPLACE VIEW services_unified AS
SELECT 
    model_name as service_name,
    CASE 
        WHEN model_name = 'gemma-2b' THEN 'Gemma 2B'
        WHEN model_name = 'gemma-4b' THEN 'Gemma 4B'
        WHEN model_name = 'gemma-12b' THEN 'Gemma 12B'
        WHEN model_name = 'mistral-7b' THEN 'Mistral 7B'
        WHEN model_name = 'deepseek-8b' THEN 'DeepSeek 8B'
        WHEN model_name = 'fraud-api' THEN 'Fraud Detection API'
        WHEN model_name = 'textosql-api' THEN 'Text to SQL API'
        WHEN model_name = 'rag-api' THEN 'RAG API'
        WHEN model_name = 'stats-api' THEN 'Stats API'
        ELSE INITCAP(REPLACE(model_name, '-', ' '))
    END as display_name,
    model_type as service_type,
    status,
    last_health_check,
    uptime_seconds,
    total_requests,
    successful_requests,
    error_count as failed_requests,
    ROUND((avg_response_time * 1000)::numeric, 2) as avg_latency_ms,
    JSONB_BUILD_OBJECT(
        'port', port,
        'model_type', model_type,
        'memory_mb', memory_usage_mb,
        'cpu_percent', cpu_usage_percent
    ) as metadata
FROM ai_models_metrics;

\echo 'Vista creada exitosamente!';
\dv services_unified
