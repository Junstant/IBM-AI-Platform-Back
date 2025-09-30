-- 13-verify-queries.sql
-- Script de verificación para todas las consultas requeridas

\echo '🔍 Verificando consultas requeridas...'

-- ===== VERIFICACIÓN PETROLERA =====
\c petrolera;
\echo '⛽ Verificando consultas de petrolera...'

\echo 'Query 1: Los primeros 100 pozos que más barriles tienen'
SELECT 
    p.nombre,
    p.ubicacion,
    SUM(e.cantidad_barriles) as total_barriles
FROM pozos p
JOIN extracciones e ON p.id = e.pozo_id
GROUP BY p.id, p.nombre, p.ubicacion
ORDER BY total_barriles DESC
LIMIT 100;

\echo 'Query 2: Todos los equipos que están fuera de servicio'
SELECT 
    tipo,
    marca,
    estado,
    COUNT(*) as cantidad
FROM equipos 
WHERE estado = 'Fuera de servicio'
GROUP BY tipo, marca, estado
ORDER BY cantidad DESC;

-- ===== VERIFICACIÓN BANCO_GLOBAL =====
\c banco_global;
\echo '🏦 Verificando consultas de banco_global...'

\echo 'Query 1: Los 10 préstamos "activos" con montos más altos'
SELECT 
    p.id,
    c.nombre || ' ' || c.apellido as cliente,
    p.monto,
    p.tasa_interes,
    p.fecha_otorgamiento,
    p.estado
FROM prestamos p
JOIN clientes c ON p.cliente_id = c.id
WHERE p.estado = 'activo'
ORDER BY p.monto DESC
LIMIT 10;

\echo 'Query 2: Las 100 transacciones con montos más grandes'
SELECT 
    t.id,
    co.numero_cuenta as cuenta_origen,
    cd.numero_cuenta as cuenta_destino,
    t.monto,
    t.fecha_transaccion,
    tt.nombre as tipo_transaccion
FROM transacciones_banco t
JOIN cuentas co ON t.cuenta_origen_id = co.id
LEFT JOIN cuentas cd ON t.cuenta_destino_id = cd.id
JOIN tipos_transaccion tt ON t.tipo_transaccion_id = tt.id
ORDER BY t.monto DESC
LIMIT 100;

\echo 'Query 3: La cuenta con mayor número de transacciones'
SELECT 
    c.numero_cuenta,
    cl.nombre || ' ' || cl.apellido as propietario,
    COUNT(t.id) as num_transacciones,
    SUM(t.monto) as total_transaccionado
FROM cuentas c
JOIN clientes cl ON c.cliente_id = cl.id
LEFT JOIN transacciones_banco t ON c.id = t.cuenta_origen_id
GROUP BY c.id, c.numero_cuenta, cl.nombre, cl.apellido
ORDER BY num_transacciones DESC
LIMIT 1;

-- ===== VERIFICACIÓN EMPRESA_MINERA =====
\c empresa_minera;
\echo '⛏️ Verificando consultas de empresa_minera...'

\echo 'Query 1: Top 5 de las máquinas más productivas (por cantidad extraída)'
SELECT 
    m.nombre,
    m.tipo,
    SUM(o.cantidad_extraida) as total_extraido,
    COUNT(o.id) as operaciones_realizadas,
    AVG(o.cantidad_extraida) as promedio_por_operacion
FROM maquinas m
JOIN operaciones o ON m.id = o.maquina_id
GROUP BY m.id, m.nombre, m.tipo
ORDER BY total_extraido DESC
LIMIT 5;

\echo 'Query 2: Yacimiento con mayor cantidad de extracciones durante turno de noche el mes pasado'
SELECT 
    y.nombre as yacimiento,
    y.ubicacion,
    COUNT(o.id) as extracciones_nocturnas,
    SUM(o.cantidad_extraida) as total_extraido_noche
FROM yacimientos y
JOIN operaciones o ON y.id = o.yacimiento_id
JOIN turnos t ON o.empleado_id = t.empleado_id AND DATE(o.fecha) = t.fecha
WHERE t.turno = 'Noche' 
  AND o.fecha >= CURRENT_DATE - INTERVAL '1 month'
GROUP BY y.id, y.nombre, y.ubicacion
ORDER BY extracciones_nocturnas DESC
LIMIT 1;

\echo 'Query 3: Ranking de los minerales más vendidos (por cantidad) en lo que va del año'
SELECT 
    m.nombre as mineral,
    SUM(v.cantidad) as cantidad_vendida,
    COUNT(v.id) as numero_ventas,
    SUM(v.monto) as ingresos_totales,
    AVG(v.precio_por_tonelada) as precio_promedio
FROM minerales m
JOIN ventas v ON m.id = v.mineral_id
WHERE EXTRACT(YEAR FROM v.fecha) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY m.id, m.nombre
ORDER BY cantidad_vendida DESC;

-- ===== VERIFICACIÓN SUPERMERCADO =====
\c supermercado;
\echo '🛒 Verificando consultas de supermercado...'

\echo 'Query 1: Total de ventas por sucursal, ordenado de mayor a menor'
SELECT 
    s.nombre as sucursal,
    s.ciudad,
    COUNT(v.id) as cantidad_ventas,
    SUM(v.total) as total_ventas,
    AVG(v.total) as venta_promedio
FROM sucursales s
LEFT JOIN ventas v ON s.id = v.sucursal_id
GROUP BY s.id, s.nombre, s.ciudad
ORDER BY total_ventas DESC;

\echo 'Query 2: Día de la semana con mayor volumen de ventas en promedio'
SELECT 
    CASE EXTRACT(DOW FROM fecha)
        WHEN 0 THEN 'Domingo'
        WHEN 1 THEN 'Lunes'
        WHEN 2 THEN 'Martes'
        WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves'
        WHEN 5 THEN 'Viernes'
        ELSE 'Sábado'
    END as dia_semana,
    COUNT(*) as cantidad_ventas,
    SUM(total) as volumen_total,
    AVG(total) as promedio_por_venta
FROM ventas
GROUP BY EXTRACT(DOW FROM fecha)
ORDER BY volumen_total DESC;

\echo 'Query 3: Valor total del inventario (stock * precio) para cada categoría'
SELECT 
    c.nombre as categoria,
    COUNT(p.id) as productos_en_categoria,
    SUM(p.stock) as stock_total,
    SUM(p.stock * p.precio) as valor_inventario,
    AVG(p.precio) as precio_promedio
FROM categorias c
LEFT JOIN productos p ON c.id = p.categoria_id
GROUP BY c.id, c.nombre
ORDER BY valor_inventario DESC;

-- ===== VERIFICACIÓN EMPRESA_AGRONOMIA =====
\c empresa_agronomia;
\echo '🌾 Verificando consultas de empresa_agronomia...'

\echo 'Query 1: Superficie total (en hectáreas) cultivada para cada tipo de cultivo'
SELECT 
    c.nombre as cultivo,
    c.temporada,
    COUNT(p.id) as parcelas_asignadas,
    SUM(p.tamaño_ha) as superficie_total_ha,
    AVG(p.tamaño_ha) as superficie_promedio_ha,
    c.rendimiento_promedio,
    c.precio_mercado
FROM cultivos c
LEFT JOIN parcelas p ON c.id = p.cultivo_id
GROUP BY c.id, c.nombre, c.temporada, c.rendimiento_promedio, c.precio_mercado
ORDER BY superficie_total_ha DESC;

\echo 'Query 2: Insumo en el que más dinero hemos gastado en el último año'
SELECT 
    i.nombre as insumo,
    i.tipo,
    COUNT(c.id) as compras_realizadas,
    SUM(c.cantidad) as cantidad_total_comprada,
    SUM(c.total) as gasto_total,
    AVG(c.precio_unitario) as precio_promedio,
    MAX(c.fecha) as ultima_compra
FROM insumos i
JOIN compras c ON i.id = c.insumo
WHERE c.fecha >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY i.id, i.nombre, i.tipo
ORDER BY gasto_total DESC
LIMIT 1;

\echo 'Query 3: Historial de precios de compra para el insumo "36"'
SELECT 
    c.fecha,
    c.cantidad,
    c.precio_unitario,
    c.total,
    p.nombre as proveedor,
    i.nombre as insumo_nombre
FROM compras c
JOIN insumos i ON c.insumo = i.id
JOIN proveedores p ON c.proveedor_id = p.id
WHERE i.id = 36
ORDER BY c.fecha DESC
LIMIT 20;

\echo '✅ Todas las consultas verificadas exitosamente';