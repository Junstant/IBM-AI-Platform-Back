-- 07-populate-petrolera.sql
-- Población de datos para la base de datos petrolera

\echo '⛽ Poblando base de datos petrolera...'

\c petrolera;

-- ===== DEPARTAMENTOS =====
INSERT INTO departamentos (nombre) VALUES
('Exploración'),
('Perforación'),
('Ingeniería'),
('Administración'),
('Mantenimiento');

-- ===== EMPLEADOS (50,000) =====
\echo 'Generando 50,000 empleados...'
INSERT INTO empleados (nombre, puesto, salario, fecha_ingreso, departamento_id)
SELECT 
    'Empleado ' || i,
    CASE (i % 4)
        WHEN 0 THEN 'Ingeniero'
        WHEN 1 THEN 'Técnico'
        WHEN 2 THEN 'Supervisor'
        ELSE 'Analista'
    END,
    30000 + (random() * 70000)::int, -- Salarios entre 30k y 100k
    CURRENT_DATE - (random() * 3650)::int, -- Fechas de ingreso últimos 10 años
    ((i % 5) + 1) -- Distribuir entre 5 departamentos
FROM generate_series(1, 50000) i;

-- ===== POZOS (500) =====
\echo 'Generando 500 pozos...'
INSERT INTO pozos (nombre, ubicacion, fecha_exploracion)
SELECT 
    'Pozo-' || LPAD(i::text, 3, '0'),
    'Ubicación ' || i || ', Sector ' || CHAR(65 + (i % 26)),
    CURRENT_DATE - (random() * 1825)::int -- Fechas de exploración últimos 5 años
FROM generate_series(1, 500) i;

-- ===== EXTRACCIONES (1,000,000) =====
\echo 'Generando 1,000,000 extracciones...'
INSERT INTO extracciones (pozo_id, fecha, cantidad_barriles)
SELECT 
    ((i % 500) + 1), -- Distribuir entre los 500 pozos
    CURRENT_DATE - (random() * 365)::int, -- Fechas del último año
    (50 + random() * 950)::int -- Barriles entre 50 y 1000
FROM generate_series(1, 1000000) i;

-- ===== PROVEEDORES (1,000) =====
\echo 'Generando 1,000 proveedores...'
INSERT INTO proveedores (nombre, telefono, email)
SELECT 
    'Proveedor ' || i,
    '+1-555-' || LPAD((random() * 9999)::int::text, 4, '0'),
    'proveedor' || i || '@empresa.com'
FROM generate_series(1, 1000) i;

-- ===== EQUIPOS (10,000) =====
\echo 'Generando 10,000 equipos...'
INSERT INTO equipos (tipo, marca, estado)
SELECT 
    CASE (i % 2)
        WHEN 0 THEN 'Bomba'
        ELSE 'Motor'
    END,
    'Marca-' || (1 + (i % 20)), -- 20 marcas diferentes
    CASE (i % 4)
        WHEN 0 THEN 'Operativo'
        WHEN 1 THEN 'En mantenimiento'
        WHEN 2 THEN 'Fuera de servicio'
        ELSE 'Disponible'
    END
FROM generate_series(1, 10000) i;

-- ===== MANTENIMIENTOS (50,000) =====
\echo 'Generando 50,000 mantenimientos...'
INSERT INTO mantenimientos (equipo_id, fecha, descripcion)
SELECT 
    ((i % 10000) + 1), -- Distribuir entre los 10,000 equipos
    CURRENT_DATE - (random() * 730)::int, -- Fechas de los últimos 2 años
    'Mantenimiento ' || (i % 10 + 1) || ' - ' || 
    CASE (i % 5)
        WHEN 0 THEN 'Revisión rutinaria'
        WHEN 1 THEN 'Cambio de aceite'
        WHEN 2 THEN 'Reparación menor'
        WHEN 3 THEN 'Calibración'
        ELSE 'Limpieza general'
    END
FROM generate_series(1, 50000) i;

-- ===== COMPRAS (200,000) =====
\echo 'Generando 200,000 compras...'
INSERT INTO compras (equipo_id, proveedor_id, fecha, monto)
SELECT 
    ((i % 10000) + 1), -- Equipos
    ((i % 1000) + 1),  -- Proveedores
    CURRENT_DATE - (random() * 1095)::int, -- Fechas de los últimos 3 años
    (100 + random() * 9900)::numeric(12,2) -- Montos entre 100 y 10,000
FROM generate_series(1, 200000) i;

-- Crear índices para optimizar consultas requeridas
CREATE INDEX IF NOT EXISTS idx_extracciones_cantidad ON extracciones(cantidad_barriles DESC);
CREATE INDEX IF NOT EXISTS idx_equipos_estado ON equipos(estado);
CREATE INDEX IF NOT EXISTS idx_pozos_nombre ON pozos(nombre);

\echo '✅ Base de datos petrolera poblada exitosamente';
\echo 'Total de registros: ~1,311,500';