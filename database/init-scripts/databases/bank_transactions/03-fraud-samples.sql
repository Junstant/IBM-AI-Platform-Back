-- databases/bank_transactions/03-fraud-samples.sql
-- Generación masiva de transacciones SUTILES Y REALISTAS para detección de fraude

\echo '🔍 Generando datos sutiles y realistas para detección de fraude...'
\echo '   Target: 10,000 transacciones con distribución MUY realista';

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
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    1000 + (gs % 800),  -- 800 usuarios diferentes
    -- Montos MUY realistas y variados
    CASE 
        WHEN random() < 0.3 THEN 50 + (random() * 450)::DECIMAL(10,2)      -- Compras pequeñas: $50-500
        WHEN random() < 0.6 THEN 500 + (random() * 1500)::DECIMAL(10,2)    -- Compras medianas: $500-2000
        WHEN random() < 0.85 THEN 2000 + (random() * 3000)::DECIMAL(10,2)  -- Compras grandes: $2000-5000
        WHEN random() < 0.95 THEN 5000 + (random() * 10000)::DECIMAL(10,2) -- Compras muy grandes: $5000-15000
        ELSE 15000 + (random() * 20000)::DECIMAL(10,2)                     -- Compras especiales: $15000-35000
    END,
    -- Solo comerciantes completamente legítimos
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
    -- Ubicaciones normales en Argentina
    CASE (gs % 12)
        WHEN 0 THEN 'Av. Corrientes 1500, CABA' WHEN 1 THEN 'Panamericana Km 25' WHEN 2 THEN 'Palermo, CABA'
        WHEN 3 THEN 'Florida 800, CABA' WHEN 4 THEN 'Av. 9 de Julio 1000' WHEN 5 THEN 'Recoleta Mall'
        WHEN 6 THEN 'Unicenter Shopping' WHEN 7 THEN 'Shopping Abasto' WHEN 8 THEN 'Microcentro, CABA'
        WHEN 9 THEN 'Puerto Madero' WHEN 10 THEN 'Villa Crespo' ELSE 'San Telmo'
    END,
    'Buenos Aires',
    'Argentina',
    CASE WHEN random() < 0.60 THEN 'Débito' WHEN random() < 0.85 THEN 'Crédito' ELSE 'Prepaga' END,
    -- Horarios completamente normales (6AM - 11PM)
    TIME '06:00:00' + (random() * INTERVAL '17 hours'),
    CURRENT_DATE - (random() * 90)::int,  -- Últimos 3 meses
    FALSE,  -- ✅ EXPLÍCITAMENTE NORMALES
    CASE WHEN random() < 0.65 THEN 'pos' WHEN random() < 0.85 THEN 'online' ELSE 'atm' END,
    10000 + (random() * 90000)::DECIMAL(10,2),  -- Saldos realistas
    (random() * 20)::DECIMAL(8,2)  -- Distancias cortas normales
FROM generate_series(1, 8500) gs;

-- ===== GENERAR TRANSACCIONES FRAUDULENTAS SUTILES =====
\echo '   🚨 Generando 1,500 transacciones fraudulentas SUTILES...';

-- Tipo 1: Fraudes sutiles con montos moderadamente altos (60% del fraude)
INSERT INTO transacciones (
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    1000 + (gs % 800),  -- Mismos usuarios
    -- Montos fraudulentos SUTILES - no tan evidentes
    CASE 
        WHEN random() < 0.4 THEN 8000 + (random() * 12000)::DECIMAL(10,2)   -- $8K-20K (un poco alto pero no obvio)
        WHEN random() < 0.7 THEN 20000 + (random() * 25000)::DECIMAL(10,2)  -- $20K-45K (alto pero creíble)
        WHEN random() < 0.9 THEN 45000 + (random() * 30000)::DECIMAL(10,2)  -- $45K-75K (muy alto)
        ELSE 75000 + (random() * 50000)::DECIMAL(10,2)                      -- $75K-125K (extremo pero no ridículo)
    END,
    -- Mix de comerciantes legítimos y medio riesgo
    CASE 
        WHEN random() < 0.3 THEN  -- 30% en comerciantes legítimos (fraude con tarjeta robada)
            CASE (gs % 8)
                WHEN 0 THEN 'COM001' WHEN 1 THEN 'COM008' WHEN 2 THEN 'COM014' WHEN 3 THEN 'COM017'
                WHEN 4 THEN 'COM019' WHEN 5 THEN 'COM021' WHEN 6 THEN 'COM024' ELSE 'COM016'
            END
        ELSE  -- 70% en comerciantes de medio riesgo
            CASE (gs % 7)
                WHEN 0 THEN 'COM019' WHEN 1 THEN 'COM020' WHEN 2 THEN 'COM021' WHEN 3 THEN 'COM022'
                WHEN 4 THEN 'COM023' WHEN 5 THEN 'COM024' ELSE 'COM025'
            END
    END,
    CASE (gs % 8)
        WHEN 0 THEN 'Tecnología' WHEN 1 THEN 'Financiero' WHEN 2 THEN 'E-commerce' WHEN 3 THEN 'Entretenimiento'
        WHEN 4 THEN 'Retail' WHEN 5 THEN 'Alimentación' WHEN 6 THEN 'Gastronomía' ELSE 'Bancario'
    END,
    -- Mezcla de ubicaciones normales y algunas sospechosas
    CASE 
        WHEN random() < 0.6 THEN  -- 60% ubicaciones normales
            CASE (gs % 6)
                WHEN 0 THEN 'Buenos Aires Centro' WHEN 1 THEN 'Palermo, CABA' WHEN 2 THEN 'Recoleta'
                WHEN 3 THEN 'Puerto Madero' WHEN 4 THEN 'Villa Crespo' ELSE 'San Telmo'
            END
        ELSE  -- 40% ubicaciones un poco sospechosas
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
    'Argentina',  -- Mantener todo en Argentina para ser más sutil
    CASE WHEN random() < 0.75 THEN 'Crédito' ELSE 'Débito' END,
    -- Horarios SUTILMENTE sospechosos
    CASE 
        WHEN random() < 0.7 THEN TIME '07:00:00' + (random() * INTERVAL '16 hours')  -- 70% horarios normales
        WHEN random() < 0.85 THEN TIME '22:00:00' + (random() * INTERVAL '3 hours') -- 15% noche temprana
        ELSE TIME '01:00:00' + (random() * INTERVAL '4 hours')                      -- 15% madrugada
    END,
    CURRENT_DATE - (random() * 30)::int,  -- Último mes (más reciente = más sospechoso)
    TRUE,  -- ✅ FRAUDE PERO SUTIL
    CASE WHEN random() < 0.6 THEN 'online' WHEN random() < 0.8 THEN 'pos' ELSE 'atm' END,
    -- Saldos que a veces son menores al monto (indicador sutil)
    CASE 
        WHEN random() < 0.3 THEN 1000 + (random() * 8000)::DECIMAL(10,2)   -- Saldo insuficiente
        WHEN random() < 0.6 THEN 10000 + (random() * 30000)::DECIMAL(10,2) -- Saldo justo
        ELSE 50000 + (random() * 100000)::DECIMAL(10,2)                    -- Saldo alto
    END,
    -- Distancias SUTILMENTE sospechosas
    CASE 
        WHEN random() < 0.4 THEN (random() * 30)::DECIMAL(8,2)      -- Cerca de lo usual
        WHEN random() < 0.7 THEN 30 + (random() * 100)::DECIMAL(8,2) -- Un poco lejos
        ELSE 100 + (random() * 200)::DECIMAL(8,2)                   -- Lejos pero no ridículo
    END
FROM generate_series(1, 900) gs;

-- Tipo 2: Fraudes de pequeños montos pero patrones sospechosos (40% del fraude)
INSERT INTO transacciones (
    cuenta_origen_id, monto, comerciante, categoria_comerciante,
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion,
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
)
SELECT 
    1000 + (gs % 800),
    -- Montos PEQUEÑOS pero con patrones sospechosos
    CASE 
        WHEN random() < 0.5 THEN 200 + (random() * 800)::DECIMAL(10,2)    -- $200-1000 (testeo de tarjeta)
        WHEN random() < 0.8 THEN 1000 + (random() * 2000)::DECIMAL(10,2)  -- $1000-3000 (fraude menor)
        ELSE 3000 + (random() * 5000)::DECIMAL(10,2)                      -- $3000-8000 (fraude medio)
    END,
    -- Comerciantes diversos
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
    -- Horarios MÁS normales para ser sutiles
    CASE 
        WHEN random() < 0.8 THEN TIME '08:00:00' + (random() * INTERVAL '14 hours')  -- Horarios normales
        WHEN random() < 0.9 THEN TIME '23:00:00' + (random() * INTERVAL '2 hours')  -- Noche
        ELSE TIME '02:00:00' + (random() * INTERVAL '3 hours')                      -- Madrugada
    END,
    CURRENT_DATE - (random() * 60)::int,
    TRUE,  -- ✅ FRAUDE PERO MUY SUTIL
    CASE WHEN random() < 0.7 THEN 'online' WHEN random() < 0.9 THEN 'pos' ELSE 'mobile' END,
    5000 + (random() * 45000)::DECIMAL(10,2),  -- Saldos normales
    (random() * 150)::DECIMAL(8,2)  -- Distancias variadas
FROM generate_series(1, 600) gs;

-- ===== VERIFICAR DISTRIBUCIÓN REALISTA =====
\echo '🔍 Verificando distribución realista de datos...';

-- Mostrar estadísticas detalladas
WITH stats AS (
    SELECT 
        es_fraude,
        COUNT(*) as cantidad,
        ROUND(AVG(monto), 2) as monto_promedio,
        ROUND(MIN(monto), 2) as monto_minimo,
        ROUND(MAX(monto), 2) as monto_maximo,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY monto), 2) as monto_mediana
    FROM transacciones
    GROUP BY es_fraude
)
SELECT 
    CASE WHEN es_fraude THEN 'FRAUDULENTAS' ELSE 'NORMALES' END as tipo,
    cantidad,
    ROUND((cantidad * 100.0 / (SELECT COUNT(*) FROM transacciones)), 2) as porcentaje,
    monto_promedio,
    monto_minimo,
    monto_maximo,
    monto_mediana
FROM stats
ORDER BY es_fraude;

-- ===== GENERAR ALERTAS SUTILES =====
\echo '🚨 Generando alertas sutiles y realistas...';
INSERT INTO alertas_fraude (transaccion_id, tipo_alerta, nivel_riesgo, puntuacion_riesgo, descripcion)
SELECT
    t.id,
    CASE
        WHEN t.monto > 100000 THEN 'Monto Muy Alto'
        WHEN t.monto > 50000 THEN 'Monto Alto Inusual'
        WHEN EXTRACT(HOUR FROM t.horario_transaccion) BETWEEN 1 AND 4 THEN 'Horario Inusual'
        WHEN t.distancia_ubicacion_usual > 100 THEN 'Ubicación Distante'
        ELSE 'Patrón Sospechoso General'
    END,
    CASE
        WHEN t.monto > 100000 AND EXTRACT(HOUR FROM t.horario_transaccion) BETWEEN 1 AND 4 THEN 'crítico'
        WHEN t.monto > 75000 THEN 'alto'
        WHEN t.monto > 40000 OR EXTRACT(HOUR FROM t.horario_transaccion) BETWEEN 1 AND 4 THEN 'medio'
        ELSE 'bajo'
    END,
    -- Puntuaciones MÁS REALISTAS (no siempre 95+)
    CASE
        WHEN t.monto > 100000 AND EXTRACT(HOUR FROM t.horario_transaccion) BETWEEN 1 AND 4 THEN 85.0 + (random() * 10)
        WHEN t.monto > 75000 THEN 70.0 + (random() * 15)
        WHEN t.monto > 40000 THEN 60.0 + (random() * 15)
        WHEN EXTRACT(HOUR FROM t.horario_transaccion) BETWEEN 1 AND 4 THEN 55.0 + (random() * 20)
        ELSE 45.0 + (random() * 25)
    END,
    'Alerta generada por patrón de comportamiento inusual'
FROM transacciones t
WHERE t.es_fraude = TRUE
AND random() < 0.7;  -- Solo 70% de los fraudes generan alertas

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

-- Mostrar tasas de fraude por comerciante
\echo '📊 Tasas de fraude por comerciante:';
SELECT 
    codigo_comerciante,
    nombre,
    total_transacciones,
    transacciones_fraudulentas,
    ROUND(tasa_fraude * 100, 2) as tasa_fraude_porcentaje
FROM comerciantes 
WHERE total_transacciones > 0
ORDER BY tasa_fraude DESC;

\echo '✅ Datos SUTILES y REALISTAS insertados exitosamente';
\echo '   📊 10,000 transacciones generadas (8,500 normales + 1,500 fraudulentas)';
\echo '   🎯 Fraudes sutiles con patrones realistas';
\echo '   💡 Montos y horarios menos evidentes';
\echo '   🔍 Distribución optimizada para ML realista';