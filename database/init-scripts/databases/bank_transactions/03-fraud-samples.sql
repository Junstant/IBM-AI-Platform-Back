-- databases/bank_transactions/03-fraud-samples.sql
-- Muestras de transacciones para detección de fraude - VERSIÓN CORREGIDA

\echo '🔍 Insertando muestras de transacciones para detección de fraude...'

\c bank_transactions;

-- ===== INSERTAR COMERCIANTES DE MUESTRA =====
INSERT INTO comerciantes (codigo_comerciante, nombre, categoria, subcategoria, ubicacion, ciudad, pais, nivel_riesgo) VALUES
('COM001', 'Supermercado Central', 'Alimentación', 'Supermercados', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM002', 'Shell Estación Norte', 'Combustibles', 'Estaciones de Servicio', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'bajo'),
('COM003', 'Restaurant El Buen Sabor', 'Gastronomía', 'Restaurantes', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM004', 'Farmacia del Centro', 'Salud', 'Farmacias', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM005', 'E-Shop Sospechoso', 'E-commerce', 'Venta Online', 'Servidor Offshore', 'Desconocida', 'Desconocido', 'alto'),
('COM006', 'Casino Internacional', 'Entretenimiento', 'Casinos', 'Las Vegas Strip', 'Las Vegas', 'Estados Unidos', 'alto'),
('COM007', 'ATM Banco Nación', 'Bancario', 'Cajeros Automáticos', 'Microcentro, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM008', 'Kiosco Villa 31', 'Telecomunicaciones', 'Recargas', 'Villa 31, CABA', 'Buenos Aires', 'Argentina', 'medio'),
('COM009', 'Apple Store Unicenter', 'Tecnología', 'Electrónicos', 'Unicenter Shopping', 'Buenos Aires', 'Argentina', 'bajo'),
('COM010', 'Western Union Miami', 'Financiero', 'Remesas', 'Online Transfer', 'Miami', 'Estados Unidos', 'medio')
ON CONFLICT (codigo_comerciante) DO NOTHING;

-- ===== INSERTAR REGLAS DE FRAUDE =====
INSERT INTO reglas_fraude (nombre, descripcion, condicion, peso, activa) VALUES
('Monto Muy Alto', 'Transacción superior a $50,000', '{"monto_minimo": 50000}', 0.85, TRUE),
('Horario Nocturno', 'Transacciones entre 23:00 y 06:00', '{"horario_inicio": "23:00", "horario_fin": "06:00"}', 0.60, TRUE),
('País de Alto Riesgo', 'Transacciones desde países no confiables', '{"paises_riesgo": ["Desconocido"]}', 0.80, TRUE),
('Comerciante Alto Riesgo', 'Transacciones en comerciantes categorizados como alto riesgo', '{"nivel_riesgo_comerciante": "alto"}', 0.75, TRUE),
('Múltiples Transacciones', 'Más de 10 transacciones en una hora', '{"max_transacciones_hora": 10}', 0.70, TRUE),
('Distancia Inusual', 'Transacción a más de 100km de ubicación habitual', '{"distancia_maxima": 100}', 0.65, TRUE)
ON CONFLICT (nombre) DO NOTHING;

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