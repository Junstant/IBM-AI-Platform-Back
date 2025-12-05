-- ================================================================
-- SCHEMA: FERRETERIA WEITZLER
-- ================================================================
-- Base de datos de ferretería con productos, inventario y ventas
-- Basado en Weitzler (Puerto Montt, Chile)
-- ================================================================

\echo '🔨 Creando esquema de Ferretería Weitzler...';

-- ===== TABLA: CATEGORIAS =====
CREATE TABLE categorias (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    categoria_padre_id INTEGER REFERENCES categorias(id_categoria),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA: MARCAS =====
CREATE TABLE marcas (
    id_marca SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    pais_origen VARCHAR(50),
    sitio_web VARCHAR(255),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA: PROVEEDORES =====
CREATE TABLE proveedores (
    id_proveedor SERIAL PRIMARY KEY,
    rut VARCHAR(20) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    contacto VARCHAR(100),
    telefono VARCHAR(20),
    email VARCHAR(100),
    direccion TEXT,
    ciudad VARCHAR(100),
    region VARCHAR(100),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA: PRODUCTOS =====
CREATE TABLE productos (
    id_producto SERIAL PRIMARY KEY,
    codigo_sku VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(300) NOT NULL,
    descripcion TEXT,
    id_categoria INTEGER REFERENCES categorias(id_categoria),
    id_marca INTEGER REFERENCES marcas(id_marca),
    id_proveedor INTEGER REFERENCES proveedores(id_proveedor),
    precio_costo DECIMAL(12, 2) NOT NULL,
    precio_venta DECIMAL(12, 2) NOT NULL,
    precio_oferta DECIMAL(12, 2),
    descuento_porcentaje INTEGER DEFAULT 0,
    unidad_medida VARCHAR(20) DEFAULT 'Unidad',
    stock_actual INTEGER DEFAULT 0,
    stock_minimo INTEGER DEFAULT 5,
    stock_maximo INTEGER DEFAULT 100,
    peso_kg DECIMAL(8, 2),
    dimensiones VARCHAR(100),
    en_oferta BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE,
    permite_despacho BOOLEAN DEFAULT TRUE,
    permite_retiro BOOLEAN DEFAULT TRUE,
    imagen_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA: SUCURSALES =====
CREATE TABLE sucursales (
    id_sucursal SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    tipo VARCHAR(50), -- 'Casa Matriz', 'Distribución', 'Constructor', etc.
    direccion VARCHAR(300),
    ciudad VARCHAR(100),
    telefono VARCHAR(100),
    email VARCHAR(100),
    horario_atencion TEXT,
    latitud DECIMAL(10, 8),
    longitud DECIMAL(11, 8),
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA: INVENTARIO POR SUCURSAL =====
CREATE TABLE inventario_sucursal (
    id_inventario SERIAL PRIMARY KEY,
    id_producto INTEGER REFERENCES productos(id_producto),
    id_sucursal INTEGER REFERENCES sucursales(id_sucursal),
    stock_disponible INTEGER DEFAULT 0,
    ultima_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(id_producto, id_sucursal)
);

-- ===== TABLA: CLIENTES =====
CREATE TABLE clientes (
    id_cliente SERIAL PRIMARY KEY,
    rut VARCHAR(20) UNIQUE,
    nombre VARCHAR(200) NOT NULL,
    apellido VARCHAR(200),
    email VARCHAR(100),
    telefono VARCHAR(20),
    direccion TEXT,
    ciudad VARCHAR(100),
    region VARCHAR(100),
    tipo_cliente VARCHAR(50) DEFAULT 'Particular', -- 'Particular', 'Empresa', 'Constructor'
    descuento_especial INTEGER DEFAULT 0,
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE
);

-- ===== TABLA: VENTAS =====
CREATE TABLE ventas (
    id_venta SERIAL PRIMARY KEY,
    numero_boleta VARCHAR(50) UNIQUE NOT NULL,
    id_cliente INTEGER REFERENCES clientes(id_cliente),
    id_sucursal INTEGER REFERENCES sucursales(id_sucursal),
    fecha_venta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12, 2) NOT NULL,
    descuento DECIMAL(12, 2) DEFAULT 0,
    total DECIMAL(12, 2) NOT NULL,
    metodo_pago VARCHAR(50), -- 'Efectivo', 'Tarjeta Débito', 'Tarjeta Crédito', 'Transferencia'
    cuotas INTEGER DEFAULT 1,
    tipo_entrega VARCHAR(50), -- 'Retiro en tienda', 'Despacho a domicilio'
    estado VARCHAR(50) DEFAULT 'Completada', -- 'Completada', 'Pendiente', 'Anulada'
    vendedor VARCHAR(100),
    observaciones TEXT
);

-- ===== TABLA: DETALLE VENTAS =====
CREATE TABLE detalle_ventas (
    id_detalle SERIAL PRIMARY KEY,
    id_venta INTEGER REFERENCES ventas(id_venta) ON DELETE CASCADE,
    id_producto INTEGER REFERENCES productos(id_producto),
    cantidad INTEGER NOT NULL,
    precio_unitario DECIMAL(12, 2) NOT NULL,
    descuento_aplicado DECIMAL(12, 2) DEFAULT 0,
    subtotal DECIMAL(12, 2) NOT NULL
);

-- ===== TABLA: ORDENES DE COMPRA =====
CREATE TABLE ordenes_compra (
    id_orden SERIAL PRIMARY KEY,
    numero_orden VARCHAR(50) UNIQUE NOT NULL,
    id_proveedor INTEGER REFERENCES proveedores(id_proveedor),
    fecha_orden TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_entrega_esperada DATE,
    fecha_entrega_real DATE,
    total DECIMAL(12, 2) NOT NULL,
    estado VARCHAR(50) DEFAULT 'Pendiente', -- 'Pendiente', 'En Tránsito', 'Recibida', 'Cancelada'
    observaciones TEXT
);

-- ===== TABLA: DETALLE ORDENES DE COMPRA =====
CREATE TABLE detalle_ordenes_compra (
    id_detalle SERIAL PRIMARY KEY,
    id_orden INTEGER REFERENCES ordenes_compra(id_orden) ON DELETE CASCADE,
    id_producto INTEGER REFERENCES productos(id_producto),
    cantidad INTEGER NOT NULL,
    precio_unitario DECIMAL(12, 2) NOT NULL,
    subtotal DECIMAL(12, 2) NOT NULL
);

-- ===== ÍNDICES PARA PERFORMANCE =====
CREATE INDEX idx_productos_categoria ON productos(id_categoria);
CREATE INDEX idx_productos_marca ON productos(id_marca);
CREATE INDEX idx_productos_sku ON productos(codigo_sku);
CREATE INDEX idx_productos_oferta ON productos(en_oferta) WHERE en_oferta = TRUE;
CREATE INDEX idx_ventas_fecha ON ventas(fecha_venta);
CREATE INDEX idx_ventas_cliente ON ventas(id_cliente);
CREATE INDEX idx_ventas_sucursal ON ventas(id_sucursal);
CREATE INDEX idx_detalle_ventas_producto ON detalle_ventas(id_producto);
CREATE INDEX idx_inventario_producto ON inventario_sucursal(id_producto);
CREATE INDEX idx_inventario_sucursal ON inventario_sucursal(id_sucursal);

-- ===== VISTAS ÚTILES =====

-- Vista de productos con stock bajo
CREATE VIEW productos_stock_bajo AS
SELECT 
    p.id_producto,
    p.codigo_sku,
    p.nombre,
    p.stock_actual,
    p.stock_minimo,
    c.nombre as categoria,
    m.nombre as marca,
    prov.nombre as proveedor
FROM productos p
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN marcas m ON p.id_marca = m.id_marca
LEFT JOIN proveedores prov ON p.id_proveedor = prov.id_proveedor
WHERE p.stock_actual <= p.stock_minimo
AND p.activo = TRUE;

-- Vista de productos en oferta
CREATE VIEW productos_ofertas AS
SELECT 
    p.id_producto,
    p.codigo_sku,
    p.nombre,
    p.precio_venta,
    p.precio_oferta,
    p.descuento_porcentaje,
    ROUND((p.precio_venta - p.precio_oferta) / p.precio_venta * 100) as descuento_real,
    c.nombre as categoria,
    m.nombre as marca
FROM productos p
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN marcas m ON p.id_marca = m.id_marca
WHERE p.en_oferta = TRUE
AND p.activo = TRUE
ORDER BY descuento_porcentaje DESC;

-- Vista de ventas diarias
CREATE VIEW ventas_diarias AS
SELECT 
    DATE(fecha_venta) as fecha,
    id_sucursal,
    COUNT(*) as total_ventas,
    SUM(total) as monto_total,
    AVG(total) as ticket_promedio
FROM ventas
WHERE estado = 'Completada'
GROUP BY DATE(fecha_venta), id_sucursal
ORDER BY fecha DESC;

-- Vista de productos más vendidos
CREATE VIEW productos_mas_vendidos AS
SELECT 
    p.id_producto,
    p.codigo_sku,
    p.nombre,
    c.nombre as categoria,
    m.nombre as marca,
    SUM(dv.cantidad) as unidades_vendidas,
    SUM(dv.subtotal) as ingresos_totales,
    COUNT(DISTINCT dv.id_venta) as numero_ventas
FROM detalle_ventas dv
JOIN productos p ON dv.id_producto = p.id_producto
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN marcas m ON p.id_marca = m.id_marca
JOIN ventas v ON dv.id_venta = v.id_venta
WHERE v.estado = 'Completada'
GROUP BY p.id_producto, p.codigo_sku, p.nombre, c.nombre, m.nombre
ORDER BY unidades_vendidas DESC;

\echo '✅ Esquema de Ferretería Weitzler creado exitosamente';
