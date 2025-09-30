-- 12-create-missing-schemas.sql
-- Creación de esquemas faltantes para bases de datos existentes

\echo '🔧 Creando esquemas faltantes...'

-- ===== ESQUEMAS PARA PETROLERA =====
\c petrolera;

CREATE TABLE IF NOT EXISTS departamentos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    puesto VARCHAR(100) NOT NULL,
    salario NUMERIC(12,2),
    fecha_ingreso DATE,
    departamento_id INTEGER REFERENCES departamentos(id),
    estado VARCHAR(50) DEFAULT 'activo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS pozos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ubicacion TEXT,
    fecha_exploracion DATE,
    estado VARCHAR(50) DEFAULT 'activo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS extracciones (
    id SERIAL PRIMARY KEY,
    pozo_id INTEGER REFERENCES pozos(id),
    fecha DATE NOT NULL,
    cantidad_barriles INTEGER NOT NULL,
    calidad VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS equipos (
    id SERIAL PRIMARY KEY,
    tipo VARCHAR(100) NOT NULL,
    marca VARCHAR(100),
    estado VARCHAR(50) NOT NULL,
    fecha_adquisicion DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mantenimientos (
    id SERIAL PRIMARY KEY,
    equipo_id INTEGER REFERENCES equipos(id),
    fecha DATE NOT NULL,
    descripcion TEXT,
    costo NUMERIC(12,2),
    tipo VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS proveedores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    telefono VARCHAR(50),
    email VARCHAR(150),
    contacto VARCHAR(200),
    tipo VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS compras (
    id SERIAL PRIMARY KEY,
    equipo_id INTEGER REFERENCES equipos(id),
    proveedor_id INTEGER REFERENCES proveedores(id),
    fecha DATE NOT NULL,
    monto NUMERIC(12,2) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== ESQUEMAS ADICIONALES PARA BANCO_GLOBAL =====
\c banco_global;

CREATE TABLE IF NOT EXISTS sucursales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    direccion TEXT,
    ciudad VARCHAR(100),
    pais VARCHAR(100),
    telefono VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    puesto VARCHAR(100),
    salario NUMERIC(12,2),
    fecha_ingreso DATE,
    sucursal_id INTEGER REFERENCES sucursales(id),
    estado VARCHAR(50) DEFAULT 'activo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tarjetas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    numero VARCHAR(20) UNIQUE NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    fecha_emision DATE DEFAULT CURRENT_DATE,
    fecha_vencimiento DATE,
    limite_credito NUMERIC(15,2),
    estado VARCHAR(50) DEFAULT 'activa',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS prestamos (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    monto NUMERIC(15,2) NOT NULL,
    tasa_interes NUMERIC(5,4),
    plazo_meses INTEGER,
    fecha_otorgamiento DATE DEFAULT CURRENT_DATE,
    estado VARCHAR(50) DEFAULT 'activo',
    monto_pendiente NUMERIC(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS tipos_inversion (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    riesgo VARCHAR(50),
    descripcion TEXT,
    rendimiento_anual NUMERIC(6,4),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS inversiones (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    tipo_inversion_id INTEGER REFERENCES tipos_inversion(id),
    monto NUMERIC(15,2) NOT NULL,
    fecha_inicio DATE DEFAULT CURRENT_DATE,
    fecha_vencimiento DATE,
    estado VARCHAR(50) DEFAULT 'activa',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cajas_seguridad (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    sucursal_id INTEGER REFERENCES sucursales(id),
    tamaño VARCHAR(50),
    fecha_alta DATE DEFAULT CURRENT_DATE,
    costo_anual NUMERIC(10,2),
    estado VARCHAR(50) DEFAULT 'activa',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clientes_sucursales (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    sucursal_id INTEGER REFERENCES sucursales(id),
    fecha_asociacion DATE DEFAULT CURRENT_DATE,
    tipo_relacion VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== ESQUEMAS PARA EMPRESA_MINERA =====
\c empresa_minera;

CREATE TABLE IF NOT EXISTS minerales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio_por_tonelada NUMERIC(12,2),
    demanda VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS yacimientos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    ubicacion TEXT,
    tipo_mineral_principal INTEGER REFERENCES minerales(id),
    estado VARCHAR(50) DEFAULT 'activo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    puesto VARCHAR(100),
    fecha_ingreso DATE,
    yacimiento_id INTEGER REFERENCES yacimientos(id),
    salario NUMERIC(12,2),
    estado VARCHAR(50) DEFAULT 'activo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS turnos (
    id SERIAL PRIMARY KEY,
    empleado_id INTEGER REFERENCES empleados(id),
    fecha DATE NOT NULL,
    turno VARCHAR(50) NOT NULL,
    horas_trabajadas INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS maquinas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    tipo VARCHAR(100),
    proveedor_id INTEGER,
    fecha_adquisicion DATE,
    estado VARCHAR(50) DEFAULT 'operativa',
    yacimiento_id INTEGER REFERENCES yacimientos(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS operaciones (
    id SERIAL PRIMARY KEY,
    fecha TIMESTAMP NOT NULL,
    empleado_id INTEGER REFERENCES empleados(id),
    maquina_id INTEGER REFERENCES maquinas(id),
    mineral_id INTEGER REFERENCES minerales(id),
    yacimiento_id INTEGER REFERENCES yacimientos(id),
    cantidad_extraida NUMERIC(10,2) NOT NULL,
    calidad VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS proveedores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    contacto VARCHAR(200),
    telefono VARCHAR(50),
    email VARCHAR(150),
    tipo_proveedor VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS compras (
    id SERIAL PRIMARY KEY,
    proveedor_id INTEGER REFERENCES proveedores(id),
    fecha DATE NOT NULL,
    descripcion TEXT,
    monto NUMERIC(12,2) NOT NULL,
    tipo_compra VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS mantenimiento (
    id SERIAL PRIMARY KEY,
    maquina_id INTEGER REFERENCES maquinas(id),
    fecha DATE NOT NULL,
    descripcion TEXT,
    costo NUMERIC(10,2),
    tipo_mantenimiento VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    pais VARCHAR(100),
    contacto VARCHAR(200),
    telefono VARCHAR(50),
    tipo_cliente VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ventas (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    cliente_id INTEGER REFERENCES clientes(id),
    mineral_id INTEGER REFERENCES minerales(id),
    cantidad NUMERIC(10,2) NOT NULL,
    monto NUMERIC(15,2) NOT NULL,
    precio_por_tonelada NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS almacenamientos (
    id SERIAL PRIMARY KEY,
    yacimiento_id INTEGER REFERENCES yacimientos(id),
    mineral_id INTEGER REFERENCES minerales(id),
    stock NUMERIC(10,2),
    capacidad_maxima NUMERIC(10,2),
    fecha_actualizacion DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS accidentes (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    empleado_id INTEGER REFERENCES empleados(id),
    descripcion TEXT,
    gravedad VARCHAR(50),
    causa VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS auditorias (
    id SERIAL PRIMARY KEY,
    fecha DATE NOT NULL,
    yacimiento_id INTEGER REFERENCES yacimientos(id),
    resultado VARCHAR(50),
    inspector VARCHAR(200),
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sensores (
    id SERIAL PRIMARY KEY,
    fecha_hora TIMESTAMP NOT NULL,
    yacimiento_id INTEGER REFERENCES yacimientos(id),
    tipo_sensor VARCHAR(50),
    valor NUMERIC(8,2),
    unidad VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== ESQUEMAS PARA SUPERMERCADO =====
\c supermercado;

CREATE TABLE IF NOT EXISTS categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS proveedores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    telefono VARCHAR(50),
    contacto VARCHAR(200),
    email VARCHAR(150),
    tipo_proveedor VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS productos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    precio NUMERIC(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    categoria_id INTEGER REFERENCES categorias(id),
    codigo_barras VARCHAR(50),
    proveedor_id INTEGER REFERENCES proveedores(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    direccion TEXT,
    email VARCHAR(150),
    fecha_registro DATE DEFAULT CURRENT_DATE,
    telefono VARCHAR(50),
    tipo_cliente VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sucursales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    ciudad VARCHAR(100),
    direccion TEXT,
    telefono VARCHAR(50),
    gerente_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    puesto VARCHAR(100),
    salario NUMERIC(12,2),
    fecha_ingreso DATE,
    sucursal_id INTEGER REFERENCES sucursales(id),
    estado VARCHAR(50) DEFAULT 'activo',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS compras (
    id SERIAL PRIMARY KEY,
    proveedor_id INTEGER REFERENCES proveedores(id),
    producto_id INTEGER REFERENCES productos(id),
    cantidad INTEGER NOT NULL,
    fecha DATE NOT NULL,
    precio_unitario NUMERIC(10,2),
    total NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ventas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    empleado_id INTEGER REFERENCES empleados(id),
    sucursal_id INTEGER REFERENCES sucursales(id),
    fecha TIMESTAMP NOT NULL,
    total NUMERIC(12,2),
    descuento NUMERIC(5,2) DEFAULT 0,
    metodo_pago VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS detalle_ventas (
    id SERIAL PRIMARY KEY,
    venta_id INTEGER REFERENCES ventas(id),
    producto_id INTEGER REFERENCES productos(id),
    cantidad INTEGER NOT NULL,
    precio_unitario NUMERIC(10,2),
    subtotal NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== ESQUEMAS PARA EMPRESA_AGRONOMIA =====
\c empresa_agronomia;

CREATE TABLE IF NOT EXISTS cultivos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    temporada VARCHAR(50),
    rendimiento_promedio NUMERIC(8,2),
    precio_mercado NUMERIC(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parcelas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    tamaño_ha NUMERIC(8,2) NOT NULL,
    ubicacion TEXT,
    cultivo_id INTEGER REFERENCES cultivos(id),
    estado VARCHAR(50) DEFAULT 'activa',
    fecha_ultima_siembra DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS proveedores (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    telefono VARCHAR(50),
    contacto VARCHAR(200),
    email VARCHAR(150),
    tipo_proveedor VARCHAR(100),
    calificacion INTEGER CHECK (calificacion BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    direccion TEXT,
    email VARCHAR(150),
    fecha_registro DATE DEFAULT CURRENT_DATE,
    telefono VARCHAR(50),
    tipo_cliente VARCHAR(50),
    credito_maximo NUMERIC(15,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sucursales (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    ciudad VARCHAR(100),
    direccion TEXT,
    telefono VARCHAR(50),
    region VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS empleados (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    puesto VARCHAR(100),
    salario NUMERIC(12,2),
    fecha_ingreso DATE,
    sucursal_id INTEGER REFERENCES sucursales(id),
    especialidad VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS compras (
    id SERIAL PRIMARY KEY,
    proveedor_id INTEGER REFERENCES proveedores(id),
    insumo INTEGER NOT NULL, -- Referencia al ID del insumo
    cantidad INTEGER NOT NULL,
    fecha DATE NOT NULL,
    precio_unitario NUMERIC(10,2),
    total NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS ventas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    empleado_id INTEGER REFERENCES empleados(id),
    sucursal_id INTEGER REFERENCES sucursales(id),
    fecha TIMESTAMP NOT NULL,
    total NUMERIC(15,2),
    descuento NUMERIC(5,2) DEFAULT 0,
    tipo_venta VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS detalle_ventas (
    id SERIAL PRIMARY KEY,
    venta_id INTEGER REFERENCES ventas(id),
    producto VARCHAR(200) NOT NULL,
    cantidad NUMERIC(10,2) NOT NULL,
    precio_unitario NUMERIC(10,2),
    subtotal NUMERIC(12,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

\echo '✅ Esquemas faltantes creados exitosamente';