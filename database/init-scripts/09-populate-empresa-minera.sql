-- 09-populate-empresa-minera.sql
-- Población de datos para empresa_minera

\echo '⛏️ Poblando base de datos empresa_minera...'

\c empresa_minera;

-- ===== MINERALES (10) =====
INSERT INTO minerales (nombre, precio_por_tonelada, demanda) VALUES
('Oro', 58000000, 'alta'),
('Plata', 750000, 'alta'),
('Cobre', 8500, 'muy alta'),
('Hierro', 120, 'muy alta'),
('Aluminio', 1800, 'alta'),
('Zinc', 2400, 'media'),
('Plomo', 2100, 'media'),
('Níquel', 18000, 'alta'),
('Carbón', 85, 'alta'),
('Litio', 12000, 'muy alta');

-- ===== YACIMIENTOS (20) =====
INSERT INTO yacimientos (nombre, ubicacion, tipo_mineral_principal, estado) VALUES
('Yacimiento Norte', 'Provincia de Salta', 1, 'activo'),
('Mina del Sur', 'Provincia de Santa Cruz', 3, 'activo'),
('Cerro Rico', 'Provincia de Potosí', 2, 'activo'),
('Valle Dorado', 'Provincia de Catamarca', 1, 'activo'),
('Sierra Nevada', 'Provincia de Mendoza', 4, 'activo'),
('Montaña Azul', 'Provincia de Neuquén', 5, 'activo'),
('Río Profundo', 'Provincia de Río Negro', 6, 'activo'),
('Pampa Grande', 'Provincia de La Pampa', 7, 'en mantenimiento'),
('Costa Mineral', 'Provincia de Chubut', 8, 'activo'),
('Cordillera Alta', 'Provincia de San Juan', 9, 'activo'),
('Llanura Verde', 'Provincia de Córdoba', 10, 'activo'),
('Pico Blanco', 'Provincia de Jujuy', 1, 'activo'),
('Quebrada Seca', 'Provincia de La Rioja', 2, 'activo'),
('Monte Alto', 'Provincia de Tucumán', 3, 'activo'),
('Valle Escondido', 'Provincia de Santiago del Estero', 4, 'activo'),
('Cerro Azul', 'Provincia de Formosa', 5, 'en exploración'),
('Río Claro', 'Provincia de Misiones', 6, 'activo'),
('Sierra Brava', 'Provincia de Corrientes', 7, 'activo'),
('Montaña Roja', 'Provincia de Entre Ríos', 8, 'activo'),
('Valle Perdido', 'Provincia de Chaco', 9, 'activo');

-- ===== EMPLEADOS (10,000) =====
\echo 'Generando 10,000 empleados...'
INSERT INTO empleados (nombre, puesto, fecha_ingreso, yacimiento_id, salario, estado)
SELECT 
    'Empleado ' || i || ' ' || 
    CASE (i % 15)
        WHEN 0 THEN 'González'
        WHEN 1 THEN 'Rodríguez'
        WHEN 2 THEN 'García'
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
        ELSE 'Álvarez'
    END,
    CASE (i % 8)
        WHEN 0 THEN 'Operador de Máquina'
        WHEN 1 THEN 'Ingeniero de Minas'
        WHEN 2 THEN 'Supervisor'
        WHEN 3 THEN 'Técnico en Seguridad'
        WHEN 4 THEN 'Analista de Calidad'
        WHEN 5 THEN 'Mecánico'
        WHEN 6 THEN 'Geólogo'
        ELSE 'Administrativo'
    END,
    CURRENT_DATE - (random() * 3650)::int, -- Fechas de ingreso últimos 10 años
    ((i % 20) + 1), -- Distribuir entre 20 yacimientos
    40000 + (random() * 60000)::int, -- Salarios entre 40k y 100k
    CASE (i % 30)
        WHEN 29 THEN 'baja'
        WHEN 28 THEN 'suspendido'
        ELSE 'activo'
    END
FROM generate_series(1, 10000) i;

-- ===== PROVEEDORES (50) =====
INSERT INTO proveedores (nombre, contacto, telefono, email, tipo_proveedor) VALUES
('Maquinarias del Norte S.A.', 'Carlos Méndez', '+54-387-555-0101', 'contacto@maqnorte.com', 'equipos'),
('Suministros Mineros Ltda.', 'Ana Vega', '+54-351-555-0102', 'ventas@summineros.com', 'suministros'),
('Tecnología Extractiva', 'Luis Herrera', '+54-11-555-0103', 'info@tecextractiva.com', 'tecnología'),
('Repuestos Industriales SA', 'María Torres', '+54-261-555-0104', 'repuestos@repisal.com', 'repuestos'),
('Servicios Técnicos Unificados', 'José Ramírez', '+54-2966-555-0105', 'servicios@stuni.com', 'servicios');

-- Generar más proveedores
INSERT INTO proveedores (nombre, contacto, telefono, email, tipo_proveedor)
SELECT 
    'Proveedor ' || i || ' S.A.',
    'Contacto ' || i,
    '+54-11-555-' || LPAD(i::text, 4, '0'),
    'proveedor' || i || '@empresa.com',
    CASE (i % 5)
        WHEN 0 THEN 'equipos'
        WHEN 1 THEN 'suministros'
        WHEN 2 THEN 'tecnología'
        WHEN 3 THEN 'repuestos'
        ELSE 'servicios'
    END
FROM generate_series(6, 50) i;

-- ===== MÁQUINAS (200) =====
\echo 'Generando 200 máquinas...'
INSERT INTO maquinas (nombre, tipo, proveedor_id, fecha_adquisicion, estado, yacimiento_id)
SELECT 
    'Máquina-' || LPAD(i::text, 3, '0'),
    CASE (i % 8)
        WHEN 0 THEN 'Excavadora'
        WHEN 1 THEN 'Perforadora'
        WHEN 2 THEN 'Cargadora'
        WHEN 3 THEN 'Trituradora'
        WHEN 4 THEN 'Volquete'
        WHEN 5 THEN 'Grúa'
        WHEN 6 THEN 'Compresora'
        ELSE 'Clasificadora'
    END,
    ((i % 50) + 1), -- Proveedores
    CURRENT_DATE - (random() * 1825)::int, -- Fechas últimos 5 años
    CASE (i % 10)
        WHEN 0 THEN 'en mantenimiento'
        WHEN 1 THEN 'fuera de servicio'
        ELSE 'operativa'
    END,
    ((i % 20) + 1) -- Yacimientos
FROM generate_series(1, 200) i;

-- ===== TURNOS (500,000) =====
\echo 'Generando 500,000 turnos...'
INSERT INTO turnos (empleado_id, fecha, turno, horas_trabajadas)
SELECT 
    ((i % 10000) + 1), -- Empleados
    CURRENT_DATE - (random() * 730)::int, -- Fechas últimos 2 años
    CASE (i % 3)
        WHEN 0 THEN 'Mañana'
        WHEN 1 THEN 'Tarde'
        ELSE 'Noche'
    END,
    6 + (random() * 4)::int -- Entre 6 y 10 horas
FROM generate_series(1, 500000) i;

-- ===== OPERACIONES (700,000) =====
\echo 'Generando 700,000 operaciones...'
INSERT INTO operaciones (fecha, empleado_id, maquina_id, mineral_id, yacimiento_id, cantidad_extraida, calidad)
SELECT 
    CURRENT_DATE - (random() * 365)::int - (random() * interval '24 hours'), -- Fechas último año
    ((i % 10000) + 1), -- Empleados
    ((i % 200) + 1), -- Máquinas
    ((i % 10) + 1), -- Minerales
    ((i % 20) + 1), -- Yacimientos
    CASE 
        WHEN (i % 100) < 5 THEN (500 + random() * 1500)::numeric(10,2) -- 5% extracciones muy altas
        WHEN (i % 100) < 20 THEN (100 + random() * 400)::numeric(10,2) -- 15% extracciones altas  
        ELSE (1 + random() * 99)::numeric(10,2) -- 80% extracciones normales
    END,
    CASE (i % 5)
        WHEN 0 THEN 'excelente'
        WHEN 1 THEN 'buena'
        WHEN 2 THEN 'regular'
        WHEN 3 THEN 'mala'
        ELSE 'muy buena'
    END
FROM generate_series(1, 700000) i;

-- ===== CLIENTES (100) =====
INSERT INTO clientes (nombre, pais, contacto, telefono, tipo_cliente) VALUES
('Metalúrgica Argentina S.A.', 'Argentina', 'Roberto Silva', '+54-11-4567-8901', 'industrial'),
('Construcciones del Sur', 'Chile', 'Carmen López', '+56-2-2345-6789', 'construcción'),
('Manufacturas Europeas Ltd.', 'España', 'Antonio García', '+34-91-234-5678', 'manufacturero'),
('Tecnología Asiática Inc.', 'China', 'Li Wei', '+86-10-8765-4321', 'tecnológico'),
('Energía Renovable Brasil', 'Brasil', 'João Santos', '+55-11-3456-7890', 'energético');

-- Generar más clientes
INSERT INTO clientes (nombre, pais, contacto, telefono, tipo_cliente)
SELECT 
    'Cliente ' || i || ' Corp.',
    CASE (i % 20)
        WHEN 0 THEN 'Argentina'
        WHEN 1 THEN 'Brasil'
        WHEN 2 THEN 'Chile'
        WHEN 3 THEN 'China'
        WHEN 4 THEN 'España'
        WHEN 5 THEN 'Estados Unidos'
        WHEN 6 THEN 'Alemania'
        WHEN 7 THEN 'Francia'
        WHEN 8 THEN 'Italia'
        WHEN 9 THEN 'Japón'
        WHEN 10 THEN 'Corea del Sur'
        WHEN 11 THEN 'India'
        WHEN 12 THEN 'Canadá'
        WHEN 13 THEN 'Australia'
        WHEN 14 THEN 'Reino Unido'
        WHEN 15 THEN 'Rusia'
        WHEN 16 THEN 'México'
        WHEN 17 THEN 'Perú'
        WHEN 18 THEN 'Colombia'
        ELSE 'Venezuela'
    END,
    'Contacto ' || i,
    '+' || (1 + (i % 99)) || '-' || LPAD((random() * 9999999)::int::text, 7, '0'),
    CASE (i % 5)
        WHEN 0 THEN 'industrial'
        WHEN 1 THEN 'construcción'
        WHEN 2 THEN 'manufacturero'
        WHEN 3 THEN 'tecnológico'
        ELSE 'energético'
    END
FROM generate_series(6, 100) i;

-- ===== VENTAS (100,000) =====
\echo 'Generando 100,000 ventas...'
INSERT INTO ventas (fecha, cliente_id, mineral_id, cantidad, monto, precio_por_tonelada)
SELECT 
    CURRENT_DATE - (random() * 365)::int, -- Fechas último año
    ((i % 100) + 1), -- Clientes
    ((i % 10) + 1), -- Minerales
    CASE 
        WHEN (i % 100) < 10 THEN (500 + random() * 1500)::numeric(10,2) -- 10% ventas grandes
        ELSE (1 + random() * 499)::numeric(10,2) -- 90% ventas normales
    END,
    CASE (i % 10) + 1
        WHEN 1 THEN (58000000 * (1 + random() * 499)::numeric(10,2)) -- Oro
        WHEN 2 THEN (750000 * (1 + random() * 499)::numeric(10,2)) -- Plata
        WHEN 3 THEN (8500 * (1 + random() * 499)::numeric(10,2)) -- Cobre
        WHEN 4 THEN (120 * (1 + random() * 499)::numeric(10,2)) -- Hierro
        WHEN 5 THEN (1800 * (1 + random() * 499)::numeric(10,2)) -- Aluminio
        WHEN 6 THEN (2400 * (1 + random() * 499)::numeric(10,2)) -- Zinc
        WHEN 7 THEN (2100 * (1 + random() * 499)::numeric(10,2)) -- Plomo
        WHEN 8 THEN (18000 * (1 + random() * 499)::numeric(10,2)) -- Níquel
        WHEN 9 THEN (85 * (1 + random() * 499)::numeric(10,2)) -- Carbón
        ELSE (12000 * (1 + random() * 499)::numeric(10,2)) -- Litio
    END,
    CASE (i % 10) + 1
        WHEN 1 THEN 58000000 -- Oro
        WHEN 2 THEN 750000 -- Plata
        WHEN 3 THEN 8500 -- Cobre
        WHEN 4 THEN 120 -- Hierro
        WHEN 5 THEN 1800 -- Aluminio
        WHEN 6 THEN 2400 -- Zinc
        WHEN 7 THEN 2100 -- Plomo
        WHEN 8 THEN 18000 -- Níquel
        WHEN 9 THEN 85 -- Carbón
        ELSE 12000 -- Litio
    END
FROM generate_series(1, 100000) i;

-- ===== COMPRAS (10,000) =====
INSERT INTO compras (proveedor_id, fecha, descripcion, monto, tipo_compra)
SELECT 
    ((i % 50) + 1), -- Proveedores
    CURRENT_DATE - (random() * 365)::int, -- Fechas último año
    'Compra de ' || 
    CASE (i % 5)
        WHEN 0 THEN 'equipos especializados'
        WHEN 1 THEN 'suministros operativos'
        WHEN 2 THEN 'tecnología avanzada'
        WHEN 3 THEN 'repuestos y mantenimiento'
        ELSE 'servicios técnicos'
    END,
    (1000 + random() * 99000)::numeric(12,2), -- Montos entre 1k y 100k
    CASE (i % 5)
        WHEN 0 THEN 'equipos'
        WHEN 1 THEN 'suministros'
        WHEN 2 THEN 'tecnología'
        WHEN 3 THEN 'repuestos'
        ELSE 'servicios'
    END
FROM generate_series(1, 10000) i;

-- ===== MANTENIMIENTO (10,000) =====
INSERT INTO mantenimiento (maquina_id, fecha, descripcion, costo, tipo_mantenimiento)
SELECT 
    ((i % 200) + 1), -- Máquinas
    CURRENT_DATE - (random() * 365)::int, -- Fechas último año
    'Mantenimiento ' || (i % 5 + 1) || ' - ' ||
    CASE (i % 6)
        WHEN 0 THEN 'Revisión general'
        WHEN 1 THEN 'Cambio de filtros'
        WHEN 2 THEN 'Reparación mecánica'
        WHEN 3 THEN 'Calibración de sistemas'
        WHEN 4 THEN 'Actualización de software'
        ELSE 'Limpieza profunda'
    END,
    (500 + random() * 9500)::numeric(10,2), -- Costos entre 500 y 10k
    CASE (i % 3)
        WHEN 0 THEN 'preventivo'
        WHEN 1 THEN 'correctivo'
        ELSE 'predictivo'
    END
FROM generate_series(1, 10000) i;

-- ===== ALMACENAMIENTOS (5,000) =====
INSERT INTO almacenamientos (yacimiento_id, mineral_id, stock, capacidad_maxima, fecha_actualizacion)
SELECT 
    ((i % 20) + 1), -- Yacimientos
    ((i % 10) + 1), -- Minerales
    (random() * 1000)::numeric(10,2), -- Stock actual
    (1000 + random() * 4000)::numeric(10,2), -- Capacidad máxima
    CURRENT_DATE - (random() * 30)::int -- Actualizaciones último mes
FROM generate_series(1, 5000) i;

-- ===== ACCIDENTES (5,000) =====
INSERT INTO accidentes (fecha, empleado_id, descripcion, gravedad, causa)
SELECT 
    CURRENT_DATE - (random() * 730)::int, -- Fechas últimos 2 años
    ((i % 10000) + 1), -- Empleados
    CASE (i % 8)
        WHEN 0 THEN 'Corte menor en mano'
        WHEN 1 THEN 'Golpe en cabeza'
        WHEN 2 THEN 'Torcedura de tobillo'
        WHEN 3 THEN 'Inhalación de polvo'
        WHEN 4 THEN 'Quemadura leve'
        WHEN 5 THEN 'Fractura de brazo'
        WHEN 6 THEN 'Contusión múltiple'
        ELSE 'Lesión en espalda'
    END,
    CASE (i % 4)
        WHEN 0 THEN 'leve'
        WHEN 1 THEN 'moderada'
        WHEN 2 THEN 'grave'
        ELSE 'muy grave'
    END,
    CASE (i % 6)
        WHEN 0 THEN 'falta de EPP'
        WHEN 1 THEN 'mal funcionamiento equipo'
        WHEN 2 THEN 'error humano'
        WHEN 3 THEN 'condiciones climáticas'
        WHEN 4 THEN 'fatiga'
        ELSE 'falta de capacitación'
    END
FROM generate_series(1, 5000) i;

-- ===== AUDITORÍAS (5,000) =====
INSERT INTO auditorias (fecha, yacimiento_id, resultado, inspector, observaciones)
SELECT 
    CURRENT_DATE - (random() * 365)::int, -- Fechas último año
    ((i % 20) + 1), -- Yacimientos
    CASE (i % 5)
        WHEN 0 THEN 'excelente'
        WHEN 1 THEN 'bueno'
        WHEN 2 THEN 'regular'
        WHEN 3 THEN 'deficiente'
        ELSE 'muy bueno'
    END,
    'Inspector ' || ((i % 20) + 1),
    'Auditoría de seguridad y cumplimiento normativo'
FROM generate_series(1, 5000) i;

-- ===== SENSORES (400,000) =====
\echo 'Generando 400,000 lecturas de sensores...'
INSERT INTO sensores (fecha_hora, yacimiento_id, tipo_sensor, valor, unidad)
SELECT 
    CURRENT_DATE - (random() * 30)::int - (random() * interval '24 hours'), -- Último mes
    ((i % 20) + 1), -- Yacimientos
    CASE (i % 6)
        WHEN 0 THEN 'temperatura'
        WHEN 1 THEN 'humedad'
        WHEN 2 THEN 'presion'
        WHEN 3 THEN 'gas'
        WHEN 4 THEN 'vibracion'
        ELSE 'ruido'
    END,
    CASE (i % 6)
        WHEN 0 THEN (15 + random() * 40)::numeric(8,2) -- Temperatura 15-55°C
        WHEN 1 THEN (30 + random() * 70)::numeric(8,2) -- Humedad 30-100%
        WHEN 2 THEN (900 + random() * 200)::numeric(8,2) -- Presión 900-1100 hPa
        WHEN 3 THEN (0 + random() * 100)::numeric(8,2) -- Gas 0-100 ppm
        WHEN 4 THEN (0 + random() * 50)::numeric(8,2) -- Vibración 0-50 Hz
        ELSE (30 + random() * 90)::numeric(8,2) -- Ruido 30-120 dB
    END,
    CASE (i % 6)
        WHEN 0 THEN '°C'
        WHEN 1 THEN '%'
        WHEN 2 THEN 'hPa'
        WHEN 3 THEN 'ppm'
        WHEN 4 THEN 'Hz'
        ELSE 'dB'
    END
FROM generate_series(1, 400000) i;

-- Crear índices para optimizar consultas requeridas
CREATE INDEX IF NOT EXISTS idx_maquinas_productividad ON operaciones(maquina_id, cantidad_extraida DESC);
CREATE INDEX IF NOT EXISTS idx_operaciones_turno_noche ON operaciones(fecha, yacimiento_id) WHERE fecha::time BETWEEN '22:00' AND '06:00';
CREATE INDEX IF NOT EXISTS idx_ventas_mineral_cantidad ON ventas(mineral_id, cantidad DESC);

-- Vista materializada para máquinas más productivas
CREATE MATERIALIZED VIEW IF NOT EXISTS maquinas_productividad AS
SELECT 
    m.id,
    m.nombre,
    m.tipo,
    SUM(o.cantidad_extraida) as total_extraido,
    AVG(o.cantidad_extraida) as promedio_extraido,
    COUNT(o.id) as operaciones_realizadas
FROM maquinas m
JOIN operaciones o ON m.id = o.maquina_id
GROUP BY m.id, m.nombre, m.tipo
ORDER BY total_extraido DESC;

CREATE INDEX IF NOT EXISTS idx_maquinas_productividad_total ON maquinas_productividad(total_extraido DESC);

\echo '✅ Base de datos empresa_minera poblada exitosamente';
\echo 'Total de registros: ~1,745,380';