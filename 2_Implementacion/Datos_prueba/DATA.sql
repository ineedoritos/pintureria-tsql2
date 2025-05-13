USE PintureriaDB;
GO

-- =============================================
-- Datos de prueba corregidos
-- =============================================

-- ----------------------------
-- 1. Insertar Clientes (5 registros)
-- ----------------------------
-- Estos DUIs son los que se usarán en las tablas relacionadas
INSERT INTO Clientes (DUI, nombre, telefono, email) VALUES
('123456785', 'Ana López', '78945612', 'ana@mail.com'),
('234567890', 'Carlos Rivas', '74185296', 'carlos@mail.com'),
('345678906', 'María Gómez', '75315982', 'maria@mail.com'),
('456789011', 'Pedro Martínez', '78963214', 'pedro@mail.com'),
('567890127', 'Luisa Ramírez', '76543210', 'luisa@mail.com');

-- ----------------------------
-- 2. Insertar Empleados (3 registros)
-- ----------------------------
INSERT INTO Empleados (DUI, nombre, fecha_nacimiento, puesto) VALUES
('678901232', 'Jorge Campos', '1990-05-15', 'Vendedor'),
('789012348', 'Marta Rodríguez', '1985-12-01', 'Gerente'),
('890123453', 'Sofía Pérez', '1998-08-20', 'Almacenista');

-- ----------------------------
-- 3. Insertar Direcciones (2 por cliente) - CORREGIDO
-- Usar los DUIs que existen en la tabla Clientes
-- ----------------------------
-- Declarar variables con los DUIs que SÍ existen en la tabla Clientes
DECLARE @dui_ana VARCHAR(10) = '123456785';
DECLARE @dui_carlos VARCHAR(10) = '234567890';
DECLARE @dui_maria VARCHAR(10) = '345678906';
DECLARE @dui_pedro VARCHAR(10) = '456789011';
DECLARE @dui_luisa VARCHAR(10) = '567890127';


INSERT INTO Direcciones (DUI_cliente, direccion, ciudad, tipo_direccion) VALUES
(@dui_ana, 'Calle 123, Col. Centro', 'San Salvador', 'Casa'),
(@dui_ana, 'Avenida 456, Residencial Las Flores', 'Santa Tecla', 'Trabajo'),
(@dui_carlos, 'Calle Principal 789', 'Soyapango', 'Casa'),
(@dui_maria, 'Pasaje 10, Col. Modelo', 'San Miguel', 'Otro'),
(@dui_pedro, 'Boulevard Los Próceres 555', 'Antiguo Cuscatlán', 'Casa'),
(@dui_luisa, 'Avenida España 22', 'San Salvador', 'Trabajo');

-- ----------------------------
-- 4. Insertar Productos (10 registros)
-- ----------------------------
INSERT INTO Productos (nombre, precio, stock) VALUES
('Pintura Acrílica Blanca', 25.99, 50),
('Barniz para Madera', 18.50, 30),
('Rodillo de Lana', 8.75, 100),
('Lija Grano 120', 2.99, 200),
('Brocha de Cerda Natural', 12.00, 80),
('Pintura en Aerosol Negro', 15.99, 60),
('Guantes de Látex', 4.50, 150),
('Cinta Métrica 5m', 6.25, 90),
('Espátula de Acero', 9.99, 70),
('Desengrasante Multiusos', 10.50, 40);

-- ----------------------------
-- 5. Insertar Ventas (3 ventas) - CORREGIDO
-- Usar DUIs de clientes que existen
-- ----------------------------
INSERT INTO Ventas (DUI_cliente, id_empleado, fecha_venta) VALUES
('123456785', 1, GETDATE()), -- Usando DUI de Ana López
('234567890', 1, DATEADD(DAY, -7, GETDATE())), -- Usando DUI de Carlos Rivas
('345678906', 2, DATEADD(DAY, -3, GETDATE())); -- Usando DUI de María Gómez


-- ----------------------------
-- 6. Insertar DetalleVentas (productos por venta) - CORREGIDO
-- Obtener los IDs de las ventas recién insertadas de forma más robusta
-- ----------------------------
-- Obtener los IDs de venta basados en los DUIs y fechas aproximadas
DECLARE @id_venta_ana INT = (SELECT TOP 1 id_venta FROM Ventas WHERE DUI_cliente = '123456785' ORDER BY fecha_venta DESC);
DECLARE @id_venta_carlos INT = (SELECT TOP 1 id_venta FROM Ventas WHERE DUI_cliente = '234567890' ORDER BY fecha_venta DESC);
DECLARE @id_venta_maria INT = (SELECT TOP 1 id_venta FROM Ventas WHERE DUI_cliente = '345678906' ORDER BY fecha_venta DESC);


INSERT INTO DetalleVentas (id_venta, id_producto, cantidad, subtotal) VALUES
(@id_venta_ana, 1, 2, (SELECT precio FROM Productos WHERE id_producto = 1) * 2),
(@id_venta_ana, 3, 1, (SELECT precio FROM Productos WHERE id_producto = 3) * 1),
(@id_venta_carlos, 5, 3, (SELECT precio FROM Productos WHERE id_producto = 5) * 3),
(@id_venta_maria, 2, 1, (SELECT precio FROM Productos WHERE id_producto = 2) * 1),
(@id_venta_maria, 4, 5, (SELECT precio FROM Productos WHERE id_producto = 4) * 5);

-- ----------------------------
-- 7. Insertar Envios (asociados a ventas) - CORREGIDO
-- Necesitas obtener los IDs de dirección asociados a los clientes de las ventas.
-- ----------------------------
-- Obtener los IDs de dirección basados en los DUIs y tipo de dirección
DECLARE @id_direccion_ana_casa INT = (SELECT TOP 1 id_direccion FROM Direcciones WHERE DUI_cliente = '123456785' AND tipo_direccion = 'Casa' ORDER BY id_direccion DESC);
DECLARE @id_direccion_carlos_casa INT = (SELECT TOP 1 id_direccion FROM Direcciones WHERE DUI_cliente = '234567890' AND tipo_direccion = 'Casa' ORDER BY id_direccion DESC);
DECLARE @id_direccion_maria_otro INT = (SELECT TOP 1 id_direccion FROM Direcciones WHERE DUI_cliente = '345678906' AND tipo_direccion = 'Otro' ORDER BY id_direccion DESC);


INSERT INTO Envios (id_venta, id_direccion, estado, fecha_envio) VALUES
(@id_venta_ana, @id_direccion_ana_casa, 'Entregado', DATEADD(DAY, 2, (SELECT fecha_venta FROM Ventas WHERE id_venta = @id_venta_ana))),
(@id_venta_carlos, @id_direccion_carlos_casa, 'En camino', DATEADD(DAY, 1, (SELECT fecha_venta FROM Ventas WHERE id_venta = @id_venta_carlos))),
(@id_venta_maria, @id_direccion_maria_otro, 'Pendiente', NULL);

-- ----------------------------
-- 8. Bitácora (se llena automáticamente vía triggers)
-- ----------------------------
-- Ejemplo de registros después de las inserciones:
-- SELECT * FROM Bitacora;

-- Revisar datos insertados
SELECT * FROM Clientes;
SELECT * FROM Ventas v INNER JOIN DetalleVentas dv ON v.id_venta = dv.id_venta;
SELECT * FROM Bitacora;  -- Debe mostrar registros de todas las inserciones
