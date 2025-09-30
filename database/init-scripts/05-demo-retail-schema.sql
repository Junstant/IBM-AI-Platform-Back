-- 05-demo-retail-schema.sql
-- Esquema para base de datos de pruebas adicional

\echo '🛍️ Configurando esquema para demo_retail...'

\c demo_retail;

-- ===== TABLA CATEGORÍAS =====
CREATE TABLE IF NOT EXISTS categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    activa BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA PRODUCTOS =====
CREATE TABLE IF NOT EXISTS productos (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,
    categoria_id INTEGER REFERENCES categorias(id),
    precio DECIMAL(10,2) NOT NULL,
    stock INTEGER DEFAULT 0,
    stock_minimo INTEGER DEFAULT 5,
    activo BOOLEAN DEFAULT TRUE,
    fecha_creacion DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA CLIENTES =====
CREATE TABLE IF NOT EXISTS clientes_retail (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE,
    telefono VARCHAR(20),
    fecha_nacimiento DATE,
    ciudad VARCHAR(100),
    fecha_registro DATE DEFAULT CURRENT_DATE,
    activo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA VENTAS =====
CREATE TABLE IF NOT EXISTS ventas (
    id SERIAL PRIMARY KEY,
    numero_venta VARCHAR(20) UNIQUE NOT NULL,
    cliente_id INTEGER REFERENCES clientes_retail(id),
    fecha_venta DATE DEFAULT CURRENT_DATE,
    subtotal DECIMAL(12,2) NOT NULL,
    impuestos DECIMAL(12,2) DEFAULT 0.00,
    descuentos DECIMAL(12,2) DEFAULT 0.00,
    total DECIMAL(12,2) NOT NULL,
    metodo_pago VARCHAR(50),
    estado VARCHAR(20) DEFAULT 'completada',
    vendedor VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ===== TABLA DETALLE VENTAS =====
CREATE TABLE IF NOT EXISTS detalle_ventas (
    id SERIAL PRIMARY KEY,
    venta_id INTEGER REFERENCES ventas(id) ON DELETE CASCADE,
    producto_id INTEGER REFERENCES productos(id),
    cantidad INTEGER NOT NULL,
    precio_unitario DECIMAL(10,2) NOT NULL,
    subtotal DECIMAL(12,2) NOT NULL,
    descuento DECIMAL(10,2) DEFAULT 0.00
);

-- Insertar datos de ejemplo
INSERT INTO categorias (nombre, descripcion) VALUES
('Electrónicos', 'Dispositivos electrónicos y gadgets'),
('Ropa', 'Vestimenta y accesorios'),
('Hogar', 'Artículos para el hogar'),
('Deportes', 'Equipamiento deportivo'),
('Libros', 'Libros y material educativo');

INSERT INTO productos (codigo, nombre, categoria_id, precio, stock) VALUES
('ELEC001', 'Smartphone Samsung Galaxy', 1, 89999.00, 25),
('ELEC002', 'Laptop Dell Inspiron', 1, 149999.00, 15),
('ROPA001', 'Camisa Casual Hombre', 2, 4500.00, 50),
('HOGAR001', 'Cafetera Automática', 3, 12999.00, 20),
('DEP001', 'Pelota Fútbol Nike', 4, 2500.00, 30);

INSERT INTO clientes_retail (nombre, apellido, email, telefono, ciudad) VALUES
('Pedro', 'Gómez', 'pedro.gomez@email.com', '+54-11-1111-2222', 'Buenos Aires'),
('Lucía', 'Torres', 'lucia.torres@email.com', '+54-11-3333-4444', 'Córdoba'),
('Diego', 'Morales', 'diego.morales@email.com', '+54-11-5555-6666', 'Rosario');

-- Índices
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_ventas_fecha ON ventas(fecha_venta);
CREATE INDEX idx_ventas_cliente ON ventas(cliente_id);

\echo '✅ Esquema demo_retail configurado exitosamente';