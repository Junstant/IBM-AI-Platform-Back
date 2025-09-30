-- 02-banco-global-schema.sql
-- Esquema y datos para la base de datos banco_global (TextoSQL)

\echo '🏦 Configurando esquema para banco_global...'

\c banco_global;

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===== TABLA CLIENTES =====
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    documento_identidad VARCHAR(20) UNIQUE,
    tipo_documento VARCHAR(10) DEFAULT 'DNI',
    direccion TEXT,
    ciudad VARCHAR(100),
    codigo_postal VARCHAR(10),
    estado_civil VARCHAR(20),
    profesion VARCHAR(100),
    ingresos_mensuales DECIMAL(12,2),
    fecha_registro DATE DEFAULT CURRENT_DATE,
    ultimo_acceso TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'suspendido')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA TIPOS DE CUENTA =====
CREATE TABLE IF NOT EXISTS tipos_cuenta (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion TEXT,
    tasa_interes DECIMAL(5,4) DEFAULT 0.0000,
    monto_minimo DECIMAL(12,2) DEFAULT 0.00,
    comision_mantenimiento DECIMAL(8,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA CUENTAS =====
CREATE TABLE IF NOT EXISTS cuentas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id) ON DELETE CASCADE,
    tipo_cuenta_id INTEGER REFERENCES tipos_cuenta(id),
    numero_cuenta VARCHAR(20) UNIQUE NOT NULL,
    saldo DECIMAL(15,2) DEFAULT 0.00,
    saldo_disponible DECIMAL(15,2) DEFAULT 0.00,
    fecha_apertura DATE DEFAULT CURRENT_DATE,
    fecha_cierre DATE,
    estado VARCHAR(20) DEFAULT 'activa' CHECK (estado IN ('activa', 'cerrada', 'bloqueada', 'suspendida')),
    sucursal_apertura VARCHAR(100),
    limite_sobregiro DECIMAL(12,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA TIPOS DE TRANSACCIÓN =====
CREATE TABLE IF NOT EXISTS tipos_transaccion (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    requiere_autorizacion BOOLEAN DEFAULT FALSE,
    comision DECIMAL(8,2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA TRANSACCIONES =====
CREATE TABLE IF NOT EXISTS transacciones_banco (
    id SERIAL PRIMARY KEY,
    numero_transaccion VARCHAR(30) UNIQUE NOT NULL DEFAULT 'TXN-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
    cuenta_origen_id INTEGER REFERENCES cuentas(id),
    cuenta_destino_id INTEGER REFERENCES cuentas(id),
    tipo_transaccion_id INTEGER REFERENCES tipos_transaccion(id),
    monto DECIMAL(15,2) NOT NULL,
    comision DECIMAL(8,2) DEFAULT 0.00,
    monto_total DECIMAL(15,2) GENERATED ALWAYS AS (monto + comision) STORED,
    descripcion TEXT,
    referencia_externa VARCHAR(100),
    fecha_transaccion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_procesamiento TIMESTAMP,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'procesada', 'rechazada', 'reversada')),
    canal VARCHAR(50) DEFAULT 'sucursal',
    ubicacion VARCHAR(200),
    usuario_autorizacion VARCHAR(100),
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA SUCURSALES =====
CREATE TABLE IF NOT EXISTS sucursales (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    direccion TEXT NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    horario_atencion VARCHAR(200),
    gerente VARCHAR(100),
    fecha_apertura DATE,
    estado VARCHAR(20) DEFAULT 'activa',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA PRODUCTOS BANCARIOS =====
CREATE TABLE IF NOT EXISTS productos_bancarios (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    descripcion TEXT,
    tasa_interes DECIMAL(5,4),
    plazo_minimo INTEGER, -- en días
    monto_minimo DECIMAL(12,2),
    monto_maximo DECIMAL(12,2),
    comisiones JSONB,
    requisitos TEXT[],
    estado VARCHAR(20) DEFAULT 'activo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA PRÉSTAMOS =====
CREATE TABLE IF NOT EXISTS prestamos (
    id SERIAL PRIMARY KEY,
    numero_prestamo VARCHAR(20) UNIQUE NOT NULL,
    cliente_id INTEGER REFERENCES clientes(id),
    producto_id INTEGER REFERENCES productos_bancarios(id),
    monto_solicitado DECIMAL(15,2) NOT NULL,
    monto_aprobado DECIMAL(15,2),
    tasa_interes DECIMAL(5,4) NOT NULL,
    plazo_meses INTEGER NOT NULL,
    cuota_mensual DECIMAL(12,2),
    fecha_solicitud DATE DEFAULT CURRENT_DATE,
    fecha_aprobacion DATE,
    fecha_desembolso DATE,
    fecha_vencimiento DATE,
    estado VARCHAR(30) DEFAULT 'solicitado',
    garantias TEXT,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== ÍNDICES PARA OPTIMIZACIÓN =====
CREATE INDEX idx_clientes_email ON clientes(email);
CREATE INDEX idx_clientes_documento ON clientes(documento_identidad);
CREATE INDEX idx_cuentas_numero ON cuentas(numero_cuenta);
CREATE INDEX idx_cuentas_cliente ON cuentas(cliente_id);
CREATE INDEX idx_transacciones_fecha ON transacciones_banco(fecha_transaccion);
CREATE INDEX idx_transacciones_cuenta_origen ON transacciones_banco(cuenta_origen_id);
CREATE INDEX idx_transacciones_cuenta_destino ON transacciones_banco(cuenta_destino_id);
CREATE INDEX idx_transacciones_estado ON transacciones_banco(estado);

\echo '✅ Esquema banco_global configurado exitosamente';