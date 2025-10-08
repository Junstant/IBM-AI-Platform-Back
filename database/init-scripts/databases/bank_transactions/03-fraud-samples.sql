-- databases/bank_transactions/03-fraud-samples.sql
-- Generación masiva de transacciones para detección de fraude - VERSIÓN CONSOLIDADA

\echo '🔍 Generando datos masivos para detección de fraude...'
\echo '   Target: 10,000 transacciones con distribución realista';

\c bank_transactions;

-- ===== LIMPIAR DATOS EXISTENTES =====
\echo '🗑️ Limpiando datos existentes...';
TRUNCATE TABLE alertas_fraude RESTART IDENTITY CASCADE;
TRUNCATE TABLE transacciones RESTART IDENTITY CASCADE;
DELETE FROM comerciantes WHERE codigo_comerciante LIKE 'COM%' OR codigo_comerciante LIKE 'MERC%';
DELETE FROM reglas_fraude WHERE nombre IN ('Monto Muy Alto', 'Horario Nocturno', 'País de Alto Riesgo');

-- ===== INSERTAR COMERCIANTES REALISTAS =====
\echo '🏪 Configurando comerciantes realistas...';
INSERT INTO comerciantes (codigo_comerciante, nombre, categoria, subcategoria, ubicacion, ciudad, pais, nivel_riesgo) VALUES
-- Comerciantes legítimos (bajo riesgo)
('COM001', 'Supermercado Central', 'Alimentación', 'Supermercados', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM002', 'Shell Estación Norte', 'Combustibles', 'Estaciones de Servicio', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'bajo'),
('COM003', 'Restaurant El Buen Sabor', 'Gastronomía', 'Restaurantes', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM004', 'Farmacia del Centro', 'Salud', 'Farmacias', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM005', 'McDonald''s Plaza', 'Gastronomía', 'Comida Rápida', 'Av. Santa Fe 2100', 'Buenos Aires', 'Argentina', 'bajo'),
('COM006', 'Starbucks Recoleta', 'Gastronomía', 'Cafeterías', 'Recoleta Mall', 'Buenos Aires', 'Argentina', 'bajo'),
('COM007', 'ATM Banco Nación', 'Bancario', 'Cajeros Automáticos', 'Microcentro, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM008', 'Apple Store Unicenter', 'Tecnología', 'Electrónicos', 'Unicenter Shopping', 'Buenos Aires', 'Argentina', 'bajo'),
('COM009', 'Cine Hoyts', 'Entretenimiento', 'Cines', 'Shopping Abasto', 'Buenos Aires', 'Argentina', 'bajo'),
('COM010', 'YPF Estación', 'Combustibles', 'Estaciones de Servicio', 'Av. 9 de Julio', 'Buenos Aires', 'Argentina', 'bajo'),
('COM011', 'Walmart Express', 'Alimentación', 'Supermercados', 'Palermo Soho', 'Buenos Aires', 'Argentina', 'bajo'),
('COM012', 'Subway Microcentro', 'Gastronomía', 'Comida Rápida', 'Florida 500', 'Buenos Aires', 'Argentina', 'bajo'),
('COM013', 'Farmacity 24hs', 'Salud', 'Farmacias', 'Av. Cabildo 2000', 'Buenos Aires', 'Argentina', 'bajo'),
('COM014', 'Garbarino Electro', 'Tecnología', 'Electrodomésticos', 'Av. Rivadavia 5000', 'Buenos Aires', 'Argentina', 'bajo'),
('COM015', 'Havanna Café', 'Gastronomía', 'Confiterías', 'Puerto Madero', 'Buenos Aires', 'Argentina', 'bajo'),

-- Comerciantes sospechosos (medio-alto riesgo)
('FRAUD001', 'E-Shop Sospechoso', 'E-commerce', 'Venta Online', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'alto'),
('FRAUD002', 'Casino Internacional', 'Entretenimiento', 'Casinos', 'Las Vegas Strip', 'Las Vegas', 'Estados Unidos', 'alto'),
('FRAUD003', 'Western Union Miami', 'Financiero', 'Remesas', 'Online Transfer', 'Miami', 'Estados Unidos', 'medio'),
('FRAUD004', 'Crypto Exchange Anon', 'Financiero', 'Criptomonedas', 'Servidor Anónimo', 'Desconocida', 'Desconocido', 'alto'),
('FRAUD005', 'Kiosco Villa 31', 'Telecomunicaciones', 'Recargas', 'Villa 31, CABA', 'Buenos Aires', 'Argentina', 'medio'),
('FRAUD006', 'Online Store Offshore', 'E-commerce', 'Electrónicos', 'Servidor Internacional', 'Unknown', 'Unknown', 'alto'),
('FRAUD007', 'Transfer Service USA', 'Financiero', 'Transferencias', 'New York', 'New York', 'Estados Unidos', 'medio'),
('FRAUD008', 'Gaming Site Anon', 'Entretenimiento', 'Juegos Online', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'alto'),
('FRAUD009', 'ATM Machine Unverified', 'Bancario', 'Cajeros No Verificados', 'Ubicación Variable', 'Desconocida', 'Desconocido', 'alto'),
('FRAUD010', 'Suspicious Merchant XYZ', 'Varios', 'Servicios Varios', 'IP Anónima', 'Desconocida', 'Desconocido', 'alto')
ON CONFLICT (codigo_comerciante) DO NOTHING;

-- ===== INSERTAR REGLAS DE FRAUDE =====
\echo '📋 Configurando reglas de detección...';
INSERT INTO reglas_fraude (nombre, descripcion, condicion, peso, activa) VALUES
('Monto Muy Alto', 'Transacción superior a $50,000', '{"monto_minimo": 50000}', 0.85, TRUE),
('Horario Nocturno', 'Transacciones entre 23:00 y 06:00', '{"horario_inicio": "23:00", "horario_fin": "06:00"}', 0.60, TRUE),
('País de Alto Riesgo', 'Transacciones desde países no confiables', '{"paises_riesgo": ["Desconocido", "Unknown"]}', 0.80, TRUE),
('Comerciante Alto Riesgo', 'Transacciones en comerciantes categorizados como alto riesgo', '{"nivel_riesgo_comerciante": "alto"}', 0.75, TRUE),
('Múltiples Transacciones', 'Más de 10 transacciones en una hora', '{"max_transacciones_hora": 10}', 0.70, TRUE),
('Distancia Inusual', 'Transacción a más de 100km de ubicación habitual', '{"distancia_maxima": 100}', 0.65, TRUE),
('Monto Internacional', 'Transferencias internacionales altas', '{"monto_internacional": 25000}', 0.70, TRUE),
('Horario Laboral Offshore', 'Compras offshore en horario laboral', '{"offshore_horario": "laboral"}', 0.65, TRUE)
ON CONFLICT (nombre) DO NOTHING;

-- ===== GENERAR TRANSACCIONES MASIVAS =====
\echo '💳 Generando 10,000 transacciones realistas...';

-- Función auxiliar para generar números de transacción únicos
CREATE OR REPLACE FUNCTION generate_unique_txn_number(counter INTEGER)
RETURNS VARCHAR(50) AS $$
BEGIN
    RETURN 'TXN-' || EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint || '-' || LPAD(counter::text, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Insertar transacciones NORMALES (80% del total = 8,000 transacciones)
\echo '   📈 Generando 8,000 transacciones normales...';
INSERT INTO transacciones (
    numero_transaccion, cuenta_origen_id, cuenta_destino_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    generate_unique_txn_number(i),
    -- Cuentas distribuidas entre 1000-2000 (1000 usuarios simulados)
    1000 + (i % 1000),
    NULL,
    -- Montos realistas para transacciones normales (100-15000)
    CASE 
        WHEN random() < 0.4 THEN 100 + (random() * 900)::decimal(10,2)     -- 40%: compras pequeñas (100-1000)
        WHEN random() < 0.7 THEN 1000 + (random() * 4000)::decimal(10,2)   -- 30%: compras medianas (1000-5000)
        WHEN random() < 0.9 THEN 5000 + (random() * 5000)::decimal(10,2)   -- 20%: compras grandes (5000-10000)
        ELSE 10000 + (random() * 5000)::decimal(10,2)                      -- 10%: compras muy grandes (10000-15000)
    END,
    -- Comerciantes legítimos (COM001-COM015)
    CASE (i % 15)
        WHEN 0 THEN 'COM001' WHEN 1 THEN 'COM002' WHEN 2 THEN 'COM003' WHEN 3 THEN 'COM004' WHEN 4 THEN 'COM005'
        WHEN 5 THEN 'COM006' WHEN 6 THEN 'COM007' WHEN 7 THEN 'COM008' WHEN 8 THEN 'COM009' WHEN 9 THEN 'COM010'
        WHEN 10 THEN 'COM011' WHEN 11 THEN 'COM012' WHEN 12 THEN 'COM013' WHEN 13 THEN 'COM014' ELSE 'COM015'
    END,
    CASE (i % 6)
        WHEN 0 THEN 'Alimentación' WHEN 1 THEN 'Combustibles' WHEN 2 THEN 'Gastronomía'
        WHEN 3 THEN 'Salud' WHEN 4 THEN 'Tecnología' ELSE 'Entretenimiento'
    END,
    CASE (i % 10)
        WHEN 0 THEN 'Av. Corrientes 1500, CABA' WHEN 1 THEN 'Panamericana Km 25'
        WHEN 2 THEN 'Palermo, CABA' WHEN 3 THEN 'Florida 800, CABA' WHEN 4 THEN 'Av. Santa Fe 2100'
        WHEN 5 THEN 'Recoleta Mall' WHEN 6 THEN 'Microcentro, CABA' WHEN 7 THEN 'Unicenter Shopping'
        WHEN 8 THEN 'Shopping Abasto' ELSE 'Puerto Madero'
    END,
    'Buenos Aires',
    'Argentina',
    CASE WHEN random() < 0.6 THEN 'Débito' ELSE 'Crédito' END,
    -- Horarios normales (7:00-22:00)
    TIME '07:00:00' + (random() * INTERVAL '15 hours'),
    -- Fechas en los últimos 30 días
    CURRENT_DATE - (random() * 30)::int,
    FALSE, -- No es fraude
    CASE WHEN random() < 0.7 THEN 'pos' WHEN random() < 0.9 THEN 'online' ELSE 'atm' END,
    -- Saldo de cuenta simulado (5000-50000)
    5000 + (random() * 45000)::decimal(10,2),
    -- Distancia normal (0-20km)
    (random() * 20)::decimal(5,2)
FROM generate_series(1, 8000) i;

-- Insertar transacciones FRAUDULENTAS (20% del total = 2,000 transacciones)
\echo '   🚨 Generando 2,000 transacciones fraudulentas...';
INSERT INTO transacciones (
    numero_transaccion, cuenta_origen_id, cuenta_destino_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    generate_unique_txn_number(8000 + i),
    -- Mismas cuentas que las normales
    1000 + (i % 1000),
    NULL,
    -- Montos sospechosos para fraude
    CASE 
        WHEN random() < 0.3 THEN 25000 + (random() * 25000)::decimal(10,2)   -- 30%: montos muy altos (25k-50k)
        WHEN random() < 0.6 THEN 50000 + (random() * 50000)::decimal(10,2)   -- 30%: montos extremos (50k-100k)
        WHEN random() < 0.8 THEN 5000 + (random() * 20000)::decimal(10,2)    -- 20%: montos medianos sospechosos
        ELSE 100000 + (random() * 100000)::decimal(10,2)                     -- 20%: montos astronómicos (100k+)
    END,
    -- Comerciantes sospechosos (FRAUD001-FRAUD010)
    CASE (i % 10)
        WHEN 0 THEN 'FRAUD001' WHEN 1 THEN 'FRAUD002' WHEN 2 THEN 'FRAUD003' WHEN 3 THEN 'FRAUD004' WHEN 4 THEN 'FRAUD005'
        WHEN 5 THEN 'FRAUD006' WHEN 6 THEN 'FRAUD007' WHEN 7 THEN 'FRAUD008' WHEN 8 THEN 'FRAUD009' ELSE 'FRAUD010'
    END,
    CASE (i % 5)
        WHEN 0 THEN 'E-commerce' WHEN 1 THEN 'Entretenimiento' WHEN 2 THEN 'Financiero'
        WHEN 3 THEN 'Criptomonedas' ELSE 'Servicios Varios'
    END,
    CASE (i % 8)
        WHEN 0 THEN 'Servidor Offshore' WHEN 1 THEN 'Las Vegas Strip' WHEN 2 THEN 'Online Transfer'
        WHEN 3 THEN 'Servidor Anónimo' WHEN 4 THEN 'Villa 31, CABA' WHEN 5 THEN 'Servidor Internacional'
        WHEN 6 THEN 'New York' ELSE 'IP Anónima'
    END,
    CASE (i % 6)
        WHEN 0 THEN 'Desconocida' WHEN 1 THEN 'Las Vegas' WHEN 2 THEN 'Miami'
        WHEN 3 THEN 'Unknown' WHEN 4 THEN 'Buenos Aires' ELSE 'New York'
    END,
    CASE (i % 4)
        WHEN 0 THEN 'Desconocido' WHEN 1 THEN 'Estados Unidos' WHEN 2 THEN 'Unknown' ELSE 'Argentina'
    END,
    'Crédito', -- Fraudes típicamente con crédito
    -- Horarios sospechosos (23:00-06:00 + algunos diurnos)
    CASE 
        WHEN random() < 0.6 THEN TIME '23:00:00' + (random() * INTERVAL '7 hours') -- 60% nocturno
        ELSE TIME '01:00:00' + (random() * INTERVAL '22 hours') -- 40% cualquier hora
    END,
    -- Fechas recientes (últimos 7 días para mayor sospecha)
    CURRENT_DATE - (random() * 7)::int,
    TRUE, -- Es fraude
    'online', -- Fraudes típicamente online
    -- Saldos que pueden quedar negativos después del fraude
    CASE 
        WHEN random() < 0.3 THEN 1000 + (random() * 4000)::decimal(10,2)     -- Cuentas con poco saldo
        WHEN random() < 0.6 THEN 5000 + (random() * 15000)::decimal(10,2)    -- Cuentas normales
        ELSE 20000 + (random() * 30000)::decimal(10,2)                       -- Cuentas con buen saldo
    END,
    -- Distancias sospechosas (muy lejos o desconocidas)
    CASE 
        WHEN random() < 0.4 THEN 500 + (random() * 1000)::decimal(5,2)       -- Muy lejos (500-1500km)
        WHEN random() < 0.7 THEN 100 + (random() * 400)::decimal(5,2)        -- Lejos (100-500km)
        ELSE 50 + (random() * 50)::decimal(5,2)                              -- Cerca pero sospechoso
    END
FROM generate_series(1, 2000) i;

-- ===== GENERAR ALERTAS AUTOMÁTICAS =====
\echo '🚨 Generando alertas para transacciones fraudulentas...';
INSERT INTO alertas_fraude (transaccion_id, tipo_alerta, nivel_riesgo, puntuacion_riesgo, descripcion)
SELECT
    t.id,
    CASE
        WHEN t.monto > 100000 THEN 'Transacción de Monto Extremo'
        WHEN t.monto > 50000 AND t.pais != 'Argentina' THEN 'Transacción Internacional de Alto Monto'
        WHEN t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 'Transacción en Horario Nocturno'
        WHEN t.distancia_ubicacion_usual > 500 THEN 'Transacción en Ubicación Muy Distante'
        WHEN t.comerciante LIKE 'FRAUD%' THEN 'Comerciante de Alto Riesgo'
        WHEN t.pais IN ('Desconocido', 'Unknown') THEN 'País No Identificado'
        ELSE 'Patrón Sospechoso Múltiple'
    END,
    CASE
        WHEN t.monto > 100000 OR t.pais IN ('Desconocido', 'Unknown') THEN 'crítico'
        WHEN t.monto > 50000 OR t.distancia_ubicacion_usual > 500 THEN 'alto'
        WHEN t.monto > 25000 OR t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 'medio'
        ELSE 'bajo'
    END,
    CASE
        WHEN t.monto > 100000 THEN 98.0
        WHEN t.monto > 75000 THEN 95.0
        WHEN t.monto > 50000 THEN 85.0
        WHEN t.pais IN ('Desconocido', 'Unknown') THEN 90.0
        WHEN t.distancia_ubicacion_usual > 500 THEN 80.0
        WHEN t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 70.0
        WHEN t.comerciante LIKE 'FRAUD%' THEN 75.0
        ELSE 60.0
    END,
    CONCAT('Sistema detectó: ', 
        CASE WHEN t.monto > 50000 THEN 'Monto alto ' ELSE '' END,
        CASE WHEN t.pais != 'Argentina' THEN 'País extranjero ' ELSE '' END,
        CASE WHEN t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 'Horario nocturno ' ELSE '' END,
        CASE WHEN t.comerciante LIKE 'FRAUD%' THEN 'Comerciante riesgo ' ELSE '' END,
        '- Requiere revisión inmediata')
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

-- ===== CREAR PERFILES DE USUARIO BÁSICOS =====
\echo '👤 Creando perfiles de usuario básicos...';
INSERT INTO perfiles_usuario (cuenta_id, ubicacion_frecuente, monto_promedio, frecuencia_transacciones, 
                             horario_preferido_inicio, horario_preferido_fin, ratio_fin_semana, 
                             ratio_horario_nocturno, max_transacciones_dia)
SELECT 
    cuenta_origen_id,
    ubicacion,
    AVG(monto),
    COUNT(*),
    TIME '08:00:00',
    TIME '20:00:00',
    0.2,
    CASE WHEN es_fraude THEN 0.8 ELSE 0.1 END,
    CASE WHEN es_fraude THEN 20 ELSE 5 END
FROM transacciones 
GROUP BY cuenta_origen_id, ubicacion, es_fraude
ON CONFLICT (cuenta_id) DO UPDATE SET
    ubicacion_frecuente = EXCLUDED.ubicacion_frecuente,
    monto_promedio = EXCLUDED.monto_promedio,
    frecuencia_transacciones = EXCLUDED.frecuencia_transacciones;

-- ===== LIMPIAR FUNCIÓN AUXILIAR =====
DROP FUNCTION IF EXISTS generate_unique_txn_number(INTEGER);

-- ===== ESTADÍSTICAS FINALES =====
\echo '';
\echo '📊 === ESTADÍSTICAS FINALES DE GENERACIÓN ===';

SELECT 
    'Total Transacciones' as tipo,
    COUNT(*) as cantidad,
    ROUND(AVG(monto), 2) as monto_promedio,
    MAX(monto) as monto_maximo
FROM transacciones
UNION ALL
SELECT 
    'Transacciones Fraudulentas' as tipo,
    COUNT(*) as cantidad,
    ROUND(AVG(monto), 2) as monto_promedio,
    MAX(monto) as monto_maximo
FROM transacciones WHERE es_fraude = TRUE
UNION ALL
SELECT 
    'Transacciones Normales' as tipo,
    COUNT(*) as cantidad,
    ROUND(AVG(monto), 2) as monto_promedio,
    MAX(monto) as monto_maximo
FROM transacciones WHERE es_fraude = FALSE;

\echo '';
SELECT 
    'Comerciantes Totales' as tipo,
    COUNT(*) as cantidad
FROM comerciantes
UNION ALL
SELECT 
    'Alertas Generadas' as tipo,
    COUNT(*) as cantidad
FROM alertas_fraude
UNION ALL
SELECT 
    'Perfiles de Usuario' as tipo,
    COUNT(*) as cantidad
FROM perfiles_usuario;

\echo '';
\echo '✅ Generación masiva completada exitosamente!';
\echo '   🎯 10,000 transacciones generadas (8,000 normales + 2,000 fraudulentas)';
\echo '   🏪 25 comerciantes configurados (15 legítimos + 10 sospechosos)';
\echo '   🚨 ~2,000 alertas de fraude generadas automáticamente';
\echo '   👤 ~1,000 perfiles de usuario creados';
\echo '';
\echo '🚀 Sistema listo para entrenamiento de IA!';

-- ===== INSERTAR TRANSACCIONES DE MUESTRA =====
-- Primero transacciones NORMALES
INSERT INTO transacciones (
    numero_transaccion, cuenta_origen_id, cuenta_destino_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
) VALUES
-- === TRANSACCIONES NORMALES ===
('TXN-NORMAL-001', 1001, NULL, 850.50, 'COM001', 'Alimentación', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'Débito', '14:30:00', CURRENT_DATE - 1, FALSE, 'pos', 15000.00, 2.5),
('TXN-NORMAL-002', 1001, NULL, 3200.00, 'COM002', 'Combustibles', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'Crédito', '08:15:00', CURRENT_DATE - 1, FALSE, 'pos', 14149.50, 15.0),
('TXN-NORMAL-003', 1001, NULL, 4500.00, 'COM003', 'Gastronomía', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'Débito', '20:45:00', CURRENT_DATE - 2, FALSE, 'pos', 10949.50, 5.0),
('TXN-NORMAL-004', 1001, NULL, 280.00, 'COM004', 'Salud', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'Débito', '11:20:00', CURRENT_DATE - 2, FALSE, 'pos', 6449.50, 1.0),
('TXN-NORMAL-005', 1002, NULL, 1200.00, 'COM001', 'Alimentación', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'Crédito', '16:00:00', CURRENT_DATE - 3, FALSE, 'pos', 25000.00, 3.0),
('TXN-NORMAL-006', 1002, NULL, 15000.00, 'COM009', 'Tecnología', 'Unicenter Shopping', 'Buenos Aires', 'Argentina', 'Crédito', '19:30:00', CURRENT_DATE - 3, FALSE, 'pos', 23800.00, 10.0),
('TXN-NORMAL-007', 1002, NULL, 500.00, 'COM007', 'Bancario', 'Microcentro, CABA', 'Buenos Aires', 'Argentina', 'Débito', '12:00:00', CURRENT_DATE - 4, FALSE, 'atm', 8800.00, 2.0),
('TXN-NORMAL-008', 1003, NULL, 650.00, 'COM002', 'Combustibles', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'Débito', '07:45:00', CURRENT_DATE - 4, FALSE, 'pos', 18000.00, 12.0),
('TXN-NORMAL-009', 1003, NULL, 2200.00, 'COM003', 'Gastronomía', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'Crédito', '21:15:00', CURRENT_DATE - 5, FALSE, 'pos', 17350.00, 8.0),
('TXN-NORMAL-010', 1004, NULL, 320.00, 'COM004', 'Salud', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'Débito', '15:30:00', CURRENT_DATE - 5, FALSE, 'pos', 12000.00, 1.5),

-- === TRANSACCIONES FRAUDULENTAS ===
('TXN-FRAUD-001', 1001, NULL, 75000.00, 'COM005', 'E-commerce', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'Crédito', '02:30:00', CURRENT_DATE, TRUE, 'online', 6169.50, 500.0),
('TXN-FRAUD-002', 1002, NULL, 95000.00, 'COM006', 'Entretenimiento', 'Las Vegas Strip', 'Las Vegas', 'Estados Unidos', 'Crédito', '03:45:00', CURRENT_DATE, TRUE, 'online', 8300.00, 10000.0),
('TXN-FRAUD-003', 1003, NULL, 45000.00, 'COM010', 'Financiero', 'Online Transfer', 'Miami', 'Estados Unidos', 'Crédito', '01:15:00', CURRENT_DATE, TRUE, 'online', 15150.00, 8000.0),
('TXN-FRAUD-004', 1001, NULL, 25000.00, 'COM008', 'Telecomunicaciones', 'Villa 31, CABA', 'Buenos Aires', 'Argentina', 'Débito', '23:45:00', CURRENT_DATE, TRUE, 'pos', 1169.50, 25.0),
('TXN-FRAUD-005', 1002, NULL, 8000.00, 'COM005', 'E-commerce', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'Crédito', '14:00:00', CURRENT_DATE, TRUE, 'online', 3300.00, 500.0),
('TXN-FRAUD-006', 1002, NULL, 7500.00, 'COM005', 'E-commerce', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'Crédito', '14:05:00', CURRENT_DATE, TRUE, 'online', -4700.00, 500.0),
('TXN-FRAUD-007', 1002, NULL, 5000.00, 'COM005', 'E-commerce', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'Crédito', '14:07:00', CURRENT_DATE, TRUE, 'online', -12200.00, 500.0),
('TXN-FRAUD-008', 1004, NULL, 55000.00, 'COM006', 'Entretenimiento', 'Las Vegas Strip', 'Las Vegas', 'Estados Unidos', 'Crédito', '04:22:00', CURRENT_DATE, TRUE, 'online', 12000.00, 10000.0),
('TXN-FRAUD-009', 1003, NULL, 35000.00, 'COM010', 'Financiero', 'Online Transfer', 'Miami', 'Estados Unidos', 'Crédito', '02:10:00', CURRENT_DATE, TRUE, 'online', 17350.00, 8000.0),
('TXN-FRAUD-010', 1001, NULL, 12000.00, 'COM005', 'E-commerce', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'Crédito', '01:30:00', CURRENT_DATE, TRUE, 'online', 6169.50, 500.0)
ON CONFLICT (numero_transaccion) DO NOTHING;

-- ===== ACTUALIZAR PERFILES DE USUARIO =====
SELECT actualizar_perfil_usuario(1001);
SELECT actualizar_perfil_usuario(1002);
SELECT actualizar_perfil_usuario(1003);
SELECT actualizar_perfil_usuario(1004);

-- ===== GENERAR ALERTAS PARA TRANSACCIONES FRAUDULENTAS =====
INSERT INTO alertas_fraude (transaccion_id, tipo_alerta, nivel_riesgo, puntuacion_riesgo, descripcion)
SELECT
    t.id,
    CASE
        WHEN t.monto > 50000 AND t.pais != 'Argentina' THEN 'Transacción Internacional de Alto Monto'
        WHEN t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 'Transacción en Horario Nocturno'
        WHEN t.distancia_ubicacion_usual > 100 THEN 'Transacción en Ubicación Distante'
        WHEN t.comerciante LIKE 'COM005' OR t.comerciante LIKE 'COM006' THEN 'Comerciante de Alto Riesgo'
        ELSE 'Patrón Sospechoso Detectado'
    END,
    CASE
        WHEN t.monto > 70000 OR t.pais = 'Desconocido' THEN 'crítico'
        WHEN t.monto > 40000 OR t.pais != 'Argentina' THEN 'alto'
        WHEN t.monto > 20000 OR t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 'medio'
        ELSE 'bajo'
    END,
    CASE
        WHEN t.monto > 70000 THEN 95.0
        WHEN t.monto > 50000 THEN 85.0
        WHEN t.pais != 'Argentina' THEN 80.0
        WHEN t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 70.0
        WHEN t.distancia_ubicacion_usual > 100 THEN 75.0
        ELSE 60.0
    END,
    'Transacción automáticamente clasificada como fraudulenta por el sistema de detección'
FROM transacciones t
WHERE t.es_fraude = TRUE
ON CONFLICT DO NOTHING;

-- ===== INSERTAR MÁS TRANSACCIONES PARA ENTRENAMIENTO =====
-- Insertar transacciones adicionales para tener un dataset más robusto
INSERT INTO transacciones (
    numero_transaccion, cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
) VALUES
-- Más transacciones normales
('TXN-BULK-001', 1001, 450.00, 'COM001', 'Alimentación', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'Débito', '12:00:00', CURRENT_DATE - 6, FALSE, 'pos', 15000.00, 2.5),
('TXN-BULK-002', 1001, 1200.00, 'COM002', 'Combustibles', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'Crédito', '18:30:00', CURRENT_DATE - 7, FALSE, 'pos', 15000.00, 15.0),
('TXN-BULK-003', 1002, 780.00, 'COM003', 'Gastronomía', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'Débito', '19:45:00', CURRENT_DATE - 8, FALSE, 'pos', 25000.00, 5.0),
('TXN-BULK-004', 1003, 350.00, 'COM004', 'Salud', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'Débito', '10:15:00', CURRENT_DATE - 9, FALSE, 'pos', 18000.00, 1.0),
('TXN-BULK-005', 1004, 2500.00, 'COM009', 'Tecnología', 'Unicenter Shopping', 'Buenos Aires', 'Argentina', 'Crédito', '16:20:00', CURRENT_DATE - 10, FALSE, 'pos', 12000.00, 10.0),

-- Más transacciones fraudulentas para balancear el dataset
('TXN-FRAUD-011', 1001, 85000.00, 'COM006', 'Entretenimiento', 'Las Vegas Strip', 'Las Vegas', 'Estados Unidos', 'Crédito', '03:30:00', CURRENT_DATE - 1, TRUE, 'online', 15000.00, 10000.0),
('TXN-FRAUD-012', 1004, 60000.00, 'COM005', 'E-commerce', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'Crédito', '02:45:00', CURRENT_DATE - 2, TRUE, 'online', 12000.00, 500.0),
('TXN-FRAUD-013', 1003, 40000.00, 'COM010', 'Financiero', 'Online Transfer', 'Miami', 'Estados Unidos', 'Crédito', '01:00:00', CURRENT_DATE - 3, TRUE, 'online', 18000.00, 8000.0)
ON CONFLICT (numero_transaccion) DO NOTHING;

-- ===== ACTUALIZAR ESTADÍSTICAS DE COMERCIANTES =====
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

-- ===== VERIFICACIÓN FINAL =====
\echo '📊 Estadísticas finales de las transacciones insertadas:';

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
FROM comerciantes
UNION ALL
SELECT 
    'Alertas generadas' as tipo,
    COUNT(*) as cantidad
FROM alertas_fraude;

\echo '✅ Muestras de fraude insertadas exitosamente en bank_transactions';