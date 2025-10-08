-- databases/banco_global/02-seed-data.sql
-- Datos iniciales básicos para banco_global

\echo '🏦 Insertando datos básicos para banco_global...'

\c banco_global;

-- ===== TIPOS DE CUENTA BÁSICOS =====
INSERT INTO tipos_cuenta (nombre, descripcion, tasa_interes, monto_minimo, comision_mantenimiento) VALUES
('Cuenta Corriente', 'Cuenta para movimientos diarios', 0.0000, 0.00, 15.00),
('Cuenta de Ahorros', 'Cuenta para ahorros con intereses', 0.0250, 100.00, 5.00),
('Cuenta Premium', 'Cuenta con beneficios adicionales', 0.0350, 5000.00, 25.00),
('Cuenta Empresarial', 'Cuenta para empresas', 0.0150, 1000.00, 50.00)
ON CONFLICT (nombre) DO NOTHING;

-- ===== TIPOS DE TRANSACCIÓN BÁSICOS =====
INSERT INTO tipos_transaccion (codigo, nombre, descripcion, requiere_autorizacion, comision) VALUES
('DEP', 'Depósito', 'Depósito en efectivo o cheque', FALSE, 0.00),
('RET', 'Retiro', 'Retiro en efectivo', FALSE, 2.00),
('TRANS', 'Transferencia', 'Transferencia entre cuentas', FALSE, 5.00),
('PAGO', 'Pago de Servicios', 'Pago de servicios públicos', FALSE, 3.00)
ON CONFLICT (codigo) DO NOTHING;

-- ===== SUCURSALES BÁSICAS =====
INSERT INTO sucursales (codigo, nombre, direccion, ciudad, telefono, gerente) VALUES
('SUC001', 'Sucursal Centro', 'Av. Principal 123', 'Buenos Aires', '+54-11-1234-5678', 'María González'),
('SUC002', 'Sucursal Norte', 'Calle Norte 456', 'Buenos Aires', '+54-11-2345-6789', 'Carlos Rodríguez')
ON CONFLICT (codigo) DO NOTHING;

\echo '✅ Datos básicos insertados en banco_global';