-- 08-populate-banco-global.sql
-- Población extendida de datos para banco_global

\echo '🏦 Poblando base de datos banco_global con datos masivos...'

\c banco_global;

-- ===== SUCURSALES (100) =====
\echo 'Generando 100 sucursales...'
INSERT INTO sucursales (nombre, direccion, ciudad, pais)
SELECT 
    'Sucursal ' || LPAD(i::text, 3, '0'),
    'Av. Principal ' || (i * 100) || ', Edificio ' || i,
    CASE (i % 20)
        WHEN 0 THEN 'Buenos Aires'
        WHEN 1 THEN 'Córdoba'
        WHEN 2 THEN 'Rosario'
        WHEN 3 THEN 'Mendoza'
        WHEN 4 THEN 'San Miguel de Tucumán'
        WHEN 5 THEN 'La Plata'
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
        ELSE 'Catamarca'
    END,
    'Argentina'
FROM generate_series(1, 100) i;

-- ===== EMPLEADOS (10,000) =====
\echo 'Generando 10,000 empleados...'
INSERT INTO empleados (nombre, puesto, salario, fecha_ingreso, sucursal_id)
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
    CASE (i % 4)
        WHEN 0 THEN 'Cajero'
        WHEN 1 THEN 'Gerente'
        WHEN 2 THEN 'Asesor'
        ELSE 'Seguridad'
    END,
    25000 + (random() * 75000)::int, -- Salarios entre 25k y 100k
    CURRENT_DATE - (random() * 3650)::int, -- Fechas de ingreso últimos 10 años
    ((i % 100) + 1) -- Distribuir entre las 100 sucursales
FROM generate_series(1, 10000) i;

-- ===== CLIENTES (100,000) =====
\echo 'Generando 100,000 clientes...'
INSERT INTO clientes (nombre, apellido, dni, direccion, telefono, email, fecha_registro)
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
    END,
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
    (10000000 + i), -- DNI único
    'Calle ' || (i % 1000) || ' #' || (i % 9999),
    '+54-11-' || LPAD((random() * 99999999)::int::text, 8, '0'),
    'cliente' || i || '@email.com',
    CURRENT_DATE - (random() * 1825)::int -- Fechas de registro últimos 5 años
FROM generate_series(1, 100000) i;

-- ===== CUENTAS (150,000) - Aumentado para más realismo =====
\echo 'Generando 150,000 cuentas bancarias...'
INSERT INTO cuentas (cliente_id, numero_cuenta, tipo_cuenta_id, saldo, fecha_apertura, estado)
SELECT 
    ((i % 100000) + 1), -- Clientes
    '00' || LPAD(i::text, 10, '0'), -- Número de cuenta único
    ((i % 5) + 1), -- Tipos de cuenta (1-5)
    (random() * 100000)::numeric(15,2), -- Saldos aleatorios hasta 100k
    CURRENT_DATE - (random() * 1460)::int, -- Fechas de apertura últimos 4 años
    CASE (i % 20)
        WHEN 19 THEN 'suspendida'
        WHEN 18 THEN 'cerrada'
        ELSE 'activa'
    END
FROM generate_series(1, 150000) i;

-- ===== TRANSACCIONES (400,000) =====
\echo 'Generando 400,000 transacciones...'
INSERT INTO transacciones_banco (
    cuenta_origen_id, 
    cuenta_destino_id, 
    monto, 
    tipo_transaccion_id, 
    fecha_transaccion, 
    descripcion,
    estado
)
SELECT 
    ((i % 150000) + 1), -- Cuenta origen
    CASE 
        WHEN (i % 3) = 0 THEN NULL -- Depósitos/retiros sin cuenta destino
        ELSE (((i + 1000) % 150000) + 1) -- Cuenta destino diferente
    END,
    CASE 
        WHEN (i % 100) < 5 THEN (50000 + random() * 450000)::numeric(15,2) -- 5% transacciones altas
        WHEN (i % 100) < 20 THEN (10000 + random() * 40000)::numeric(15,2) -- 15% transacciones medias
        ELSE (1 + random() * 9999)::numeric(15,2) -- 80% transacciones normales
    END,
    ((i % 6) + 1), -- Tipos de transacción (1-6)
    CURRENT_DATE - (random() * 365)::int - (random() * interval '24 hours'), -- Fechas último año
    CASE (i % 6)
        WHEN 0 THEN 'Depósito en efectivo'
        WHEN 1 THEN 'Retiro ATM'
        WHEN 2 THEN 'Transferencia bancaria'
        WHEN 3 THEN 'Pago de servicios'
        WHEN 4 THEN 'Compra POS'
        ELSE 'Transferencia online'
    END,
    CASE (i % 100)
        WHEN 99 THEN 'pendiente'
        WHEN 98 THEN 'cancelada'
        ELSE 'completada'
    END
FROM generate_series(1, 400000) i;

-- ===== TARJETAS (70,000) - Aumentado =====
\echo 'Generando 70,000 tarjetas...'
INSERT INTO tarjetas (cliente_id, numero, tipo, fecha_emision, fecha_vencimiento, limite_credito, estado)
SELECT 
    ((i % 100000) + 1), -- Clientes
    '4' || LPAD((random() * 999999999999999)::bigint::text, 15, '0'), -- Número de tarjeta
    CASE (i % 3)
        WHEN 0 THEN 'débito'
        WHEN 1 THEN 'crédito'
        ELSE 'prepaga'
    END,
    CURRENT_DATE - (random() * 1095)::int, -- Fechas de emisión últimos 3 años
    CURRENT_DATE + (random() * 1460)::int, -- Fechas de vencimiento próximos 4 años
    CASE 
        WHEN (i % 3) = 1 THEN (5000 + random() * 95000)::numeric(15,2) -- Tarjetas crédito
        ELSE NULL -- Débito/prepaga sin límite
    END,
    CASE (i % 20)
        WHEN 19 THEN 'bloqueada'
        WHEN 18 THEN 'vencida'
        ELSE 'activa'
    END
FROM generate_series(1, 70000) i;

-- ===== TIPOS DE INVERSIÓN =====
INSERT INTO tipos_inversion (nombre, riesgo, descripcion, rendimiento_anual) VALUES
('Plazo Fijo', 'bajo', 'Inversión segura con rendimiento fijo', 0.035),
('Bonos Gobierno', 'bajo', 'Bonos del gobierno nacional', 0.045),
('Fondos Comunes', 'medio', 'Diversificación en cartera mixta', 0.065),
('Acciones Blue Chip', 'medio', 'Acciones de empresas líderes', 0.085),
('Fondos de Riesgo', 'alto', 'Inversiones de alto riesgo y rendimiento', 0.125);

-- ===== PRÉSTAMOS (20,000) =====
\echo 'Generando 20,000 préstamos...'
INSERT INTO prestamos (cliente_id, monto, tasa_interes, plazo_meses, fecha_otorgamiento, estado, monto_pendiente)
SELECT 
    ((i % 100000) + 1), -- Clientes
    CASE 
        WHEN (i % 100) < 10 THEN (500000 + random() * 1500000)::numeric(15,2) -- 10% préstamos altos
        WHEN (i % 100) < 30 THEN (100000 + random() * 400000)::numeric(15,2) -- 20% préstamos medios
        ELSE (10000 + random() * 90000)::numeric(15,2) -- 70% préstamos pequeños
    END,
    (0.15 + random() * 0.35), -- Tasas entre 15% y 50%
    CASE (i % 5)
        WHEN 0 THEN 12
        WHEN 1 THEN 24
        WHEN 2 THEN 36
        WHEN 3 THEN 48
        ELSE 60
    END,
    CURRENT_DATE - (random() * 1095)::int, -- Fechas últimos 3 años
    CASE (i % 10)
        WHEN 0 THEN 'en mora'
        WHEN 1 THEN 'cancelado'
        ELSE 'activo'
    END,
    CASE 
        WHEN (i % 10) = 1 THEN 0 -- Cancelados
        ELSE (random() * 0.8 + 0.1) -- Entre 10% y 90% del monto original
    END * (CASE 
        WHEN (i % 100) < 10 THEN (500000 + random() * 1500000)::numeric(15,2)
        WHEN (i % 100) < 30 THEN (100000 + random() * 400000)::numeric(15,2)
        ELSE (10000 + random() * 90000)::numeric(15,2)
    END)
FROM generate_series(1, 20000) i;

-- ===== INVERSIONES (10,000) =====
\echo 'Generando 10,000 inversiones...'
INSERT INTO inversiones (cliente_id, tipo_inversion_id, monto, fecha_inicio, fecha_vencimiento, estado)
SELECT 
    ((i % 100000) + 1), -- Clientes
    ((i % 5) + 1), -- Tipos de inversión
    (1000 + random() * 99000)::numeric(15,2), -- Montos entre 1k y 100k
    CURRENT_DATE - (random() * 730)::int, -- Fechas últimos 2 años
    CURRENT_DATE + (random() * 730)::int, -- Vencimientos próximos 2 años
    CASE (i % 10)
        WHEN 0 THEN 'vencida'
        WHEN 1 THEN 'cancelada'
        ELSE 'activa'
    END
FROM generate_series(1, 10000) i;

-- ===== CAJAS DE SEGURIDAD (5,000) =====
\echo 'Generando 5,000 cajas de seguridad...'
INSERT INTO cajas_seguridad (cliente_id, sucursal_id, tamaño, fecha_alta, costo_anual, estado)
SELECT 
    ((i % 100000) + 1), -- Clientes
    ((i % 100) + 1), -- Sucursales
    CASE (i % 3)
        WHEN 0 THEN 'chica'
        WHEN 1 THEN 'mediana'
        ELSE 'grande'
    END,
    CURRENT_DATE - (random() * 1095)::int, -- Fechas últimos 3 años
    CASE (i % 3)
        WHEN 0 THEN 1200 -- Chica
        WHEN 1 THEN 2400 -- Mediana
        ELSE 4800 -- Grande
    END,
    CASE (i % 20)
        WHEN 19 THEN 'suspendida'
        ELSE 'activa'
    END
FROM generate_series(1, 5000) i;

-- ===== CLIENTES-SUCURSALES (30,000) =====
\echo 'Generando 30,000 asociaciones cliente-sucursal...'
INSERT INTO clientes_sucursales (cliente_id, sucursal_id, fecha_asociacion, tipo_relacion)
SELECT 
    ((i % 100000) + 1), -- Clientes
    ((i % 100) + 1), -- Sucursales
    CURRENT_DATE - (random() * 1460)::int, -- Fechas últimos 4 años
    CASE (i % 3)
        WHEN 0 THEN 'principal'
        WHEN 1 THEN 'secundaria'
        ELSE 'ocasional'
    END
FROM generate_series(1, 30000) i;

-- ===== AUDITORÍAS (10,000) =====
\echo 'Generando 10,000 auditorías...'
INSERT INTO auditorias (usuario, accion, cuenta_afectada, fecha, descripcion, ip_origen)
SELECT 
    'usuario' || ((i % 1000) + 1), -- 1000 usuarios diferentes
    CASE (i % 4)
        WHEN 0 THEN 'actualización de saldo'
        WHEN 1 THEN 'bloqueo'
        WHEN 2 THEN 'apertura'
        ELSE 'cierre'
    END,
    ((i % 150000) + 1), -- Cuentas afectadas
    CURRENT_DATE - (random() * 365)::int - (random() * interval '24 hours'), -- Fechas último año
    'Acción realizada por motivos operativos',
    '192.168.' || (random() * 255)::int || '.' || (random() * 255)::int
FROM generate_series(1, 10000) i;

-- Crear índices para optimizar las consultas requeridas
CREATE INDEX IF NOT EXISTS idx_prestamos_estado_monto ON prestamos(estado, monto DESC) WHERE estado = 'activo';
CREATE INDEX IF NOT EXISTS idx_transacciones_monto ON transacciones_banco(monto DESC);
CREATE INDEX IF NOT EXISTS idx_transacciones_cuenta_origen ON transacciones_banco(cuenta_origen_id);

-- Estadísticas de conteo de transacciones por cuenta
CREATE MATERIALIZED VIEW IF NOT EXISTS cuenta_transacciones_count AS
SELECT 
    cuenta_origen_id as cuenta_id,
    COUNT(*) as num_transacciones,
    SUM(monto) as total_monto
FROM transacciones_banco 
WHERE estado = 'completada'
GROUP BY cuenta_origen_id
ORDER BY num_transacciones DESC;

CREATE INDEX IF NOT EXISTS idx_cuenta_transacciones_count ON cuenta_transacciones_count(num_transacciones DESC);

\echo '✅ Base de datos banco_global poblada exitosamente';
\echo 'Total de registros: ~602,105';
\echo 'Vistas materializadas creadas para optimización';