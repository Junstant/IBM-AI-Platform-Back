-- databases/bank_transactions/03-fraud-samples.sql
-- Generación masiva de transacciones SUTILES Y REALISTAS para detección de fraude

\echo '🔍 Generando datos sutiles y realistas para detección de fraude...'
\echo '   Target: 10,000+ transacciones con distribución MUY realista';

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
-- Comerciantes 100% legítimos (bajo riesgo)
('COM001', 'Supermercado Disco', 'Alimentación', 'Supermercados', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM002', 'Shell Estación Norte', 'Combustibles', 'Estaciones de Servicio', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'bajo'),
('COM003', 'Restaurant Don Julio', 'Gastronomía', 'Restaurantes', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM004', 'Farmacity Centro', 'Salud', 'Farmacias', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM005', 'McDonald''s Obelisco', 'Gastronomía', 'Comida Rápida', 'Av. 9 de Julio 1000', 'Buenos Aires', 'Argentina', 'bajo'),
('COM006', 'Starbucks Recoleta', 'Gastronomía', 'Cafeterías', 'Recoleta Mall', 'Buenos Aires', 'Argentina', 'bajo'),
('COM007', 'ATM Banco Galicia', 'Bancario', 'Cajeros Automáticos', 'Microcentro, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM008', 'Garbarino Unicenter', 'Tecnología', 'Electrónicos', 'Unicenter Shopping', 'Buenos Aires', 'Argentina', 'bajo'),
('COM009', 'Cine Hoyts Abasto', 'Entretenimiento', 'Cines', 'Shopping Abasto', 'Buenos Aires', 'Argentina', 'bajo'),
('COM010', 'YPF San Isidro', 'Combustibles', 'Estaciones de Servicio', 'Panamericana Km 30', 'Buenos Aires', 'Argentina', 'bajo'),
('COM011', 'Walmart Palermo', 'Alimentación', 'Supermercados', 'Palermo Soho', 'Buenos Aires', 'Argentina', 'bajo'),
('COM012', 'Subway Florida', 'Gastronomía', 'Comida Rápida', 'Florida 500', 'Buenos Aires', 'Argentina', 'bajo'),
('COM013', 'Dr. Ahorro Farmacia', 'Salud', 'Farmacias', 'Av. Cabildo 2000', 'Buenos Aires', 'Argentina', 'bajo'),
('COM014', 'Frávega Electro', 'Tecnología', 'Electrodomésticos', 'Av. Rivadavia 5000', 'Buenos Aires', 'Argentina', 'bajo'),
('COM015', 'Havanna Puerto Madero', 'Gastronomía', 'Confiterías', 'Puerto Madero', 'Buenos Aires', 'Argentina', 'bajo'),
('COM016', 'Coto Digital', 'Alimentación', 'Supermercados Online', 'Villa Crespo', 'Buenos Aires', 'Argentina', 'bajo'),
('COM017', 'Mercado Libre Pago', 'E-commerce', 'Marketplace', 'San Telmo', 'Buenos Aires', 'Argentina', 'bajo'),
('COM018', 'Rappi Delivery', 'Gastronomía', 'Delivery', 'Belgrano', 'Buenos Aires', 'Argentina', 'bajo'),

-- Comerciantes con SUTILES indicadores de riesgo medio (muy realistas)
('COM019', 'TechStore Online', 'Tecnología', 'E-commerce', 'Zona Norte', 'Buenos Aires', 'Argentina', 'medio'),
('COM020', 'Western Union Centro', 'Financiero', 'Remesas', 'Microcentro', 'Buenos Aires', 'Argentina', 'medio'),
('COM021', 'Amazon Argentina', 'E-commerce', 'Marketplace', 'Online', 'Buenos Aires', 'Argentina', 'medio'),
('COM022', 'Casino Puerto Madero', 'Entretenimiento', 'Casinos', 'Puerto Madero', 'Buenos Aires', 'Argentina', 'medio'),
('COM023', 'Binance P2P', 'Financiero', 'Criptomonedas', 'Online', 'Buenos Aires', 'Argentina', 'medio'),
('COM024', 'Nike Store Online', 'Retail', 'Deportes', 'Online', 'Buenos Aires', 'Argentina', 'medio'),
('COM025', 'MoneyGram Flores', 'Financiero', 'Transferencias', 'Flores', 'Buenos Aires', 'Argentina', 'medio');

-- ===== INSERTAR REGLAS DE FRAUDE SUTILES =====
\echo '📋 Configurando reglas de detección sutiles...';
INSERT INTO reglas_fraude (nombre, descripcion, condicion, peso, activa) VALUES
('Monto Muy Alto', 'Transacción superior a $200,000', '{"monto_minimo": 200000}', 0.70, TRUE),
('Horario Muy Inusual', 'Transacciones entre 01:00 y 04:00', '{"horario_inicio": "01:00", "horario_fin": "04:00"}', 0.35, TRUE),
('Secuencia Rápida', 'Múltiples transacciones seguidas', '{"secuencia_rapida": true}', 0.50, TRUE),
('Ubicación Inusual', 'Transacción en ubicación no habitual', '{"ubicacion_nueva": true}', 0.40, TRUE),
('Monto Atípico Usuario', 'Monto muy superior al promedio del usuario', '{"monto_atipico": true}', 0.45, TRUE),
('Comerciante Nuevo', 'Primera vez en comerciante desconocido', '{"comerciante_nuevo": true}', 0.30, TRUE);

-- ===== GENERAR TRANSACCIONES NORMALES REALISTAS =====
\echo '   📈 Generando 8,500 transacciones completamente normales...';
INSERT INTO transacciones (
    numero_transaccion,
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT
    'TXN-N-' || EXTRACT(EPOCH FROM now())::BIGINT || '-' || gs,
    1000 + (gs % 500),  -- 500 usuarios diferentes para evitar conflictos
    CASE
        WHEN random() < 0.3 THEN 50 + (random() * 450)::NUMERIC(10,2)      -- Compras pequeñas: $50-500
        WHEN random() < 0.6 THEN 500 + (random() * 1500)::NUMERIC(10,2)    -- Compras medianas: $500-2000
        WHEN random() < 0.85 THEN 2000 + (random() * 3000)::NUMERIC(10,2)  -- Compras grandes: $2000-5000
        WHEN random() < 0.95 THEN 5000 + (random() * 10000)::NUMERIC(10,2) -- Compras muy grandes: $5000-15000
        ELSE 15000 + (random() * 20000)::NUMERIC(10,2)                      -- Compras especiales: $15000-35000
    END,
    CASE (gs % 18)
        WHEN 0 THEN 'COM001' WHEN 1 THEN 'COM002' WHEN 2 THEN 'COM003' WHEN 3 THEN 'COM004'
        WHEN 4 THEN 'COM005' WHEN 5 THEN 'COM006' WHEN 6 THEN 'COM007' WHEN 7 THEN 'COM008'
        WHEN 8 THEN 'COM009' WHEN 9 THEN 'COM010' WHEN 10 THEN 'COM011' WHEN 11 THEN 'COM012'
        WHEN 12 THEN 'COM013' WHEN 13 THEN 'COM014' WHEN 14 THEN 'COM015' WHEN 15 THEN 'COM016'
        WHEN 16 THEN 'COM017' ELSE 'COM018'
    END,
    CASE (gs % 7)
        WHEN 0 THEN 'Alimentación' WHEN 1 THEN 'Combustibles' WHEN 2 THEN 'Gastronomía'
        WHEN 3 THEN 'Salud' WHEN 4 THEN 'Tecnología' WHEN 5 THEN 'Entretenimiento' ELSE 'E-commerce'
    END,
    CASE (gs % 12)
        WHEN 0 THEN 'Av. Corrientes 1500, CABA' WHEN 1 THEN 'Panamericana Km 25' WHEN 2 THEN 'Palermo, CABA'
        WHEN 3 THEN 'Florida 800, CABA' WHEN 4 THEN 'Av. 9 de Julio 1000' WHEN 5 THEN 'Recoleta Mall'
        WHEN 6 THEN 'Unicenter Shopping' WHEN 7 THEN 'Shopping Abasto' WHEN 8 THEN 'Microcentro, CABA'
        WHEN 9 THEN 'Puerto Madero' WHEN 10 THEN 'Villa Crespo' ELSE 'San Telmo'
    END,
    'Buenos Aires',
    'Argentina',
    CASE WHEN random() < 0.60 THEN 'Débito' WHEN random() < 0.85 THEN 'Crédito' ELSE 'Prepaga' END,
    TIME '06:00:00' + (random() * INTERVAL '17 hours'),
    CURRENT_DATE - (random() * 90)::int,
    FALSE,
    CASE WHEN random() < 0.65 THEN 'pos' WHEN random() < 0.85 THEN 'online' ELSE 'atm' END,
    10000 + (random() * 90000)::NUMERIC(10,2),
    (random() * 20)::NUMERIC(8,2)
FROM generate_series(1, 8500) gs;

-- ===== GENERAR TRANSACCIONES FRAUDULENTAS SUTILES =====
\echo '   🚨 Generando 1,500 transacciones fraudulentas SUTILES...';

-- Tipo 1: Fraudes sutiles con montos moderadamente altos
INSERT INTO transacciones (
    numero_transaccion,
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT
    'TXN-F1-' || EXTRACT(EPOCH FROM now())::BIGINT || '-' || gs,
    1000 + (gs % 500),
    CASE
        WHEN random() < 0.4 THEN 8000 + (random() * 12000)::NUMERIC(10,2)
        WHEN random() < 0.7 THEN 20000 + (random() * 25000)::NUMERIC(10,2)
        WHEN random() < 0.9 THEN 45000 + (random() * 30000)::NUMERIC(10,2)
        ELSE 75000 + (random() * 50000)::NUMERIC(10,2)
    END,
    CASE
        WHEN random() < 0.3 THEN
            CASE (gs % 8)
                WHEN 0 THEN 'COM001' WHEN 1 THEN 'COM008' WHEN 2 THEN 'COM014' WHEN 3 THEN 'COM017'
                WHEN 4 THEN 'COM019' WHEN 5 THEN 'COM021' WHEN 6 THEN 'COM024' ELSE 'COM016'
            END
        ELSE
            CASE (gs % 7)
                WHEN 0 THEN 'COM019' WHEN 1 THEN 'COM020' WHEN 2 THEN 'COM021' WHEN 3 THEN 'COM022'
                WHEN 4 THEN 'COM023' WHEN 5 THEN 'COM024' ELSE 'COM025'
            END
    END,
    CASE (gs % 8)
        WHEN 0 THEN 'Tecnología' WHEN 1 THEN 'Financiero' WHEN 2 THEN 'E-commerce' WHEN 3 THEN 'Entretenimiento'
        WHEN 4 THEN 'Retail' WHEN 5 THEN 'Alimentación' WHEN 6 THEN 'Gastronomía' ELSE 'Bancario'
    END,
    CASE
        WHEN random() < 0.6 THEN
            CASE (gs % 6)
                WHEN 0 THEN 'Buenos Aires Centro' WHEN 1 THEN 'Palermo, CABA' WHEN 2 THEN 'Recoleta'
                WHEN 3 THEN 'Puerto Madero' WHEN 4 THEN 'Villa Crespo' ELSE 'San Telmo'
            END
        ELSE
            CASE (gs % 5)
                WHEN 0 THEN 'Online' WHEN 1 THEN 'Zona Norte GBA' WHEN 2 THEN 'La Plata'
                WHEN 3 THEN 'Córdoba Capital' ELSE 'Rosario Centro'
            END
    END,
    CASE
        WHEN random() < 0.7 THEN 'Buenos Aires'
        WHEN random() < 0.85 THEN 'Buenos Aires'
        WHEN random() < 0.95 THEN 'Córdoba'
        ELSE 'Santa Fe'
    END,
    'Argentina',
    CASE WHEN random() < 0.75 THEN 'Crédito' ELSE 'Débito' END,
    CASE
        WHEN random() < 0.7 THEN TIME '07:00:00' + (random() * INTERVAL '16 hours')
        WHEN random() < 0.85 THEN TIME '22:00:00' + (random() * INTERVAL '3 hours')
        ELSE TIME '01:00:00' + (random() * INTERVAL '4 hours')
    END,
    CURRENT_DATE - (random() * 30)::int,
    TRUE,
    CASE WHEN random() < 0.6 THEN 'online' WHEN random() < 0.8 THEN 'pos' ELSE 'atm' END,
    CASE
        WHEN random() < 0.3 THEN 1000 + (random() * 8000)::NUMERIC(10,2)
        WHEN random() < 0.6 THEN 10000 + (random() * 30000)::NUMERIC(10,2)
        ELSE 50000 + (random() * 100000)::NUMERIC(10,2)
    END,
    CASE
        WHEN random() < 0.4 THEN (random() * 30)::NUMERIC(8,2)
        WHEN random() < 0.7 THEN 30 + (random() * 100)::NUMERIC(8,2)
        ELSE 100 + (random() * 200)::NUMERIC(8,2)
    END
FROM generate_series(10001, 10900) gs;

-- Tipo 2: Fraudes de bajo monto para testeo de tarjetas
INSERT INTO transacciones (
    numero_transaccion,
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT
    'TXN-F2-' || EXTRACT(EPOCH FROM now())::BIGINT || '-' || gs,
    1000 + (gs % 500),
    CASE
        WHEN random() < 0.5 THEN 200 + (random() * 800)::NUMERIC(10,2)
        WHEN random() < 0.8 THEN 1000 + (random() * 2000)::NUMERIC(10,2)
        ELSE 3000 + (random() * 5000)::NUMERIC(10,2)
    END,
    CASE (gs % 12)
        WHEN 0 THEN 'COM019' WHEN 1 THEN 'COM020' WHEN 2 THEN 'COM021' WHEN 3 THEN 'COM022'
        WHEN 4 THEN 'COM001' WHEN 5 THEN 'COM008' WHEN 6 THEN 'COM017' WHEN 7 THEN 'COM023'
        WHEN 8 THEN 'COM024' WHEN 9 THEN 'COM025' WHEN 10 THEN 'COM014' ELSE 'COM016'
    END,
    CASE (gs % 6)
        WHEN 0 THEN 'E-commerce' WHEN 1 THEN 'Tecnología' WHEN 2 THEN 'Financiero'
        WHEN 3 THEN 'Retail' WHEN 4 THEN 'Alimentación' ELSE 'Gastronomía'
    END,
    CASE (gs % 8)
        WHEN 0 THEN 'Online' WHEN 1 THEN 'Buenos Aires Centro' WHEN 2 THEN 'Zona Norte'
        WHEN 3 THEN 'La Plata' WHEN 4 THEN 'Córdoba' WHEN 5 THEN 'Rosario'
        WHEN 6 THEN 'Mendoza' ELSE 'Mar del Plata'
    END,
    CASE (gs % 6)
        WHEN 0 THEN 'Buenos Aires' WHEN 1 THEN 'Buenos Aires' WHEN 2 THEN 'Córdoba'
        WHEN 3 THEN 'Santa Fe' WHEN 4 THEN 'Mendoza' ELSE 'Buenos Aires'
    END,
    'Argentina',
    CASE WHEN random() < 0.65 THEN 'Débito' ELSE 'Crédito' END,
    CASE
        WHEN random() < 0.8 THEN TIME '08:00:00' + (random() * INTERVAL '14 hours')
        WHEN random() < 0.9 THEN TIME '23:00:00' + (random() * INTERVAL '2 hours')
        ELSE TIME '02:00:00' + (random() * INTERVAL '3 hours')
    END,
    CURRENT_DATE - (random() * 60)::int,
    TRUE,
    CASE WHEN random() < 0.7 THEN 'online' WHEN random() < 0.9 THEN 'pos' ELSE 'mobile' END,
    5000 + (random() * 45000)::NUMERIC(10,2),
    (random() * 150)::NUMERIC(8,2)
FROM generate_series(20001, 20600) gs;

-- ===== 🔥🔥 NUEVA SECCIÓN: FRAUDES EXTREMOS Y PATRONES INTERNACIONALES 🔥🔥 =====
\echo '   🚨 Generando fraudes EXTREMOS y de patrones internacionales...';
INSERT INTO transacciones (
    numero_transaccion, cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
) VALUES
-- Caso 1: Monto extremo, comerciante desconocido, país inusual (tu ejemplo)
('TXN-EXT-001', 1001, 12345678.90, 'pepe-services-online', 'E-commerce',
'Desconocida', 'Miami', 'USA', 'Crédito', '14:30:00', CURRENT_DATE - 1,
TRUE, 'online', 50000.00, 7000.0),

-- Caso 2: Múltiples compras pequeñas y rápidas desde un país de alto riesgo
('TXN-EXT-002', 1002, 150.00, 'random-goods-store', 'Retail',
'Desconocida', 'Lagos', 'Nigeria', 'Débito', '03:15:00', CURRENT_DATE - 2,
TRUE, 'online', 2500.00, 9000.0),
('TXN-EXT-003', 1002, 175.50, 'random-goods-store', 'Retail',
'Desconocida', 'Lagos', 'Nigeria', 'Débito', '03:18:00', CURRENT_DATE - 2,
TRUE, 'online', 2350.00, 9000.0),

-- Caso 3: Compra en comerciante de cripto a altas horas de la noche desde un país sancionado
('TXN-EXT-004', 1003, 25000.00, 'Crypto4U', 'Financiero',
'Online', 'Online', 'Rusia', 'Crédito', '02:45:00', CURRENT_DATE - 5,
TRUE, 'online', 30000.00, 12000.0),

-- Caso 4: Monto muy alto en un casino online
('TXN-EXT-005', 1010, 550000.00, 'online-casino-bet', 'Entretenimiento',
'Online', 'Online', 'Malta', 'Crédito', '23:50:00', CURRENT_DATE - 3,
TRUE, 'online', 600000.00, 11000.0);

\echo '✅ Configuración completa finalizada exitosamente';