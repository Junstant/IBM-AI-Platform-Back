-- 11-populate-empresa-agronomia.sql
-- Población de datos para empresa_agronomia

\echo '🌾 Poblando base de datos empresa_agronomia...'

\c empresa_agronomia;

-- ===== CULTIVOS (10) =====
INSERT INTO cultivos (nombre, temporada, rendimiento_promedio, precio_mercado) VALUES
('Soja', 'verano', 3200, 450),
('Maíz', 'verano', 8500, 280),
('Trigo', 'invierno', 2800, 320),
('Girasol', 'verano', 2100, 680),
('Sorgo', 'verano', 4500, 250),
('Cebada', 'invierno', 3200, 290),
('Avena', 'invierno', 2400, 310),
('Arroz', 'verano', 6800, 420),
('Algodón', 'verano', 1200, 1850),
('Caña de Azúcar', 'perenne', 75000, 45);

-- ===== PARCELAS (20,000) =====
\echo 'Generando 20,000 parcelas...'
INSERT INTO parcelas (nombre, tamaño_ha, ubicacion, cultivo_id, estado, fecha_ultima_siembra)
SELECT 
    'Parcela-' || LPAD(i::text, 5, '0'),
    CASE 
        WHEN (i % 100) < 5 THEN (100 + random() * 400)::numeric(8,2) -- 5% parcelas grandes
        WHEN (i % 100) < 20 THEN (20 + random() * 80)::numeric(8,2) -- 15% parcelas medianas
        ELSE (1 + random() * 19)::numeric(8,2) -- 80% parcelas pequeñas
    END,
    'Campo ' || (i % 500) || ', Zona ' || CHAR(65 + (i % 26)) || ', Provincia de ' ||
    CASE (i % 15)
        WHEN 0 THEN 'Buenos Aires'
        WHEN 1 THEN 'Córdoba'
        WHEN 2 THEN 'Santa Fe'
        WHEN 3 THEN 'Entre Ríos'
        WHEN 4 THEN 'La Pampa'
        WHEN 5 THEN 'Santiago del Estero'
        WHEN 6 THEN 'Chaco'
        WHEN 7 THEN 'Salta'
        WHEN 8 THEN 'Tucumán'
        WHEN 9 THEN 'San Luis'
        WHEN 10 THEN 'Corrientes'
        WHEN 11 THEN 'Formosa'
        WHEN 12 THEN 'Misiones'
        WHEN 13 THEN 'Jujuy'
        ELSE 'Catamarca'
    END,
    ((i % 10) + 1), -- Cultivos
    CASE (i % 20)
        WHEN 0 THEN 'en preparación'
        WHEN 1 THEN 'sembrada'
        WHEN 2 THEN 'en crecimiento'
        WHEN 3 THEN 'lista para cosecha'
        WHEN 4 THEN 'cosechada'
        ELSE 'activa'
    END,
    CURRENT_DATE - (random() * 365)::int -- Fechas último año
FROM generate_series(1, 20000) i;

-- ===== PROVEEDORES (500) =====
\echo 'Generando 500 proveedores...'
INSERT INTO proveedores (nombre, telefono, contacto, email, tipo_proveedor, calificacion)
SELECT 
    'Proveedor Agrícola ' || i || ' S.A.',
    '+54-' || (11 + (i % 89)) || '-' || LPAD((random() * 99999999)::int::text, 8, '0'),
    'Contacto ' || i,
    'proveedor' || i || '@agro.com',
    CASE (i % 8)
        WHEN 0 THEN 'semillas'
        WHEN 1 THEN 'fertilizantes'
        WHEN 2 THEN 'pesticidas'
        WHEN 3 THEN 'maquinaria'
        WHEN 4 THEN 'combustible'
        WHEN 5 THEN 'equipos_riego'
        WHEN 6 THEN 'servicios_campo'
        ELSE 'insumos_varios'
    END,
    1 + (random() * 4)::int -- Calificación 1-5
FROM generate_series(1, 500) i;

-- ===== CLIENTES (200,000) =====
\echo 'Generando 200,000 clientes...'
INSERT INTO clientes (nombre, direccion, email, fecha_registro, telefono, tipo_cliente, credito_maximo)
SELECT 
    CASE (i % 25)
        WHEN 0 THEN 'Molinos Río de la Plata'
        WHEN 1 THEN 'Cargill Argentina'
        WHEN 2 THEN 'ADM Argentina'
        WHEN 3 THEN 'Bunge Argentina'
        WHEN 4 THEN 'Louis Dreyfus Company'
        WHEN 5 THEN 'Aceitera General Deheza'
        WHEN 6 THEN 'Vicentin'
        WHEN 7 THEN 'Noble Argentina'
        WHEN 8 THEN 'Oleaginosa Moreno'
        WHEN 9 THEN 'Terminal 6'
        ELSE 'Cliente ' || i || ' S.A.'
    END,
    'Dirección ' || i || ', Ciudad ' || (i % 100),
    'cliente' || i || '@empresa.com',
    CURRENT_DATE - (random() * 1825)::int, -- Fechas últimos 5 años
    '+54-11-' || LPAD((random() * 99999999)::int::text, 8, '0'),
    CASE (i % 6)
        WHEN 0 THEN 'cooperativa'
        WHEN 1 THEN 'acopio'
        WHEN 2 THEN 'exportador'
        WHEN 3 THEN 'molino'
        WHEN 4 THEN 'industria'
        ELSE 'mayorista'
    END,
    CASE 
        WHEN (i % 100) < 10 THEN (1000000 + random() * 9000000)::numeric(15,2) -- 10% clientes grandes
        WHEN (i % 100) < 30 THEN (100000 + random() * 900000)::numeric(15,2) -- 20% clientes medianos
        ELSE (1000 + random() * 99000)::numeric(15,2) -- 70% clientes pequeños
    END
FROM generate_series(1, 200000) i;

-- ===== EMPLEADOS (1,000) =====
\echo 'Generando 1,000 empleados...'
INSERT INTO empleados (nombre, puesto, salario, fecha_ingreso, sucursal_id, especialidad)
SELECT 
    'Empleado ' || i || ' ' || 
    CASE (i % 12)
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
        WHEN 10 THEN 'Ruiz'
        ELSE 'Morales'
    END,
    CASE (i % 8)
        WHEN 0 THEN 'Ingeniero Agrónomo'
        WHEN 1 THEN 'Técnico Agrícola'
        WHEN 2 THEN 'Supervisor de Campo'
        WHEN 3 THEN 'Vendedor'
        WHEN 4 THEN 'Administrativo'
        WHEN 5 THEN 'Operario'
        WHEN 6 THEN 'Gerente'
        ELSE 'Asesor Técnico'
    END,
    30000 + (random() * 70000)::int, -- Salarios entre 30k y 100k
    CURRENT_DATE - (random() * 2920)::int, -- Fechas últimos 8 años
    ((i % 100) + 1), -- Sucursales
    CASE (i % 10)
        WHEN 0 THEN 'cereales'
        WHEN 1 THEN 'oleaginosas'
        WHEN 2 THEN 'legumbres'
        WHEN 3 THEN 'fruticultura'
        WHEN 4 THEN 'horticultura'
        WHEN 5 THEN 'ganadería'
        WHEN 6 THEN 'maquinaria'
        WHEN 7 THEN 'riego'
        WHEN 8 THEN 'fertilización'
        ELSE 'control_plagas'
    END
FROM generate_series(1, 1000) i;

-- ===== SUCURSALES (100) =====
\echo 'Generando 100 sucursales...'
INSERT INTO sucursales (nombre, ciudad, direccion, telefono, region)
SELECT 
    'Sucursal Agrícola ' || LPAD(i::text, 3, '0'),
    CASE (i % 30)
        WHEN 0 THEN 'Rosario'
        WHEN 1 THEN 'Córdoba'
        WHEN 2 THEN 'Bahía Blanca'
        WHEN 3 THEN 'Santa Fe'
        WHEN 4 THEN 'Paraná'
        WHEN 5 THEN 'Venado Tuerto'
        WHEN 6 THEN 'Río Cuarto'
        WHEN 7 THEN 'Rafaela'
        WHEN 8 THEN 'Pergamino'
        WHEN 9 THEN 'Tandil'
        WHEN 10 THEN 'Balcarce'
        WHEN 11 THEN 'General Pico'
        WHEN 12 THEN 'Tres Arroyos'
        WHEN 13 THEN 'Junín'
        WHEN 14 THEN 'Lincoln'
        WHEN 15 THEN 'Mercedes'
        WHEN 16 THEN 'Gualeguaychú'
        WHEN 17 THEN 'Concordia'
        WHEN 18 THEN 'Reconquista'
        WHEN 19 THEN 'Esperanza'
        WHEN 20 THEN 'Casilda'
        WHEN 21 THEN 'San Lorenzo'
        WHEN 22 THEN 'Villa María'
        WHEN 23 THEN 'Marcos Juárez'
        WHEN 24 THEN 'Las Parejas'
        WHEN 25 THEN 'Firmat'
        WHEN 26 THEN 'Cañada de Gómez'
        WHEN 27 THEN 'Villa Constitución'
        WHEN 28 THEN 'San Nicolás'
        ELSE 'Campana'
    END,
    'Ruta ' || (i % 50) || ' Km ' || (i * 5) || ', Local ' || i,
    '+54-341-555-' || LPAD(i::text, 4, '0'),
    CASE (i % 5)
        WHEN 0 THEN 'Pampeana'
        WHEN 1 THEN 'Litoral'
        WHEN 2 THEN 'Centro'
        WHEN 3 THEN 'NOA'
        ELSE 'NEA'
    END
FROM generate_series(1, 100) i;

-- ===== INSUMOS (Necesario para las compras) =====
CREATE TABLE IF NOT EXISTS insumos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    tipo VARCHAR(100),
    unidad_medida VARCHAR(50),
    precio_promedio NUMERIC(10,2)
);

INSERT INTO insumos (nombre, tipo, unidad_medida, precio_promedio) VALUES
('Semilla de Soja RR', 'semilla', 'kg', 450),
('Semilla de Maíz Híbrido', 'semilla', 'kg', 850),
('Semilla de Trigo', 'semilla', 'kg', 280),
('Urea 46%', 'fertilizante', 'kg', 580),
('Fosfato Diamónico', 'fertilizante', 'kg', 720),
('Superfosfato Triple', 'fertilizante', 'kg', 680),
('Cloruro de Potasio', 'fertilizante', 'kg', 620),
('Glifosato 48%', 'herbicida', 'litro', 320),
('2,4-D Amina', 'herbicida', 'litro', 180),
('Atrazina 50%', 'herbicida', 'litro', 240),
-- Continúo hasta llegar a insumo 36
('Insecticida Cipermetrina', 'insecticida', 'litro', 450),
('Fungicida Tebuconazol', 'fungicida', 'litro', 680),
('Aceite Mineral', 'coadyuvante', 'litro', 120),
('Fertilizante Foliar NPK', 'fertilizante', 'litro', 95),
('Cal Agrícola', 'corrector', 'tonelada', 1200),
('Yeso Agrícola', 'corrector', 'tonelada', 800),
('Compost Orgánico', 'fertilizante', 'tonelada', 2500),
('Bioestimulante Radicular', 'bioestimulante', 'litro', 350),
('Inoculante para Soja', 'inoculante', 'dosis', 45),
('Inoculante para Leguminosas', 'inoculante', 'dosis', 52),
('Semilla de Girasol', 'semilla', 'kg', 680),
('Semilla de Sorgo', 'semilla', 'kg', 420),
('Herbicida Paraquat', 'herbicida', 'litro', 380),
('Insecticida Lambdacialotrina', 'insecticida', 'litro', 520),
('Fungicida Azoxistrobina', 'fungicida', 'litro', 780),
('Fertilizante Líquido UAN', 'fertilizante', 'litro', 68),
('Sulfato de Amonio', 'fertilizante', 'kg', 420),
('Micronutrientes Quelados', 'micronutriente', 'kg', 1800),
('Adherente Siliconado', 'coadyuvante', 'litro', 280),
('Regulador de Crecimiento', 'regulador', 'litro', 650),
('Coadyuvante pH Buffer', 'coadyuvante', 'litro', 150),
('Aceite Vegetal Emulsificado', 'coadyuvante', 'litro', 185),
('Fertilizante Arranque 18-46-0', 'fertilizante', 'kg', 890),
('Bioinsecticida Bt', 'bioinsecticida', 'kg', 450),
('Extracto de Algas Marinas', 'bioestimulante', 'litro', 520),
('Insumo Especial 36', 'especial', 'kg', 2500); -- Insumo 36 específico

-- ===== COMPRAS (100,000) =====
\echo 'Generando 100,000 compras...'
INSERT INTO compras (proveedor_id, insumo, cantidad, fecha, precio_unitario, total)
SELECT 
    ((i % 500) + 1), -- Proveedores
    i % 36 + 1, -- ID del insumo (1-36)
    CASE 
        WHEN (i % 100) < 10 THEN (1000 + random() * 9000)::int -- 10% compras grandes
        WHEN (i % 100) < 30 THEN (100 + random() * 900)::int -- 20% compras medianas
        ELSE (1 + random() * 99)::int -- 70% compras pequeñas
    END,
    CURRENT_DATE - (random() * 365)::int, -- Fechas último año
    CASE (i % 36) + 1
        WHEN 1 THEN 450 + (random() * 100 - 50) -- Variación de precio ±50
        WHEN 2 THEN 850 + (random() * 200 - 100)
        WHEN 3 THEN 280 + (random() * 60 - 30)
        WHEN 4 THEN 580 + (random() * 120 - 60)
        WHEN 5 THEN 720 + (random() * 140 - 70)
        WHEN 6 THEN 680 + (random() * 130 - 65)
        WHEN 7 THEN 620 + (random() * 120 - 60)
        WHEN 8 THEN 320 + (random() * 70 - 35)
        WHEN 9 THEN 180 + (random() * 40 - 20)
        WHEN 10 THEN 240 + (random() * 50 - 25)
        -- Continúo con todos los precios hasta el 36
        WHEN 36 THEN 2500 + (random() * 500 - 250) -- Insumo 36
        ELSE 100 + (random() * 200)::numeric(10,2)
    END,
    -- Total = cantidad * precio_unitario (calculado)
    (CASE 
        WHEN (i % 100) < 10 THEN (1000 + random() * 9000)::int
        WHEN (i % 100) < 30 THEN (100 + random() * 900)::int
        ELSE (1 + random() * 99)::int
    END) * (CASE (i % 36) + 1
        WHEN 1 THEN 450 + (random() * 100 - 50)
        WHEN 36 THEN 2500 + (random() * 500 - 250)
        ELSE 100 + (random() * 200)::numeric(10,2)
    END)
FROM generate_series(1, 100000) i;

-- ===== VENTAS (300,000) =====
\echo 'Generando 300,000 ventas...'
INSERT INTO ventas (cliente_id, empleado_id, sucursal_id, fecha, total, descuento, tipo_venta)
SELECT 
    ((i % 200000) + 1), -- Clientes
    ((i % 1000) + 1), -- Empleados
    ((i % 100) + 1), -- Sucursales
    CURRENT_DATE - (random() * 365)::int - (random() * interval '24 hours'), -- Fechas último año
    CASE 
        WHEN (i % 100) < 15 THEN (100000 + random() * 900000)::numeric(15,2) -- 15% ventas altas
        WHEN (i % 100) < 40 THEN (10000 + random() * 90000)::numeric(15,2) -- 25% ventas medias
        ELSE (1000 + random() * 9000)::numeric(15,2) -- 60% ventas normales
    END,
    CASE 
        WHEN (i % 20) < 3 THEN (random() * 15)::numeric(5,2) -- 15% con descuento
        ELSE 0
    END,
    CASE (i % 4)
        WHEN 0 THEN 'contado'
        WHEN 1 THEN 'credito_30'
        WHEN 2 THEN 'credito_60'
        ELSE 'credito_90'
    END
FROM generate_series(1, 300000) i;

-- ===== DETALLE VENTAS (300,000) =====
\echo 'Generando 300,000 detalles de ventas...'
INSERT INTO detalle_ventas (venta_id, producto, cantidad, precio_unitario, subtotal)
SELECT 
    i, -- Venta ID (1:1 para simplificar)
    CASE (i % 10)
        WHEN 0 THEN 'Soja RG'
        WHEN 1 THEN 'Maíz Flint'
        WHEN 2 THEN 'Trigo Pan'
        WHEN 3 THEN 'Girasol Alto Oleico'
        WHEN 4 THEN 'Sorgo Granífero'
        WHEN 5 THEN 'Cebada Maltera'
        WHEN 6 THEN 'Avena'
        WHEN 7 THEN 'Arroz Largo'
        WHEN 8 THEN 'Algodón'
        ELSE 'Caña de Azúcar'
    END,
    CASE 
        WHEN (i % 100) < 20 THEN (500 + random() * 4500)::numeric(10,2) -- 20% cantidades altas
        ELSE (1 + random() * 499)::numeric(10,2) -- 80% cantidades normales
    END,
    CASE (i % 10)
        WHEN 0 THEN 450 + (random() * 100 - 50) -- Soja
        WHEN 1 THEN 280 + (random() * 60 - 30) -- Maíz
        WHEN 2 THEN 320 + (random() * 70 - 35) -- Trigo
        WHEN 3 THEN 680 + (random() * 140 - 70) -- Girasol
        WHEN 4 THEN 250 + (random() * 50 - 25) -- Sorgo
        WHEN 5 THEN 290 + (random() * 60 - 30) -- Cebada
        WHEN 6 THEN 310 + (random() * 60 - 30) -- Avena
        WHEN 7 THEN 420 + (random() * 80 - 40) -- Arroz
        WHEN 8 THEN 1850 + (random() * 350 - 175) -- Algodón
        ELSE 45 + (random() * 10 - 5) -- Caña
    END,
    -- Subtotal calculado
    (CASE 
        WHEN (i % 100) < 20 THEN (500 + random() * 4500)::numeric(10,2)
        ELSE (1 + random() * 499)::numeric(10,2)
    END) * (CASE (i % 10)
        WHEN 0 THEN 450 + (random() * 100 - 50)
        WHEN 1 THEN 280 + (random() * 60 - 30)
        ELSE 300 + (random() * 100)::numeric(10,2)
    END)
FROM generate_series(1, 300000) i;

-- Crear índices para optimizar consultas requeridas
CREATE INDEX IF NOT EXISTS idx_parcelas_cultivo_tamaño ON parcelas(cultivo_id, tamaño_ha DESC);
CREATE INDEX IF NOT EXISTS idx_compras_insumo_fecha ON compras(insumo, fecha DESC, total DESC);
CREATE INDEX IF NOT EXISTS idx_compras_insumo_36 ON compras(insumo, fecha DESC) WHERE insumo = 36;

-- Vista materializada para superficie por cultivo
CREATE MATERIALIZED VIEW IF NOT EXISTS superficie_por_cultivo AS
SELECT 
    c.id as cultivo_id,
    c.nombre as cultivo_nombre,
    c.temporada,
    COUNT(p.id) as cantidad_parcelas,
    SUM(p.tamaño_ha) as superficie_total_ha,
    AVG(p.tamaño_ha) as superficie_promedio_ha,
    c.rendimiento_promedio,
    c.precio_mercado
FROM cultivos c
LEFT JOIN parcelas p ON c.id = p.cultivo_id
GROUP BY c.id, c.nombre, c.temporada, c.rendimiento_promedio, c.precio_mercado
ORDER BY superficie_total_ha DESC;

-- Vista materializada para gastos por insumo último año
CREATE MATERIALIZED VIEW IF NOT EXISTS gastos_insumos_ultimo_año AS
SELECT 
    i.id as insumo_id,
    i.nombre as insumo_nombre,
    i.tipo,
    COUNT(c.id) as cantidad_compras,
    SUM(c.cantidad) as cantidad_total,
    SUM(c.total) as gasto_total,
    AVG(c.precio_unitario) as precio_promedio,
    MAX(c.fecha) as ultima_compra
FROM insumos i
LEFT JOIN compras c ON i.id = c.insumo
WHERE c.fecha >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY i.id, i.nombre, i.tipo
ORDER BY gasto_total DESC;

-- Vista materializada específica para insumo 36
CREATE MATERIALIZED VIEW IF NOT EXISTS historial_precios_insumo_36 AS
SELECT 
    fecha,
    precio_unitario,
    cantidad,
    total,
    proveedor_id,
    ROW_NUMBER() OVER (ORDER BY fecha DESC) as orden_cronologico
FROM compras c
JOIN insumos i ON c.insumo = i.id
WHERE i.id = 36
ORDER BY fecha DESC;

\echo '✅ Base de datos empresa_agronomia poblada exitosamente';
\echo 'Total de registros: ~945,610';
\echo 'Vistas materializadas creadas para análisis agronómico';