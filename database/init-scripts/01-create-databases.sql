-- 01-create-databases.sql
-- Script para crear las bases de datos necesarias para la plataforma AI

\echo 'Creando bases de datos para la plataforma AI...'

-- Crear base de datos para el módulo TextoSQL
CREATE DATABASE banco_global
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Crear base de datos para el módulo de detección de fraude
CREATE DATABASE bank_transactions
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Crear base de datos de pruebas adicional
CREATE DATABASE demo_retail
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.utf8'
    LC_CTYPE = 'en_US.utf8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

-- Conceder todos los privilegios al usuario postgres
GRANT ALL PRIVILEGES ON DATABASE banco_global TO postgres;
GRANT ALL PRIVILEGES ON DATABASE bank_transactions TO postgres;
GRANT ALL PRIVILEGES ON DATABASE demo_retail TO postgres;

\echo 'Bases de datos creadas exitosamente:'
\echo '  - banco_global (para TextoSQL)'
\echo '  - bank_transactions (para detección de fraude)'