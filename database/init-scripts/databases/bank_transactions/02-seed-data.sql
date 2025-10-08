-- databases/bank_transactions/02-seed-data.sql
-- Datos básicos y configuración inicial para bank_transactions

\echo '🔍 Configurando datos básicos para bank_transactions...'

\c bank_transactions;

-- ===== INSERTAR COMERCIANTES BÁSICOS =====
INSERT INTO comerciantes (codigo_comerciante, nombre, categoria, subcategoria, ubicacion, ciudad, pais, nivel_riesgo) VALUES
('BASIC001', 'Comerciante Genérico 1', 'Retail', 'General', 'Centro, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('BASIC002', 'Comerciante Genérico 2', 'Servicios', 'General', 'Norte, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('BASIC003', 'Comerciante Genérico 3', 'Alimentación', 'General', 'Sur, CABA', 'Buenos Aires', 'Argentina', 'bajo')
ON CONFLICT (codigo_comerciante) DO NOTHING;

-- ===== REGLAS DE FRAUDE BÁSICAS =====
INSERT INTO reglas_fraude (nombre, descripcion, condicion, peso, activa) VALUES
('Regla Básica 1', 'Detección básica de montos altos', '{"monto_minimo": 10000}', 0.50, TRUE),
('Regla Básica 2', 'Detección básica de horario nocturno', '{"horario_riesgo": "nocturno"}', 0.40, TRUE)
ON CONFLICT (nombre) DO NOTHING;

\echo '✅ Datos básicos configurados para bank_transactions';