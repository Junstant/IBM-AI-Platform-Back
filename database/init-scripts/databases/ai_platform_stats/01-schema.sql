-- ================================================================
-- AI PLATFORM STATS DATABASE SCHEMA
-- Sistema de métricas y estadísticas para la plataforma IBM AI
-- ================================================================

\echo '📊 Configurando esquema para ai_platform_stats...'

\c ai_platform_stats;

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";

-- ================================================================
-- 1. MÉTRICAS DE MODELOS IA
-- ================================================================
CREATE TABLE IF NOT EXISTS ai_models_metrics (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    model_type VARCHAR(50) NOT NULL, -- 'llm', 'fraud', 'textosql'
    model_size VARCHAR(20), -- '2B', '4B', '7B', '8B', '12B', '14B'
    status VARCHAR(20) NOT NULL DEFAULT 'inactive', -- 'active', 'inactive', 'loading', 'error', 'maintenance'
    port INTEGER,
    host VARCHAR(100) DEFAULT 'localhost',
    last_health_check TIMESTAMP DEFAULT NOW(),
    total_requests INTEGER DEFAULT 0,
    successful_requests INTEGER DEFAULT 0,
    error_count INTEGER DEFAULT 0,
    avg_response_time DECIMAL(10,3), -- en segundos
    min_response_time DECIMAL(10,3),
    max_response_time DECIMAL(10,3),
    memory_usage_mb INTEGER, -- uso de memoria en MB
    cpu_usage_percent DECIMAL(5,2), -- porcentaje de CPU
    gpu_usage_percent DECIMAL(5,2), -- porcentaje de GPU (si aplica)
    tokens_processed INTEGER DEFAULT 0, -- tokens procesados (para LLM)
    model_load_time DECIMAL(10,3), -- tiempo de carga del modelo
    uptime_seconds INTEGER DEFAULT 0, -- tiempo activo en segundos
    last_error_message TEXT, -- último mensaje de error
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_status CHECK (status IN ('active', 'inactive', 'loading', 'error', 'maintenance')),
    CONSTRAINT chk_model_type CHECK (model_type IN ('llm', 'fraud', 'textosql', 'api')),
    CONSTRAINT unique_model_name UNIQUE (model_name)
);

-- ================================================================
-- 2. MÉTRICAS DE CONSULTAS POR FUNCIONALIDAD
-- ================================================================
CREATE TABLE IF NOT EXISTS functionality_metrics (
    id SERIAL PRIMARY KEY,
    functionality VARCHAR(50) NOT NULL, -- 'textosql', 'fraud-detection', 'chatbot', 'sql-execution'
    model_used VARCHAR(100), -- qué modelo se usó para esta funcionalidad
    total_queries INTEGER DEFAULT 0,
    successful_queries INTEGER DEFAULT 0,
    failed_queries INTEGER DEFAULT 0,
    timeout_queries INTEGER DEFAULT 0,
    avg_response_time DECIMAL(10,3),
    min_response_time DECIMAL(10,3),
    max_response_time DECIMAL(10,3),
    total_tokens_used INTEGER DEFAULT 0, -- para LLM
    avg_tokens_per_query DECIMAL(10,2),
    peak_concurrent_requests INTEGER DEFAULT 0,
    date DATE DEFAULT CURRENT_DATE,
    hour INTEGER DEFAULT EXTRACT(HOUR FROM NOW()),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_functionality CHECK (functionality IN ('textosql', 'fraud-detection', 'chatbot', 'sql-execution', 'model-health')),
    UNIQUE(functionality, date, hour)
);

-- ================================================================
-- 3. LOGS DE PERFORMANCE DE APIS (DETALLADO)
-- ================================================================
CREATE TABLE IF NOT EXISTS api_performance_logs (
    id BIGSERIAL PRIMARY KEY,
    endpoint VARCHAR(200) NOT NULL,
    endpoint_base VARCHAR(200), -- endpoint sin IDs ni query params (v2.0)
    method VARCHAR(10) NOT NULL,
    functionality VARCHAR(50), -- relaciona con functionality_metrics
    model_used VARCHAR(100), -- modelo específico usado
    request_size_bytes INTEGER, -- tamaño del request
    response_size_bytes INTEGER, -- tamaño del response
    response_time DECIMAL(10,3) NOT NULL,
    status_code INTEGER NOT NULL,
    error_message TEXT,
    error_type VARCHAR(50), -- 'timeout', 'model_error', 'database_error', 'validation_error'
    user_agent VARCHAR(500),
    client_ip INET,
    request_id UUID DEFAULT uuid_generate_v4(),
    timestamp TIMESTAMP DEFAULT NOW(),
    -- Campos específicos para análisis
    query_complexity_score INTEGER, -- 1-10 para TextoSQL
    fraud_risk_score DECIMAL(5,2), -- para detección de fraude
    sql_execution_time DECIMAL(10,3), -- tiempo de ejecución SQL
    database_name VARCHAR(100) -- BD utilizada
);

-- ================================================================
-- 4. MÉTRICAS DE PRECISIÓN Y CALIDAD
-- ================================================================
CREATE TABLE IF NOT EXISTS accuracy_metrics (
    id SERIAL PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    functionality VARCHAR(50) NOT NULL,
    accuracy_percentage DECIMAL(5,2),
    precision_percentage DECIMAL(5,2), -- para ML
    recall_percentage DECIMAL(5,2), -- para ML
    f1_score DECIMAL(5,2), -- para ML
    total_predictions INTEGER DEFAULT 0,
    correct_predictions INTEGER DEFAULT 0,
    false_positives INTEGER DEFAULT 0, -- importante para fraude
    false_negatives INTEGER DEFAULT 0, -- importante para fraude
    query_success_rate DECIMAL(5,2), -- para TextoSQL
    sql_syntax_accuracy DECIMAL(5,2), -- para TextoSQL
    semantic_accuracy DECIMAL(5,2), -- para TextoSQL
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(model_name, functionality, date)
);

-- ================================================================
-- 5. ESTADÍSTICAS DE USO DE RECURSOS DEL SISTEMA
-- ================================================================
CREATE TABLE IF NOT EXISTS system_resources (
    id SERIAL PRIMARY KEY,
    server_name VARCHAR(100) DEFAULT 'main-server',
    total_memory_mb INTEGER,
    used_memory_mb INTEGER,
    memory_usage_percent DECIMAL(5,2),
    total_cpu_cores INTEGER,
    cpu_usage_percent DECIMAL(5,2),
    disk_total_gb INTEGER,
    disk_used_gb INTEGER,
    disk_usage_percent DECIMAL(5,2),
    gpu_count INTEGER DEFAULT 0,
    gpu_memory_total_mb INTEGER DEFAULT 0,
    gpu_memory_used_mb INTEGER DEFAULT 0,
    network_rx_bytes BIGINT DEFAULT 0, -- bytes recibidos
    network_tx_bytes BIGINT DEFAULT 0, -- bytes enviados
    active_connections INTEGER DEFAULT 0, -- conexiones PostgreSQL activas
    docker_containers_running INTEGER DEFAULT 0,
    timestamp TIMESTAMP DEFAULT NOW()
);

-- ================================================================
-- 6. MÉTRICAS DE BASE DE DATOS
-- ================================================================
CREATE TABLE IF NOT EXISTS database_metrics (
    id SERIAL PRIMARY KEY,
    database_name VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    operation_type VARCHAR(20) NOT NULL, -- 'SELECT', 'INSERT', 'UPDATE', 'DELETE'
    query_count INTEGER DEFAULT 0,
    avg_execution_time DECIMAL(10,3),
    max_execution_time DECIMAL(10,3),
    total_rows_affected INTEGER DEFAULT 0,
    cache_hit_ratio DECIMAL(5,2), -- ratio de cache hits
    connection_count INTEGER DEFAULT 0,
    lock_count INTEGER DEFAULT 0,
    date DATE DEFAULT CURRENT_DATE,
    hour INTEGER DEFAULT EXTRACT(HOUR FROM NOW()),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_operation_type CHECK (operation_type IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'HEALTH_CHECK')),
    UNIQUE(database_name, table_name, operation_type, date, hour)
);

-- ================================================================
-- 7. ALERTAS Y EVENTOS DEL SISTEMA
-- ================================================================
CREATE TABLE IF NOT EXISTS system_alerts (
    id SERIAL PRIMARY KEY,
    alert_type VARCHAR(50) NOT NULL, -- 'error', 'warning', 'info', 'critical'
    component VARCHAR(100) NOT NULL, -- 'model', 'api', 'database', 'system'
    component_name VARCHAR(100), -- nombre específico del componente
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    severity INTEGER DEFAULT 1, -- 1-5 (1=info, 5=critical)
    resolved BOOLEAN DEFAULT FALSE,
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(100),
    metadata JSONB, -- información adicional en JSON
    created_at TIMESTAMP DEFAULT NOW()
);

-- ================================================================
-- VISTAS PARA EL DASHBOARD
-- ================================================================

-- Vista principal del dashboard
CREATE OR REPLACE VIEW dashboard_summary AS
SELECT 
    -- Modelos activos
    (SELECT COUNT(*) FROM ai_models_metrics WHERE status = 'active') as active_models,
    (SELECT COUNT(*) FROM ai_models_metrics WHERE status = 'error') as error_models,
    
    -- Consultas del día
    (SELECT COALESCE(SUM(total_queries), 0) FROM functionality_metrics WHERE date = CURRENT_DATE) as daily_queries,
    (SELECT COALESCE(SUM(successful_queries), 0) FROM functionality_metrics WHERE date = CURRENT_DATE) as daily_successful_queries,
    
    -- Performance promedio
    (SELECT COALESCE(AVG(avg_response_time), 0) FROM functionality_metrics WHERE date = CURRENT_DATE) as avg_response_time,
    
    -- Precisión global
    (SELECT COALESCE(AVG(accuracy_percentage), 0) FROM accuracy_metrics WHERE date = CURRENT_DATE) as global_accuracy,
    
    -- Alertas críticas
    (SELECT COUNT(*) FROM system_alerts WHERE severity >= 4 AND resolved = FALSE) as critical_alerts,
    
    -- Uso de recursos
    (SELECT COALESCE(AVG(memory_usage_percent), 0) FROM system_resources WHERE timestamp >= NOW() - INTERVAL '1 hour') as avg_memory_usage,
    (SELECT COALESCE(AVG(cpu_usage_percent), 0) FROM system_resources WHERE timestamp >= NOW() - INTERVAL '1 hour') as avg_cpu_usage;

-- Performance por funcionalidad (últimos 7 días)
CREATE OR REPLACE VIEW functionality_performance AS
SELECT 
    functionality,
    SUM(total_queries) as total_queries,
    SUM(successful_queries) as successful_queries,
    SUM(failed_queries) as failed_queries,
    AVG(avg_response_time) as avg_response_time,
    CASE 
        WHEN SUM(total_queries) > 0 THEN 
            ROUND((SUM(successful_queries)::DECIMAL / SUM(total_queries) * 100), 2)
        ELSE 0 
    END as success_rate,
    MIN(date) as first_date,
    MAX(date) as last_date
FROM functionality_metrics 
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY functionality
ORDER BY total_queries DESC;

-- Estado de modelos con detalles
CREATE OR REPLACE VIEW models_status_detailed AS
SELECT 
    model_name,
    model_type,
    model_size,
    status,
    port,
    total_requests,
    successful_requests,
    CASE 
        WHEN total_requests > 0 THEN 
            ROUND((successful_requests::DECIMAL / total_requests * 100), 2)
        ELSE 0 
    END as success_rate,
    avg_response_time,
    memory_usage_mb,
    cpu_usage_percent,
    uptime_seconds,
    last_health_check,
    CASE 
        WHEN last_health_check < NOW() - INTERVAL '5 minutes' THEN 'stale'
        WHEN status = 'active' THEN 'healthy'
        ELSE 'unhealthy'
    END as health_status
FROM ai_models_metrics
ORDER BY model_type, model_name;

-- Top errores recientes
CREATE OR REPLACE VIEW top_errors_recent AS
SELECT 
    error_type,
    COUNT(*) as error_count,
    functionality,
    endpoint,
    MAX(timestamp) as last_occurrence,
    AVG(response_time) as avg_response_time
FROM api_performance_logs 
WHERE timestamp >= NOW() - INTERVAL '24 hours' 
  AND status_code >= 400
GROUP BY error_type, functionality, endpoint
ORDER BY error_count DESC
LIMIT 20;

-- Performance trends (últimas 24 horas por hora)
CREATE OR REPLACE VIEW hourly_performance_trends AS
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    functionality,
    COUNT(*) as request_count,
    AVG(response_time) as avg_response_time,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time) as p95_response_time,
    COUNT(*) FILTER (WHERE status_code >= 400) as error_count
FROM api_performance_logs 
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY DATE_TRUNC('hour', timestamp), functionality
ORDER BY hour DESC, functionality;

-- ================================================================
-- ÍNDICES PARA OPTIMIZACIÓN
-- ================================================================

-- Índices para ai_models_metrics
CREATE INDEX IF NOT EXISTS idx_ai_models_status ON ai_models_metrics(status);
CREATE INDEX IF NOT EXISTS idx_ai_models_type ON ai_models_metrics(model_type);
CREATE INDEX IF NOT EXISTS idx_ai_models_health_check ON ai_models_metrics(last_health_check);

-- Índices para functionality_metrics
CREATE INDEX IF NOT EXISTS idx_functionality_date ON functionality_metrics(date);
CREATE INDEX IF NOT EXISTS idx_functionality_name ON functionality_metrics(functionality);
CREATE INDEX IF NOT EXISTS idx_functionality_date_hour ON functionality_metrics(date, hour);

-- Índices para accuracy_metrics
CREATE INDEX IF NOT EXISTS idx_accuracy_date ON accuracy_metrics(date);
CREATE INDEX IF NOT EXISTS idx_accuracy_model ON accuracy_metrics(model_name);
CREATE INDEX IF NOT EXISTS idx_accuracy_functionality ON accuracy_metrics(functionality);

-- Índices para database_metrics
CREATE INDEX IF NOT EXISTS idx_database_metrics_date_hour ON database_metrics(date, hour);
CREATE INDEX IF NOT EXISTS idx_database_metrics_db_name ON database_metrics(database_name);

-- ================================================================
-- FUNCIONES AUXILIARES
-- ================================================================

-- Función para limpiar logs antiguos (mantener solo últimos 30 días)
CREATE OR REPLACE FUNCTION cleanup_old_logs() RETURNS void AS $$
BEGIN
    DELETE FROM api_performance_logs WHERE timestamp < NOW() - INTERVAL '30 days';
    DELETE FROM system_resources WHERE timestamp < NOW() - INTERVAL '30 days';
    DELETE FROM system_alerts WHERE created_at < NOW() - INTERVAL '30 days' AND resolved = TRUE;
    
    -- Actualizar estadísticas de tablas
    ANALYZE api_performance_logs;
    ANALYZE system_resources;
    ANALYZE system_alerts;
END;
$$ LANGUAGE plpgsql;

-- Función para calcular métricas agregadas diarias
CREATE OR REPLACE FUNCTION calculate_daily_metrics() RETURNS void AS $$
BEGIN
    -- Actualizar functionality_metrics con datos del día actual
    INSERT INTO functionality_metrics (functionality, date, hour, total_queries, successful_queries, failed_queries, avg_response_time)
    SELECT 
        functionality,
        CURRENT_DATE,
        EXTRACT(HOUR FROM NOW()),
        COUNT(*),
        COUNT(*) FILTER (WHERE status_code < 400),
        COUNT(*) FILTER (WHERE status_code >= 400),
        AVG(response_time)
    FROM api_performance_logs 
    WHERE DATE(timestamp) = CURRENT_DATE 
      AND EXTRACT(HOUR FROM timestamp) = EXTRACT(HOUR FROM NOW())
    GROUP BY functionality
    ON CONFLICT (functionality, date, hour) 
    DO UPDATE SET 
        total_queries = EXCLUDED.total_queries,
        successful_queries = EXCLUDED.successful_queries,
        failed_queries = EXCLUDED.failed_queries,
        avg_response_time = EXCLUDED.avg_response_time,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ================================================================
-- VISTAS V2.0 (ESPECIFICACIÓN FRONTEND)
-- ================================================================

-- Vista unificada de servicios (LLM models + API endpoints)
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

-- Métricas detalladas por hora con percentiles
CREATE OR REPLACE VIEW detailed_metrics_hourly AS
SELECT 
    DATE_TRUNC('hour', timestamp) as period,
    functionality,
    endpoint_base,
    COUNT(*) as total_requests,
    COUNT(*) FILTER (WHERE status_code < 400) as successful_requests,
    COUNT(*) FILTER (WHERE status_code >= 400) as failed_requests,
    ROUND(AVG(response_time)::numeric, 3) as avg_response_time,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY response_time)::numeric, 3) as p50_response_time,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time)::numeric, 3) as p95_response_time,
    ROUND(PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY response_time)::numeric, 3) as p99_response_time,
    ROUND(MIN(response_time)::numeric, 3) as min_response_time,
    ROUND(MAX(response_time)::numeric, 3) as max_response_time
FROM api_performance_logs
WHERE timestamp >= NOW() - INTERVAL '7 days'
GROUP BY DATE_TRUNC('hour', timestamp), functionality, endpoint_base
ORDER BY period DESC;

-- Top endpoints por volumen
CREATE OR REPLACE VIEW top_endpoints_view AS
SELECT 
    endpoint_base,
    functionality,
    COUNT(*) as total_requests,
    COUNT(*) FILTER (WHERE status_code < 400) as successful_requests,
    ROUND(AVG(response_time)::numeric, 3) as avg_response_time,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time)::numeric, 3) as p95_response_time,
    CASE 
        WHEN COUNT(*) > 0 THEN 
            ROUND((COUNT(*) FILTER (WHERE status_code < 400)::DECIMAL / COUNT(*) * 100), 2)
        ELSE 0 
    END as success_rate
FROM api_performance_logs
WHERE timestamp >= NOW() - INTERVAL '24 hours'
GROUP BY endpoint_base, functionality
ORDER BY total_requests DESC
LIMIT 20;

-- Endpoints más lentos
CREATE OR REPLACE VIEW slowest_endpoints_view AS
SELECT 
    endpoint_base,
    functionality,
    COUNT(*) as total_requests,
    ROUND(AVG(response_time)::numeric, 3) as avg_response_time,
    ROUND(MAX(response_time)::numeric, 3) as max_response_time,
    ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time)::numeric, 3) as p95_response_time
FROM api_performance_logs
WHERE timestamp >= NOW() - INTERVAL '24 hours'
  AND status_code < 400
GROUP BY endpoint_base, functionality
HAVING COUNT(*) >= 5
ORDER BY avg_response_time DESC
LIMIT 20;

-- Activity log (generado desde system_alerts)
CREATE OR REPLACE VIEW activity_log_view AS
SELECT 
    id::TEXT as activity_id,
    created_at as timestamp,
    alert_type as activity_type,
    CASE 
        WHEN severity >= 4 THEN 'critical'
        WHEN severity = 3 THEN 'warning'
        ELSE 'info'
    END as severity,
    title,
    message as description,
    COALESCE(resolved_by, 'system') as user,
    JSONB_BUILD_OBJECT(
        'component', component,
        'component_name', component_name,
        'resolved', resolved,
        'resolved_at', resolved_at
    ) as metadata
FROM system_alerts
ORDER BY created_at DESC
LIMIT 100;

-- ================================================================
-- TRIGGERS V2.0
-- ================================================================

-- Trigger para actualizar endpoint_base automáticamente
CREATE OR REPLACE FUNCTION update_endpoint_base_function()
RETURNS TRIGGER AS $$
BEGIN
    -- Extraer endpoint base removiendo IDs numéricos y query params
    NEW.endpoint_base := REGEXP_REPLACE(
        REGEXP_REPLACE(NEW.endpoint, '\?.*$', ''),  -- Remover query params
        '/[0-9]+', '/[id]', 'g'  -- Reemplazar IDs numéricos con [id]
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_endpoint_base
BEFORE INSERT ON api_performance_logs
FOR EACH ROW
EXECUTE FUNCTION update_endpoint_base_function();

-- Trigger para normalizar nombres de funcionalidades
CREATE OR REPLACE FUNCTION normalize_functionality_function()
RETURNS TRIGGER AS $$
BEGIN
    -- Normalizar nombres de funcionalidades a estándar v2.0
    NEW.functionality := CASE
        WHEN NEW.functionality IN ('fraude', 'fraud', 'fraud_detection') THEN 'fraud_detection'
        WHEN NEW.functionality IN ('textosql', 'texto_sql', 'text_to_sql', 'sql') THEN 'text_to_sql'
        WHEN NEW.functionality IN ('rag', 'rag_query', 'rag_documents') THEN 'rag_documents'
        WHEN NEW.functionality IN ('chat', 'chatbot', 'conversation') THEN 'chatbot'
        ELSE COALESCE(NEW.functionality, 'unknown')
    END;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER normalize_functionality
BEFORE INSERT ON api_performance_logs
FOR EACH ROW
EXECUTE FUNCTION normalize_functionality_function();

-- ================================================================
-- ÍNDICES ADICIONALES V2.0
-- ================================================================

-- Índice para api_performance_logs
CREATE INDEX IF NOT EXISTS idx_api_logs_timestamp ON api_performance_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_api_logs_functionality ON api_performance_logs(functionality);
CREATE INDEX IF NOT EXISTS idx_api_logs_endpoint_base ON api_performance_logs(endpoint_base);
CREATE INDEX IF NOT EXISTS idx_api_logs_status ON api_performance_logs(status_code);
CREATE INDEX IF NOT EXISTS idx_api_logs_request_id ON api_performance_logs(request_id);

-- Índice compuesto para queries frecuentes
CREATE INDEX IF NOT EXISTS idx_api_logs_time_func ON api_performance_logs(timestamp DESC, functionality);
CREATE INDEX IF NOT EXISTS idx_api_logs_time_endpoint ON api_performance_logs(timestamp DESC, endpoint_base);

-- ================================================================
-- CONFIGURACIÓN DE RETENCIÓN Y LIMPIEZA AUTOMÁTICA
-- ================================================================

-- Crear extensión para jobs programados (si está disponible)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Programar limpieza automática (requiere pg_cron)
-- SELECT cron.schedule('cleanup-old-logs', '0 2 * * *', 'SELECT cleanup_old_logs();');

\echo '✅ Esquema ai_platform_stats configurado exitosamente (v2.0)';
\echo '📊 Tablas creadas:';
\echo '   - ai_models_metrics: Estado y performance de modelos IA';
\echo '   - functionality_metrics: Métricas agregadas por funcionalidad';
\echo '   - api_performance_logs: Logs detallados (con endpoint_base v2.0)';
\echo '   - accuracy_metrics: Métricas de precisión y calidad';
\echo '   - system_resources: Uso de recursos del sistema';
\echo '   - database_metrics: Métricas de base de datos';
\echo '   - system_alerts: Alertas y eventos del sistema';
\echo '';
\echo '🔍 Vistas creadas (v1.0 + v2.0):';
\echo '   - dashboard_summary: Resumen principal para dashboard';
\echo '   - functionality_performance: Performance por funcionalidad';
\echo '   - models_status_detailed: Estado detallado de modelos';
\echo '   - top_errors_recent: Top errores recientes';
\echo '   - hourly_performance_trends: Tendencias de performance por hora';
\echo '   - services_unified: Vista unificada (LLM + APIs) [v2.0]';
\echo '   - detailed_metrics_hourly: Métricas horarias con percentiles [v2.0]';
\echo '   - top_endpoints_view: Top endpoints por volumen [v2.0]';
\echo '   - slowest_endpoints_view: Endpoints más lentos [v2.0]';
\echo '   - activity_log_view: Log de actividades [v2.0]';
\echo '';
\echo '🔧 Triggers v2.0:';
\echo '   - normalize_functionality: Normaliza nombres de funcionalidades';
\echo '   - update_endpoint_base: Genera endpoint_base automáticamente';
\echo '';
\echo '⚡ Funciones utilitarias:';
\echo '   - cleanup_old_logs(): Limpieza de logs antiguos';
\echo '   - calculate_daily_metrics(): Cálculo de métricas diarias';