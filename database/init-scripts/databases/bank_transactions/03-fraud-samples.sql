-- databases/bank_transactions/03-fraud-samples.sql
-- Generación masiva de transacciones REALISTAS para detección de fraude

\echo '🔍 Generando datos masivos para detección de fraude...'
\echo '   Target: 10,000 transacciones con distribución realista';

\c bank_transactions;

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
('COM025', 'MercadoLibre Pago', 'E-commerce', 'Marketplace', 'Online', 'Buenos Aires', 'Argentina', 'bajo')
ON CONFLICT (codigo_comerciante) DO NOTHING;

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
('Canal de Riesgo', 'Transacciones online en horarios inusuales', '{"canal_horario_riesgo": "online_nocturno"}', 0.40, TRUE)
ON CONFLICT (nombre) DO NOTHING;

-- ===== GENERAR TRANSACCIONES REALISTAS =====
\echo '💳 Generando 10,000 transacciones realistas...';

-- Función auxiliar para generar números de transacción únicos
CREATE OR REPLACE FUNCTION generate_realistic_txn_number(counter INTEGER)
RETURNS VARCHAR(50) AS $$
BEGIN
    RETURN 'BA' || TO_CHAR(CURRENT_DATE, 'YYMMDD') || LPAD(counter::text, 6, '0');
END;
$$ LANGUAGE plpgsql;

-- Insertar transacciones NORMALES (85% del total = 8,500 transacciones)
\echo '   📈 Generando 8,500 transacciones normales...';
INSERT INTO transacciones (
    numero_transaccion, cuenta_origen_id, cuenta_destino_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    generate_realistic_txn_number(i),
    -- Cuentas distribuidas entre 1000-2000 (1000 usuarios simulados)
    1000 + (i % 1000),
    NULL,
    -- Montos realistas para transacciones normales
    CASE 
        WHEN random() < 0.5 THEN 150 + (random() * 1850)::decimal(10,2)     -- 50%: compras pequeñas (150-2000)
        WHEN random() < 0.8 THEN 2000 + (random() * 8000)::decimal(10,2)    -- 30%: compras medianas (2000-10000)
        WHEN random() < 0.95 THEN 10000 + (random() * 15000)::decimal(10,2) -- 15%: compras grandes (10000-25000)
        ELSE 25000 + (random() * 25000)::decimal(10,2)                      -- 5%: compras muy grandes (25000-50000)
    END,
    -- Comerciantes legítimos con distribución realista
    CASE (i % 25)
        WHEN 0 THEN 'COM001' WHEN 1 THEN 'COM002' WHEN 2 THEN 'COM003' WHEN 3 THEN 'COM004' WHEN 4 THEN 'COM005'
        WHEN 5 THEN 'COM006' WHEN 6 THEN 'COM007' WHEN 7 THEN 'COM008' WHEN 8 THEN 'COM009' WHEN 9 THEN 'COM010'
        WHEN 10 THEN 'COM011' WHEN 11 THEN 'COM012' WHEN 12 THEN 'COM013' WHEN 13 THEN 'COM014' WHEN 14 THEN 'COM015'
        WHEN 15 THEN 'COM016' WHEN 16 THEN 'COM017' WHEN 17 THEN 'COM018' WHEN 18 THEN 'COM020' WHEN 19 THEN 'COM021'
        WHEN 20 THEN 'COM022' WHEN 21 THEN 'COM024' WHEN 22 THEN 'COM025' WHEN 23 THEN 'COM001' ELSE 'COM002'
    END,
    CASE (i % 8)
        WHEN 0 THEN 'Alimentación' WHEN 1 THEN 'Combustibles' WHEN 2 THEN 'Gastronomía' WHEN 3 THEN 'Salud'
        WHEN 4 THEN 'Tecnología' WHEN 5 THEN 'Entretenimiento' WHEN 6 THEN 'Bancario' ELSE 'E-commerce'
    END,
    CASE (i % 15)
        WHEN 0 THEN 'Av. Corrientes 1500, CABA' WHEN 1 THEN 'Panamericana Km 25' WHEN 2 THEN 'Palermo, CABA'
        WHEN 3 THEN 'Florida 800, CABA' WHEN 4 THEN 'Av. 9 de Julio 1000' WHEN 5 THEN 'Recoleta Mall'
        WHEN 6 THEN 'Unicenter Shopping' WHEN 7 THEN 'Shopping Abasto' WHEN 8 THEN 'Microcentro, CABA'
        WHEN 9 THEN 'Puerto Madero' WHEN 10 THEN 'Retiro' WHEN 11 THEN 'Zona Norte' WHEN 12 THEN 'Flores'
        WHEN 13 THEN 'Villa Crespo' ELSE 'Belgrano'
    END,
    'Buenos Aires',
    'Argentina',
    CASE WHEN random() < 0.65 THEN 'Débito' WHEN random() < 0.9 THEN 'Crédito' ELSE 'Prepaga' END,
    -- Horarios normales con distribución realista (6:00-23:00)
    TIME '06:00:00' + (random() * INTERVAL '17 hours'),
    -- Fechas en los últimos 60 días
    CURRENT_DATE - (random() * 60)::int,
    FALSE, -- No es fraude
    CASE 
        WHEN random() < 0.6 THEN 'pos' 
        WHEN random() < 0.85 THEN 'online' 
        WHEN random() < 0.95 THEN 'atm' 
        ELSE 'mobile' 
    END,
    -- Saldo de cuenta simulado realista
    5000 + (random() * 95000)::decimal(10,2),
    -- Distancia normal (0-50km)
    (random() * 50)::decimal(5,2)
FROM generate_series(1, 8500) i;

-- Insertar transacciones FRAUDULENTAS SUTILES (15% del total = 1,500 transacciones)
\echo '   🚨 Generando 1,500 transacciones fraudulentas sutiles...';
INSERT INTO transacciones (
    numero_transaccion, cuenta_origen_id, cuenta_destino_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    generate_realistic_txn_number(8500 + i),
    -- Mismas cuentas que las normales (para hacer más difícil la detección)
    1000 + (i % 1000),
    NULL,
    -- Montos fraudulentos MÁS SUTILES
    CASE 
        WHEN random() < 0.4 THEN 15000 + (random() * 35000)::decimal(10,2)   -- 40%: montos altos pero no extremos (15k-50k)
        WHEN random() < 0.7 THEN 50000 + (random() * 50000)::decimal(10,2)   -- 30%: montos muy altos (50k-100k)
        WHEN random() < 0.85 THEN 8000 + (random() * 17000)::decimal(10,2)   -- 15%: montos medianos (8k-25k)
        ELSE 100000 + (random() * 100000)::decimal(10,2)                     -- 15%: montos extremos (100k+)
    END,
    -- Mezcla de comerciantes legítimos Y sospechosos (más realista)
    CASE (i % 20)
        WHEN 0 THEN 'COM019' WHEN 1 THEN 'COM023' WHEN 2 THEN 'COM017'  -- Alto riesgo
        WHEN 3 THEN 'COM016' WHEN 4 THEN 'COM018' WHEN 5 THEN 'COM020' WHEN 6 THEN 'COM022' WHEN 7 THEN 'COM024' -- Medio riesgo
        WHEN 8 THEN 'COM021' WHEN 9 THEN 'COM025' -- E-commerce
        -- Comerciantes normales usados fraudulentamente
        WHEN 10 THEN 'COM007' WHEN 11 THEN 'COM008' WHEN 12 THEN 'COM001' WHEN 13 THEN 'COM002'
        WHEN 14 THEN 'COM003' WHEN 15 THEN 'COM005' WHEN 16 THEN 'COM006' WHEN 17 THEN 'COM009'
        ELSE 'COM010'
    END,
    CASE (i % 8)
        WHEN 0 THEN 'Financiero' WHEN 1 THEN 'E-commerce' WHEN 2 THEN 'Entretenimiento' WHEN 3 THEN 'Bancario'
        WHEN 4 THEN 'Tecnología' WHEN 5 THEN 'Gastronomía' WHEN 6 THEN 'Retail' ELSE 'Apuestas Online'
    END,
    CASE (i % 12)
        WHEN 0 THEN 'Online' WHEN 1 THEN 'Microcentro' WHEN 2 THEN 'Puerto Madero' WHEN 3 THEN 'Retiro'
        WHEN 4 THEN 'Londres' WHEN 5 THEN 'São Paulo' WHEN 6 THEN 'Villa Crespo' WHEN 7 THEN 'Zona Norte'
        WHEN 8 THEN 'Miami' WHEN 9 THEN 'Madrid' WHEN 10 THEN 'Palermo, CABA' ELSE 'Flores'
    END,
    CASE (i % 10)
        WHEN 0 THEN 'Buenos Aires' WHEN 1 THEN 'Buenos Aires' WHEN 2 THEN 'Buenos Aires' WHEN 3 THEN 'Buenos Aires'
        WHEN 4 THEN 'São Paulo' WHEN 5 THEN 'Londres' WHEN 6 THEN 'Miami' WHEN 7 THEN 'Madrid'
        WHEN 8 THEN 'Buenos Aires' ELSE 'Buenos Aires'
    END,
    CASE (i % 8)
        WHEN 0 THEN 'Argentina' WHEN 1 THEN 'Argentina' WHEN 2 THEN 'Argentina' WHEN 3 THEN 'Argentina'
        WHEN 4 THEN 'Brasil' WHEN 5 THEN 'Reino Unido' WHEN 6 THEN 'Estados Unidos' ELSE 'España'
    END,
    CASE WHEN random() < 0.8 THEN 'Crédito' ELSE 'Débito' END, -- Fraudes más comunes con crédito
    -- Horarios MÁS REALISTAS para fraude (no solo nocturno)
    CASE 
        WHEN random() < 0.3 THEN TIME '00:00:00' + (random() * INTERVAL '6 hours')   -- 30% nocturno temprano
        WHEN random() < 0.4 THEN TIME '22:00:00' + (random() * INTERVAL '2 hours')   -- 10% nocturno tardío
        WHEN random() < 0.6 THEN TIME '10:00:00' + (random() * INTERVAL '8 hours')   -- 20% horario laboral
        ELSE TIME '06:00:00' + (random() * INTERVAL '18 hours')                      -- 40% cualquier hora
    END,
    -- Fechas más recientes para fraudes (últimos 14 días)
    CURRENT_DATE - (random() * 14)::int,
    TRUE, -- Es fraude
    CASE 
        WHEN random() < 0.7 THEN 'online' 
        WHEN random() < 0.85 THEN 'atm'
        WHEN random() < 0.95 THEN 'mobile'
        ELSE 'pos'
    END,
    -- Saldos más variados (algunos con poco dinero, otros con mucho)
    CASE 
        WHEN random() < 0.3 THEN 500 + (random() * 4500)::decimal(10,2)      -- Cuentas con poco saldo
        WHEN random() < 0.6 THEN 5000 + (random() * 20000)::decimal(10,2)    -- Cuentas normales
        ELSE 25000 + (random() * 75000)::decimal(10,2)                       -- Cuentas con buen saldo
    END,
    -- Distancias más realistas (no siempre extremas)
    CASE 
        WHEN random() < 0.3 THEN 100 + (random() * 400)::decimal(5,2)        -- Distancias largas pero posibles
        WHEN random() < 0.5 THEN 50 + (random() * 100)::decimal(5,2)         -- Distancias medianas
        WHEN random() < 0.7 THEN 5 + (random() * 45)::decimal(5,2)           -- Distancias normales
        ELSE 500 + (random() * 1500)::decimal(5,2)                           -- Distancias extremas
    END
FROM generate_series(1, 1500) i;

-- ===== GENERAR ALERTAS MÁS SUTILES =====
\echo '🚨 Generando alertas para transacciones fraudulentas...';
INSERT INTO alertas_fraude (transaccion_id, tipo_alerta, nivel_riesgo, puntuacion_riesgo, descripcion)
SELECT
    t.id,
    CASE
        WHEN t.monto > 150000 THEN 'Transacción de Monto Extremo'
        WHEN t.monto > 75000 AND t.pais != 'Argentina' THEN 'Transacción Internacional de Alto Monto'
        WHEN t.monto > 100000 THEN 'Monto Inusualmente Alto'
        WHEN t.horario_transaccion BETWEEN '00:00:00' AND '05:00:00' THEN 'Transacción en Horario de Madrugada'
        WHEN t.distancia_ubicacion_usual > 300 THEN 'Transacción en Ubicación Muy Distante'
        WHEN t.comerciante IN ('COM019', 'COM023') THEN 'Comerciante de Alto Riesgo'
        WHEN t.pais != 'Argentina' AND t.monto > 25000 THEN 'Transacción Internacional Significativa'
        WHEN t.canal = 'online' AND t.horario_transaccion BETWEEN '02:00:00' AND '05:00:00' THEN 'Compra Online Nocturna'
        ELSE 'Patrón de Riesgo Múltiple'
    END,
    CASE
        WHEN t.monto > 150000 OR (t.comerciante IN ('COM019', 'COM023') AND t.monto > 50000) THEN 'crítico'
        WHEN t.monto > 100000 OR t.distancia_ubicacion_usual > 300 THEN 'alto'
        WHEN t.monto > 50000 OR t.horario_transaccion BETWEEN '00:00:00' AND '05:00:00' THEN 'medio'
        ELSE 'bajo'
    END,
    CASE
        WHEN t.monto > 150000 THEN 92.0
        WHEN t.monto > 100000 THEN 85.0
        WHEN t.comerciante IN ('COM019', 'COM023') THEN 78.0
        WHEN t.pais != 'Argentina' AND t.monto > 50000 THEN 75.0
        WHEN t.distancia_ubicacion_usual > 300 THEN 70.0
        WHEN t.horario_transaccion BETWEEN '00:00:00' AND '05:00:00' THEN 65.0
        WHEN t.monto > 75000 THEN 68.0
        ELSE 55.0
    END,
    CONCAT('Alerta automática: ', 
        CASE WHEN t.monto > 100000 THEN 'Monto elevado ' ELSE '' END,
        CASE WHEN t.pais != 'Argentina' THEN 'Origen internacional ' ELSE '' END,
        CASE WHEN t.horario_transaccion BETWEEN '00:00:00' AND '05:00:00' THEN 'Horario inusual ' ELSE '' END,
        CASE WHEN t.comerciante IN ('COM019', 'COM023') THEN 'Comerciante riesgo ' ELSE '' END,
        '- Revisar operación')
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

-- ===== CREAR PERFILES DE USUARIO REALISTAS =====
\echo '👤 Creando perfiles de usuario realistas...';
INSERT INTO perfiles_usuario (cuenta_id, ubicacion_frecuente, monto_promedio, frecuencia_transaccional, 
                             horario_preferido_inicio, horario_preferido_fin, ratio_fin_semana, 
                             ratio_noche, max_transacciones_diarias)
SELECT 
    cuenta_origen_id,
    mode() WITHIN GROUP (ORDER BY ubicacion),
    AVG(monto),
    COUNT(*),
    TIME '08:00:00',
    TIME '20:00:00',
    0.25,
    AVG(CASE WHEN horario_transaccion BETWEEN '22:00:00' AND '06:00:00' THEN 1.0 ELSE 0.0 END),
    GREATEST(COUNT(*) / GREATEST((MAX(fecha_transaccion) - MIN(fecha_transaccion))::INTEGER, 1), 1)
FROM transacciones 
GROUP BY cuenta_origen_id
ON CONFLICT (cuenta_id) DO UPDATE SET
    ubicacion_frecuente = EXCLUDED.ubicacion_frecuente,
    monto_promedio = EXCLUDED.monto_promedio,
    frecuencia_transaccional = EXCLUDED.frecuencia_transaccional;

-- ===== LIMPIAR FUNCIÓN AUXILIAR =====
DROP FUNCTION IF EXISTS generate_realistic_txn_number(INTEGER);

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
\echo '   🎯 10,000 transacciones generadas (8,500 normales + 1,500 fraudulentas)';
\echo '   🏪 25 comerciantes configurados (15 legítimos + 10 riesgo medio/alto)';
\echo '   🚨 ~1,500 alertas de fraude generadas automáticamente';
\echo '   👤 ~1,000 perfiles de usuario creados';
\echo '';
\echo '🚀 Sistema listo para entrenamiento de IA con datos realistas!';

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

\echo '✅ Datos realistas insertados exitosamente en bank_transactions';