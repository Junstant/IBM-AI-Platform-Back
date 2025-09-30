-- 03-setup-bank-transactions.sql
-- Esquema para la base de datos bank_transactions (detección de fraude)

\echo 'Configurando esquema para bank_transactions...'

-- Conectar a la base de datos bank_transactions
\c bank_transactions;

-- Crear tabla principal de transacciones para análisis de fraude
CREATE TABLE IF NOT EXISTS transacciones (
    id SERIAL PRIMARY KEY,
    cuenta_origen_id INTEGER NOT NULL,
    cuenta_destino_id INTEGER NOT NULL,
    monto DECIMAL(10,2) NOT NULL,
    comerciante VARCHAR(255) NOT NULL,
    ubicacion VARCHAR(255) NOT NULL,
    tipo_tarjeta VARCHAR(50) NOT NULL,
    horario_transaccion TIME NOT NULL,
    fecha_transaccion DATE NOT NULL,
    es_fraude BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Campos adicionales para análisis más detallado
    canal_transaccion VARCHAR(50), -- 'online', 'cajero', 'pos', 'telefono'
    codigo_comerciante VARCHAR(50),
    categoria_comerciante VARCHAR(100),
    pais_origen VARCHAR(3),
    pais_destino VARCHAR(3),
    ip_origen INET,
    dispositivo_id VARCHAR(100),
    metodo_autenticacion VARCHAR(50),
    monto_usd DECIMAL(10,2),
    
    -- Campos de análisis de riesgo
    score_riesgo DECIMAL(5,4) DEFAULT 0.0000,
    flags_alerta TEXT[], -- Array de flags de alerta
    fecha_procesamiento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_monto_positivo CHECK (monto > 0),
    CONSTRAINT chk_score_riesgo CHECK (score_riesgo >= 0 AND score_riesgo <= 1),
    CONSTRAINT chk_tipo_tarjeta CHECK (tipo_tarjeta IN ('credito', 'debito', 'prepaga')),
    CONSTRAINT chk_canal CHECK (canal_transaccion IN ('online', 'cajero', 'pos', 'telefono', 'mobile'))
);

-- Crear tabla de perfiles de usuario para detección de anomalías
CREATE TABLE IF NOT EXISTS perfiles_usuario (
    cuenta_id INTEGER PRIMARY KEY,
    promedio_transacciones_diarias DECIMAL(8,2) DEFAULT 0.00,
    monto_promedio_transaccion DECIMAL(10,2) DEFAULT 0.00,
    horario_habitual_inicio TIME DEFAULT '09:00:00',
    horario_habitual_fin TIME DEFAULT '18:00:00',
    ubicaciones_frecuentes TEXT[], -- Array de ubicaciones frecuentes
    comerciantes_frecuentes TEXT[], -- Array de comerciantes frecuentes
    dias_activos_semana INTEGER[] DEFAULT '{1,2,3,4,5}', -- 1=Lunes, 7=Domingo
    fecha_primer_transaccion DATE,
    fecha_ultima_transaccion DATE,
    total_transacciones INTEGER DEFAULT 0,
    monto_total_transacciones DECIMAL(15,2) DEFAULT 0.00,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla de comerciantes para enriquecimiento de datos
CREATE TABLE IF NOT EXISTS comerciantes (
    id SERIAL PRIMARY KEY,
    codigo VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(255) NOT NULL,
    categoria VARCHAR(100),
    subcategoria VARCHAR(100),
    ubicacion VARCHAR(255),
    ciudad VARCHAR(100),
    pais VARCHAR(3),
    nivel_riesgo VARCHAR(20) DEFAULT 'bajo', -- bajo, medio, alto
    activo BOOLEAN DEFAULT true,
    fecha_registro DATE DEFAULT CURRENT_DATE
);

-- Crear tabla de reglas de fraude
CREATE TABLE IF NOT EXISTS reglas_fraude (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    condicion JSONB NOT NULL, -- Condición en formato JSON
    peso DECIMAL(5,4) DEFAULT 1.0000,
    activa BOOLEAN DEFAULT true,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Crear tabla de alertas generadas
CREATE TABLE IF NOT EXISTS alertas_fraude (
    id SERIAL PRIMARY KEY,
    transaccion_id INTEGER NOT NULL REFERENCES transacciones(id),
    regla_id INTEGER REFERENCES reglas_fraude(id),
    tipo_alerta VARCHAR(50) NOT NULL,
    severidad VARCHAR(20) DEFAULT 'media', -- baja, media, alta, critica
    score DECIMAL(5,4) NOT NULL,
    descripcion TEXT,
    estado VARCHAR(20) DEFAULT 'pendiente', -- pendiente, revisada, falsa_alarma, confirmada
    fecha_generacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_revision TIMESTAMP,
    revisor VARCHAR(100),
    notas TEXT
);

-- Insertar comerciantes de ejemplo
INSERT INTO comerciantes (codigo, nombre, categoria, subcategoria, ubicacion, ciudad, pais, nivel_riesgo) VALUES
('MERC001', 'SuperMercado Central', 'Retail', 'Supermercado', 'Av. Corrientes 1234', 'Buenos Aires', 'ARG', 'bajo'),
('MERC002', 'Farmacia San Juan', 'Salud', 'Farmacia', 'San Juan 567', 'Buenos Aires', 'ARG', 'bajo'),
('MERC003', 'Shell Estación', 'Combustibles', 'Estación de Servicio', 'Panamericana Km 25', 'Buenos Aires', 'ARG', 'bajo'),
('MERC004', 'Casino Royal', 'Entretenimiento', 'Casino', 'Puerto Madero', 'Buenos Aires', 'ARG', 'alto'),
('MERC005', 'TechStore Online', 'Tecnología', 'E-commerce', 'Online', 'Online', 'ARG', 'medio'),
('MERC006', 'Banco ATM', 'Financiero', 'Cajero Automático', 'Varios', 'Buenos Aires', 'ARG', 'bajo'),
('MERC007', 'Tienda Sospechosa', 'Varios', 'Desconocido', 'Ubicación Remota', 'Desconocida', 'UNK', 'alto');

-- Insertar reglas de fraude básicas
INSERT INTO reglas_fraude (nombre, descripcion, condicion, peso) VALUES
('Monto Alto Inusual', 'Transacción con monto 10x superior al promedio del usuario', 
 '{"tipo": "monto_anomalo", "factor": 10}', 0.8),
 
('Horario Inusual', 'Transacción fuera del horario habitual del usuario',
 '{"tipo": "horario_anomalo", "tolerancia_horas": 2}', 0.6),
 
('Ubicación Sospechosa', 'Transacción en ubicación no frecuente',
 '{"tipo": "ubicacion_anomala", "distancia_km": 100}', 0.7),
 
('Frecuencia Alta', 'Múltiples transacciones en corto período',
 '{"tipo": "frecuencia_alta", "max_transacciones": 5, "periodo_minutos": 30}', 0.9),
 
('Comerciante Alto Riesgo', 'Transacción con comerciante de alto riesgo',
 '{"tipo": "comerciante_riesgo", "nivel_minimo": "alto"}', 0.85);

-- Crear índices para optimizar consultas de detección de fraude
CREATE INDEX idx_transacciones_fecha ON transacciones(fecha_transaccion);
CREATE INDEX idx_transacciones_cuenta_origen ON transacciones(cuenta_origen_id);
CREATE INDEX idx_transacciones_monto ON transacciones(monto);
CREATE INDEX idx_transacciones_fraude ON transacciones(es_fraude);
CREATE INDEX idx_transacciones_comerciante ON transacciones(comerciante);
CREATE INDEX idx_transacciones_ubicacion ON transacciones(ubicacion);
CREATE INDEX idx_transacciones_canal ON transacciones(canal_transaccion);
CREATE INDEX idx_transacciones_score ON transacciones(score_riesgo);

CREATE INDEX idx_alertas_transaccion ON alertas_fraude(transaccion_id);
CREATE INDEX idx_alertas_estado ON alertas_fraude(estado);
CREATE INDEX idx_alertas_severidad ON alertas_fraude(severidad);
CREATE INDEX idx_alertas_fecha ON alertas_fraude(fecha_generacion);

-- Crear vista para análisis de transacciones
CREATE VIEW vista_transacciones_enriquecidas AS
SELECT 
    t.*,
    m.nombre as nombre_comerciante,
    m.categoria,
    m.nivel_riesgo as riesgo_comerciante,
    p.promedio_transacciones_diarias,
    p.monto_promedio_transaccion,
    CASE 
        WHEN t.monto > (p.monto_promedio_transaccion * 5) THEN true 
        ELSE false 
    END as monto_anomalo,
    CASE 
        WHEN t.horario_transaccion < p.horario_habitual_inicio 
             OR t.horario_transaccion > p.horario_habitual_fin THEN true 
        ELSE false 
    END as horario_anomalo
FROM transacciones t
LEFT JOIN comerciantes m ON t.codigo_comerciante = m.codigo
LEFT JOIN perfiles_usuario p ON t.cuenta_origen_id = p.cuenta_id;

-- Crear vista de resumen de alertas
CREATE VIEW vista_resumen_alertas AS
SELECT 
    DATE(fecha_generacion) as fecha,
    tipo_alerta,
    severidad,
    estado,
    COUNT(*) as cantidad,
    AVG(score) as score_promedio
FROM alertas_fraude
GROUP BY DATE(fecha_generacion), tipo_alerta, severidad, estado
ORDER BY fecha DESC, cantidad DESC;

-- Crear función para calcular score de riesgo
CREATE OR REPLACE FUNCTION calcular_score_riesgo(
    p_cuenta_id INTEGER,
    p_monto DECIMAL,
    p_horario TIME,
    p_ubicacion VARCHAR,
    p_comerciante VARCHAR
) RETURNS DECIMAL AS $$
DECLARE
    score DECIMAL(5,4) := 0.0000;
    perfil RECORD;
BEGIN
    -- Obtener perfil del usuario
    SELECT * INTO perfil FROM perfiles_usuario WHERE cuenta_id = p_cuenta_id;
    
    IF perfil IS NULL THEN
        RETURN 0.5000; -- Score neutral para usuarios sin historial
    END IF;
    
    -- Evaluar monto (peso: 30%)
    IF p_monto > (perfil.monto_promedio_transaccion * 10) THEN
        score := score + 0.3000;
    ELSIF p_monto > (perfil.monto_promedio_transaccion * 5) THEN
        score := score + 0.1500;
    END IF;
    
    -- Evaluar horario (peso: 20%)
    IF p_horario < perfil.horario_habitual_inicio OR p_horario > perfil.horario_habitual_fin THEN
        score := score + 0.2000;
    END IF;
    
    -- Evaluar ubicación (peso: 25%)
    IF NOT (p_ubicacion = ANY(perfil.ubicaciones_frecuentes)) THEN
        score := score + 0.2500;
    END IF;
    
    -- Evaluar comerciante (peso: 25%)
    IF NOT (p_comerciante = ANY(perfil.comerciantes_frecuentes)) THEN
        score := score + 0.1250;
    END IF;
    
    -- Verificar comerciante de alto riesgo
    IF EXISTS (SELECT 1 FROM comerciantes WHERE nombre = p_comerciante AND nivel_riesgo = 'alto') THEN
        score := score + 0.2500;
    END IF;
    
    RETURN LEAST(score, 1.0000);
END;
$$ LANGUAGE plpgsql;

-- Insertar algunos datos de ejemplo para testing
INSERT INTO transacciones (cuenta_origen_id, cuenta_destino_id, monto, comerciante, ubicacion, tipo_tarjeta, horario_transaccion, fecha_transaccion, canal_transaccion, es_fraude) VALUES
(1001, 2001, 150.00, 'SuperMercado Central', 'Av. Corrientes 1234', 'debito', '14:30:00', CURRENT_DATE, 'pos', false),
(1001, 2002, 2500.00, 'TechStore Online', 'Online', 'credito', '22:45:00', CURRENT_DATE, 'online', false),
(1002, 2003, 50000.00, 'Casino Royal', 'Puerto Madero', 'credito', '03:15:00', CURRENT_DATE, 'pos', true),
(1003, 2001, 80.00, 'Farmacia San Juan', 'San Juan 567', 'debito', '11:20:00', CURRENT_DATE, 'pos', false),
(1001, 2004, 15000.00, 'Tienda Sospechosa', 'Ubicación Remota', 'credito', '23:30:00', CURRENT_DATE, 'online', true);

-- Insertar perfiles de usuario de ejemplo
INSERT INTO perfiles_usuario (cuenta_id, promedio_transacciones_diarias, monto_promedio_transaccion, ubicaciones_frecuentes, comerciantes_frecuentes) VALUES
(1001, 3.2, 250.00, ARRAY['Av. Corrientes 1234', 'San Juan 567'], ARRAY['SuperMercado Central', 'Farmacia San Juan']),
(1002, 1.8, 800.00, ARRAY['Puerto Madero', 'Palermo'], ARRAY['TechStore Online', 'Banco ATM']),
(1003, 2.5, 180.00, ARRAY['San Juan 567', 'Av. Corrientes 1234'], ARRAY['Farmacia San Juan', 'SuperMercado Central']);

\echo 'Esquema bank_transactions configurado exitosamente con datos de ejemplo'