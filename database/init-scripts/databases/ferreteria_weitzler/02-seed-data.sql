-- ================================================================
-- DATOS DE PRUEBA: FERRETERIA WEITZLER
-- ================================================================
-- Productos reales basados en catálogo de Weitzler
-- ================================================================

\echo '📦 Insertando datos de productos Weitzler...';

-- ===== CATEGORÍAS =====
INSERT INTO categorias (nombre, descripcion, categoria_padre_id) VALUES
('Herramientas Eléctricas', 'Taladros, esmeriles, sierras eléctricas', NULL),
('Herramientas Manuales', 'Llaves, destornilladores, martillos', NULL),
('Construcción', 'Materiales para construcción y obra gruesa', NULL),
('Ferretería General', 'Tornillos, clavos, tarugos', NULL),
('Pisos y Revestimientos', 'Pisos laminados, SPC, cerámicos', NULL),
('Jardín y Exterior', 'Herramientas de jardinería', NULL),
('Decoración', 'Artículos decorativos para el hogar', NULL),
('Seguridad Industrial', 'EPP, guantes, lentes de seguridad', NULL),
('Pinturas y Barnices', 'Pinturas, esmaltes, imprimantes', NULL),
('Electricidad', 'Cables, enchufes, interruptores', NULL);

-- Subcategorías
INSERT INTO categorias (nombre, descripcion, categoria_padre_id) VALUES
('Esmeriles Angulares', 'Amoladoras y esmeriles angulares', 1),
('Brocas y Accesorios', 'Brocas para metal, madera, concreto', 1),
('Llaves y Dados', 'Llaves combinadas, dados hexagonales', 2),
('Sierras Manuales', 'Serruchos, arcos de sierra', 2),
('Pisos SPC', 'Stone Plastic Composite', 5),
('Decoración Navideña', 'Artículos decorativos de temporada', 7),
('Guantes de Seguridad', 'Guantes de trabajo', 8),
('Lentes de Protección', 'Lentes de seguridad industrial', 8),
('Discos de Corte', 'Discos para esmeril angular', 1);

-- ===== MARCAS =====
INSERT INTO marcas (nombre, pais_origen, sitio_web) VALUES
('Makita', 'Japón', 'https://www.makita.com'),
('Fixtec', 'Chile', NULL),
('fjäder', 'Chile', NULL),
('Santini', 'Chile', NULL),
('Bosch', 'Alemania', 'https://www.bosch.com'),
('DeWalt', 'Estados Unidos', 'https://www.dewalt.com'),
('Stanley', 'Estados Unidos', 'https://www.stanley.com'),
('Black & Decker', 'Estados Unidos', 'https://www.blackanddecker.com'),
('Ceresita', 'Chile', 'https://www.ceresita.cl'),
('Tricolor', 'Chile', NULL);

-- ===== PROVEEDORES =====
INSERT INTO proveedores (rut, nombre, contacto, telefono, email, ciudad, region) VALUES
('76.123.456-7', 'Importadora Makita Chile S.A.', 'Juan Pérez', '+56-2-2345-6789', 'ventas@makita.cl', 'Santiago', 'Metropolitana'),
('77.234.567-8', 'Distribuidora Fixtec Ltda.', 'María González', '+56-2-3456-7890', 'contacto@fixtec.cl', 'Santiago', 'Metropolitana'),
('78.345.678-9', 'Pisos fjäder Chile', 'Carlos Rodríguez', '+56-2-4567-8901', 'ventas@fjader.cl', 'Santiago', 'Metropolitana'),
('79.456.789-0', 'Decoraciones Santini', 'Ana López', '+56-2-5678-9012', 'info@santini.cl', 'Santiago', 'Metropolitana'),
('80.567.890-1', 'Pinturas Ceresita S.A.', 'Pedro Soto', '+56-2-6789-0123', 'ventas@ceresita.cl', 'Santiago', 'Metropolitana');

-- ===== SUCURSALES WEITZLER =====
INSERT INTO sucursales (nombre, tipo, direccion, ciudad, telefono, horario_atencion) VALUES
('Weitzler Casa Matriz', 'Casa Matriz', 'Antonio Varas 1112', 'Puerto Montt', '+56-65-2253-548', 'Lun-Vie: 08:30-18:30, Sáb: 08:30-12:30'),
('Weitzler Distribución', 'Distribución', 'Ruta 5 Sur 1012', 'Puerto Varas', '+56-65-2487-200', 'Lun-Vie: 08:30-18:30, Sáb: 08:30-12:30'),
('Weitzler Constructor', 'Constructor', 'Presidente Ibañez 728', 'Puerto Montt', '+56-65-2254-067', 'Lun-Vie: 08:30-18:30, Sáb: 08:30-12:30'),
('Weitzler Osorno', 'Sucursal', 'Bulnes 803', 'Osorno', '+56-64-2233-573', 'Lun-Vie: 08:30-18:30, Sáb: 08:30-12:30'),
('Weitzler Hogar', 'Hogar', 'Urmeneta 855', 'Puerto Montt', '+56-65-2252-505', 'Lun-Vie: 08:30-18:30, Sáb: 08:30-12:30'),
('Weitzler Mueblista', 'Mueblista', 'Diego Portales 850', 'Osorno', '+56-64-2233-573', 'Lun-Vie: 08:30-18:30, Sáb: 08:30-12:30');

-- ===== PRODUCTOS (Basados en catálogo real de Weitzler) =====

-- Herramientas Eléctricas Makita (categoría principal)
INSERT INTO productos (codigo_sku, nombre, descripcion, id_categoria, id_marca, id_proveedor, precio_costo, precio_venta, precio_oferta, descuento_porcentaje, stock_actual, stock_minimo, en_oferta, permite_despacho) VALUES
('MAK-D15986', 'Broca para Vidrio/Cerámica 10 x 80mm 1/4" 14 D-15986 Makita', 'Broca especializada para perforación de vidrio y cerámica, 10mm x 80mm', 3, 1, 1, 4200, 6150, 5290, 14, 45, 30, TRUE, FALSE),
('MAK-9557HNG', 'Esmeril Angular 9557HNG Makita', 'Esmeril angular 4 1/2", 840W, incluye disco de corte', 11, 1, 1, 62000, 88300, 74990, 15, 12, 20, TRUE, FALSE),
('MAK-HP1630', 'Taladro Percutor 5/8" HP1630 Makita', 'Taladro percutor 710W, 5/8 pulgadas, velocidad variable', 1, 1, 1, 48000, 79990, NULL, NULL, 25, NULL, FALSE, TRUE),
('MAK-4329', 'Sierra Caladora 4329 Makita', 'Sierra caladora 450W, cambio de hoja sin herramientas', 1, 1, 1, 42000, 69990, NULL, NULL, 18, NULL, FALSE, TRUE),
('MAK-9069', 'Esmeril Recto 6mm 9069 Makita', 'Esmeril recto 450W, pinza 6mm, 28000 RPM', 1, 1, 1, 38000, 64990, NULL, NULL, 14, NULL, FALSE, TRUE),
('MAK-5017RKB', 'Martillo Demoledor 5017RKB Makita', 'Martillo demoledor 2300W, 68J, SDS-Max, incluye maletín', 1, 1, 1, 385000, 649990, NULL, NULL, 4, NULL, FALSE, FALSE),
('MAK-6271D', 'Atornillador Inalámbrico 6271D Makita', 'Atornillador inalámbrico 7.2V, incluye batería y cargador', 1, 1, 1, 32000, 54990, NULL, NULL, 16, NULL, FALSE, TRUE),
('MAK-UC3541A', 'Motosierra Eléctrica UC3541A Makita', 'Motosierra eléctrica 1800W, espada 35cm, freno cadena', 1, 1, 1, 95000, 159990, NULL, NULL, 7, NULL, FALSE, TRUE),
('MAK-JR3050T', 'Sierra Sable JR3050T Makita', 'Sierra sable 1010W, velocidad variable, cambio rápido hoja', 1, 1, 1, 68000, 115990, NULL, NULL, 9, NULL, FALSE, TRUE),
('MAK-RP1801', 'Fresadora RP1801 Makita', 'Fresadora 1850W, pinza 12mm, velocidad variable', 1, 1, 1, 125000, 209990, NULL, NULL, 5, NULL, FALSE, FALSE),
('MAK-TW0350', 'Llave de Impacto TW0350 Makita', 'Llave de impacto 1/2", 350W, par máximo 300Nm', 1, 1, 1, 78000, 129990, NULL, NULL, 11, NULL, FALSE, TRUE),
('MAK-4350FCT', 'Sierra Caladora 4350FCT Makita', 'Sierra caladora 720W, luz LED, velocidad variable, sistema pendular', 1, 1, 1, 58000, 98990, NULL, NULL, 13, NULL, FALSE, TRUE),
('MAK-9565CV', 'Esmeril Angular 9565CV Makita', 'Esmeril angular 1400W, 5", velocidad variable, arranque suave', 1, 1, 1, 85000, 142990, NULL, NULL, 8, NULL, FALSE, TRUE),
('BSH-GSB550', 'Taladro Percutor GSB 550 Bosch', 'Taladro percutor 550W, mandril 13mm, reversible', 1, 5, 1, 38000, 64990, NULL, NULL, 22, NULL, FALSE, TRUE),
('BSH-GWS9125', 'Esmeril Angular GWS 9-125 Bosch', 'Esmeril angular 900W, 5 pulgadas, protección contra polvo', 1, 5, 1, 52000, 89990, NULL, NULL, 16, NULL, FALSE, TRUE),
('DWT-DWE4120', 'Esmeril Angular DWE4120 DeWalt', 'Esmeril angular 800W, 4 1/2 pulgadas, interruptor deslizante', 1, 6, 1, 58000, 99990, NULL, NULL, 12, NULL, FALSE, TRUE),
('DWT-DWD520', 'Taladro DWD520 DeWalt', 'Taladro 10mm, 600W, velocidad variable, empuñadura lateral', 1, 6, 1, 45000, 76990, NULL, NULL, 19, NULL, FALSE, TRUE),
('BD-TM500', 'Taladro 3/8" TM500 Black & Decker', 'Taladro 500W, 3/8 pulgadas, velocidad única', 1, 8, 1, 28000, 47990, NULL, NULL, 28, NULL, FALSE, TRUE),
('BD-G720', 'Esmeril Angular G720 Black & Decker', 'Esmeril angular 820W, 4 1/2 pulgadas, mango auxiliar', 1, 8, 1, 42000, 71990, NULL, NULL, 15, NULL, FALSE, TRUE);

-- Herramientas Fixtec
INSERT INTO productos (codigo_sku, nombre, descripcion, id_categoria, id_marca, id_proveedor, precio_costo, precio_venta, precio_oferta, descuento_porcentaje, stock_actual, en_oferta, permite_despacho) VALUES
('FXT-FHHS1212', 'Dado Hexagonal 1/2" 12x38mm FHHS1212 Fixtec', 'Dado hexagonal 1/2 pulgada, medida 12mm, largo 38mm', 13, 2, 2, 350, 900, 550, 39, 150, TRUE, FALSE),
('FXT-FHHS1224L', 'Dado Largo Hexagonal 1/2" 24x76mm FHHS1224L Fixtec', 'Dado largo hexagonal 1/2 pulgada, medida 24mm, largo 76mm', 13, 2, 2, 850, 2100, 1290, 39, 85, TRUE, FALSE),
('FXT-FHTK234', 'Set 74 Herramientas + 160 Tarugos/Clavos/Tornillos FHTK234 Fixtec', 'Kit completo de herramientas con maletín, incluye 74 herramientas y 160 accesorios', 2, 2, 2, 20000, 41400, 29990, 28, 28, TRUE, FALSE),
('FXT-FHCPCRV24', 'Llave Punta Corona 24 FHCPCRV24 Fixtec', 'Llave combinada punta-corona 24mm, acero cromo vanadio', 13, 2, 2, 1700, 3400, 2490, 27, 95, TRUE, FALSE),
('FXT-FACD111510', 'Disco de Corte 4 1/2" FACD111510 Fixtec', 'Disco de corte para metal 4.5 pulgadas, alta durabilidad', 19, 2, 2, 140, 290, 200, 31, 450, TRUE, FALSE),
('FXT-FPCG0620', 'Guante de Algodón 10" FPCG0620 Fixtec', 'Guante de trabajo en algodón, talla 10, par', 17, 2, 2, 250, 500, 350, 30, 320, TRUE, FALSE),
('FXT-FPSG03', 'Lente de Seguridad FPSG03 Fixtec', 'Lentes de seguridad transparentes, protección UV', 18, 2, 2, 480, 1000, 690, 31, 180, TRUE, FALSE),
('FXT-CARTONERO', 'Cartonero Fixtec', 'Cuchillo cartonero con cuchilla retráctil, incluye 3 repuestos', 2, 2, 2, 850, 1590, 1190, 25, 140, TRUE, FALSE),
('FXT-FDBG10020', 'Broca para Metal HSS 2.0mm FDBG10020 Fixtec', 'Broca HSS para metal 2.0mm, alta velocidad', 12, 2, 2, 60, 700, 200, 71, 280, TRUE, FALSE),
('FXT-SIERRA12', 'Repuesto Hoja de Sierra 12" para Marco Fixtec', 'Hoja de sierra de repuesto 12 pulgadas para arco', 14, 2, 2, 240, 390, 340, 13, 195, TRUE, FALSE);

-- Pisos fjäder
INSERT INTO productos (codigo_sku, nombre, descripcion, id_categoria, id_marca, id_proveedor, precio_costo, precio_venta, precio_oferta, descuento_porcentaje, unidad_medida, stock_actual, en_oferta, permite_despacho) VALUES
('FJD-ASH-175', 'Piso SPC 5.5mm Ash 1.75m2 fjäder', 'Piso vinílico SPC color Ash, 5.5mm espesor, caja de 1.75m2', 15, 3, 3, 10500, 20342.86, 14851.43, 27, 'm2', 240, TRUE, FALSE),
('FJD-BEECH-175', 'Piso SPC 5.5mm Beech 1.75m2 fjäder', 'Piso vinílico SPC color Beech, 5.5mm espesor, caja de 1.75m2', 15, 3, 3, 10500, 20342.86, 14851.43, 27, 'm2', 185, TRUE, FALSE);

-- Decoración Santini
INSERT INTO productos (codigo_sku, nombre, descripcion, id_categoria, id_marca, id_proveedor, precio_costo, precio_venta, precio_oferta, descuento_porcentaje, stock_actual, stock_minimo, en_oferta, permite_despacho) VALUES
('SNT-BOLAS40', 'Juego 12 Bolas 40mm Santini', 'Set de 12 bolas decorativas navideñas 40mm, colores variados', 16, 4, 4, 1100, 2500, 1690, 32, 68, 50, TRUE, FALSE),
('SNT-PORTAVELA', 'Portavela D13xH27cm Champagne Blues Santini', 'Portavela decorativo color champagne, 13cm diámetro x 27cm alto', 7, 4, 4, 11000, 22990, 15790, 31, 42, 60, TRUE, FALSE);

-- Productos adicionales sin oferta
INSERT INTO productos (codigo_sku, nombre, descripcion, id_categoria, id_marca, id_proveedor, precio_costo, precio_venta, stock_actual, permite_despacho) VALUES
('FXT-MART500', 'Martillo de Carpintero 500g Fixtec', 'Martillo de carpintero con mango de fibra de vidrio, 500 gramos', 2, 2, 2, 4500, 8990, 85, TRUE),
('FXT-FLEX3M', 'Flexómetro 3 Metros Fixtec', 'Huincha de medir 3 metros, cinta de acero con freno', 2, 2, 2, 1800, 3990, 145, TRUE),
('MAK-DHP453', 'Taladro Atornillador Inalámbrico DHP453 Makita', 'Taladro percutor inalámbrico 18V, incluye 2 baterías y cargador', 1, 1, 1, 85000, 149990, 8, FALSE),
('FXT-ALICATE8', 'Alicate Universal 8" Fixtec', 'Alicate universal 8 pulgadas, mango ergonómico', 2, 2, 2, 3200, 6490, 110, TRUE),
('CER-LATEX15', 'Pintura Látex Interior 15L Ceresita', 'Pintura látex lavable para interiores, rendimiento 180m2', 9, 9, 5, 18500, 32990, 45, TRUE),

-- Productos con stock crítico (stock_actual < stock_minimo)
INSERT INTO productos (codigo_sku, nombre, descripcion, id_categoria, id_marca, id_proveedor, precio_costo, precio_venta, stock_actual, stock_minimo, permite_despacho) VALUES
('MAK-GA4530', 'Esmeril Angular 4 1/2" GA4530 Makita', 'Esmeril angular 720W, 11000 RPM, para corte y desbaste', 11, 1, 1, 42000, 69990, 2, 10, TRUE),
('FXT-TORX30', 'Set Puntas Torx 30 Piezas Fixtec', 'Juego de 30 puntas magnéticas Torx, incluye estuche', 13, 2, 2, 3500, 7990, 1, 8, TRUE),
('MAK-BO4556', 'Lijadora Orbital BO4556 Makita', 'Lijadora orbital 200W, base cuadrada, control velocidad', 1, 1, 1, 38000, 62990, 3, 12, TRUE),
('FXT-NIVELLASER', 'Nivel Láser Autonivelante Fixtec', 'Nivel láser con línea horizontal y vertical, alcance 10m', 2, 2, 2, 15000, 29990, 2, 15, TRUE),
('CER-ESMALTE1L', 'Esmalte Sintético Negro 1L Ceresita', 'Esmalte brillante para metal y madera, secado rápido', 9, 9, 5, 5200, 11990, 4, 20, TRUE),
('FXT-EXT5M', 'Extensión Eléctrica 5 Metros Fixtec', 'Extensión eléctrica con 4 enchufes, cable 5m, protección sobrecarga', 10, 2, 2, 4800, 9990, 3, 25, TRUE),
('MAK-M9204', 'Pulidora Recta M9204 Makita', 'Pulidora recta 750W, 25000 RPM, para desbaste y pulido', 11, 1, 1, 48000, 79990, 1, 6, FALSE),
('FXT-SERRUCH22', 'Serrucho 22" Diente Fino Fixtec', 'Serrucho carpintería 22 pulgadas, diente fino, mango ergonómico', 14, 2, 2, 3800, 8490, 4, 18, TRUE),
('MAK-HR2470', 'Taladro Rotomartillo HR2470 Makita', 'Rotomartillo 780W, 3 modos, SDS-Plus, incluye maletín', 1, 1, 1, 95000, 159990, 4, 15, TRUE),
('FXT-NIVEL24', 'Nivel de Burbuja 24" Fixtec', 'Nivel de aluminio 24 pulgadas, 3 burbujas', 2, 2, 2, 4800, 9990, 65, TRUE),
('FXT-SERRUCHO', 'Serrucho Carpintero 22" Fixtec', 'Serrucho para madera 22 pulgadas, mango de plástico', 14, 2, 2, 3500, 7490, 75, TRUE),
('FXT-DESTPUNTA', 'Set 6 Destornilladores Punta Plana/Phillips Fixtec', 'Juego de 6 destornilladores con estuche, puntas planas y phillips', 2, 2, 2, 5500, 11990, 52, TRUE);

-- Más herramientas eléctricas en subcategorías
INSERT INTO productos (codigo_sku, nombre, descripcion, id_categoria, id_marca, id_proveedor, precio_costo, precio_venta, stock_actual, permite_despacho) VALUES
('MAK-BROCAS5P', 'Set 5 Brocas SDS-Plus Makita', 'Juego 5 brocas SDS-Plus para concreto, diámetros variados', 12, 1, 1, 8500, 17990, 42, TRUE),
('BSH-BROCAS13P', 'Set 13 Brocas Metal Titanio Bosch', 'Juego 13 brocas HSS-TiN titanio, 1.5mm a 6.5mm', 12, 5, 1, 12000, 24990, 35, TRUE),
('DWT-BROCAS14P', 'Set 14 Brocas Madera/Metal DeWalt', 'Kit completo brocas para madera y metal, estuche incluido', 12, 6, 1, 15000, 29990, 28, TRUE),
('FXT-DISCOS10P', 'Pack 10 Discos Corte Metal 4.5" Fixtec', 'Pack económico 10 discos corte metal 4 1/2 pulgadas', 19, 2, 2, 2800, 5990, 85, TRUE),
('MAK-DISCOS5P', 'Set 5 Discos Desbaste 4.5" Makita', 'Juego 5 discos desbaste metal 4 1/2 pulgadas, alta durabilidad', 19, 2, 2, 5200, 10990, 52, TRUE),
('BSH-DISCOD230', 'Disco Diamantado 9" Turbo Bosch', 'Disco diamantado 9 pulgadas, corte concreto/ladrillo', 19, 5, 1, 18000, 36990, 18, TRUE);

-- Más productos con stock crítico - variedad de categorías y marcas
INSERT INTO productos (codigo_sku, nombre, descripcion, id_categoria, id_marca, id_proveedor, precio_costo, precio_venta, stock_actual, stock_minimo, permite_despacho) VALUES
('MAK-JS3201', 'Sierra Caladora JS3201 Makita', 'Sierra caladora 720W, velocidad variable, cambio herramienta sin llave', 1, 1, 1, 52000, 89990, 3, 15, TRUE),
('FXT-PINZA10', 'Pinza de Presión 10" Fixtec', 'Pinza de presión tipo vise-grip 10 pulgadas, mordaza ajustable', 2, 2, 2, 4200, 8990, 5, 25, TRUE),
('BSH-GBH220', 'Rotomartillo GBH 2-20 Bosch', 'Rotomartillo profesional 650W, SDS-Plus, reversible', 1, 5, 1, 68000, 119990, 2, 12, TRUE),
('DWT-DCD771', 'Taladro Atornillador DCD771 DeWalt', 'Taladro inalámbrico 20V, 2 velocidades, incluye batería', 1, 6, 1, 72000, 129990, 4, 18, TRUE),
('FXT-BROCAS19', 'Set 19 Brocas Metal/Madera Fixtec', 'Juego completo de brocas HSS y brad point, estuche plástico', 12, 2, 2, 6500, 14990, 8, 30, TRUE),
('STL-FLEX5M', 'Flexómetro 5m PowerLock Stanley', 'Huincha de medir 5 metros, cinta ancha 25mm, freno automático', 2, 7, 2, 5800, 12990, 6, 35, TRUE),
('FXT-PISTOLASIL', 'Pistola Silicona Profesional Fixtec', 'Pistola aplicadora silicona esqueleto, refuerzo metálico', 4, 2, 2, 1800, 4990, 15, 50, TRUE),
('MAK-9005B', 'Esmeril Recto 9005B Makita', 'Esmeril recto 500W, 30000 RPM, pinza 6mm', 11, 1, 1, 38000, 65990, 2, 8, TRUE),
('CER-BARNIZ1L', 'Barniz Marino Ceresita 1L', 'Barniz marino brillante, protección UV, uso exterior', 9, 9, 5, 6200, 13990, 7, 25, TRUE),
('FXT-LLAVING12', 'Llave Inglesa 12" Fixtec', 'Llave ajustable 12 pulgadas, apertura máxima 30mm', 13, 2, 2, 3600, 7990, 10, 40, TRUE),
('BD-KR604', 'Taladro Percutor KR604 Black & Decker', 'Taladro percutor 650W, reversible, selector 2 velocidades', 1, 8, 1, 35000, 59990, 5, 20, TRUE),
('FXT-TARUGO8', 'Caja 100 Tarugos 8mm Fixtec', 'Tarugos plásticos 8mm con tornillos, uso general', 4, 2, 2, 2800, 5990, 18, 60, TRUE),
('MAK-TD0101', 'Rotomartillo TD0101 Makita', 'Rotomartillo ligero 450W, mandril SDS-Plus, velocidad variable', 1, 1, 1, 58000, 99990, 3, 10, TRUE),
('TRI-LATEX4L', 'Pintura Látex Premium 4L Tricolor', 'Látex premium lavable, alto cubrimiento, bajo olor', 9, 10, 5, 8500, 17990, 12, 45, TRUE),
('FXT-SOLDADOR60', 'Soldador Eléctrico 60W Fixtec', 'Cautín eléctrico 60W, punta de cobre, mango aislado', 10, 2, 2, 3200, 6990, 9, 35, TRUE),
('STL-NIVEL60', 'Nivel Torpedo Stanley', 'Nivel torpedo 9 pulgadas, magnético, 3 burbujas', 2, 7, 2, 4500, 9990, 14, 50, TRUE),
('FXT-ARCO12', 'Arco Sierra 12" Ajustable Fixtec', 'Marco sierra ajustable 12 pulgadas, mango ergonómico', 14, 2, 2, 2400, 5490, 11, 45, TRUE),
('CER-OLEO1L', 'Óleo Opaco Blanco 1L Ceresita', 'Pintura al óleo opaca, alto cubrimiento, uso interior/exterior', 9, 9, 5, 7800, 16990, 6, 30, TRUE),
('MAK-9553NB', 'Esmeril Angular 9553NB Makita', 'Esmeril angular 840W, 4 1/2", interruptor deslizante', 11, 1, 1, 59000, 99990, 7, 25, TRUE),
('FXT-MAZOGOMA', 'Mazo de Goma 16oz Fixtec', 'Mazo cabeza goma blanca/negra, mango madera, 16 onzas', 2, 2, 2, 3800, 8490, 16, 55, TRUE);

-- ===== INVENTARIO POR SUCURSAL =====
-- Distribuir inventario en las sucursales
INSERT INTO inventario_sucursal (id_producto, id_sucursal, stock_disponible) VALUES
-- Casa Matriz (principal)
(1, 1, 20), (2, 1, 5), (3, 1, 60), (4, 1, 35), (5, 1, 12),
(6, 1, 180), (7, 1, 120), (8, 1, 75), (9, 1, 55), (10, 1, 140),
(11, 1, 90), (12, 1, 100), (13, 1, 85), (14, 1, 30), (15, 1, 22),
(16, 1, 40), (17, 1, 3), (18, 1, 50), (19, 1, 22), (20, 1, 35),
(21, 1, 28), (22, 1, 32), (23, 1, 25), (24, 1, 2),
-- Distribución Puerto Varas
(1, 2, 15), (3, 2, 45), (6, 2, 85), (7, 2, 60), (11, 2, 80),
(12, 2, 50), (16, 2, 25), (19, 2, 22), (21, 2, 20), (24, 2, 2),
-- Constructor
(2, 3, 4), (5, 3, 8), (9, 3, 110), (10, 3, 35), (17, 3, 3),
(18, 3, 35), (20, 3, 18), (22, 3, 15), (24, 3, 0),
-- Osorno
(1, 4, 10), (3, 4, 45), (4, 4, 25), (6, 4, 55), (8, 4, 40),
(11, 4, 70), (12, 4, 35), (16, 4, 20),
-- Hogar
(13, 5, 26), (14, 5, 16), (21, 5, 12), (22, 5, 15), (23, 5, 18),
-- Mueblista
(11, 6, 35), (12, 6, 45), (13, 6, 12), (14, 6, 10);

-- ===== CLIENTES =====
INSERT INTO clientes (rut, nombre, apellido, email, telefono, ciudad, region, tipo_cliente, descuento_especial) VALUES
('12.345.678-9', 'Juan', 'Pérez García', 'juan.perez@email.com', '+56-9-8765-4321', 'Puerto Montt', 'Los Lagos', 'Particular', 0),
('23.456.789-0', 'María', 'González Silva', 'maria.gonzalez@email.com', '+56-9-7654-3210', 'Puerto Varas', 'Los Lagos', 'Particular', 0),
('34.567.890-1', 'Constructora Sur Ltda.', NULL, 'ventas@constructorasur.cl', '+56-65-234-5678', 'Puerto Montt', 'Los Lagos', 'Empresa', 10),
('45.678.901-2', 'Carlos', 'Rodríguez López', 'carlos.rodriguez@email.com', '+56-9-6543-2109', 'Osorno', 'Los Lagos', 'Constructor', 5),
('56.789.012-3', 'Ana', 'Martínez Rojas', 'ana.martinez@email.com', '+56-9-5432-1098', 'Puerto Montt', 'Los Lagos', 'Particular', 0),
('67.890.123-4', 'Maestranza del Sur S.A.', NULL, 'compras@maestranzasur.cl', '+56-65-345-6789', 'Osorno', 'Los Lagos', 'Empresa', 15),
('78.901.234-5', 'Pedro', 'Soto Muñoz', 'pedro.soto@email.com', '+56-9-4321-0987', 'Puerto Varas', 'Los Lagos', 'Particular', 0),
('89.012.345-6', 'Inmobiliaria Los Lagos', NULL, 'contacto@inmobiliarialagos.cl', '+56-65-456-7890', 'Puerto Montt', 'Los Lagos', 'Empresa', 12);

-- ===== VENTAS =====
-- Ventas de empresas (método: transferencia)
INSERT INTO ventas (id_cliente, fecha_venta, total, metodo_pago, estado) VALUES
(3, '2024-11-15 10:30:00', 425990, 'transferencia', 'completada'),  -- Constructora Sur
(3, '2024-11-22 14:15:00', 189980, 'transferencia', 'completada'),  -- Constructora Sur
(3, '2024-12-01 09:45:00', 567940, 'transferencia', 'completada'),  -- Constructora Sur
(6, '2024-11-18 11:20:00', 890750, 'transferencia', 'completada'),  -- Maestranza del Sur
(6, '2024-11-28 15:30:00', 234560, 'transferencia', 'completada'),  -- Maestranza del Sur
(8, '2024-12-02 10:00:00', 678920, 'transferencia', 'completada'),  -- Inmobiliaria Los Lagos
(8, '2024-12-04 13:45:00', 345670, 'transferencia', 'completada'),  -- Inmobiliaria Los Lagos

-- Ventas de particulares (métodos mixtos: efectivo, tarjeta, transferencia)
INSERT INTO ventas (id_cliente, fecha_venta, total, metodo_pago, estado) VALUES
(1, '2024-11-20 16:30:00', 89990, 'efectivo', 'completada'),   -- Juan Pérez
(1, '2024-11-25 10:15:00', 45990, 'tarjeta', 'completada'),    -- Juan Pérez
(1, '2024-12-03 14:20:00', 127980, 'tarjeta', 'completada'),   -- Juan Pérez
(1, '2024-12-05 09:30:00', 23990, 'efectivo', 'completada'),   -- Juan Pérez
(2, '2024-11-19 11:45:00', 67490, 'tarjeta', 'completada'),    -- María González
(2, '2024-11-30 15:20:00', 189990, 'transferencia', 'completada'), -- María González
(2, '2024-12-04 16:10:00', 34990, 'tarjeta', 'completada'),    -- María González
(4, '2024-11-21 08:30:00', 234560, 'transferencia', 'completada'), -- Carlos Rodríguez
(4, '2024-12-02 12:15:00', 156780, 'transferencia', 'completada'), -- Carlos Rodríguez
(5, '2024-11-23 13:40:00', 78990, 'efectivo', 'completada'),   -- Ana Martínez
(5, '2024-12-01 10:25:00', 45990, 'tarjeta', 'completada'),    -- Ana Martínez
(7, '2024-11-24 14:50:00', 123490, 'tarjeta', 'completada');   -- Pedro Soto

-- ===== DETALLE DE VENTAS =====
-- Detalles Constructora Sur (id_cliente=3)
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES
(1, 1, 2, 89990, 179980),   -- 2 Esmeriles Makita
(1, 5, 10, 3990, 39900),    -- 10 Discos Fixtec
(1, 15, 1, 189990, 189990), -- 1 Taladro Percutor Makita
(2, 8, 5, 11990, 59950),    -- 5 Juegos Destornilladores
(2, 12, 20, 6500, 130000),  -- 20 Cajas Tornillos
(3, 20, 3, 145990, 437970), -- 3 Sierras Circulares Makita
(3, 25, 10, 12990, 129900); -- 10 Metros Cable Eléctrico

-- Detalles Maestranza del Sur (id_cliente=6)
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES
(4, 15, 4, 189990, 759960), -- 4 Taladros Percutores
(4, 8, 10, 11990, 119900),  -- 10 Juegos Destornilladores
(5, 30, 15, 15640, 234600); -- 15 Brocas HSS

-- Detalles Inmobiliaria Los Lagos (id_cliente=8)
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES
(6, 35, 50, 8990, 449500),  -- 50 Candados Yale
(6, 40, 30, 7650, 229500),  -- 30 Cerraduras
(7, 45, 20, 17290, 345800); -- 20 Pinturas Ceresita

-- Detalles Juan Pérez (id_cliente=1) - Tarjeta preferida
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES
(8, 1, 1, 89990, 89990),    -- 1 Esmeril Makita
(9, 5, 10, 3990, 39900),    -- 10 Discos
(9, 10, 1, 5990, 5990),     -- 1 Martillo
(10, 20, 1, 145990, 145990),-- 1 Sierra Circular
(11, 3, 1, 23990, 23990);   -- 1 Caja Herramientas

-- Detalles María González (id_cliente=2) - Tarjeta preferida
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES
(12, 3, 2, 23990, 47980),   -- 2 Cajas Herramientas
(12, 8, 1, 11990, 11990),   -- 1 Juego Destornilladores
(13, 15, 1, 189990, 189990),-- 1 Taladro Percutor
(14, 5, 5, 3990, 19950),    -- 5 Discos
(14, 25, 1, 12990, 12990);  -- 1 Metro Cable

-- Detalles Carlos Rodríguez (id_cliente=4) - Transferencia preferida
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES
(15, 20, 1, 145990, 145990),-- 1 Sierra Circular
(15, 15, 1, 89990, 89990),  -- 1 Taladro
(16, 35, 10, 8990, 89900),  -- 10 Candados
(16, 40, 5, 7650, 38250);   -- 5 Cerraduras

-- Detalles Ana Martínez (id_cliente=5) - Tarjeta preferida
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES
(17, 10, 3, 5990, 17970),   -- 3 Martillos
(17, 45, 2, 17290, 34580),  -- 2 Pinturas
(18, 5, 10, 3990, 39900);   -- 10 Discos

-- Detalles Pedro Soto (id_cliente=7) - Solo 1 compra
INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal) VALUES
(19, 15, 1, 189990, 189990),-- 1 Taladro Percutor
(19, 8, 2, 11990, 23980);   -- 2 Juegos Destornilladores

\echo '✅ Datos de productos Weitzler y ventas insertados exitosamente';
