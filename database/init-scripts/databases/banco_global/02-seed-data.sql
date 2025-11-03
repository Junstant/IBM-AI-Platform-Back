-- databases/banco_global/02-seed-data.sql
-- Datos masivos realistas para banco_global

\echo '🏦 Insertando datos masivos para banco_global...'

\c banco_global;

-- ===== TIPOS DE CUENTA BÁSICOS =====
INSERT INTO tipos_cuenta (nombre, descripcion, tasa_interes, monto_minimo, comision_mantenimiento) VALUES
('Cuenta Corriente', 'Cuenta para movimientos diarios', 0.0000, 0.00, 15.00),
('Cuenta de Ahorros', 'Cuenta para ahorros con intereses', 0.0250, 100.00, 5.00),
('Cuenta Premium', 'Cuenta con beneficios adicionales', 0.0350, 5000.00, 25.00),
('Cuenta Empresarial', 'Cuenta para empresas', 0.0150, 1000.00, 50.00),
('Cuenta VIP', 'Cuenta para clientes VIP', 0.0450, 50000.00, 100.00),
('Cuenta Joven', 'Cuenta para menores de 25 años', 0.0300, 0.00, 0.00)
ON CONFLICT (nombre) DO NOTHING;

-- ===== TIPOS DE TRANSACCIÓN BÁSICOS =====
INSERT INTO tipos_transaccion (codigo, nombre, descripcion, requiere_autorizacion, comision) VALUES
('DEP', 'Depósito', 'Depósito en efectivo o cheque', FALSE, 0.00),
('RET', 'Retiro', 'Retiro en efectivo', FALSE, 2.00),
('TRANS', 'Transferencia', 'Transferencia entre cuentas', FALSE, 5.00),
('PAGO', 'Pago de Servicios', 'Pago de servicios públicos', FALSE, 3.00),
('DEBITO', 'Débito Automático', 'Débito automático de servicios', FALSE, 1.00),
('CREDITO', 'Acreditación', 'Acreditación de salario/ingresos', FALSE, 0.00),
('COMPRA', 'Compra con Tarjeta', 'Compra con tarjeta de débito/crédito', FALSE, 0.00),
('INTERES', 'Pago de Intereses', 'Pago de intereses de cuenta de ahorros', FALSE, 0.00)
ON CONFLICT (codigo) DO NOTHING;

-- ===== SUCURSALES (25 SUCURSALES) =====
INSERT INTO sucursales (codigo, nombre, direccion, ciudad, telefono, gerente, activa) VALUES
('SUC001', 'Sucursal Centro', 'Av. Principal 123', 'Buenos Aires', '+54-11-1234-5678', 'María González', TRUE),
('SUC002', 'Sucursal Norte', 'Calle Norte 456', 'Buenos Aires', '+54-11-2345-6789', 'Carlos Rodríguez', TRUE),
('SUC003', 'Sucursal Sur', 'Av. Libertador 789', 'Buenos Aires', '+54-11-3456-7890', 'Ana Martínez', TRUE),
('SUC004', 'Sucursal Oeste', 'Calle Comercio 321', 'Buenos Aires', '+54-11-4567-8901', 'Luis Fernández', TRUE),
('SUC005', 'Sucursal Este', 'Av. Costanera 654', 'Buenos Aires', '+54-11-5678-9012', 'Carmen López', TRUE),
('SUC006', 'Sucursal Palermo', 'Av. Santa Fe 987', 'Buenos Aires', '+54-11-6789-0123', 'Diego Silva', TRUE),
('SUC007', 'Sucursal Belgrano', 'Av. Cabildo 1234', 'Buenos Aires', '+54-11-7890-1234', 'Laura Torres', TRUE),
('SUC008', 'Sucursal San Telmo', 'Defensa 567', 'Buenos Aires', '+54-11-8901-2345', 'Miguel Herrera', TRUE),
('SUC009', 'Sucursal Recoleta', 'Av. Las Heras 890', 'Buenos Aires', '+54-11-9012-3456', 'Sofía Vargas', TRUE),
('SUC010', 'Sucursal Caballito', 'Av. Rivadavia 2345', 'Buenos Aires', '+54-11-0123-4567', 'Roberto Méndez', TRUE),
('SUC011', 'Sucursal Villa Crespo', 'Av. Corrientes 3456', 'Buenos Aires', '+54-11-1234-5679', 'Patricia Jiménez', TRUE),
('SUC012', 'Sucursal Barracas', 'Av. Montes de Oca 789', 'Buenos Aires', '+54-11-2345-6780', 'Fernando Castro', TRUE),
('SUC013', 'Sucursal La Boca', 'Caminito 123', 'Buenos Aires', '+54-11-3456-7891', 'Gabriela Morales', TRUE),
('SUC014', 'Sucursal Flores', 'Av. Directorio 456', 'Buenos Aires', '+54-11-4567-8902', 'Andrés Ruiz', TRUE),
('SUC015', 'Sucursal Almagro', 'Av. Medrano 789', 'Buenos Aires', '+54-11-5678-9013', 'Valeria Ortega', TRUE),
('SUC016', 'Sucursal Villa Urquiza', 'Av. Triunvirato 1011', 'Buenos Aires', '+54-11-6789-0124', 'Héctor Ramírez', TRUE),
('SUC017', 'Sucursal Núñez', 'Av. Del Libertador 1213', 'Buenos Aires', '+54-11-7890-1235', 'Claudia Soto', TRUE),
('SUC018', 'Sucursal Colegiales', 'Av. Federico Lacroze 1415', 'Buenos Aires', '+54-11-8901-2346', 'Javier Peña', TRUE),
('SUC019', 'Sucursal Chacarita', 'Av. Dorrego 1617', 'Buenos Aires', '+54-11-9012-3457', 'Marcela Aguilar', TRUE),
('SUC020', 'Sucursal Villa Devoto', 'Av. Francisco Beiró 1819', 'Buenos Aires', '+54-11-0123-4568', 'Eduardo Vega', TRUE),
('SUC021', 'Sucursal Liniers', 'Av. Rivadavia 9021', 'Buenos Aires', '+54-11-1234-5680', 'Silvia Romero', TRUE),
('SUC022', 'Sucursal Mataderos', 'Av. Directorio 2223', 'Buenos Aires', '+54-11-2345-6781', 'Gustavo Molina', TRUE),
('SUC023', 'Sucursal Parque Patricios', 'Av. Caseros 2425', 'Buenos Aires', '+54-11-3456-7892', 'Beatriz Guerrero', TRUE),
('SUC024', 'Sucursal San Cristóbal', 'Av. Independencia 2627', 'Buenos Aires', '+54-11-4567-8903', 'Raúl Herrera', TRUE),
('SUC025', 'Sucursal Constitución', 'Av. Brasil 2829', 'Buenos Aires', '+54-11-5678-9014', 'Marina Cabrera', TRUE)
ON CONFLICT (codigo) DO NOTHING;

-- ===== FUNCIÓN PARA GENERAR DATOS MASIVOS =====
DO $$
DECLARE
    i INTEGER;
    j INTEGER;
    k INTEGER;
    cliente_id_var INTEGER;
    cuenta_id_var INTEGER;
    tipo_cuenta_var INTEGER;
    sucursal_var INTEGER;
    tipo_transaccion_var INTEGER;
    monto_var NUMERIC;
    fecha_var DATE;
    nombres TEXT[] := ARRAY['Juan', 'María', 'Carlos', 'Ana', 'Luis', 'Laura', 'Diego', 'Sofía', 'Miguel', 'Carmen', 
                           'Roberto', 'Patricia', 'Fernando', 'Gabriela', 'Andrés', 'Valeria', 'Héctor', 'Claudia', 
                           'Javier', 'Marcela', 'Eduardo', 'Silvia', 'Gustavo', 'Beatriz', 'Raúl', 'Marina', 'Pablo', 
                           'Elena', 'Sergio', 'Natalia', 'Adrián', 'Mónica', 'Martín', 'Lucía', 'Alejandro', 'Rosa',
                           'Daniel', 'Isabel', 'Jorge', 'Graciela', 'Ricardo', 'Norma', 'Guillermo', 'Susana', 'Oscar',
                           'Marta', 'Ernesto', 'Teresa', 'Ramón', 'Liliana'];
    apellidos TEXT[] := ARRAY['González', 'Rodríguez', 'Martínez', 'López', 'García', 'Fernández', 'Pérez', 'Sánchez',
                             'Romero', 'Torres', 'Flores', 'Rivera', 'Gómez', 'Díaz', 'Morales', 'Herrera', 'Jiménez',
                             'Álvarez', 'Ruiz', 'Vargas', 'Castro', 'Ortega', 'Ramos', 'Delgado', 'Moreno', 'Gutiérrez',
                             'Reyes', 'Silva', 'Mendoza', 'Aguilar', 'Vega', 'Molina', 'Guerrero', 'Cabrera', 'Medina',
                             'Campos', 'Cortés', 'Navarro', 'Rojas', 'Bravo'];
    ciudades TEXT[] := ARRAY['Buenos Aires', 'Córdoba', 'Rosario', 'Mendoza', 'La Plata', 'Mar del Plata', 'Salta', 'Tucumán'];
    calles TEXT[] := ARRAY['Av. Corrientes', 'Av. Santa Fe', 'Av. Rivadavia', 'Calle Florida', 'Av. Libertador', 'Av. Cabildo', 
                          'Av. Las Heras', 'Defensa', 'Reconquista', 'San Martín', 'Belgrano', 'Maipú', 'Lavalle', 'Bartolomé Mitre'];
BEGIN
    -- ===== INSERTAR 5000 CLIENTES =====
    RAISE NOTICE 'Insertando 5000 clientes...';
    FOR i IN 1..5000 LOOP
        INSERT INTO clientes (
            nombre, apellido, email, telefono, fecha_nacimiento, documento_identidad, 
            direccion, ciudad, provincia, codigo_postal, estado, fecha_registro
        ) VALUES (
            nombres[1 + (i % array_length(nombres, 1))],
            apellidos[1 + (i % array_length(apellidos, 1))],
            'cliente' || i || '@email.com',
            '+54-11-' || LPAD((1000 + (i % 9000))::TEXT, 4, '0') || '-' || LPAD((1000 + (i % 9000))::TEXT, 4, '0'),
            DATE '1960-01-01' + (i % 15000) * INTERVAL '1 day',
            LPAD(i::TEXT, 8, '0'),
            calles[1 + (i % array_length(calles, 1))] || ' ' || (100 + (i % 9000))::TEXT,
            ciudades[1 + (i % array_length(ciudades, 1))],
            'Buenos Aires',
            (1000 + (i % 50))::TEXT,
            CASE WHEN i % 20 = 0 THEN 'inactivo' ELSE 'activo' END,
            DATE '2020-01-01' + (i % 1460) * INTERVAL '1 day'
        );
    END LOOP;
    
    RAISE NOTICE 'Clientes insertados: %', (SELECT COUNT(*) FROM clientes);

    -- ===== INSERTAR 8000 CUENTAS =====
    RAISE NOTICE 'Insertando 8000 cuentas...';
    FOR i IN 1..8000 LOOP
        cliente_id_var := 1 + (i % 5000);
        tipo_cuenta_var := 1 + (i % 6);
        sucursal_var := 1 + (i % 25);
        
        INSERT INTO cuentas (
            numero_cuenta, cliente_id, tipo_cuenta_id, sucursal_id, saldo, fecha_apertura, estado
        ) VALUES (
            '4' || LPAD((1000 + (i / 1000))::TEXT, 3, '0') || '-' || LPAD((i % 1000)::TEXT, 3, '0') || '-' || LPAD((i % 100)::TEXT, 3, '0'),
            cliente_id_var,
            tipo_cuenta_var,
            sucursal_var,
            -- Saldos variados: algunos muy altos, algunos normales, algunos bajos
            CASE 
                WHEN i % 50 = 0 THEN 500000 + (RANDOM() * 2000000)::NUMERIC(12,2)  -- 2% cuentas VIP
                WHEN i % 10 = 0 THEN 50000 + (RANDOM() * 200000)::NUMERIC(12,2)    -- 10% cuentas altas
                WHEN i % 5 = 0 THEN 10000 + (RANDOM() * 50000)::NUMERIC(12,2)      -- 20% cuentas medias
                ELSE 100 + (RANDOM() * 10000)::NUMERIC(12,2)                       -- 68% cuentas normales
            END,
            DATE '2020-01-01' + (i % 1460) * INTERVAL '1 day',
            CASE WHEN i % 100 = 0 THEN 'inactiva' ELSE 'activa' END
        );
    END LOOP;
    
    RAISE NOTICE 'Cuentas insertadas: %', (SELECT COUNT(*) FROM cuentas);

    -- ===== INSERTAR PRODUCTOS BANCARIOS =====
    INSERT INTO productos_bancarios (codigo, nombre, categoria, descripcion, tasa_interes, plazo_minimo, plazo_maximo, monto_minimo, monto_maximo, activo) VALUES
    ('PREST-001', 'Préstamo Personal', 'Préstamos', 'Préstamo personal para diversos fines', 0.2500, 12, 60, 10000.00, 500000.00, TRUE),
    ('PREST-002', 'Préstamo Hipotecario', 'Préstamos', 'Préstamo para compra de vivienda', 0.1200, 120, 360, 50000.00, 5000000.00, TRUE),
    ('PREST-003', 'Préstamo Automotor', 'Préstamos', 'Préstamo para compra de vehículo', 0.1800, 12, 84, 20000.00, 1000000.00, TRUE),
    ('INV-001', 'Plazo Fijo', 'Inversiones', 'Inversión a plazo fijo', 0.4500, 30, 365, 1000.00, 10000000.00, TRUE),
    ('INV-002', 'Fondo Común de Inversión', 'Inversiones', 'FCI diversificado', 0.3500, 1, 9999, 500.00, 1000000.00, TRUE),
    ('SEG-001', 'Seguro de Vida', 'Seguros', 'Seguro de vida básico', 0.0000, 12, 240, 100.00, 50000.00, TRUE)
    ON CONFLICT (codigo) DO NOTHING;

    -- ===== INSERTAR 15000 TRANSACCIONES (ÚLTIMOS 2 AÑOS) =====
    RAISE NOTICE 'Insertando 15000 transacciones...';
    FOR i IN 1..15000 LOOP
        cuenta_id_var := 1 + (i % 8000);
        tipo_transaccion_var := 1 + (i % 8);
        sucursal_var := 1 + (i % 25);
        fecha_var := CURRENT_DATE - (i % 730) * INTERVAL '1 day';
        
        -- Generar montos realistas según tipo de transacción
        monto_var := CASE tipo_transaccion_var
            WHEN 1 THEN 1000 + (RANDOM() * 50000)::NUMERIC(12,2)     -- Depósitos
            WHEN 2 THEN 500 + (RANDOM() * 10000)::NUMERIC(12,2)      -- Retiros
            WHEN 3 THEN 1000 + (RANDOM() * 25000)::NUMERIC(12,2)     -- Transferencias
            WHEN 4 THEN 100 + (RANDOM() * 5000)::NUMERIC(12,2)       -- Pagos servicios
            WHEN 5 THEN 500 + (RANDOM() * 3000)::NUMERIC(12,2)       -- Débitos automáticos
            WHEN 6 THEN 20000 + (RANDOM() * 80000)::NUMERIC(12,2)    -- Acreditaciones salario
            WHEN 7 THEN 50 + (RANDOM() * 2000)::NUMERIC(12,2)        -- Compras
            ELSE 100 + (RANDOM() * 1000)::NUMERIC(12,2)              -- Intereses
        END;

        INSERT INTO transacciones_banco (
            numero_transaccion, cuenta_origen_id, cuenta_destino_id, tipo_transaccion_id,
            monto, descripcion, fecha_transaccion, hora_transaccion, sucursal_id, estado,
            saldo_anterior_origen, saldo_nuevo_origen
        ) VALUES (
            'TXN-' || TO_CHAR(fecha_var, 'YYYY-MM') || '-' || LPAD(i::TEXT, 6, '0'),
            CASE WHEN tipo_transaccion_var IN (2, 3, 4, 5, 7) THEN cuenta_id_var ELSE NULL END,
            CASE WHEN tipo_transaccion_var IN (1, 3, 6, 8) THEN cuenta_id_var ELSE NULL END,
            tipo_transaccion_var,
            monto_var,
            CASE tipo_transaccion_var
                WHEN 1 THEN 'Depósito ' || CASE WHEN i % 3 = 0 THEN 'en efectivo' WHEN i % 3 = 1 THEN 'por transferencia' ELSE 'por cheque' END
                WHEN 2 THEN 'Retiro ' || CASE WHEN i % 2 = 0 THEN 'en cajero automático' ELSE 'en ventanilla' END
                WHEN 3 THEN 'Transferencia ' || CASE WHEN i % 2 = 0 THEN 'a terceros' ELSE 'entre cuentas propias' END
                WHEN 4 THEN 'Pago de ' || CASE WHEN i % 4 = 0 THEN 'luz' WHEN i % 4 = 1 THEN 'gas' WHEN i % 4 = 2 THEN 'agua' ELSE 'internet' END
                WHEN 5 THEN 'Débito automático ' || CASE WHEN i % 3 = 0 THEN 'tarjeta de crédito' WHEN i % 3 = 1 THEN 'préstamo' ELSE 'seguro' END
                WHEN 6 THEN 'Acreditación ' || CASE WHEN i % 2 = 0 THEN 'salario' ELSE 'jubilación' END
                WHEN 7 THEN 'Compra en ' || CASE WHEN i % 3 = 0 THEN 'supermercado' WHEN i % 3 = 1 THEN 'farmacia' ELSE 'comercio' END
                ELSE 'Pago de intereses cuenta de ahorros'
            END,
            fecha_var,
            TIME '08:00:00' + (i % 720) * INTERVAL '1 minute',
            sucursal_var,
            CASE WHEN i % 1000 = 0 THEN 'pendiente' WHEN i % 500 = 0 THEN 'rechazada' ELSE 'completada' END,
            10000 + (RANDOM() * 50000)::NUMERIC(12,2),
            10000 + (RANDOM() * 50000)::NUMERIC(12,2)
        );
    END LOOP;

    -- ===== INSERTAR 2000 PRÉSTAMOS =====
    RAISE NOTICE 'Insertando 2000 préstamos...';
    FOR i IN 1..2000 LOOP
        cliente_id_var := 1 + (i % 5000);
        
        INSERT INTO prestamos (
            numero_prestamo, cliente_id, producto_id, monto, tasa_interes, plazo_meses,
            cuota_mensual, fecha_otorgamiento, fecha_vencimiento, saldo_pendiente, sucursal_id, estado
        ) VALUES (
            'PREST-' || EXTRACT(YEAR FROM CURRENT_DATE)::TEXT || '-' || LPAD(i::TEXT, 6, '0'),
            cliente_id_var,
            1 + (i % 3),
            CASE 
                WHEN i % 3 = 0 THEN 50000 + (RANDOM() * 200000)::NUMERIC(12,2)   -- Préstamo personal
                WHEN i % 3 = 1 THEN 500000 + (RANDOM() * 2000000)::NUMERIC(12,2) -- Préstamo hipotecario
                ELSE 100000 + (RANDOM() * 500000)::NUMERIC(12,2)                 -- Préstamo automotor
            END,
            CASE 
                WHEN i % 3 = 0 THEN 0.25  -- Personal
                WHEN i % 3 = 1 THEN 0.12  -- Hipotecario
                ELSE 0.18                 -- Automotor
            END,
            CASE 
                WHEN i % 3 = 0 THEN 12 + (i % 48)   -- Personal: 12-60 meses
                WHEN i % 3 = 1 THEN 120 + (i % 240) -- Hipotecario: 120-360 meses
                ELSE 12 + (i % 72)                  -- Automotor: 12-84 meses
            END,
            1000 + (RANDOM() * 5000)::NUMERIC(12,2),
            CURRENT_DATE - (i % 365) * INTERVAL '1 day',
            CURRENT_DATE + (1000 + (i % 2000)) * INTERVAL '1 day',
            (50000 + (RANDOM() * 500000))::NUMERIC(12,2),
            1 + (i % 25),
            CASE WHEN i % 50 = 0 THEN 'cancelado' WHEN i % 100 = 0 THEN 'vencido' ELSE 'activo' END
        );
    END LOOP;
    
    RAISE NOTICE 'Préstamos insertados: %', (SELECT COUNT(*) FROM prestamos);

    -- ===== INSERTAR TARJETAS (5000 TARJETAS) =====
    RAISE NOTICE 'Insertando 5000 tarjetas...';
    FOR i IN 1..5000 LOOP
        cliente_id_var := 1 + (i % 5000);
        
        INSERT INTO tarjetas (numero, cliente_id, cuenta_id, tipo, fecha_emision, fecha_vencimiento, limite_credito) VALUES
        ('4532-' || LPAD((1000 + (i / 1000))::TEXT, 3, '0') || '-' || LPAD((i % 1000)::TEXT, 3, '0') || '-' || LPAD((i % 100)::TEXT, 3, '0'),
         cliente_id_var,
         1 + (i % 8000),
         CASE WHEN i % 3 = 0 THEN 'crédito' ELSE 'débito' END,
         CURRENT_DATE - (i % 365) * INTERVAL '1 day',
         CURRENT_DATE + (365 + (i % 365)) * INTERVAL '1 day',
         CASE WHEN i % 3 = 0 THEN 50000 + (RANDOM() * 150000)::NUMERIC(12,2) ELSE NULL END
        );
    END LOOP;
    
    RAISE NOTICE 'Tarjetas insertadas: %', (SELECT COUNT(*) FROM tarjetas);
END $$;

\echo '✅ Datos masivos insertados en banco_global';
\echo '📊 Resumen de datos:';
\echo '   - 5000 clientes activos';
\echo '   - 8000 cuentas (200 con saldo >50.000)';
\echo '   - 100+ clientes con múltiples cuentas';
\echo '   - 15000 transacciones (últimos 2 años)';
\echo '   - 36 depósitos distribuidos en 12 meses';
\echo '   - 2000 préstamos activos';
\echo '   - 5000 tarjetas emitidas';