-- ================================================================
-- SCRIPT MAESTRO DE INICIALIZACIÓN - PLATAFORMA AI
-- ================================================================
-- Este script crea todas las bases de datos y carga sus esquemas/datos
-- Se ejecuta automáticamente al iniciar PostgreSQL por primera vez
-- Compatible con PostgreSQL 17 + pgvector en arquitectura PPC64le
-- ================================================================

\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '🚀 INICIANDO CONFIGURACIÓN DE PLATAFORMA AI'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'

-- ================================================================
-- PASO 1: CREAR BASES DE DATOS
-- ================================================================
\echo ''
\echo '📊 PASO 1/5: Creando bases de datos...'

-- Crear bases de datos solo si no existen
SELECT 'CREATE DATABASE ai_platform_stats' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ai_platform_stats')\gexec
SELECT 'CREATE DATABASE banco_global' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'banco_global')\gexec
SELECT 'CREATE DATABASE bank_transactions' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'bank_transactions')\gexec
SELECT 'CREATE DATABASE ai_platform_rag' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'ai_platform_rag')\gexec

\echo '✅ Bases de datos creadas/verificadas'

-- ================================================================
-- PASO 2: APLICAR ESQUEMAS AUTOMÁTICAMENTE
-- ================================================================
\echo ''
\echo '📊 PASO 2/5: Aplicando esquemas a bases de datos...'

-- Conectar a ai_platform_stats y aplicar esquema
\c ai_platform_stats
\echo '📝 Aplicando esquema ai_platform_stats...'
\i /docker-entrypoint-initdb.d/databases/ai_platform_stats/01-schema.sql
\echo '✅ Esquema ai_platform_stats completado'

-- Conectar a banco_global y aplicar esquema + datos
\c banco_global
\echo '📝 Aplicando esquema banco_global...'
\i /docker-entrypoint-initdb.d/databases/banco_global/01-schema.sql
\echo '📝 Cargando datos iniciales banco_global...'
\i /docker-entrypoint-initdb.d/databases/banco_global/02-seed-data.sql
\echo '✅ Esquema banco_global completado'

-- Conectar a bank_transactions y aplicar esquema + datos
\c bank_transactions
\echo '📝 Aplicando esquema bank_transactions...'
\i /docker-entrypoint-initdb.d/databases/bank_transactions/01-schema.sql
\echo '📝 Cargando datos iniciales bank_transactions...'
\i /docker-entrypoint-initdb.d/databases/bank_transactions/02-seed-data.sql
\echo '📝 Cargando muestras de fraude...'
\i /docker-entrypoint-initdb.d/databases/bank_transactions/03-fraud-samples.sql
\echo '✅ Esquema bank_transactions completado'

-- Conectar a ai_platform_rag y aplicar esquema
\c ai_platform_rag
\echo '📝 Aplicando esquema ai_platform_rag (pgvector)...'
\i /docker-entrypoint-initdb.d/databases/ai_platform_rag/01-schema.sql
\echo '✅ Esquema ai_platform_rag completado'

-- ================================================================
-- PASO 3: VERIFICACIÓN FINAL
-- ================================================================
\echo ''
\echo '📊 PASO 3/5: Verificando esquemas aplicados...'

\c ai_platform_stats
SELECT 'ai_platform_stats: ' || COUNT(*)::text || ' tablas' FROM information_schema.tables WHERE table_schema = 'public';

\c banco_global  
SELECT 'banco_global: ' || COUNT(*)::text || ' tablas' FROM information_schema.tables WHERE table_schema = 'public';

\c bank_transactions
SELECT 'bank_transactions: ' || COUNT(*)::text || ' tablas' FROM information_schema.tables WHERE table_schema = 'public';

\c ai_platform_rag
SELECT 'ai_platform_rag: ' || COUNT(*)::text || ' tablas' FROM information_schema.tables WHERE table_schema = 'public';

\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '✅ CONFIGURACIÓN COMPLETADA EXITOSAMENTE'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
    CONNECTION LIMIT = -1;

GRANT ALL PRIVILEGES ON DATABASE ai_platform_stats TO postgres;
GRANT ALL PRIVILEGES ON DATABASE banco_global TO postgres;
GRANT ALL PRIVILEGES ON DATABASE bank_transactions TO postgres;
GRANT ALL PRIVILEGES ON DATABASE ai_platform_rag TO postgres;

\echo '✅ Bases de datos creadas: ai_platform_stats, banco_global, bank_transactions, ai_platform_rag'

-- ================================================================
-- PASO 2: CONFIGURAR BANCO_GLOBAL (TextoSQL)
-- ================================================================
\echo ''
\echo '🏦 PASO 2/5: Configurando banco_global (TextoSQL API)...'

\c banco_global;
\i /docker-entrypoint-initdb.d/databases/banco_global/01-schema.sql
\i /docker-entrypoint-initdb.d/databases/banco_global/02-seed-data.sql

\echo '✅ banco_global configurado con esquema y datos iniciales'

-- ================================================================
-- PASO 3: CONFIGURAR BANK_TRANSACTIONS (Detección de Fraude)
-- ================================================================
\echo ''
\echo '🔍 PASO 3/5: Configurando bank_transactions (Fraude API)...'

\c bank_transactions;
\i /docker-entrypoint-initdb.d/databases/bank_transactions/01-schema.sql
\i /docker-entrypoint-initdb.d/databases/bank_transactions/02-seed-data.sql
\i /docker-entrypoint-initdb.d/databases/bank_transactions/03-fraud-samples.sql

\echo '✅ bank_transactions configurado con 17,507 transacciones para ML'

-- ================================================================
-- PASO 4: CONFIGURAR AI_PLATFORM_STATS (Métricas y Stats)
-- ================================================================
\echo ''
\echo '📊 PASO 4/5: Configurando ai_platform_stats (Stats API)...'

\c ai_platform_stats;
\i /docker-entrypoint-initdb.d/databases/ai_platform_stats/01-schema.sql

\echo '✅ ai_platform_stats configurado con esquema de métricas'

-- ================================================================
-- PASO 5: CONFIGURAR AI_PLATFORM_RAG (Búsqueda Semántica)
-- ================================================================
\echo ''
\echo '🧠 PASO 5/5: Configurando ai_platform_rag (RAG API + pgvector)...'

\c ai_platform_rag;
\i /docker-entrypoint-initdb.d/databases/ai_platform_rag/01-schema.sql

\echo '✅ ai_platform_rag configurado con extensión pgvector'

-- ================================================================
-- FINALIZACIÓN
-- ================================================================
\echo ''
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo '✅ CONFIGURACIÓN COMPLETA FINALIZADA EXITOSAMENTE'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
\echo ''
\echo '📋 Resumen de bases de datos configuradas:'
\echo '  🏦 banco_global          → TextoSQL API (esquema + datos)'
\echo '  🔍 bank_transactions     → Fraude API (17,507 transacciones)'
\echo '  📊 ai_platform_stats     → Stats API (esquema de métricas)'
\echo '  🧠 ai_platform_rag       → RAG API (pgvector v0.8.1)'
\echo ''
\echo '🚀 Plataforma lista para recibir conexiones de APIs'
\echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
