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
('INTERES', 'Pago de Intereses', 'Pago de intereses de cuenta de ahorros', FALSE, 0.00),
('COMISION', 'Comisión Bancaria', 'Cobro de comisiones', FALSE, 0.00),
('PREST_DESEM', 'Desembolso Préstamo', 'Desembolso de préstamo aprobado', FALSE, 0.00),
('PREST_PAGO', 'Pago Préstamo', 'Pago de cuota de préstamo', FALSE, 0.00),
('TC_PAGO', 'Pago Tarjeta Crédito', 'Pago de tarjeta de crédito', FALSE, 0.00)
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

-- ===== PRODUCTOS BANCARIOS =====
INSERT INTO productos_bancarios (codigo, nombre, categoria, descripcion, tasa_interes, plazo_minimo, plazo_maximo, monto_minimo, monto_maximo, activo) VALUES
('PREST-001', 'Préstamo Personal', 'Préstamos', 'Préstamo personal para diversos fines', 0.2500, 12, 60, 10000.00, 500000.00, TRUE),
('PREST-002', 'Préstamo Hipotecario', 'Préstamos', 'Préstamo para compra de vivienda', 0.1200, 120, 360, 50000.00, 5000000.00, TRUE),
('PREST-003', 'Préstamo Automotor', 'Préstamos', 'Préstamo para compra de vehículo', 0.1800, 12, 84, 20000.00, 1000000.00, TRUE),
('PREST-004', 'Préstamo Prendario', 'Préstamos', 'Préstamo con garantía prendaria', 0.2200, 12, 48, 5000.00, 300000.00, TRUE),
('INV-001', 'Plazo Fijo', 'Inversiones', 'Inversión a plazo fijo', 0.4500, 30, 365, 1000.00, 10000000.00, TRUE),
('INV-002', 'Fondo Común de Inversión', 'Inversiones', 'FCI diversificado', 0.3500, 1, 9999, 500.00, 1000000.00, TRUE),
('SEG-001', 'Seguro de Vida', 'Seguros', 'Seguro de vida básico', 0.0000, 12, 240, 100.00, 50000.00, TRUE),
('SEG-002', 'Seguro Automotor', 'Seguros', 'Seguro para vehículos', 0.0000, 12, 12, 500.00, 100000.00, TRUE)
ON CONFLICT (codigo) DO NOTHING;

-- ===== FUNCIÓN PARA GENERAR DATOS MASIVOS REALISTAS =====
DO $$
DECLARE
    i INTEGER;
    j INTEGER;
    k INTEGER;
    cliente_id_var INTEGER;
    cuenta_id_var INTEGER;
    cuenta_destino_var INTEGER;
    tipo_cuenta_var INTEGER;
    sucursal_var INTEGER;
    tipo_transaccion_var INTEGER;
    monto_var NUMERIC;
    fecha_var DATE;
    hora_var TIME;
    saldo_cuenta NUMERIC;
    saldo_anterior NUMERIC;
    saldo_nuevo NUMERIC;
    comision_var NUMERIC;
    prestamo_id_var INTEGER;
    cuota_num INTEGER;
    
    -- Arrays de datos realistas
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
    comercios TEXT[] := ARRAY['Supermercado Día', 'Carrefour', 'Farmacity', 'Farmacia del Ahorro', 'YPF', 'Shell',
                             'McDonald''s', 'Burger King', 'Starbucks', 'Librería Yenny', 'Musimundo', 'Frávega',
                             'Easy', 'Garbarino', 'Mercado Libre Envíos', 'Rappi', 'PedidosYa', 'Uber'];
    servicios TEXT[] := ARRAY['Edesur (Luz)', 'Edenor (Luz)', 'Metrogas (Gas)', 'AySA (Agua)', 'Telecom (Internet)',
                             'Claro (Celular)', 'Movistar (Celular)', 'Personal (Celular)', 'Cablevisión', 'DirecTV'];
BEGIN
    -- ===== INSERTAR 5000 CLIENTES =====
    RAISE NOTICE '📊 Insertando 5000 clientes...';
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
        
        -- Progreso cada 1000 clientes
        IF i % 1000 = 0 THEN
            RAISE NOTICE '   ✓ % clientes insertados...', i;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ Total clientes insertados: %', (SELECT COUNT(*) FROM clientes);

    -- ===== INSERTAR 8000 CUENTAS CON SALDOS INICIALES REALISTAS =====
    RAISE NOTICE '📊 Insertando 8000 cuentas con saldos iniciales...';
    FOR i IN 1..8000 LOOP
        cliente_id_var := 1 + (i % 5000);
        tipo_cuenta_var := 1 + (i % 6);
        sucursal_var := 1 + (i % 25);
        
        -- Generar saldo inicial realista según tipo de cuenta
        saldo_cuenta := CASE tipo_cuenta_var
            WHEN 1 THEN 1000 + (RANDOM() * 15000)::NUMERIC(12,2)      -- Cuenta Corriente: $1K-16K
            WHEN 2 THEN 5000 + (RANDOM() * 50000)::NUMERIC(12,2)      -- Cuenta Ahorros: $5K-55K
            WHEN 3 THEN 50000 + (RANDOM() * 200000)::NUMERIC(12,2)    -- Premium: $50K-250K
            WHEN 4 THEN 10000 + (RANDOM() * 100000)::NUMERIC(12,2)    -- Empresarial: $10K-110K
            WHEN 5 THEN 500000 + (RANDOM() * 2000000)::NUMERIC(12,2)  -- VIP: $500K-2.5M
            ELSE 500 + (RANDOM() * 5000)::NUMERIC(12,2)               -- Joven: $500-5.5K
        END;
        
        INSERT INTO cuentas (
            numero_cuenta, cliente_id, tipo_cuenta_id, sucursal_id, saldo, fecha_apertura, estado
        ) VALUES (
            '4' || LPAD((1000 + (i / 1000))::TEXT, 3, '0') || '-' || LPAD((i % 1000)::TEXT, 3, '0') || '-' || LPAD((i % 100)::TEXT, 3, '0'),
            cliente_id_var,
            tipo_cuenta_var,
            sucursal_var,
            saldo_cuenta,
            DATE '2020-01-01' + (i % 1460) * INTERVAL '1 day',
            CASE WHEN i % 100 = 0 THEN 'inactiva' ELSE 'activa' END
        );
        
        -- Progreso cada 2000 cuentas
        IF i % 2000 = 0 THEN
            RAISE NOTICE '   ✓ % cuentas insertadas...', i;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ Total cuentas insertadas: %', (SELECT COUNT(*) FROM cuentas);

    -- ===== INSERTAR 50000 TRANSACCIONES REALISTAS (ÚLTIMOS 2 AÑOS) =====
    RAISE NOTICE '📊 Insertando 50000 transacciones con saldos coherentes...';
    
    FOR i IN 1..50000 LOOP
        -- Seleccionar cuenta aleatoria
        cuenta_id_var := 1 + (RANDOM() * 7999)::INTEGER;
        sucursal_var := 1 + (i % 25);
        
        -- Obtener saldo actual de la cuenta
        SELECT saldo INTO saldo_cuenta FROM cuentas WHERE id = cuenta_id_var;
        saldo_anterior := saldo_cuenta;
        
        -- Generar fecha/hora realista (más transacciones recientes)
        fecha_var := CASE 
            WHEN i % 10 < 7 THEN CURRENT_DATE - (RANDOM() * 180)::INTEGER
            WHEN i % 10 < 9 THEN CURRENT_DATE - (180 + (RANDOM() * 180)::INTEGER)
            ELSE CURRENT_DATE - (360 + (RANDOM() * 365)::INTEGER)
        END;
        
        -- Horario bancario realista (8:00 - 20:00)
        hora_var := TIME '08:00:00' + (
            CASE 
                WHEN i % 10 < 3 THEN (RANDOM() * 240)::INTEGER
                WHEN i % 10 < 7 THEN (240 + (RANDOM() * 240)::INTEGER)
                ELSE (480 + (RANDOM() * 240)::INTEGER)
            END
        ) * INTERVAL '1 minute';
        
        -- Determinar tipo de transacción
        tipo_transaccion_var := CASE 
            WHEN i % 100 < 5 THEN 1
            WHEN i % 100 < 15 THEN 2
            WHEN i % 100 < 25 THEN 3
            WHEN i % 100 < 45 THEN 4
            WHEN i % 100 < 52 THEN 5
            WHEN i % 100 < 55 THEN 6
            WHEN i % 100 < 90 THEN 7
            WHEN i % 100 < 95 THEN 8
            WHEN i % 100 < 98 THEN 9
            ELSE 11
        END;
        
        -- Generar montos realistas
        monto_var := CASE tipo_transaccion_var
            WHEN 1 THEN 500 + (RANDOM() * LEAST(50000, saldo_anterior * 0.5))::NUMERIC(12,2)
            WHEN 2 THEN 200 + (RANDOM() * LEAST(5000, saldo_anterior * 0.3))::NUMERIC(12,2)
            WHEN 3 THEN 500 + (RANDOM() * LEAST(20000, saldo_anterior * 0.4))::NUMERIC(12,2)
            WHEN 4 THEN 100 + (RANDOM() * 3000)::NUMERIC(12,2)
            WHEN 5 THEN CASE 
                WHEN i % 4 = 0 THEN 5000 + (RANDOM() * 2000)::NUMERIC(12,2)
                WHEN i % 4 = 1 THEN 1500 + (RANDOM() * 500)::NUMERIC(12,2)
                WHEN i % 4 = 2 THEN 800 + (RANDOM() * 400)::NUMERIC(12,2)
                ELSE 300 + (RANDOM() * 200)::NUMERIC(12,2)
            END
            WHEN 6 THEN 50000 + (RANDOM() * 150000)::NUMERIC(12,2)
            WHEN 7 THEN 50 + (RANDOM() * 5000)::NUMERIC(12,2)
            WHEN 8 THEN (saldo_anterior * (0.005 + RANDOM() * 0.015))::NUMERIC(12,2)
            WHEN 9 THEN 5 + (RANDOM() * 50)::NUMERIC(12,2)
            ELSE 2000 + (RANDOM() * 8000)::NUMERIC(12,2)
        END;
        
        -- Obtener comisión
        SELECT comision INTO comision_var FROM tipos_transaccion WHERE id = tipo_transaccion_var;
        
        -- Calcular nuevo saldo
        saldo_nuevo := CASE 
            WHEN tipo_transaccion_var IN (1, 6, 8) THEN saldo_anterior + monto_var
            WHEN tipo_transaccion_var IN (2, 3, 4, 5, 7, 9, 11) THEN 
                GREATEST(0, saldo_anterior - monto_var - COALESCE(comision_var, 0))
            ELSE saldo_anterior
        END;
        
        -- Solo insertar si la transacción es válida
        IF saldo_nuevo >= 0 OR tipo_transaccion_var IN (1, 6, 8) THEN
            cuenta_destino_var := CASE 
                WHEN tipo_transaccion_var = 3 THEN 1 + (RANDOM() * 7999)::INTEGER
                WHEN tipo_transaccion_var IN (1, 6, 8) THEN cuenta_id_var
                ELSE NULL
            END;
            
            INSERT INTO transacciones_banco (
                numero_transaccion, 
                cuenta_origen_id, 
                cuenta_destino_id, 
                tipo_transaccion_id,
                monto, 
                descripcion, 
                fecha_transaccion, 
                hora_transaccion, 
                sucursal_id, 
                estado,
                saldo_anterior_origen, 
                saldo_nuevo_origen
            ) VALUES (
                'TXN-' || TO_CHAR(fecha_var, 'YYYY-MM-DD') || '-' || LPAD(i::TEXT, 8, '0'),
                CASE WHEN tipo_transaccion_var IN (2, 3, 4, 5, 7, 9, 11) THEN cuenta_id_var ELSE NULL END,
                cuenta_destino_var,
                tipo_transaccion_var,
                monto_var,
                CASE tipo_transaccion_var
                    WHEN 1 THEN 'Depósito ' || CASE WHEN i % 3 = 0 THEN 'en efectivo' WHEN i % 3 = 1 THEN 'por transferencia' ELSE 'por cheque' END
                    WHEN 2 THEN 'Retiro ' || CASE WHEN i % 2 = 0 THEN 'en cajero automático' ELSE 'en ventanilla' END
                    WHEN 3 THEN 'Transferencia ' || CASE WHEN i % 2 = 0 THEN 'a terceros' ELSE 'entre cuentas propias' END
                    WHEN 4 THEN 'Pago: ' || servicios[1 + (i % array_length(servicios, 1))]
                    WHEN 5 THEN 'Débito automático: ' || CASE 
                        WHEN i % 4 = 0 THEN 'Tarjeta de crédito VISA'
                        WHEN i % 4 = 1 THEN 'Cuota préstamo personal'
                        WHEN i % 4 = 2 THEN 'Seguro de vida'
                        ELSE 'Suscripción ' || CASE WHEN i % 3 = 0 THEN 'Netflix' WHEN i % 3 = 1 THEN 'Spotify' ELSE 'Amazon Prime' END
                    END
                    WHEN 6 THEN 'Acreditación ' || CASE WHEN i % 3 = 0 THEN 'salario' WHEN i % 3 = 1 THEN 'jubilación' ELSE 'honorarios profesionales' END
                    WHEN 7 THEN 'Compra: ' || comercios[1 + (i % array_length(comercios, 1))]
                    WHEN 8 THEN 'Pago de intereses - Cuenta de ahorros'
                    WHEN 9 THEN 'Comisión ' || CASE WHEN i % 3 = 0 THEN 'mantenimiento cuenta' WHEN i % 3 = 1 THEN 'uso cajero' ELSE 'transferencia' END
                    ELSE 'Pago cuota préstamo #' || (1 + (i % 60))::TEXT
                END,
                fecha_var,
                hora_var,
                sucursal_var,
                CASE 
                    WHEN i % 500 = 0 THEN 'pendiente'
                    WHEN i % 1000 = 0 THEN 'rechazada'
                    ELSE 'completada'
                END,
                saldo_anterior,
                saldo_nuevo
            );
            
            -- Actualizar saldo de la cuenta
            IF (i % 500 <> 0) AND (i % 1000 <> 0) THEN
                UPDATE cuentas SET saldo = saldo_nuevo WHERE id = cuenta_id_var;
            END IF;
        END IF;
        
        -- Progreso cada 10000 transacciones
        IF i % 10000 = 0 THEN
            RAISE NOTICE '   ✓ % transacciones insertadas...', i;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ Total transacciones insertadas: %', (SELECT COUNT(*) FROM transacciones_banco);

    -- ===== INSERTAR 3000 PRÉSTAMOS =====
    RAISE NOTICE '📊 Insertando 3000 préstamos...';
    FOR i IN 1..3000 LOOP
        cliente_id_var := 1 + (i % 5000);
        
        monto_var := CASE 
            WHEN i % 4 = 0 THEN 50000 + (RANDOM() * 200000)::NUMERIC(12,2)
            WHEN i % 4 = 1 THEN 500000 + (RANDOM() * 2000000)::NUMERIC(12,2)
            WHEN i % 4 = 2 THEN 100000 + (RANDOM() * 500000)::NUMERIC(12,2)
            ELSE 20000 + (RANDOM() * 100000)::NUMERIC(12,2)
        END;
        
        INSERT INTO prestamos (
            numero_prestamo, cliente_id, producto_id, monto, tasa_interes, plazo_meses,
            cuota_mensual, fecha_otorgamiento, fecha_vencimiento, saldo_pendiente, sucursal_id, estado
        ) VALUES (
            'PREST-' || EXTRACT(YEAR FROM CURRENT_DATE)::TEXT || '-' || LPAD(i::TEXT, 6, '0'),
            cliente_id_var,
            1 + (i % 4),
            monto_var,
            CASE WHEN i % 4 = 0 THEN 0.25 WHEN i % 4 = 1 THEN 0.12 WHEN i % 4 = 2 THEN 0.18 ELSE 0.22 END,
            CASE WHEN i % 4 = 0 THEN 12 + (i % 48) WHEN i % 4 = 1 THEN 120 + (i % 240) WHEN i % 4 = 2 THEN 12 + (i % 72) ELSE 12 + (i % 36) END,
            (monto_var * (1 + CASE WHEN i % 4 = 0 THEN 0.25 WHEN i % 4 = 1 THEN 0.12 WHEN i % 4 = 2 THEN 0.18 ELSE 0.22 END) / 
                CASE WHEN i % 4 = 0 THEN (12 + (i % 48)) WHEN i % 4 = 1 THEN (120 + (i % 240)) WHEN i % 4 = 2 THEN (12 + (i % 72)) ELSE (12 + (i % 36)) END)::NUMERIC(12,2),
            CURRENT_DATE - (i % 730) * INTERVAL '1 day',
            CURRENT_DATE + (1000 + (i % 2000)) * INTERVAL '1 day',
            monto_var * (0.5 + RANDOM() * 0.5),
            1 + (i % 25),
            CASE WHEN i % 100 = 0 THEN 'cancelado' WHEN i % 200 = 0 THEN 'vencido' WHEN i % 50 = 0 THEN 'en mora' ELSE 'activo' END
        );
        
        IF i % 1000 = 0 THEN
            RAISE NOTICE '   ✓ % préstamos insertados...', i;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ Total préstamos insertados: %', (SELECT COUNT(*) FROM prestamos);

    -- ===== INSERTAR 6000 TARJETAS =====
    RAISE NOTICE '📊 Insertando 6000 tarjetas...';
    FOR i IN 1..6000 LOOP
        cliente_id_var := 1 + (i % 5000);
        
        INSERT INTO tarjetas (
            numero, cliente_id, cuenta_id, tipo, fecha_emision, fecha_vencimiento, 
            limite_credito, saldo_utilizado, estado, cvv
        ) 
        SELECT 
            '4532-' || LPAD((1000 + (i / 1000))::TEXT, 4, '0') || '-' || LPAD((i % 1000)::TEXT, 4, '0') || '-' || LPAD((i % 10000)::TEXT, 4, '0'),
            cliente_id_var,
            c.id,
            CASE WHEN i % 3 = 0 THEN 'crédito' ELSE 'débito' END,
            CURRENT_DATE - (i % 730) * INTERVAL '1 day',
            CURRENT_DATE + (365 + (i % 1095)) * INTERVAL '1 day',
            CASE WHEN i % 3 = 0 THEN 
                CASE 
                    WHEN c.saldo > 100000 THEN 100000 + (RANDOM() * 200000)::NUMERIC(12,2)
                    WHEN c.saldo > 50000 THEN 50000 + (RANDOM() * 100000)::NUMERIC(12,2)
                    ELSE 20000 + (RANDOM() * 50000)::NUMERIC(12,2)
                END
            ELSE NULL END,
            CASE WHEN i % 3 = 0 THEN (RANDOM() * 30000)::NUMERIC(12,2) ELSE 0 END,
            CASE WHEN i % 100 = 0 THEN 'bloqueada' WHEN i % 200 = 0 THEN 'vencida' ELSE 'activa' END,
            LPAD((100 + (i % 900))::TEXT, 3, '0')
        FROM cuentas c
        WHERE c.cliente_id = cliente_id_var
        ORDER BY c.saldo DESC
        LIMIT 1;
        
        IF i % 2000 = 0 THEN
            RAISE NOTICE '   ✓ % tarjetas insertadas...', i;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ Total tarjetas insertadas: %', (SELECT COUNT(*) FROM tarjetas);

    -- ===== ACTUALIZAR ESTADÍSTICAS =====
    RAISE NOTICE '📊 Actualizando estadísticas de la base de datos...';
    ANALYZE clientes;
    ANALYZE cuentas;
    ANALYZE transacciones_banco;
    ANALYZE prestamos;
    ANALYZE tarjetas;
    
    RAISE NOTICE '🎉 ¡Proceso completado exitosamente!';
    
END $$;

\echo '';
\echo '✅ Datos masivos insertados en banco_global';
\echo '📊 Resumen Final:';
\echo '   ✓ 5,000 clientes (95% activos)';
\echo '   ✓ 8,000 cuentas con saldos coherentes';
\echo '   ✓ 50,000 transacciones realistas (últimos 2 años)';
\echo '   ✓ 3,000 préstamos con historial';
\echo '   ✓ 6,000 tarjetas (débito y crédito)';
\echo '';