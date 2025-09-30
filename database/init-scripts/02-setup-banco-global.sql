-- 02-setup-banco-global.sql
-- Esquema y datos iniciales para la base de datos banco_global (TextoSQL)

\echo 'Configurando esquema para banco_global...'

-- Conectar a la base de datos banco_global
\c banco_global;

-- Crear tabla de clientes
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    dni VARCHAR(20) UNIQUE,
    direccion TEXT,
    ciudad VARCHAR(100),
    pais VARCHAR(100) DEFAULT 'Argentina',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'activo',
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- Crear tabla de tipos de cuenta
CREATE TABLE IF NOT EXISTS tipos_cuenta (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    tasa_interes DECIMAL(5,4) DEFAULT 0.0000,
    comision_mantenimiento DECIMAL(10,2) DEFAULT 0.00,
    saldo_minimo DECIMAL(15,2) DEFAULT 0.00
);

-- Crear tabla de cuentas
CREATE TABLE IF NOT EXISTS cuentas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id) ON DELETE CASCADE,
    numero_cuenta VARCHAR(20) UNIQUE NOT NULL,
    tipo_cuenta_id INTEGER NOT NULL REFERENCES tipos_cuenta(id),
    saldo DECIMAL(15,2) DEFAULT 0.00,
    fecha_apertura DATE DEFAULT CURRENT_DATE,
    fecha_cierre DATE,
    estado VARCHAR(20) DEFAULT 'activa',
    sucursal VARCHAR(100),
    CONSTRAINT chk_saldo_positivo CHECK (saldo >= 0),
    CONSTRAINT chk_estado_cuenta CHECK (estado IN ('activa', 'suspendida', 'cerrada'))
);

-- Crear tabla de transacciones
CREATE TABLE IF NOT EXISTS transacciones_banco (
    id SERIAL PRIMARY KEY,
    cuenta_origen_id INTEGER REFERENCES cuentas(id),
    cuenta_destino_id INTEGER REFERENCES cuentas(id),
    monto DECIMAL(15,2) NOT NULL,
    tipo_transaccion VARCHAR(50) NOT NULL,
    descripcion TEXT,
    referencia VARCHAR(100),
    fecha_transaccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_procesamiento TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'pendiente',
    comision DECIMAL(10,2) DEFAULT 0.00,
    tasa_cambio DECIMAL(10,6),
    moneda_origen VARCHAR(3) DEFAULT 'ARS',
    moneda_destino VARCHAR(3) DEFAULT 'ARS',
    CONSTRAINT chk_monto_positivo CHECK (monto > 0),
    CONSTRAINT chk_estado_transaccion CHECK (estado IN ('pendiente', 'procesada', 'rechazada', 'cancelada')),
    CONSTRAINT chk_tipo_transaccion CHECK (tipo_transaccion IN (
        'deposito', 'retiro', 'transferencia', 'pago_servicio', 
        'compra', 'cajero', 'interes', 'comision'
    ))
);

-- Crear tabla de sucursales
CREATE TABLE IF NOT EXISTS sucursales (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT,
    ciudad VARCHAR(100),
    provincia VARCHAR(100),
    telefono VARCHAR(20),
    horario_atencion VARCHAR(200),
    fecha_apertura DATE DEFAULT CURRENT_DATE,
    gerente VARCHAR(100)
);

-- Crear tabla de productos bancarios
CREATE TABLE IF NOT EXISTS productos_bancarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    descripcion TEXT,
    tasa_interes DECIMAL(5,4),
    plazo_minimo INTEGER, -- en días
    plazo_maximo INTEGER, -- en días
    monto_minimo DECIMAL(15,2),
    monto_maximo DECIMAL(15,2),
    comisiones JSONB,
    requisitos TEXT,
    activo BOOLEAN DEFAULT true
);

-- Insertar tipos de cuenta
INSERT INTO tipos_cuenta (nombre, descripcion, tasa_interes, comision_mantenimiento, saldo_minimo) VALUES
('Caja de Ahorros', 'Cuenta básica para ahorros', 0.0200, 0.00, 0.00),
('Cuenta Corriente', 'Cuenta para operaciones comerciales', 0.0000, 500.00, 1000.00),
('Cuenta Premium', 'Cuenta con beneficios adicionales', 0.0350, 1200.00, 10000.00),
('Cuenta Empresarial', 'Cuenta para empresas', 0.0150, 2000.00, 50000.00);

-- Insertar sucursales
INSERT INTO sucursales (codigo, nombre, direccion, ciudad, provincia, telefono, gerente) VALUES
('SUC001', 'Sucursal Centro', 'Av. San Martín 1234', 'Buenos Aires', 'CABA', '011-1234-5678', 'Ana García'),
('SUC002', 'Sucursal Norte', 'Av. Cabildo 5678', 'Buenos Aires', 'CABA', '011-2345-6789', 'Carlos Mendez'),
('SUC003', 'Sucursal Microcentro', 'Florida 890', 'Buenos Aires', 'CABA', '011-3456-7890', 'Laura Rodriguez'),
('SUC004', 'Sucursal Palermo', 'Av. Santa Fe 2345', 'Buenos Aires', 'CABA', '011-4567-8901', 'Miguel Torres');

-- Insertar productos bancarios
INSERT INTO productos_bancarios (nombre, tipo, descripcion, tasa_interes, plazo_minimo, monto_minimo, activo) VALUES
('Plazo Fijo 30 días', 'Plazo Fijo', 'Inversión a plazo fijo de 30 días', 0.4500, 30, 1000.00, true),
('Plazo Fijo 60 días', 'Plazo Fijo', 'Inversión a plazo fijo de 60 días', 0.4800, 60, 1000.00, true),
('Prestamo Personal', 'Préstamo', 'Préstamo personal sin garantía', 0.6500, null, 5000.00, true),
('Prestamo Hipotecario', 'Préstamo', 'Préstamo con garantía hipotecaria', 0.3500, null, 100000.00, true);

-- Insertar clientes de ejemplo
INSERT INTO clientes (nombre, apellido, email, telefono, fecha_nacimiento, dni, direccion, ciudad) VALUES
('Juan Carlos', 'Pérez', 'juan.perez@email.com', '011-1111-1111', '1985-03-15', '12345678', 'Rivadavia 1234', 'Buenos Aires'),
('María Elena', 'García', 'maria.garcia@email.com', '011-2222-2222', '1990-07-22', '23456789', 'Corrientes 5678', 'Buenos Aires'),
('Carlos Alberto', 'López', 'carlos.lopez@email.com', '011-3333-3333', '1978-11-08', '34567890', 'Santa Fe 9012', 'Buenos Aires'),
('Ana Lucía', 'Martínez', 'ana.martinez@email.com', '011-4444-4444', '1995-01-30', '45678901', 'Belgrano 3456', 'Buenos Aires'),
('Roberto Daniel', 'Fernández', 'roberto.fernandez@email.com', '011-5555-5555', '1982-05-12', '56789012', 'Callao 7890', 'Buenos Aires');

-- Insertar cuentas de ejemplo
INSERT INTO cuentas (cliente_id, numero_cuenta, tipo_cuenta_id, saldo, sucursal) VALUES
(1, '0001-2001-3001-4001', 1, 150000.00, 'SUC001'),
(1, '0001-2002-3002-4002', 2, 85000.00, 'SUC001'),
(2, '0002-2001-3001-4003', 1, 220000.00, 'SUC002'),
(3, '0003-2001-3001-4004', 1, 320000.00, 'SUC001'),
(3, '0003-2002-3002-4005', 3, 750000.00, 'SUC003'),
(4, '0004-2001-3001-4006', 1, 95000.00, 'SUC002'),
(5, '0005-2001-3001-4007', 4, 1250000.00, 'SUC004');

-- Insertar transacciones de ejemplo
INSERT INTO transacciones_banco (cuenta_origen_id, cuenta_destino_id, monto, tipo_transaccion, descripcion, estado, fecha_transaccion) VALUES
(1, 3, 25000.00, 'transferencia', 'Transferencia a María García', 'procesada', CURRENT_TIMESTAMP - INTERVAL '5 days'),
(2, null, 50000.00, 'deposito', 'Depósito en efectivo', 'procesada', CURRENT_TIMESTAMP - INTERVAL '3 days'),
(4, 1, 15000.00, 'transferencia', 'Pago de servicios', 'procesada', CURRENT_TIMESTAMP - INTERVAL '2 days'),
(5, null, 75000.00, 'retiro', 'Retiro cajero automático', 'procesada', CURRENT_TIMESTAMP - INTERVAL '1 day'),
(3, 6, 30000.00, 'transferencia', 'Transferencia a Ana Martínez', 'procesada', CURRENT_TIMESTAMP);

-- Crear índices para optimizar consultas
CREATE INDEX idx_clientes_email ON clientes(email);
CREATE INDEX idx_clientes_dni ON clientes(dni);
CREATE INDEX idx_cuentas_numero ON cuentas(numero_cuenta);
CREATE INDEX idx_cuentas_cliente ON cuentas(cliente_id);
CREATE INDEX idx_transacciones_fecha ON transacciones_banco(fecha_transaccion);
CREATE INDEX idx_transacciones_origen ON transacciones_banco(cuenta_origen_id);
CREATE INDEX idx_transacciones_destino ON transacciones_banco(cuenta_destino_id);

-- Crear vistas útiles
CREATE VIEW vista_cuentas_clientes AS
SELECT 
    c.id as cuenta_id,
    c.numero_cuenta,
    cl.nombre || ' ' || cl.apellido as cliente_nombre,
    cl.email,
    tc.nombre as tipo_cuenta,
    c.saldo,
    c.estado as estado_cuenta,
    c.fecha_apertura
FROM cuentas c
JOIN clientes cl ON c.cliente_id = cl.id
JOIN tipos_cuenta tc ON c.tipo_cuenta_id = tc.id;

CREATE VIEW vista_transacciones_detalle AS
SELECT 
    t.id,
    co.numero_cuenta as cuenta_origen,
    cd.numero_cuenta as cuenta_destino,
    t.monto,
    t.tipo_transaccion,
    t.descripcion,
    t.fecha_transaccion,
    t.estado,
    clo.nombre || ' ' || clo.apellido as cliente_origen,
    cld.nombre || ' ' || cld.apellido as cliente_destino
FROM transacciones_banco t
LEFT JOIN cuentas co ON t.cuenta_origen_id = co.id
LEFT JOIN cuentas cd ON t.cuenta_destino_id = cd.id
LEFT JOIN clientes clo ON co.cliente_id = clo.id
LEFT JOIN clientes cld ON cd.cliente_id = cld.id;

\echo 'Esquema banco_global configurado exitosamente con datos de ejemplo'