-- databases/bank_transactions/03-fraud-samples.sql
-- Generación masiva de transacciones REALISTAS para detección de fraude

\echo '🔍 Generando datos masivos para detección de fraude...'
\echo '   Target: 10,000 transacciones con distribución realista';

\c bank_transactions;

-- ===== LIMPIAR DATOS EXISTENTES PRIMERO =====
\echo '🗑️ Limpiando datos existentes...';
TRUNCATE TABLE alertas_fraude RESTART IDENTITY CASCADE;
TRUNCATE TABLE transacciones RESTART IDENTITY CASCADE;
DELETE FROM comerciantes;
DELETE FROM perfiles_usuario;

-- ===== INSERTAR COMERCIANTES REALISTAS =====
\echo '🏪 Configurando comerciantes realistas...';
INSERT INTO comerciantes (codigo_comerciante, nombre, categoria, subcategoria, ubicacion, ciudad, pais, nivel_riesgo) VALUES
-- Comerciantes legítimos (bajo riesgo)
('COM001', 'Supermercado Disco', 'Alimentación', 'Supermercados', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM002', 'Shell Estación Norte', 'Combustibles', 'Estaciones de Servicio', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'bajo'),
('COM003', 'Restaurant Don Julio', 'Gastronomía', 'Restaurantes', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM004', 'Farmacity Centro', 'Salud', 'Farmacias', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM005', 'McDonald''s Obelisco', 'Gastronomía', 'Comida Rápida', 'Av. 9 de Julio 1000', 'Buenos Aires', 'Argentina', 'bajo'),
('COM006', 'Starbucks Recoleta', 'Gastronomía', 'Cafeterías', 'Recoleta Mall', 'Buenos Aires', 'Argentina', 'bajo'),
('COM007', 'ATM Banco Galicia', 'Bancario', 'Cajeros Automáticos', 'Microcentro, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM008', 'Garbarino Unicenter', 'Tecnología', 'Electrónicos', 'Unicenter Shopping', 'Buenos Aires', 'Argentina', 'bajo'),
('COM009', 'Cine Hoyts Abasto', 'Entretenimiento', 'Cines', 'Shopping Abasto', 'Buenos Aires', 'Argentina', 'bajo'),
('COM010', 'YPF Panamericana', 'Combustibles', 'Estaciones de Servicio', 'Panamericana Km 30', 'Buenos Aires', 'Argentina', 'bajo'),
('COM011', 'Walmart Palermo', 'Alimentación', 'Supermercados', 'Palermo Soho', 'Buenos Aires', 'Argentina', 'bajo'),
('COM012', 'Subway Florida', 'Gastronomía', 'Comida Rápida', 'Florida 500', 'Buenos Aires', 'Argentina', 'bajo'),
('COM013', 'Dr. Ahorro Farmacia', 'Salud', 'Farmacias', 'Av. Cabildo 2000', 'Buenos Aires', 'Argentina', 'bajo'),
('COM014', 'Frávega Electro', 'Tecnología', 'Electrodomésticos', 'Av. Rivadavia 5000', 'Buenos Aires', 'Argentina', 'bajo'),
('COM015', 'Havanna Puerto Madero', 'Gastronomía', 'Confiterías', 'Puerto Madero', 'Buenos Aires', 'Argentina', 'bajo'),

-- Comerciantes con riesgo medio-alto (más sutiles)
('COM016', 'TechStore Online', 'E-commerce', 'Electrónicos', 'Zona Norte', 'Buenos Aires', 'Argentina', 'medio'),
('COM017', 'Casino Buenos Aires', 'Entretenimiento', 'Casinos', 'Puerto Madero', 'Buenos Aires', 'Argentina', 'medio'),
('COM018', 'Western Union Retiro', 'Financiero', 'Remesas', 'Retiro', 'Buenos Aires', 'Argentina', 'medio'),
('COM019', 'BitCoin Exchange', 'Financiero', 'Criptomonedas', 'Microcentro', 'Buenos Aires', 'Argentina', 'alto'),
('COM020', 'Kiosco 24hs Terminal', 'Retail', 'Kioscos', 'Retiro Terminal', 'Buenos Aires', 'Argentina', 'medio'),
('COM021', 'Amazon Marketplace', 'E-commerce', 'Marketplace', 'Online', 'São Paulo', 'Brasil', 'medio'),
('COM022', 'MoneyGram Flores', 'Financiero', 'Transferencias', 'Flores', 'Buenos Aires', 'Argentina', 'medio'),
('COM023', 'Bet365 Gaming', 'Entretenimiento', 'Apuestas Online', 'Online', 'Londres', 'Reino Unido', 'alto'),
('COM024', 'ATM Genérico', 'Bancario', 'Cajeros Independientes', 'Villa Crespo', 'Buenos Aires', 'Argentina', 'medio'),
('COM025', 'MercadoLibre Pago', 'E-commerce', 'Marketplace', 'Online', 'Buenos Aires', 'Argentina', 'bajo');

-- ===== INSERTAR REGLAS DE FRAUDE REALISTAS =====
\echo '📋 Configurando reglas de detección...';
INSERT INTO reglas_fraude (nombre, descripcion, condicion, peso, activa) VALUES
('Monto Alto Inusual', 'Transacción superior a $150,000', '{"monto_minimo": 150000}', 0.75, TRUE),
('Horario Nocturno Sospechoso', 'Transacciones entre 02:00 y 05:00', '{"horario_inicio": "02:00", "horario_fin": "05:00"}', 0.45, TRUE),
('Múltiples Intentos Rápidos', 'Más de 5 transacciones en 10 minutos', '{"max_transacciones_10min": 5}', 0.80, TRUE),
('Comerciante Alto Riesgo', 'Transacciones en comerciantes con alta tasa de fraude', '{"nivel_riesgo_comerciante": "alto"}', 0.60, TRUE),
('Distancia Geográfica Extrema', 'Transacción a más de 200km de ubicación habitual', '{"distancia_maxima": 200}', 0.50, TRUE),
('Monto Internacional Alto', 'Transferencias internacionales superiores a $50,000', '{"monto_internacional": 50000}', 0.65, TRUE),
('Patrón Velocidad Inusual', 'Transacciones muy rápidas en secuencia', '{"velocidad_transacciones": "alta"}', 0.55, TRUE),
('Canal de Riesgo', 'Transacciones online en horarios inusuales', '{"canal_horario_riesgo": "online_nocturno"}', 0.40, TRUE);

-- ===== GENERAR TRANSACCIONES REALISTAS =====
\echo '💳 Generando 10,000 transacciones realistas...';

-- 1. Insertar transacciones NORMALES (7,500 transacciones)
\echo '   📈 Generando 7,500 transacciones normales...';
INSERT INTO transacciones (
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    1000 + (gs % 1000),  -- Cuentas distribuidas entre 1000-2000
    CASE 
        WHEN random() < 0.5 THEN 150 + (random() * 1850)
        WHEN random() < 0.8 THEN 2000 + (random() * 8000)
        WHEN random() < 0.95 THEN 10000 + (random() * 15000)
        ELSE 25000 + (random() * 25000)
    END,
    CASE (gs % 15)
        WHEN 0 THEN 'COM001' WHEN 1 THEN 'COM002' WHEN 2 THEN 'COM003' WHEN 3 THEN 'COM004' WHEN 4 THEN 'COM005'
        WHEN 5 THEN 'COM006' WHEN 6 THEN 'COM007' WHEN 7 THEN 'COM008' WHEN 8 THEN 'COM009' WHEN 9 THEN 'COM010'
        WHEN 10 THEN 'COM011' WHEN 11 THEN 'COM012' WHEN 12 THEN 'COM013' WHEN 13 THEN 'COM014' ELSE 'COM015'
    END,
    CASE (gs % 6)
        WHEN 0 THEN 'Alimentación' WHEN 1 THEN 'Combustibles' WHEN 2 THEN 'Gastronomía'
        WHEN 3 THEN 'Salud' WHEN 4 THEN 'Tecnología' ELSE 'Entretenimiento'
    END,
    CASE (gs % 10)
        WHEN 0 THEN 'Av. Corrientes 1500, CABA' WHEN 1 THEN 'Panamericana Km 25' WHEN 2 THEN 'Palermo, CABA'
        WHEN 3 THEN 'Florida 800, CABA' WHEN 4 THEN 'Av. 9 de Julio 1000' WHEN 5 THEN 'Recoleta Mall'
        WHEN 6 THEN 'Unicenter Shopping' WHEN 7 THEN 'Shopping Abasto' WHEN 8 THEN 'Microcentro, CABA'
        ELSE 'Puerto Madero'
    END,
    'Buenos Aires',
    'Argentina',
    CASE WHEN random() < 0.65 THEN 'Débito' WHEN random() < 0.9 THEN 'Crédito' ELSE 'Prepaga' END,
    TIME '06:00:00' + (random() * INTERVAL '17 hours'),
    CURRENT_DATE - (random() * 60)::int,
    FALSE,  -- ✅ EXPLÍCITAMENTE FALSE
    CASE WHEN random() < 0.6 THEN 'pos' WHEN random() < 0.85 THEN 'online' ELSE 'atm' END,
    5000 + (random() * 95000),
    (random() * 50)
FROM generate_series(1, 7500) gs;

-- 2. Insertar transacciones FRAUDULENTAS (2,500 transacciones)
\echo '   🚨 Generando 2,500 transacciones fraudulentas...';
INSERT INTO transacciones (
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    1000 + (gs % 1000),  -- Mismas cuentas
    CASE 
        WHEN random() < 0.4 THEN 15000 + (random() * 35000)   -- Montos altos sutiles
        WHEN random() < 0.7 THEN 50000 + (random() * 50000)   -- Montos muy altos
        WHEN random() < 0.85 THEN 8000 + (random() * 17000)   -- Montos medianos
        ELSE 100000 + (random() * 100000)                     -- Montos extremos
    END,
    CASE (gs % 10)
        WHEN 0 THEN 'COM019' WHEN 1 THEN 'COM023' WHEN 2 THEN 'COM017'  -- Alto riesgo
        WHEN 3 THEN 'COM016' WHEN 4 THEN 'COM018' WHEN 5 THEN 'COM020'  -- Medio riesgo
        WHEN 6 THEN 'COM021' WHEN 7 THEN 'COM022' WHEN 8 THEN 'COM024'  -- E-commerce/otros
        ELSE 'COM007'  -- Algunos comerciantes legítimos usados fraudulentemente
    END,
    CASE (gs % 6)
        WHEN 0 THEN 'Financiero' WHEN 1 THEN 'E-commerce' WHEN 2 THEN 'Entretenimiento'
        WHEN 3 THEN 'Bancario' WHEN 4 THEN 'Tecnología' ELSE 'Retail'
    END,
    CASE (gs % 8)
        WHEN 0 THEN 'Online' WHEN 1 THEN 'Microcentro' WHEN 2 THEN 'Puerto Madero'
        WHEN 3 THEN 'Londres' WHEN 4 THEN 'São Paulo' WHEN 5 THEN 'Miami'
        WHEN 6 THEN 'Madrid' ELSE 'Villa Crespo'
    END,
    CASE (gs % 6)
        WHEN 0 THEN 'Buenos Aires' WHEN 1 THEN 'Buenos Aires' WHEN 2 THEN 'São Paulo'
        WHEN 3 THEN 'Londres' WHEN 4 THEN 'Miami' ELSE 'Madrid'
    END,
    CASE (gs % 6)
        WHEN 0 THEN 'Argentina' WHEN 1 THEN 'Argentina' WHEN 2 THEN 'Brasil'
        WHEN 3 THEN 'Reino Unido' WHEN 4 THEN 'Estados Unidos' ELSE 'España'
    END,
    CASE WHEN random() < 0.8 THEN 'Crédito' ELSE 'Débito' END,
    CASE 
        WHEN random() < 0.3 THEN TIME '00:00:00' + (random() * INTERVAL '6 hours')
        WHEN random() < 0.4 THEN TIME '22:00:00' + (random() * INTERVAL '2 hours')
        ELSE TIME '06:00:00' + (random() * INTERVAL '18 hours')
    END,
    CURRENT_DATE - (random() * 14)::int,
    TRUE,  -- ✅ EXPLÍCITAMENTE TRUE
    CASE WHEN random() < 0.7 THEN 'online' WHEN random() < 0.85 THEN 'atm' ELSE 'mobile' END,
    CASE 
        WHEN random() < 0.3 THEN 500 + (random() * 4500)
        WHEN random() < 0.6 THEN 5000 + (random() * 20000)
        ELSE 25000 + (random() * 75000)
    END,
    CASE 
        WHEN random() < 0.3 THEN 100 + (random() * 400)
        WHEN random() < 0.5 THEN 50 + (random() * 100)
        ELSE 500 + (random() * 1500)
    END
FROM generate_series(1, 2500) gs;

-- ===== VERIFICAR DATOS GENERADOS =====
\echo '🔍 Verificando datos generados...';
\echo 'Estadísticas de transacciones:';

SELECT 
    'Total transacciones' as tipo,
    COUNT(*) as cantidad
FROM transacciones
UNION ALL
SELECT 
    'Transacciones fraudulentas' as tipo,
    COUNT(*) as cantidad
FROM transacciones WHERE es_fraude = TRUE
UNION ALL
SELECT 
    'Transacciones normales' as tipo,
    COUNT(*) as cantidad
FROM transacciones WHERE es_fraude = FALSE
UNION ALL
SELECT 
    'Comerciantes registrados' as tipo,
    COUNT(*) as cantidad
FROM comerciantes;

-- ===== GENERAR ALERTAS =====
\echo '🚨 Generando alertas para transacciones fraudulentas...';
INSERT INTO alertas_fraude (transaccion_id, tipo_alerta, nivel_riesgo, puntuacion_riesgo, descripcion)
SELECT
    t.id,
    'Alerta Automática de Fraude',
    CASE
        WHEN t.monto > 150000 THEN 'crítico'
        WHEN t.monto > 100000 THEN 'alto'
        WHEN t.monto > 50000 THEN 'medio'
        ELSE 'bajo'
    END,
    CASE
        WHEN t.monto > 150000 THEN 95.0
        WHEN t.monto > 100000 THEN 85.0
        WHEN t.monto > 50000 THEN 75.0
        ELSE 65.0
    END,
    'Transacción marcada como fraudulenta por el sistema'
FROM transacciones t
WHERE t.es_fraude = TRUE;

-- ===== ACTUALIZAR ESTADÍSTICAS DE COMERCIANTES =====
\echo '📊 Actualizando estadísticas de comerciantes...';
UPDATE comerciantes SET
    total_transacciones = (
        SELECT COUNT(*) FROM transacciones
        WHERE comerciante = comerciantes.codigo_comerciante
    ),
    transacciones_fraudulentas = (
        SELECT COUNT(*) FROM transacciones
        WHERE comerciante = comerciantes.codigo_comerciante AND es_fraude = TRUE
    );

UPDATE comerciantes SET
    tasa_fraude = CASE 
        WHEN total_transacciones > 0 THEN 
            transacciones_fraudulentas::DECIMAL / total_transacciones::DECIMAL
        ELSE 0
    END;

\echo '✅ Datos realistas insertados exitosamente en bank_transactions';
\echo '   📊 10,000 transacciones generadas (7,500 normales + 2,500 fraudulentas)';
\echo '   🏪 25 comerciantes configurados';
\echo '   🚨 Alertas de fraude generadas automáticamente';