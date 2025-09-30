-- 03-banco-global-data.sql
-- Datos de ejemplo para la base de datos banco_global

\echo '📊 Insertando datos de ejemplo en banco_global...'

\c banco_global;

-- ===== TIPOS DE CUENTA =====
INSERT INTO tipos_cuenta (nombre, descripcion, tasa_interes, monto_minimo, comision_mantenimiento) VALUES
('Cuenta Corriente', 'Cuenta para movimientos diarios', 0.0000, 0.00, 15.00),
('Cuenta de Ahorros', 'Cuenta para ahorros con intereses', 0.0250, 100.00, 5.00),
('Cuenta Premium', 'Cuenta con beneficios adicionales', 0.0350, 5000.00, 25.00),
('Cuenta Empresarial', 'Cuenta para empresas', 0.0150, 1000.00, 50.00),
('Cuenta Joven', 'Cuenta especial para jóvenes', 0.0300, 50.00, 0.00)
ON CONFLICT (nombre) DO NOTHING;

-- ===== TIPOS DE TRANSACCIÓN =====
INSERT INTO tipos_transaccion (codigo, nombre, descripcion, requiere_autorizacion, comision) VALUES
('DEP', 'Depósito', 'Depósito en efectivo o cheque', FALSE, 0.00),
('RET', 'Retiro', 'Retiro en efectivo', FALSE, 2.00),
('TRANS', 'Transferencia', 'Transferencia entre cuentas', FALSE, 5.00),
('PAGO', 'Pago de Servicios', 'Pago de servicios públicos', FALSE, 3.00),
('PREST', 'Pago Préstamo', 'Pago de cuota de préstamo', FALSE, 0.00),
('WIRE', 'Transferencia Internacional', 'Transferencia internacional', TRUE, 25.00),
('CHQ', 'Emisión Cheque', 'Emisión de cheque', FALSE, 1.50)
ON CONFLICT (codigo) DO NOTHING;

-- ===== SUCURSALES =====
INSERT INTO sucursales (codigo, nombre, direccion, ciudad, telefono, horario_atencion, gerente, fecha_apertura) VALUES
('SUC001', 'Sucursal Centro', 'Av. Principal 123', 'Buenos Aires', '+54-11-1234-5678', 'L-V: 8:00-16:00', 'María González', '2020-01-15'),
('SUC002', 'Sucursal Norte', 'Calle Norte 456', 'Buenos Aires', '+54-11-2345-6789', 'L-V: 9:00-17:00', 'Carlos Rodríguez', '2020-03-20'),
('SUC003', 'Sucursal Sur', 'Av. Sur 789', 'Buenos Aires', '+54-11-3456-7890', 'L-V: 8:30-16:30', 'Ana Martínez', '2020-06-10'),
('SUC004', 'Sucursal Oeste', 'Blvd. Oeste 321', 'Buenos Aires', '+54-11-4567-8901', 'L-V: 8:00-15:00', 'Luis Fernández', '2021-01-05')
ON CONFLICT (codigo) DO NOTHING;

-- ===== PRODUCTOS BANCARIOS =====
INSERT INTO productos_bancarios (codigo, nombre, categoria, descripcion, tasa_interes, plazo_minimo, monto_minimo, monto_maximo, requisitos) VALUES
('PREST-PERS', 'Préstamo Personal', 'Préstamos', 'Préstamo personal sin garantía', 0.1800, 90, 10000.00, 500000.00, ARRAY['Ingresos demostrables', 'Antigüedad laboral 6 meses']),
('PREST-HIP', 'Préstamo Hipotecario', 'Préstamos', 'Préstamo para compra de vivienda', 0.0850, 1095, 100000.00, 2000000.00, ARRAY['Garantía hipotecaria', 'Ingresos demostrables', 'Seguro de vida']),
('TARJ-CRED', 'Tarjeta de Crédito', 'Tarjetas', 'Tarjeta de crédito Visa/Mastercard', 0.2400, 30, 1000.00, 100000.00, ARRAY['Ingresos mínimos $50,000', 'Score crediticio']),
('PLAZO-FIJO', 'Plazo Fijo', 'Inversiones', 'Inversión a plazo fijo', 0.0450, 30, 5000.00, 10000000.00, ARRAY['Monto mínimo']),
('FONDO-INV', 'Fondo de Inversión', 'Inversiones', 'Fondo común de inversión', 0.0600, 30, 1000.00, NULL, ARRAY['Perfil de riesgo'])
ON CONFLICT (codigo) DO NOTHING;

-- ===== CLIENTES =====
INSERT INTO clientes (nombre, apellido, email, telefono, fecha_nacimiento, documento_identidad, tipo_documento, direccion, ciudad, codigo_postal, estado_civil, profesion, ingresos_mensuales) VALUES
('Juan Carlos', 'Pérez López', 'juan.perez@email.com', '+54-11-9876-5432', '1985-03-15', '12345678', 'DNI', 'Av. Libertador 1500', 'Buenos Aires', '1425', 'Casado', 'Ingeniero', 150000.00),
('María Elena', 'García Rodríguez', 'maria.garcia@email.com', '+54-11-8765-4321', '1990-07-22', '23456789', 'DNI', 'Calle Florida 800', 'Buenos Aires', '1005', 'Soltera', 'Contadora', 120000.00),
('Carlos Alberto', 'López Martínez', 'carlos.lopez@email.com', '+54-11-7654-3210', '1982-11-08', '34567890', 'DNI', 'Av. Corrientes 2200', 'Buenos Aires', '1040', 'Divorciado', 'Abogado', 200000.00),
('Ana Sofía', 'Martínez Silva', 'ana.martinez@email.com', '+54-11-6543-2109', '1988-05-30', '45678901', 'DNI', 'Calle Defensa 456', 'Buenos Aires', '1065', 'Casada', 'Médica', 180000.00),
('Luis Fernando', 'Fernández Torres', 'luis.fernandez@email.com', '+54-11-5432-1098', '1995-12-12', '56789012', 'DNI', 'Av. Santa Fe 3000', 'Buenos Aires', '1425', 'Soltero', 'Programador', 140000.00),
('Patricia Isabel', 'González Herrera', 'patricia.gonzalez@email.com', '+54-11-4321-0987', '1987-09-18', '67890123', 'DNI', 'Calle Maipú 750', 'Buenos Aires', '1006', 'Casada', 'Arquitecta', 160000.00),
('Roberto Miguel', 'Sánchez Díaz', 'roberto.sanchez@email.com', '+54-11-3210-9876', '1983-02-25', '78901234', 'DNI', 'Av. Rivadavia 5500', 'Buenos Aires', '1424', 'Casado', 'Comerciante', 130000.00),
('Claudia Beatriz', 'Ramírez Castro', 'claudia.ramirez@email.com', '+54-11-2109-8765', '1992-08-14', '89012345', 'DNI', 'Calle Lavalle 1200', 'Buenos Aires', '1048', 'Soltera', 'Diseñadora', 110000.00)
ON CONFLICT (documento_identidad) DO NOTHING;

-- ===== CUENTAS =====
INSERT INTO cuentas (cliente_id, tipo_cuenta_id, numero_cuenta, saldo, saldo_disponible, sucursal_apertura) VALUES
(1, 1, '0001-2001-3001-4001', 25000.00, 25000.00, 'SUC001'),
(1, 2, '0001-2002-3001-4001', 50000.00, 50000.00, 'SUC001'),
(2, 1, '0002-2001-3002-4002', 18500.00, 18500.00, 'SUC002'),
(2, 3, '0002-2003-3002-4002', 85000.00, 85000.00, 'SUC002'),
(3, 1, '0003-2001-3003-4003', 32000.00, 32000.00, 'SUC001'),
(3, 4, '0003-2004-3003-4003', 150000.00, 150000.00, 'SUC001'),
(4, 2, '0004-2002-3004-4004', 42000.00, 42000.00, 'SUC003'),
(5, 5, '0005-2005-3005-4005', 8500.00, 8500.00, 'SUC004'),
(6, 1, '0006-2001-3006-4006', 28000.00, 28000.00, 'SUC002'),
(7, 1, '0007-2001-3007-4007', 35000.00, 35000.00, 'SUC003'),
(8, 2, '0008-2002-3008-4008', 12000.00, 12000.00, 'SUC004')
ON CONFLICT (numero_cuenta) DO NOTHING;

-- ===== TRANSACCIONES DE EJEMPLO =====
-- Usar números únicos para evitar conflictos
INSERT INTO transacciones_banco (numero_transaccion, cuenta_origen_id, cuenta_destino_id, tipo_transaccion_id, monto, descripcion, canal, estado, fecha_transaccion) VALUES
-- Depósitos iniciales
('TXN-INIT-001', NULL, 1, 1, 25000.00, 'Depósito inicial apertura cuenta', 'sucursal', 'procesada', '2024-01-15 09:30:00'),
('TXN-INIT-002', NULL, 2, 1, 50000.00, 'Depósito inicial apertura cuenta ahorros', 'sucursal', 'procesada', '2024-01-15 09:45:00'),
('TXN-INIT-003', NULL, 3, 1, 18500.00, 'Depósito inicial apertura cuenta', 'sucursal', 'procesada', '2024-01-20 10:15:00'),

-- Transferencias entre cuentas
('TXN-TRANS-001', 1, 3, 3, 5000.00, 'Transferencia a María García', 'online', 'procesada', '2024-09-15 14:20:00'),
('TXN-TRANS-002', 2, 7, 3, 8000.00, 'Pago a proveedor', 'online', 'procesada', '2024-09-20 11:30:00'),
('TXN-TRANS-003', 3, 1, 3, 2000.00, 'Devolución préstamo', 'sucursal', 'procesada', '2024-09-22 16:45:00'),

-- Retiros
('TXN-RET-001', 1, NULL, 2, 3000.00, 'Retiro en efectivo ATM', 'atm', 'procesada', '2024-09-25 19:15:00'),
('TXN-RET-002', 4, NULL, 2, 5000.00, 'Retiro en efectivo sucursal', 'sucursal', 'procesada', '2024-09-26 10:30:00'),

-- Pagos de servicios
('TXN-PAGO-001', 1, NULL, 4, 1500.00, 'Pago servicio eléctrico', 'online', 'procesada', '2024-09-27 08:45:00'),
('TXN-PAGO-002', 2, NULL, 4, 2200.00, 'Pago servicio gas', 'online', 'procesada', '2024-09-27 09:00:00'),
('TXN-PAGO-003', 3, NULL, 4, 800.00, 'Pago servicio agua', 'sucursal', 'procesada', '2024-09-28 14:20:00')
ON CONFLICT (numero_transaccion) DO NOTHING;

-- ===== PRÉSTAMOS =====
INSERT INTO prestamos (numero_prestamo, cliente_id, producto_id, monto_solicitado, monto_aprobado, tasa_interes, plazo_meses, cuota_mensual, fecha_solicitud, fecha_aprobacion, fecha_desembolso, estado) VALUES
('PREST-001-2024', 1, 1, 100000.00, 90000.00, 0.1800, 24, 4500.00, '2024-08-01', '2024-08-15', '2024-08-20', 'vigente'),
('PREST-002-2024', 3, 1, 150000.00, 150000.00, 0.1750, 36, 5200.00, '2024-07-15', '2024-07-30', '2024-08-05', 'vigente'),
('PREST-003-2024', 4, 2, 800000.00, 750000.00, 0.0850, 240, 8500.00, '2024-06-01', '2024-06-20', '2024-07-01', 'vigente')
ON CONFLICT (numero_prestamo) DO NOTHING;

\echo '✅ Datos de ejemplo insertados en banco_global exitosamente';