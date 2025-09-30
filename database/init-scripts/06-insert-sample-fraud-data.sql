-- 06-insert-sample-fraud-data.sql
-- Datos de ejemplo para detección de fraude

\echo '🔍 Insertando datos de ejemplo para detección de fraude...'

\c bank_transactions;

-- ===== REGLAS DE FRAUDE =====
INSERT INTO reglas_fraude (nombre, descripcion, categoria, peso) VALUES
('Monto Alto Inusual', 'Transacción con monto 5x superior al promedio del usuario', 'monto', 0.30),
('Horario Nocturno', 'Transacción entre 23:00 y 06:00', 'temporal', 0.15),
('Ubicación Distante', 'Transacción a más de 100km de ubicación usual', 'ubicacion', 0.25),
('Frecuencia Alta', 'Más de 5 transacciones en 1 hora', 'frecuencia', 0.20),
('Comerciante de Alto Riesgo', 'Transacción en comerciante con alta tasa de fraude', 'comerciante', 0.35),
('Transacción Internacional', 'Transacción fuera del país de residencia', 'ubicacion', 0.40),
('Monto Redondo Exacto', 'Montos en números redondos exactos (100, 500, 1000)', 'monto', 0.10);

-- ===== COMERCIANTES =====
INSERT INTO comerciantes (codigo_comerciante, nombre, categoria, subcategoria, ubicacion, ciudad, pais, nivel_riesgo) VALUES
('COM001', 'Supermercado Central', 'Alimentación', 'Supermercados', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM002', 'Estación de Servicio Shell', 'Combustibles', 'Estaciones de Servicio', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'bajo'),
('COM003', 'Restaurant El Buen Sabor', 'Gastronomía', 'Restaurantes', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM004', 'Farmacia del Centro', 'Salud', 'Farmacias', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM005', 'Tienda Online Sospechosa', 'E-commerce', 'Venta Online', 'Ubicación desconocida', 'Desconocida', 'Desconocido', 'alto'),
('COM006', 'Casino Las Vegas', 'Entretenimiento', 'Casinos', 'Las Vegas Strip', 'Las Vegas', 'Estados Unidos', 'alto'),
('COM007', 'ATM Banco Nación', 'Bancario', 'Cajeros', 'Microcentro, CABA', 'Buenos Aires', 'Argentina', 'bajo'),
('COM008', 'Carga Celular Kiosco', 'Telecomunicaciones', 'Recargas', 'Villa 31, CABA', 'Buenos Aires', 'Argentina', 'medio'),
('COM009', 'Apple Store Oficial', 'Tecnología', 'Electrónicos', 'Unicenter Shopping', 'Buenos Aires', 'Argentina', 'bajo'),
('COM010', 'Transferencia Internacional', 'Financiero', 'Remesas', 'Online', 'Miami', 'Estados Unidos', 'medio');

-- ===== DATOS DE TRANSACCIONES DE EJEMPLO =====
-- Insertamos transacciones normales y fraudulentas para entrenamiento

-- Transacciones NORMALES (es_fraude = FALSE)
INSERT INTO transacciones (
    cuenta_origen_id, cuenta_destino_id, monto, comerciante, categoria_comerciante, 
    ubicacion, ciudad, pais, tipo_tarjeta, horario_transaccion, fecha_transaccion, 
    es_fraude, canal, monto_cuenta_origen, distancia_ubicacion_usual
) VALUES
-- Usuario 1001 - Patrón normal: compras locales, montos razonables
(1001, NULL, 850.50, 'COM001', 'Alimentación', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'Débito', '14:30:00', '2024-09-15', FALSE, 'pos', 15000.00, 2.5),
(1001, NULL, 3200.00, 'COM002', 'Combustibles', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'Crédito', '08:15:00', '2024-09-16', FALSE, 'pos', 14149.50, 15.0),
(1001, NULL, 4500.00, 'COM003', 'Gastronomía', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'Débito', '20:45:00', '2024-09-17', FALSE, 'pos', 10949.50, 5.0),
(1001, NULL, 280.00, 'COM004', 'Salud', 'Florida 800, CABA', 'Buenos Aires', 'Argentina', 'Débito', '11:20:00', '2024-09-18', FALSE, 'pos', 6449.50, 1.0),

-- Usuario 1002 - Patrón normal: compras variadas
(1002, NULL, 1200.00, 'COM001', 'Alimentación', 'Av. Corrientes 1500, CABA', 'Buenos Aires', 'Argentina', 'Crédito', '16:00:00', '2024-09-15', FALSE, 'pos', 25000.00, 3.0),
(1002, NULL, 15000.00, 'COM009', 'Tecnología', 'Unicenter Shopping', 'Buenos Aires', 'Argentina', 'Crédito', '19:30:00', '2024-09-16', FALSE, 'pos', 23800.00, 10.0),
(1002, NULL, 500.00, 'COM007', 'Bancario', 'Microcentro, CABA', 'Buenos Aires', 'Argentina', 'Débito', '12:00:00', '2024-09-17', FALSE, 'atm', 8800.00, 2.0),

-- Usuario 1003 - Patrón normal
(1003, NULL, 650.00, 'COM002', 'Combustibles', 'Panamericana Km 25', 'Buenos Aires', 'Argentina', 'Débito', '07:45:00', '2024-09-15', FALSE, 'pos', 18000.00, 12.0),
(1003, NULL, 2200.00, 'COM003', 'Gastronomía', 'Palermo, CABA', 'Buenos Aires', 'Argentina', 'Crédito', '21:15:00', '2024-09-16', FALSE, 'pos', 17350.00, 8.0),

-- Transacciones FRAUDULENTAS (es_fraude = TRUE)
-- Casos de fraude por monto alto inusual
(1001, NULL, 45000.00, 'COM005', 'E-commerce', 'Ubicación desconocida', 'Desconocida', 'Desconocido', 'Crédito', '02:30:00', '2024-09-19', TRUE, 'online', 6169.50, 500.0),
(1002, NULL, 85000.00, 'COM006', 'Entretenimiento', 'Las Vegas Strip', 'Las Vegas', 'Estados Unidos', 'Crédito', '03:45:00', '2024-09-18', TRUE, 'online', 8300.00, 10000.0),

-- Casos de fraude por ubicación internacional sospechosa
(1003, NULL, 25000.00, 'COM010', 'Financiero', 'Online', 'Miami', 'Estados Unidos', 'Crédito', '01:15:00', '2024-09-17', TRUE, 'online', 15150.00, 8000.0),

-- Casos de fraude por horario nocturno + monto alto
(1001, NULL, 15000.00, 'COM008', 'Telecomunicaciones', 'Villa 31, CABA', 'Buenos Aires', 'Argentina', 'Débito', '23:45:00', '2024-09-20', TRUE, 'pos', 1169.50, 25.0),

-- Casos de fraude por múltiples transacciones rápidas
(1002, NULL, 5000.00, 'COM005', 'E-commerce', 'Ubicación desconocida', 'Desconocida', 'Desconocido', 'Crédito', '14:00:00', '2024-09-19', TRUE, 'online', 3300.00, 500.0),
(1002, NULL, 4500.00, 'COM005', 'E-commerce', 'Ubicación desconocida', 'Desconocida', 'Desconocido', 'Crédito', '14:05:00', '2024-09-19', TRUE, 'online', -1700.00, 500.0),
(1002, NULL, 3000.00, 'COM005', 'E-commerce', 'Ubicación desconocida', 'Desconocida', 'Desconocido', 'Crédito', '14:07:00', '2024-09-19', TRUE, 'online', -6200.00, 500.0);

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

-- ===== CREAR PERFILES DE USUARIO =====
SELECT actualizar_perfil_usuario(1001);
SELECT actualizar_perfil_usuario(1002);
SELECT actualizar_perfil_usuario(1003);

-- ===== GENERAR ALERTAS PARA TRANSACCIONES FRAUDULENTAS =====
INSERT INTO alertas_fraude (transaccion_id, tipo_alerta, nivel_riesgo, puntuacion_riesgo, descripcion, reglas_activadas)
SELECT 
    t.id,
    CASE 
        WHEN t.monto > 30000 AND t.pais != 'Argentina' THEN 'Transacción Internacional de Alto Monto'
        WHEN t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 'Transacción en Horario Nocturno'
        WHEN t.distancia_ubicacion_usual > 100 THEN 'Transacción en Ubicación Distante'
        ELSE 'Patrón Sospechoso Detectado'
    END,
    CASE 
        WHEN t.monto > 50000 OR t.pais != 'Argentina' THEN 'crítico'
        WHEN t.monto > 20000 OR t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 'alto'
        ELSE 'medio'
    END,
    CASE 
        WHEN t.monto > 50000 THEN 95.0
        WHEN t.pais != 'Argentina' THEN 85.0
        WHEN t.horario_transaccion BETWEEN '23:00:00' AND '06:00:00' THEN 75.0
        ELSE 65.0
    END,
    'Transacción marcada como fraudulenta por el sistema de detección',
    ARRAY['Monto Alto Inusual', 'Ubicación Distante', 'Horario Nocturno']
FROM transacciones t
WHERE t.es_fraude = TRUE;

\echo '✅ Datos de ejemplo para detección de fraude insertados exitosamente';