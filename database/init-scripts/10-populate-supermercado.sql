-- 10-populate-supermercado.sql
-- Población de datos para supermercado

\echo '🛒 Poblando base de datos supermercado...'

\c supermercado;

-- ===== CATEGORÍAS (10) =====
INSERT INTO categorias (nombre, descripcion) VALUES
('Carnes y Pescados', 'Productos cárnicos y mariscos frescos'),
('Lácteos y Huevos', 'Leche, quesos, yogures y huevos'),
('Frutas y Verduras', 'Productos frescos del campo'),
('Panadería', 'Pan fresco y productos de panadería'),
('Bebidas', 'Gaseosas, jugos, agua y bebidas alcohólicas'),
('Limpieza', 'Productos de limpieza y cuidado del hogar'),
('Higiene Personal', 'Productos de cuidado personal y cosmética'),
('Congelados', 'Alimentos congelados y helados'),
('Despensa', 'Productos enlatados, granos y condimentos'),
('Electrónicos', 'Pequeños electrodomésticos y electrónicos');

-- ===== PRODUCTOS (20,000) =====
\echo 'Generando 20,000 productos...'
INSERT INTO productos (nombre, precio, stock, categoria_id, codigo_barras, proveedor_id)
SELECT 
    CASE (i % 10)
        WHEN 0 THEN 'Producto Carne ' || i
        WHEN 1 THEN 'Producto Lácteo ' || i
        WHEN 2 THEN 'Producto Fruta ' || i
        WHEN 3 THEN 'Producto Pan ' || i
        WHEN 4 THEN 'Producto Bebida ' || i
        WHEN 5 THEN 'Producto Limpieza ' || i
        WHEN 6 THEN 'Producto Higiene ' || i
        WHEN 7 THEN 'Producto Congelado ' || i
        WHEN 8 THEN 'Producto Despensa ' || i
        ELSE 'Producto Electrónico ' || i
    END,
    CASE 
        WHEN (i % 100) < 5 THEN (5000 + random() * 45000)::numeric(10,2) -- 5% productos caros
        WHEN (i % 100) < 20 THEN (500 + random() * 4500)::numeric(10,2) -- 15% productos medios
        ELSE (10 + random() * 490)::numeric(10,2) -- 80% productos baratos
    END,
    (random() * 1000)::int, -- Stock aleatorio
    ((i % 10) + 1), -- Categorías
    '78' || LPAD(i::text, 11, '0'), -- Código de barras único
    ((i % 500) + 1) -- Proveedores
FROM generate_series(1, 20000) i;

-- ===== PROVEEDORES (500) =====
\echo 'Generando 500 proveedores...'
INSERT INTO proveedores (nombre, telefono, contacto, email, tipo_proveedor)
SELECT 
    'Proveedor ' || i || ' S.A.',
    '+54-11-' || LPAD((random() * 99999999)::int::text, 8, '0'),
    'Contacto ' || i,
    'proveedor' || i || '@empresa.com',
    CASE (i % 10)
        WHEN 0 THEN 'carnes'
        WHEN 1 THEN 'lácteos'
        WHEN 2 THEN 'frutas'
        WHEN 3 THEN 'panadería'
        WHEN 4 THEN 'bebidas'
        WHEN 5 THEN 'limpieza'
        WHEN 6 THEN 'higiene'
        WHEN 7 THEN 'congelados'
        WHEN 8 THEN 'despensa'
        ELSE 'electrónicos'
    END
FROM generate_series(1, 500) i;

-- ===== CLIENTES (200,000) =====
\echo 'Generando 200,000 clientes...'
INSERT INTO clientes (nombre, direccion, email, fecha_registro, telefono, tipo_cliente)
SELECT 
    CASE (i % 20)
        WHEN 0 THEN 'Juan'
        WHEN 1 THEN 'María'
        WHEN 2 THEN 'Carlos'
        WHEN 3 THEN 'Ana'
        WHEN 4 THEN 'Luis'
        WHEN 5 THEN 'Laura'
        WHEN 6 THEN 'Miguel'
        WHEN 7 THEN 'Carmen'
        WHEN 8 THEN 'José'
        WHEN 9 THEN 'Isabel'
        WHEN 10 THEN 'Francisco'
        WHEN 11 THEN 'Patricia'
        WHEN 12 THEN 'Antonio'
        WHEN 13 THEN 'Elena'
        WHEN 14 THEN 'Manuel'
        WHEN 15 THEN 'Rosa'
        WHEN 16 THEN 'David'
        WHEN 17 THEN 'Pilar'
        WHEN 18 THEN 'Pedro'
        ELSE 'Marta'
    END || ' ' ||
    CASE (i % 15)
        WHEN 0 THEN 'García'
        WHEN 1 THEN 'Rodríguez'
        WHEN 2 THEN 'González'
        WHEN 3 THEN 'Fernández'
        WHEN 4 THEN 'López'
        WHEN 5 THEN 'Martínez'
        WHEN 6 THEN 'Sánchez'
        WHEN 7 THEN 'Pérez'
        WHEN 8 THEN 'Gómez'
        WHEN 9 THEN 'Martín'
        WHEN 10 THEN 'Jiménez'
        WHEN 11 THEN 'Ruiz'
        WHEN 12 THEN 'Hernández'
        WHEN 13 THEN 'Díaz'
        ELSE 'Moreno'
    END,
    'Calle ' || (i % 1000) || ' #' || (i % 9999) || ', Ciudad',
    'cliente' || i || '@email.com',
    CURRENT_DATE - (random() * 1825)::int, -- Fechas últimos 5 años
    '+54-11-' || LPAD((random() * 99999999)::int::text, 8, '0'),
    CASE (i % 5)
        WHEN 0 THEN 'premium'
        WHEN 1 THEN 'frecuente'
        WHEN 2 THEN 'ocasional'
        WHEN 3 THEN 'mayorista'
        ELSE 'regular'
    END
FROM generate_series(1, 200000) i;

-- ===== EMPLEADOS (1,000) =====
\echo 'Generando 1,000 empleados...'
INSERT INTO empleados (nombre, puesto, salario, fecha_ingreso, sucursal_id, estado)
SELECT 
    'Empleado ' || i || ' ' || 
    CASE (i % 10)
        WHEN 0 THEN 'García'
        WHEN 1 THEN 'Rodríguez'
        WHEN 2 THEN 'González'
        WHEN 3 THEN 'Fernández'
        WHEN 4 THEN 'López'
        WHEN 5 THEN 'Martínez'
        WHEN 6 THEN 'Sánchez'
        WHEN 7 THEN 'Pérez'
        WHEN 8 THEN 'Gómez'
        ELSE 'Martín'
    END,
    CASE (i % 6)
        WHEN 0 THEN 'Cajero'
        WHEN 1 THEN 'Repositor'
        WHEN 2 THEN 'Supervisor'
        WHEN 3 THEN 'Gerente'
        WHEN 4 THEN 'Limpieza'
        ELSE 'Seguridad'
    END,
    20000 + (random() * 50000)::int, -- Salarios entre 20k y 70k
    CURRENT_DATE - (random() * 2555)::int, -- Fechas últimos 7 años
    ((i % 100) + 1), -- Sucursales
    CASE (i % 20)
        WHEN 19 THEN 'inactivo'
        ELSE 'activo'
    END
FROM generate_series(1, 1000) i;

-- ===== SUCURSALES (100) =====
\echo 'Generando 100 sucursales...'
INSERT INTO sucursales (nombre, ciudad, direccion, telefono, gerente_id)
SELECT 
    'Sucursal ' || LPAD(i::text, 3, '0'),
    CASE (i % 25)
        WHEN 0 THEN 'Buenos Aires'
        WHEN 1 THEN 'Córdoba'
        WHEN 2 THEN 'Rosario'
        WHEN 3 THEN 'Mendoza'
        WHEN 4 THEN 'La Plata'
        WHEN 5 THEN 'San Miguel de Tucumán'
        WHEN 6 THEN 'Mar del Plata'
        WHEN 7 THEN 'Salta'
        WHEN 8 THEN 'Santa Fe'
        WHEN 9 THEN 'San Juan'
        WHEN 10 THEN 'Resistencia'
        WHEN 11 THEN 'Neuquén'
        WHEN 12 THEN 'Santiago del Estero'
        WHEN 13 THEN 'Corrientes'
        WHEN 14 THEN 'Posadas'
        WHEN 15 THEN 'Bahía Blanca'
        WHEN 16 THEN 'Paraná'
        WHEN 17 THEN 'Formosa'
        WHEN 18 THEN 'San Luis'
        WHEN 19 THEN 'Catamarca'
        WHEN 20 THEN 'La Rioja'
        WHEN 21 THEN 'Río Gallegos'
        WHEN 22 THEN 'Ushuaia'
        WHEN 23 THEN 'Rawson'
        ELSE 'Viedma'
    END,
    'Av. Principal ' || (i * 100) || ', Local ' || i,
    '+54-11-555-' || LPAD(i::text, 4, '0'),
    CASE 
        WHEN i <= 1000 THEN i -- Asignar gerentes existentes
        ELSE NULL
    END
FROM generate_series(1, 100) i;

-- ===== COMPRAS (100,000) =====
\echo 'Generando 100,000 compras...'
INSERT INTO compras (proveedor_id, producto_id, cantidad, fecha, precio_unitario, total)
SELECT 
    ((i % 500) + 1), -- Proveedores
    ((i % 20000) + 1), -- Productos
    (1 + random() * 1000)::int, -- Cantidad
    CURRENT_DATE - (random() * 365)::int, -- Fechas último año
    CASE 
        WHEN (i % 100) < 5 THEN (5000 + random() * 45000)::numeric(10,2)
        WHEN (i % 100) < 20 THEN (500 + random() * 4500)::numeric(10,2)
        ELSE (10 + random() * 490)::numeric(10,2)
    END,
    ((1 + random() * 1000)::int) * (CASE 
        WHEN (i % 100) < 5 THEN (5000 + random() * 45000)::numeric(10,2)
        WHEN (i % 100) < 20 THEN (500 + random() * 4500)::numeric(10,2)
        ELSE (10 + random() * 490)::numeric(10,2)
    END)
FROM generate_series(1, 100000) i;

-- ===== VENTAS (300,000) =====
\echo 'Generando 300,000 ventas...'
INSERT INTO ventas (cliente_id, empleado_id, sucursal_id, fecha, total, descuento, metodo_pago)
SELECT 
    ((i % 200000) + 1), -- Clientes
    ((i % 1000) + 1), -- Empleados
    ((i % 100) + 1), -- Sucursales
    CURRENT_DATE - (random() * 365)::int - (random() * interval '24 hours'), -- Fechas último año
    CASE 
        WHEN (i % 100) < 10 THEN (5000 + random() * 45000)::numeric(12,2) -- 10% ventas altas
        WHEN (i % 100) < 30 THEN (500 + random() * 4500)::numeric(12,2) -- 20% ventas medias
        ELSE (50 + random() * 450)::numeric(12,2) -- 70% ventas normales
    END,
    CASE 
        WHEN (i % 10) < 2 THEN (random() * 20)::numeric(5,2) -- 20% con descuento
        ELSE 0
    END,
    CASE (i % 5)
        WHEN 0 THEN 'efectivo'
        WHEN 1 THEN 'tarjeta_debito'
        WHEN 2 THEN 'tarjeta_credito'
        WHEN 3 THEN 'transferencia'
        ELSE 'cheque'
    END
FROM generate_series(1, 300000) i;

-- ===== DETALLE VENTAS (300,000) =====
\echo 'Generando 300,000 detalles de ventas...'
INSERT INTO detalle_ventas (venta_id, producto_id, cantidad, precio_unitario, subtotal)
SELECT 
    i, -- Venta ID (1:1 para simplificar)
    ((i % 20000) + 1), -- Productos
    (1 + random() * 10)::int, -- Cantidad
    CASE 
        WHEN (i % 100) < 5 THEN (5000 + random() * 45000)::numeric(10,2)
        WHEN (i % 100) < 20 THEN (500 + random() * 4500)::numeric(10,2)
        ELSE (10 + random() * 490)::numeric(10,2)
    END,
    ((1 + random() * 10)::int) * (CASE 
        WHEN (i % 100) < 5 THEN (5000 + random() * 45000)::numeric(10,2)
        WHEN (i % 100) < 20 THEN (500 + random() * 4500)::numeric(10,2)
        ELSE (10 + random() * 490)::numeric(10,2)
    END)
FROM generate_series(1, 300000) i;

-- Crear índices para optimizar consultas requeridas
CREATE INDEX IF NOT EXISTS idx_ventas_sucursal_total ON ventas(sucursal_id, total DESC);
CREATE INDEX IF NOT EXISTS idx_ventas_fecha_dow ON ventas(fecha, EXTRACT(DOW FROM fecha));
CREATE INDEX IF NOT EXISTS idx_productos_categoria_stock ON productos(categoria_id, stock, precio);

-- Vista materializada para ventas por sucursal
CREATE MATERIALIZED VIEW IF NOT EXISTS ventas_por_sucursal AS
SELECT 
    s.id as sucursal_id,
    s.nombre as sucursal_nombre,
    s.ciudad,
    SUM(v.total) as total_ventas,
    COUNT(v.id) as cantidad_ventas,
    AVG(v.total) as promedio_venta
FROM sucursales s
LEFT JOIN ventas v ON s.id = v.sucursal_id
GROUP BY s.id, s.nombre, s.ciudad
ORDER BY total_ventas DESC;

-- Vista materializada para análisis por día de semana
CREATE MATERIALIZED VIEW IF NOT EXISTS ventas_por_dia_semana AS
SELECT 
    EXTRACT(DOW FROM fecha) as dia_semana,
    CASE EXTRACT(DOW FROM fecha)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        ELSE 'Sábado'
    END as nombre_dia,
    COUNT(*) as cantidad_ventas,
    SUM(total) as total_ventas,
    AVG(total) as promedio_ventas
FROM ventas
GROUP BY EXTRACT(DOW FROM fecha)
ORDER BY cantidad_ventas DESC;

-- Vista materializada para valor de inventario por categoría
CREATE MATERIALIZED VIEW IF NOT EXISTS inventario_por_categoria AS
SELECT 
    c.id as categoria_id,
    c.nombre as categoria_nombre,
    COUNT(p.id) as cantidad_productos,
    SUM(p.stock) as stock_total,
    SUM(p.stock * p.precio) as valor_inventario,
    AVG(p.precio) as precio_promedio
FROM categorias c
LEFT JOIN productos p ON c.id = p.categoria_id
GROUP BY c.id, c.nombre
ORDER BY valor_inventario DESC;

\echo '✅ Base de datos supermercado poblada exitosamente';
\echo 'Total de registros: ~945,610';
\echo 'Vistas materializadas creadas para análisis';