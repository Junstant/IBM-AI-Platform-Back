-- databases/banco_global/01-schema.sql
-- Esquema completo para la base de datos banco_global (TextoSQL)

\echo '🏦 Configurando esquema para banco_global...'

\c banco_global;

-- Crear extensiones útiles
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ===== TABLA TIPOS DE CUENTA =====
CREATE TABLE IF NOT EXISTS tipos_cuenta (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    tasa_interes DECIMAL(5,4) DEFAULT 0.0000,
    monto_minimo DECIMAL(15,2) DEFAULT 0.00,
    comision_mantenimiento DECIMAL(10,2) DEFAULT 0.00,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA CLIENTES =====
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    documento_identidad VARCHAR(20) UNIQUE,
    direccion TEXT,
    ciudad VARCHAR(100),
    provincia VARCHAR(100),
    codigo_postal VARCHAR(10),
    estado VARCHAR(20) DEFAULT 'activo',
    fecha_registro DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_estado_cliente CHECK (estado IN ('activa', 'inactiva', 'suspendida', 'cerrada')),
    CONSTRAINT chk_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

-- ===== TABLA SUCURSALES =====
CREATE TABLE IF NOT EXISTS sucursales (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    direccion TEXT NOT NULL,
    ciudad VARCHAR(100) NOT NULL,
    provincia VARCHAR(100),
    codigo_postal VARCHAR(10),
    telefono VARCHAR(20),
    email VARCHAR(150),
    horario_atencion VARCHAR(100),
    gerente VARCHAR(100),
    fecha_apertura DATE DEFAULT CURRENT_DATE,
    activa BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA CUENTAS =====
CREATE TABLE IF NOT EXISTS cuentas (
    id SERIAL PRIMARY KEY,
    numero_cuenta VARCHAR(20) UNIQUE NOT NULL,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    tipo_cuenta_id INTEGER NOT NULL REFERENCES tipos_cuenta(id),
    sucursal_id INTEGER REFERENCES sucursales(id),
    saldo DECIMAL(15,2) DEFAULT 0.00,
    fecha_apertura DATE DEFAULT CURRENT_DATE,
    estado VARCHAR(20) DEFAULT 'activa',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_estado_cuenta CHECK (estado IN ('activa', 'inactiva', 'suspendida', 'cerrada'))
);

-- ===== TABLA TIPOS DE TRANSACCIÓN =====
CREATE TABLE IF NOT EXISTS tipos_transaccion (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(10) UNIQUE NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    requiere_autorizacion BOOLEAN DEFAULT FALSE,
    comision DECIMAL(10,2) DEFAULT 0.00,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA TRANSACCIONES =====
CREATE TABLE IF NOT EXISTS transacciones_banco (
    id SERIAL PRIMARY KEY,
    numero_transaccion VARCHAR(50) UNIQUE DEFAULT ('TXN-' || EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint || '-' || FLOOR(RANDOM() * 1000)::int),
    cuenta_origen_id INTEGER REFERENCES cuentas(id),
    cuenta_destino_id INTEGER REFERENCES cuentas(id),
    tipo_transaccion_id INTEGER NOT NULL REFERENCES tipos_transaccion(id),
    monto DECIMAL(15,2) NOT NULL,
    descripcion TEXT,
    fecha_transaccion DATE DEFAULT CURRENT_DATE,
    hora_transaccion TIME DEFAULT CURRENT_TIME,
    sucursal_id INTEGER REFERENCES sucursales(id),
    usuario_cajero VARCHAR(100),
    referencia_externa VARCHAR(100),
    estado VARCHAR(20) DEFAULT 'completada',
    comision_aplicada DECIMAL(10,2) DEFAULT 0.00,
    saldo_anterior_origen DECIMAL(15,2),
    saldo_nuevo_origen DECIMAL(15,2),
    saldo_anterior_destino DECIMAL(15,2),
    saldo_nuevo_destino DECIMAL(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_estado_transaccion CHECK (estado IN ('pendiente', 'completada', 'cancelada', 'rechazada')),
    CONSTRAINT chk_monto_positivo CHECK (monto > 0)
);

-- ===== TABLA PRODUCTOS BANCARIOS =====
CREATE TABLE IF NOT EXISTS productos_bancarios (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    categoria VARCHAR(100) NOT NULL,
    descripcion TEXT,
    tasa_interes DECIMAL(6,4),
    plazo_minimo INTEGER,
    plazo_maximo INTEGER,
    monto_minimo DECIMAL(15,2),
    monto_maximo DECIMAL(15,2),
    requisitos TEXT[],
    comisiones JSONB,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA PRÉSTAMOS =====
CREATE TABLE IF NOT EXISTS prestamos (
    id SERIAL PRIMARY KEY,
    numero_prestamo VARCHAR(30) UNIQUE DEFAULT ('PREST-' || EXTRACT(epoch FROM CURRENT_TIMESTAMP)::bigint),
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    producto_id INTEGER REFERENCES productos_bancarios(id),
    monto DECIMAL(15,2) NOT NULL,
    tasa_interes DECIMAL(6,4) NOT NULL,
    plazo_meses INTEGER NOT NULL,
    cuota_mensual DECIMAL(15,2) NOT NULL,
    fecha_otorgamiento DATE DEFAULT CURRENT_DATE,
    fecha_vencimiento DATE,
    saldo_pendiente DECIMAL(15,2),
    estado VARCHAR(20) DEFAULT 'activo',
    sucursal_id INTEGER REFERENCES sucursales(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_estado_prestamo CHECK (estado IN ('solicitado', 'aprobado', 'activo', 'pagado', 'vencido', 'cancelado'))
);

-- ===== TABLA TARJETAS =====
CREATE TABLE IF NOT EXISTS tarjetas (
    id SERIAL PRIMARY KEY,
    numero VARCHAR(20) UNIQUE NOT NULL,
    cliente_id INTEGER NOT NULL REFERENCES clientes(id),
    cuenta_id INTEGER REFERENCES cuentas(id),
    tipo VARCHAR(20) NOT NULL,
    fecha_emision DATE DEFAULT CURRENT_DATE,
    fecha_vencimiento DATE NOT NULL,
    limite_credito DECIMAL(15,2),
    estado VARCHAR(20) DEFAULT 'activa',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_tipo_tarjeta CHECK (tipo IN ('débito', 'crédito', 'prepaga')),
    CONSTRAINT chk_estado_tarjeta CHECK (estado IN ('activa', 'bloqueada', 'vencida', 'cancelada'))
);

-- ===== ÍNDICES PARA OPTIMIZACIÓN =====
CREATE INDEX IF NOT EXISTS idx_clientes_email ON clientes(email);
CREATE INDEX IF NOT EXISTS idx_clientes_documento ON clientes(documento_identidad);
CREATE INDEX IF NOT EXISTS idx_cuentas_numero ON cuentas(numero_cuenta);
CREATE INDEX IF NOT EXISTS idx_cuentas_cliente ON cuentas(cliente_id);
CREATE INDEX IF NOT EXISTS idx_transacciones_fecha ON transacciones_banco(fecha_transaccion);
CREATE INDEX IF NOT EXISTS idx_transacciones_cuenta_origen ON transacciones_banco(cuenta_origen_id);
CREATE INDEX IF NOT EXISTS idx_transacciones_cuenta_destino ON transacciones_banco(cuenta_destino_id);
CREATE INDEX IF NOT EXISTS idx_transacciones_estado ON transacciones_banco(estado);
CREATE INDEX IF NOT EXISTS idx_prestamos_cliente ON prestamos(cliente_id);
CREATE INDEX IF NOT EXISTS idx_tarjetas_cliente ON tarjetas(cliente_id);

\echo '✅ Esquema banco_global configurado exitosamente';