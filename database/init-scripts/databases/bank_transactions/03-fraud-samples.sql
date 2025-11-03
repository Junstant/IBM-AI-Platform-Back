-- databases/bank_transactions/03-fraud-samples.sql
-- Generación masiva de transacciones COMPLETAMENTE COMPATIBLE con advanced_fraud_model.py y behavioral_fraud_model.py

\echo '🔍 Generando datos súper realistas y COMPATIBLES para detección de fraude IA...'
\echo '   Target: 10,000+ transacciones con distribución optimizada para ML';

\c bank_transactions;

-- ===== INSERTAR COMERCIANTES COMPATIBLES CON EL MODELO IA =====
\echo '🏪 Configurando comerciantes compatibles con IA avanzada...';
INSERT INTO comerciantes (codigo_comerciante, nombre, categoria, subcategoria, ubicacion, ciudad, pais, nivel_riesgo) VALUES
-- Comerciantes 100% legítimos (bajo riesgo) - EXACTAMENTE como espera el modelo
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

-- ⚠️ COMERCIANTES DE RIESGO MEDIO - EXACTAMENTE como espera advanced_fraud_model.py
('COM019', 'TechStore Online', 'Tecnología', 'E-commerce', 'Zona Norte', 'Buenos Aires', 'Argentina', 'medio'),
('COM020', 'Western Union Centro', 'Financiero', 'Remesas', 'Microcentro', 'Buenos Aires', 'Argentina', 'medio'),
('COM021', 'Amazon Argentina', 'E-commerce', 'Marketplace', 'Online', 'Buenos Aires', 'Argentina', 'medio'),
('COM022', 'Casino Puerto Madero', 'Entretenimiento', 'Casinos', 'Puerto Madero', 'Buenos Aires', 'Argentina', 'medio'),
('COM023', 'Binance P2P', 'Financiero', 'Criptomonedas', 'Online', 'Buenos Aires', 'Argentina', 'medio'),
('COM024', 'Nike Store Online', 'Retail', 'Deportes', 'Online', 'Buenos Aires', 'Argentina', 'medio'),
('COM025', 'MoneyGram Flores', 'Financiero', 'Transferencias', 'Flores', 'Buenos Aires', 'Argentina', 'medio'),

-- 🚨 NUEVOS COMERCIANTES SOSPECHOSOS para testear behavioral_fraud_model.py
('SUSP001', 'pepe-services-online', 'E-commerce', 'Servicios Online', 'Desconocida', 'Miami', 'USA', 'alto'),
('SUSP002', 'random-goods-store', 'Retail', 'Tienda General', 'Desconocida', 'Lagos', 'Nigeria', 'alto'),
('SUSP003', 'Crypto4U', 'Financiero', 'Criptomonedas', 'Online', 'Online', 'Rusia', 'alto'),
('SUSP004', 'online-casino-bet', 'Entretenimiento', 'Casinos Online', 'Online', 'Online', 'Malta', 'alto'),
('SUSP005', 'unknown-merchant-test', 'Desconocido', 'Varios', 'Online', 'Online', 'Desconocido', 'alto');

-- ===== INSERTAR REGLAS DE FRAUDE OPTIMIZADAS PARA IA =====
\echo '📋 Configurando reglas de detección optimizadas para IA...';
INSERT INTO reglas_fraude (nombre, descripcion, condicion, peso, activa) VALUES
('Monto Extremadamente Alto', 'Transacción superior a $500,000', '{"monto_minimo": 500000}', 0.90, TRUE),
('Monto Muy Alto', 'Transacción superior a $75,000', '{"monto_minimo": 75000}', 0.75, TRUE),
('Monto Alto Sospechoso', 'Transacción superior a $45,000', '{"monto_minimo": 45000}', 0.60, TRUE),
('Horario Muy Inusual', 'Transacciones entre 01:00 y 04:00', '{"horario_inicio": "01:00", "horario_fin": "04:00"}', 0.40, TRUE),
('Comerciante Riesgo Alto', 'Comerciantes con nivel de riesgo alto', '{"comerciantes_riesgo": ["COM019", "COM020", "COM021", "COM022", "COM023", "COM024", "COM025"]}', 0.50, TRUE),
('País de Alto Riesgo', 'Transacciones desde países sancionados', '{"paises_riesgo": ["Nigeria", "Rusia", "Malta"]}', 0.65, TRUE),
('Distancia Extrema', 'Ubicación muy distante de lo habitual', '{"distancia_minima": 1000}', 0.45, TRUE),
('Comerciante Desconocido', 'Comerciantes no registrados previamente', '{"comerciante_nuevo": true}', 0.35, TRUE);

-- ===== GENERAR TRANSACCIONES NORMALES OPTIMIZADAS PARA ML =====
\echo '   📈 Generando 7,500 transacciones normales optimizadas para IA...';
INSERT INTO transacciones (
    numero_transaccion,
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT
    'TXN-N-' || EXTRACT(EPOCH FROM now())::BIGINT || '-' || gs,
    1000 + (gs % 500),  -- 500 usuarios diferentes para crear patrones de comportamiento
    CASE
        WHEN random() < 0.35 THEN 100 + (random() * 400)::NUMERIC(10,2)      -- Compras pequeñas: $100-500
        WHEN random() < 0.65 THEN 500 + (random() * 1500)::NUMERIC(10,2)     -- Compras medianas: $500-2000
        WHEN random() < 0.85 THEN 2000 + (random() * 3000)::NUMERIC(10,2)    -- Compras grandes: $2000-5000
        WHEN random() < 0.95 THEN 5000 + (random() * 8000)::NUMERIC(10,2)    -- Compras muy grandes: $5000-13000
        ELSE 13000 + (random() * 12000)::NUMERIC(10,2)                        -- Compras especiales: $13000-25000
    END,
    -- Usar SOLO comerciantes legítimos para transacciones normales
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
    -- Horarios NORMALES (6AM a 11PM) para entrenar el modelo correctamente
    TIME '06:00:00' + (random() * INTERVAL '17 hours'),
    CURRENT_DATE - (random() * 90)::int,
    FALSE,  -- ✅ Definitivamente NO es fraude
    CASE WHEN random() < 0.65 THEN 'pos' WHEN random() < 0.85 THEN 'online' ELSE 'atm' END,
    15000 + (random() * 85000)::NUMERIC(10,2),  -- Saldos realistas
    (random() * 15)::NUMERIC(8,2)  -- Distancias cortas para transacciones normales
FROM generate_series(1, 7500) gs;

-- ===== GENERAR FRAUDES SUTILES PARA ENTRENAR IA =====
\echo '   🚨 Generando 1,800 fraudes sutiles para entrenar IA avanzada...';

-- Tipo 1: Fraudes sutiles con comerciantes de riesgo medio
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
        WHEN random() < 0.3 THEN 8000 + (random() * 12000)::NUMERIC(10,2)    -- $8k-20k
        WHEN random() < 0.6 THEN 20000 + (random() * 25000)::NUMERIC(10,2)   -- $20k-45k
        WHEN random() < 0.85 THEN 45000 + (random() * 30000)::NUMERIC(10,2)  -- $45k-75k ⚠️ Rango crítico
        ELSE 75000 + (random() * 50000)::NUMERIC(10,2)                        -- $75k-125k 🚨 Muy alto
    END,
    -- Usar comerciantes de riesgo medio COMO ESPERA EL MODELO
    CASE (gs % 7)
        WHEN 0 THEN 'COM019' WHEN 1 THEN 'COM020' WHEN 2 THEN 'COM021' WHEN 3 THEN 'COM022'
        WHEN 4 THEN 'COM023' WHEN 5 THEN 'COM024' ELSE 'COM025'
    END,
    CASE (gs % 6)
        WHEN 0 THEN 'Tecnología' WHEN 1 THEN 'Financiero' WHEN 2 THEN 'E-commerce' 
        WHEN 3 THEN 'Entretenimiento' WHEN 4 THEN 'Retail' ELSE 'Financiero'
    END,
    CASE (gs % 8)
        WHEN 0 THEN 'Online' WHEN 1 THEN 'Zona Norte GBA' WHEN 2 THEN 'La Plata'
        WHEN 3 THEN 'Córdoba Capital' WHEN 4 THEN 'Rosario Centro' WHEN 5 THEN 'Microcentro'
        WHEN 6 THEN 'Puerto Madero' ELSE 'Villa Crespo'
    END,
    CASE
        WHEN random() < 0.8 THEN 'Buenos Aires'  -- Mayoría en Argentina
        WHEN random() < 0.95 THEN 'Córdoba'
        ELSE 'Santa Fe'
    END,
    'Argentina',
    CASE WHEN random() < 0.75 THEN 'Crédito' ELSE 'Débito' END,
    CASE
        WHEN random() < 0.6 THEN TIME '07:00:00' + (random() * INTERVAL '16 hours')  -- Normal
        WHEN random() < 0.8 THEN TIME '22:00:00' + (random() * INTERVAL '3 hours')   -- Tarde
        ELSE TIME '01:00:00' + (random() * INTERVAL '4 hours')                        -- 🚨 Muy tarde
    END,
    CURRENT_DATE - (random() * 45)::int,
    TRUE,  -- ✅ Definitivamente ES fraude
    CASE WHEN random() < 0.7 THEN 'online' WHEN random() < 0.9 THEN 'pos' ELSE 'atm' END,
    CASE
        WHEN random() < 0.4 THEN 5000 + (random() * 15000)::NUMERIC(10,2)   -- Saldos bajos
        WHEN random() < 0.7 THEN 20000 + (random() * 40000)::NUMERIC(10,2)  -- Saldos medios
        ELSE 60000 + (random() * 90000)::NUMERIC(10,2)                       -- Saldos altos
    END,
    CASE
        WHEN random() < 0.3 THEN (random() * 50)::NUMERIC(8,2)         -- Distancia normal
        WHEN random() < 0.6 THEN 50 + (random() * 150)::NUMERIC(8,2)   -- Distancia media
        ELSE 200 + (random() * 300)::NUMERIC(8,2)                      -- 🚨 Distancia alta
    END
FROM generate_series(10001, 11200) gs;

-- Tipo 2: Fraudes de bajo monto (testeo de tarjetas)
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
        WHEN random() < 0.6 THEN 50 + (random() * 450)::NUMERIC(10,2)    -- $50-500 (testeo de tarjetas)
        WHEN random() < 0.85 THEN 500 + (random() * 1500)::NUMERIC(10,2) -- $500-2000
        ELSE 2000 + (random() * 3000)::NUMERIC(10,2)                     -- $2000-5000
    END,
    -- Mezclar comerciantes legítimos y de riesgo medio
    CASE (gs % 14)
        WHEN 0 THEN 'COM019' WHEN 1 THEN 'COM020' WHEN 2 THEN 'COM021' WHEN 3 THEN 'COM022'
        WHEN 4 THEN 'COM023' WHEN 5 THEN 'COM024' WHEN 6 THEN 'COM025' WHEN 7 THEN 'COM001'
        WHEN 8 THEN 'COM008' WHEN 9 THEN 'COM014' WHEN 10 THEN 'COM016' WHEN 11 THEN 'COM017'
        WHEN 12 THEN 'COM002' ELSE 'COM011'
    END,
    CASE (gs % 6)
        WHEN 0 THEN 'E-commerce' WHEN 1 THEN 'Tecnología' WHEN 2 THEN 'Financiero'
        WHEN 3 THEN 'Retail' WHEN 4 THEN 'Alimentación' ELSE 'Gastronomía'
    END,
    CASE (gs % 10)
        WHEN 0 THEN 'Online' WHEN 1 THEN 'Buenos Aires Centro' WHEN 2 THEN 'Zona Norte'
        WHEN 3 THEN 'La Plata' WHEN 4 THEN 'Córdoba' WHEN 5 THEN 'Rosario'
        WHEN 6 THEN 'Mendoza' WHEN 7 THEN 'Mar del Plata' WHEN 8 THEN 'Palermo, CABA'
        ELSE 'Microcentro, CABA'
    END,
    CASE (gs % 7)
        WHEN 0 THEN 'Buenos Aires' WHEN 1 THEN 'Buenos Aires' WHEN 2 THEN 'Buenos Aires'
        WHEN 3 THEN 'Córdoba' WHEN 4 THEN 'Santa Fe' WHEN 5 THEN 'Mendoza' ELSE 'Buenos Aires'
    END,
    'Argentina',
    CASE WHEN random() < 0.65 THEN 'Débito' ELSE 'Crédito' END,
    CASE
        WHEN random() < 0.7 THEN TIME '08:00:00' + (random() * INTERVAL '14 hours')  -- Horarios normales
        WHEN random() < 0.85 THEN TIME '23:00:00' + (random() * INTERVAL '2 hours') -- Noche
        ELSE TIME '02:00:00' + (random() * INTERVAL '3 hours')                       -- Madrugada 🚨
    END,
    CURRENT_DATE - (random() * 75)::int,
    TRUE,  -- ✅ Definitivamente ES fraude
    CASE WHEN random() < 0.8 THEN 'online' WHEN random() < 0.95 THEN 'pos' ELSE 'mobile' END,
    8000 + (random() * 42000)::NUMERIC(10,2),  -- Saldos variados
    (random() * 200)::NUMERIC(8,2)  -- Distancias variadas
FROM generate_series(20001, 20400) gs;

-- ===== FRAUDES EXTREMOS PARA TESTEAR BEHAVIORAL MODEL =====
\echo '   🔥 Generando fraudes EXTREMOS para testear behavioral_fraud_model.py...';
INSERT INTO transacciones (
    numero_transaccion, cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
) VALUES
-- Caso 1: Monto extremo + comerciante sospechoso + país de riesgo
('TXN-EXT-001', 1001, 12345678.90, 'SUSP001', 'E-commerce',
'Desconocida', 'Miami', 'USA', 'Crédito', '14:30:00', CURRENT_DATE - 1,
TRUE, 'online', 50000.00, 7000.0),

-- Caso 2: Secuencia rápida de compras pequeñas desde país de alto riesgo
('TXN-EXT-002A', 1002, 150.00, 'SUSP002', 'Retail',
'Desconocida', 'Lagos', 'Nigeria', 'Débito', '03:15:00', CURRENT_DATE - 2,
TRUE, 'online', 2500.00, 9000.0),
('TXN-EXT-002B', 1002, 175.50, 'SUSP002', 'Retail',
'Desconocida', 'Lagos', 'Nigeria', 'Débito', '03:18:00', CURRENT_DATE - 2,
TRUE, 'online', 2325.00, 9000.0),
('TXN-EXT-002C', 1002, 89.99, 'SUSP002', 'Retail',
'Desconocida', 'Lagos', 'Nigeria', 'Débito', '03:22:00', CURRENT_DATE - 2,
TRUE, 'online', 2235.01, 9000.0),

-- Caso 3: Comerciante de cripto + horario sospechoso + país sancionado
('TXN-EXT-003', 1003, 25000.00, 'SUSP003', 'Financiero',
'Online', 'Online', 'Rusia', 'Crédito', '02:45:00', CURRENT_DATE - 5,
TRUE, 'online', 30000.00, 12000.0),

-- Caso 4: Casino online + monto muy alto + país offshore
('TXN-EXT-004', 1010, 550000.00, 'SUSP004', 'Entretenimiento',
'Online', 'Online', 'Malta', 'Crédito', '23:50:00', CURRENT_DATE - 3,
TRUE, 'online', 600000.00, 11000.0),

-- Caso 5: Comerciante completamente desconocido + patrón anómalo
('TXN-EXT-005', 1015, 999999.99, 'SUSP005', 'Desconocido',
'Online', 'Online', 'Desconocido', 'Crédito', '01:33:00', CURRENT_DATE - 1,
TRUE, 'online', 1000000.00, 15000.0);

-- ===== GENERAR PERFILES DE USUARIO PARA BEHAVIORAL ANALYSIS =====
\echo '👤 Creando perfiles de usuario para análisis comportamental...';
INSERT INTO perfiles_usuario (cuenta_id, ubicacion_frecuente, comerciante_frecuente,
horario_preferido_inicio, horario_preferido_fin, monto_promedio, 
frecuencia_transaccional, ratio_fin_semana, ratio_noche) 
SELECT 
    1000 + gs,
    CASE (gs % 5)
        WHEN 0 THEN 'Microcentro, CABA'
        WHEN 1 THEN 'Palermo, CABA'
        WHEN 2 THEN 'Recoleta'
        WHEN 3 THEN 'Puerto Madero'
        ELSE 'Villa Crespo'
    END,
    CASE (gs % 7)
        WHEN 0 THEN 'COM001' WHEN 1 THEN 'COM002' WHEN 2 THEN 'COM003'
        WHEN 3 THEN 'COM004' WHEN 4 THEN 'COM005' WHEN 5 THEN 'COM006'
        ELSE 'COM007'
    END,
    CASE 
        WHEN random() < 0.6 THEN '08:00'::time
        WHEN random() < 0.8 THEN '09:00'::time
        ELSE '10:00'::time
    END,
    CASE
        WHEN random() < 0.5 THEN '18:00'::time
        WHEN random() < 0.8 THEN '20:00'::time
        ELSE '22:00'::time  
    END,
    CASE
        WHEN random() < 0.4 THEN 200 + (random() * 800)::NUMERIC(10,2)
        WHEN random() < 0.8 THEN 1000 + (random() * 3000)::NUMERIC(10,2)  
        ELSE 4000 + (random() * 8000)::NUMERIC(10,2)
    END,
    CASE 
        WHEN random() < 0.3 THEN 0.17 + (random() * 0.33)::NUMERIC(4,2)  -- Usuarios poco activos (5-15 txn/mes)
        WHEN random() < 0.7 THEN 0.50 + (random() * 0.67)::NUMERIC(4,2)  -- Usuarios normales (15-35 txn/mes)
        ELSE 1.17 + (random() * 1.00)::NUMERIC(4,2)                       -- Usuarios muy activos (35-65 txn/mes)
    END,
    CASE WHEN random() < 0.3 THEN 0.25 + (random() * 0.15)::NUMERIC(4,3) ELSE 0.05 + (random() * 0.15)::NUMERIC(4,3) END,  -- 30% prefieren fin de semana
    CASE WHEN random() < 0.2 THEN 0.10 + (random() * 0.20)::NUMERIC(4,3) ELSE 0.00 + (random() * 0.08)::NUMERIC(4,3) END   -- 20% activos de noche
FROM generate_series(1, 500) gs;

-- ===== ESTADÍSTICAS FINALES =====
\echo '📊 Generando estadísticas finales del dataset...';

-- Contar transacciones por tipo
DO $$
DECLARE
    total_count INTEGER;
    fraud_count INTEGER;
    normal_count INTEGER;
    extreme_fraud_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_count FROM transacciones;
    SELECT COUNT(*) INTO fraud_count FROM transacciones WHERE es_fraude = TRUE;
    SELECT COUNT(*) INTO normal_count FROM transacciones WHERE es_fraude = FALSE;
    SELECT COUNT(*) INTO extreme_fraud_count FROM transacciones WHERE monto > 100000 AND es_fraude = TRUE;
    
    RAISE NOTICE '✅ DATASET GENERADO EXITOSAMENTE:';
    RAISE NOTICE '   📊 Total transacciones: %', total_count;
    RAISE NOTICE '   ✅ Transacciones normales: % (%.1f%%)', normal_count, (normal_count::float / total_count * 100);
    RAISE NOTICE '   🚨 Transacciones fraudulentas: % (%.1f%%)', fraud_count, (fraud_count::float / total_count * 100);
    RAISE NOTICE '   🔥 Fraudes extremos: % (%.1f%% del total)', extreme_fraud_count, (extreme_fraud_count::float / total_count * 100);
    RAISE NOTICE '   🏪 Comerciantes configurados: %', (SELECT COUNT(*) FROM comerciantes);
    RAISE NOTICE '   👤 Perfiles de usuario: %', (SELECT COUNT(*) FROM perfiles_usuario);
END $$;

\echo '🎯 Dataset optimizado para advanced_fraud_model.py y behavioral_fraud_model.py';
\echo '✅ Configuración completa finalizada exitosamente - LISTO PARA IA';