-- 00-init-all-databases.sql
-- Script SQL que ejecuta el script bash maestro
-- PostgreSQL garantiza la ejecución de archivos .sql en orden alfabético

\echo '🚀 Ejecutando script maestro de inicialización desde SQL...'

-- Ejecutar el script bash maestro
\! /docker-entrypoint-initdb.d/00-master-init.sh

\echo '✅ Script maestro ejecutado desde SQL'