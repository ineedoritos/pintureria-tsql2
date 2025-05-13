USE pintureriaDB;
GO

-- Eliminar procedimientos de lógica de negocio si existen
DROP PROCEDURE IF EXISTS sp_CalcularTotalVenta;
GO

-- =============================================
-- Descripción: Calcula el total de una venta aplicando descuentos por volumen.
--              Maneja transacciones y errores detallados.
-- Caso de Uso: CU-10 (Proceso de venta)
-- =============================================
CREATE PROCEDURE sp_CalcularTotalVenta
    @id_venta INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @total DECIMAL(10,2),
                @descuento DECIMAL(5,2) = 0;

        -- Paso 1: Calcular subtotal con validación
        SELECT @total = SUM(subtotal)
        FROM DetalleVentas
        WHERE id_venta = @id_venta;

        IF @total IS NULL
            RAISERROR('Error SP07: La venta (ID: %d) no existe o no tiene detalles.', 16, 1, @id_venta);

        -- Paso 2: Aplicar descuento progresivo (CASE)
        SET @descuento = CASE
            WHEN @total > 1000 THEN 0.10  -- 10% para compras > $1000
            WHEN @total > 500 THEN 0.05   -- 5% para compras > $500
            ELSE 0
        END;

        -- Paso 3: Actualizar total en Ventas
        UPDATE Ventas
        SET total = @total * (1 - @descuento)
        WHERE id_venta = @id_venta;

        COMMIT TRANSACTION;
        PRINT CONCAT('Total actualizado: $', @total * (1 - @descuento), ' (Descuento: ', @descuento * 100, '%)');
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @mensaje_error VARCHAR(2000) =
            CONCAT('Error en sp_CalcularTotalVenta (Venta ID: ', @id_venta, '): ', ERROR_MESSAGE());
        RAISERROR(@mensaje_error, 16, 1);
    END CATCH;
END;
GO

-- Eliminar sp_GestionarStock si existe
DROP PROCEDURE IF EXISTS sp_GestionarStock;
GO

-- =============================================
-- Descripción: Actualiza el stock para múltiples productos usando cursor.
--              Valida formato XML y maneja stock negativo.
-- Caso de Uso: CU-12 (Reposición de inventario)
-- =============================================
CREATE PROCEDURE sp_GestionarStock
    @productos XML  -- Formato: <productos><producto id="1" cantidad="5"/></productos>
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Paso 1: Validar estructura XML
        IF @productos.exist('/productos/producto') = 0
            RAISERROR('Error SP08: Formato XML inválido. Use <productos><producto id="X" cantidad="Y"/></productos>', 16, 1);

        -- Paso 2: Crear tabla temporal
        CREATE TABLE #TempProductos (
            ID INT PRIMARY KEY,
            Cantidad INT
        );

        -- Paso 3: Cargar datos desde XML
        INSERT INTO #TempProductos (ID, Cantidad)
        SELECT
            T.Item.value('@id', 'INT'),
            T.Item.value('@cantidad', 'INT')
        FROM @productos.nodes('/productos/producto') AS T(Item);

        -- Paso 4: Procesar con cursor
        DECLARE cur_productos CURSOR LOCAL FOR
            SELECT ID, Cantidad FROM #TempProductos;

        DECLARE @id INT, @cantidad INT;

        OPEN cur_productos;
        FETCH NEXT FROM cur_productos INTO @id, @cantidad;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Validar existencia del producto
            IF NOT EXISTS (SELECT 1 FROM Productos WHERE id_producto = @id)
                RAISERROR('Error SP09: Producto ID %d no encontrado.', 16, 1, @id);

            -- Validar stock resultante
            DECLARE @stock_actual INT;
            SELECT @stock_actual = stock FROM Productos WHERE id_producto = @id;

            IF (@stock_actual + @cantidad) < 0
                RAISERROR('Error SP10: Stock insuficiente para el producto ID %d (Stock actual: %d).', 16, 1, @id, @stock_actual);

            -- Actualizar stock
            UPDATE Productos
            SET stock = stock + @cantidad
            WHERE id_producto = @id;

            FETCH NEXT FROM cur_productos INTO @id, @cantidad;
        END;

        CLOSE cur_productos;
        DEALLOCATE cur_productos;

        COMMIT TRANSACTION;
        PRINT 'Stock actualizado exitosamente.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @mensaje_error VARCHAR(2000) =
            CONCAT('Error en sp_GestionarStock: ', ERROR_MESSAGE());
        RAISERROR(@mensaje_error, 16, 1);
    END CATCH;
END;
GO

-- Eliminar sp_RegistrarVenta si existe
DROP PROCEDURE IF EXISTS sp_RegistrarVenta;
GO

CREATE PROCEDURE sp_RegistrarVenta
    @DUI_cliente VARCHAR(10),
    @id_empleado INT,
    @detalle_venta XML  -- Formato: <productos><producto id="X" cantidad="Y"/></productos>
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Validar DUI del cliente (assuming sp_ValidarDUI exists and works)
        DECLARE @EsValido BIT;
        EXEC sp_ValidarDUI @DUI_cliente, @EsValido OUTPUT;
        IF @EsValido = 0
            RAISERROR('Error: DUI del cliente no válido', 16, 1);

        -- Paso 1: Crear la venta
        INSERT INTO Ventas (DUI_cliente, id_empleado, fecha_venta)
        VALUES (@DUI_cliente, @id_empleado, GETDATE());

        DECLARE @id_venta INT = SCOPE_IDENTITY();

        -- Paso 2: Procesar detalle de venta
        CREATE TABLE #TempDetalle (
            id_producto INT,
            cantidad INT
        );

        -- Cargar datos desde XML
        INSERT INTO #TempDetalle (id_producto, cantidad)
        SELECT
            T.Item.value('@id', 'INT'),
            T.Item.value('@cantidad', 'INT')
        FROM @detalle_venta.nodes('/productos/producto') AS T(Item);

        -- Paso 3: Validar y actualizar stock
        DECLARE @id_producto INT, @cantidad INT, @stock_actual INT;
        DECLARE cur_detalle CURSOR LOCAL FOR
            SELECT id_producto, cantidad FROM #TempDetalle;

        OPEN cur_detalle;
        FETCH NEXT FROM cur_detalle INTO @id_producto, @cantidad;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Validar existencia de producto
            IF NOT EXISTS (SELECT 1 FROM Productos WHERE id_producto = @id_producto)
                RAISERROR('Error: Producto ID %d no existe', 16, 1, @id_producto);

            -- Validar stock
            SELECT @stock_actual = stock FROM Productos WHERE id_producto = @id_producto;
            IF (@stock_actual - @cantidad) < 0
                RAISERROR('Error: Stock insuficiente para producto ID %d (Stock: %d)', 16, 1, @id_producto, @stock_actual);

            -- Actualizar stock
            UPDATE Productos
            SET stock = stock - @cantidad
            WHERE id_producto = @id_producto;

            -- Insertar detalle de venta
            INSERT INTO DetalleVentas (id_venta, id_producto, cantidad, subtotal)
            VALUES (
                @id_venta,
                @id_producto,
                @cantidad,
                @cantidad * (SELECT precio FROM Productos WHERE id_producto = @id_producto)
            );

            FETCH NEXT FROM cur_detalle INTO @id_producto, @cantidad;
        END;

        CLOSE cur_detalle;
        DEALLOCATE cur_detalle;

        -- Paso 4: Calcular total de la venta
        EXEC sp_CalcularTotalVenta @id_venta;

        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, CONCAT('Venta registrada (ID: ', @id_venta, ')') AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO

-- Eliminar sp_ValidarDUI si existe
DROP PROCEDURE IF EXISTS sp_ValidarDUI;
GO

CREATE PROCEDURE sp_ValidarDUI
    @DUI VARCHAR(10),
    @EsValido BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Suma INT = 0,
            @Valor INT = 9,
            @Div INT,
            @Resta INT,
            @DigitoVerificador INT,
            @i INT = 1,
            @TodosNumeros BIT = 1;

    -- Validar longitud y caracteres numéricos
    IF LEN(@DUI) <> 9
    BEGIN
        SET @EsValido = 0;
        RETURN;
    END;

    -- Verificar que todos sean dígitos numéricos
    WHILE @i <= 9
    BEGIN
        IF SUBSTRING(@DUI, @i, 1) NOT LIKE '[0-9]'
        BEGIN
            SET @TodosNumeros = 0;
            BREAK;
        END;
        SET @i += 1;
    END;

    IF @TodosNumeros = 0
    BEGIN
        SET @EsValido = 0;
        RETURN;
    END;

    -- Calcular suma ponderada
    SET @i = 1;
    WHILE @i <= 8
    BEGIN
        SET @Suma += CAST(SUBSTRING(@DUI, @i, 1) AS INT) * @Valor;
        SET @Valor -= 1;
        SET @i += 1;
    END;

    -- Calcular dígito verificador
    SET @Div = @Suma % 10;
    SET @Resta = 10 - @Div;
    IF @Resta = 10 SET @Resta = 0;

    -- Obtener último dígito
    SET @DigitoVerificador = CAST(SUBSTRING(@DUI, 9, 1) AS INT);

    -- Validar coincidencia
    SET @EsValido = CASE WHEN @Resta = @DigitoVerificador THEN 1 ELSE 0 END;
END;
GO

-- Eliminar sp_AplicarDescuentoVentas si existe
DROP PROCEDURE IF EXISTS sp_AplicarDescuentoVentas;
GO

CREATE PROCEDURE sp_AplicarDescuentoVentas
    @fecha_inicio DATE,
    @fecha_fin DATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_venta INT, @total DECIMAL(10,2);

    -- Cursor para procesar ventas en el rango
    DECLARE ventas_cursor CURSOR FOR
    SELECT id_venta, total
    FROM Ventas
    WHERE fecha_venta BETWEEN @fecha_inicio AND @fecha_fin;

    OPEN ventas_cursor;
    FETCH NEXT FROM ventas_cursor INTO @id_venta, @total;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Aplicar descuento según monto (CASE)
        DECLARE @descuento DECIMAL(5,2) =
            CASE
                WHEN @total > 1000 THEN 0.10
                WHEN @total > 500 THEN 0.05
                ELSE 0
            END;

        -- Actualizar venta
        UPDATE Ventas
        SET total = @total * (1 - @descuento)
        WHERE id_venta = @id_venta;

        PRINT CONCAT('Venta ', @id_venta, ': Descuento aplicado (', @descuento * 100, '%)');

        FETCH NEXT FROM ventas_cursor INTO @id_venta, @total;
    END;

    CLOSE ventas_cursor;
    DEALLOCATE ventas_cursor;

    PRINT 'Proceso de descuentos completado.';
END;
GO

-- Eliminar sp_ReponerStock si existe
DROP PROCEDURE IF EXISTS sp_ReponerStock;
GO

CREATE PROCEDURE sp_ReponerStock
    @nivel_minimo INT = 50,
    @cantidad_reposicion INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id_producto INT, @stock_actual INT;

    -- Tabla temporal de productos con stock bajo
    CREATE TABLE #ProductosBajoStock (
        id_producto INT PRIMARY KEY,
        stock INT
    );

    INSERT INTO #ProductosBajoStock
    SELECT id_producto, stock
    FROM Productos
    WHERE stock < @nivel_minimo;

    -- Procesar reposición
    WHILE EXISTS (SELECT 1 FROM #ProductosBajoStock)
    BEGIN
        SELECT TOP 1 @id_producto = id_producto, @stock_actual = stock
        FROM #ProductosBajoStock;

        -- Actualizar stock
        UPDATE Productos
        SET stock = @stock_actual + @cantidad_reposicion
        WHERE id_producto = @id_producto;

        PRINT CONCAT('Producto ', @id_producto, ': Stock repuesto (+', @cantidad_reposicion, ')');

        DELETE FROM #ProductosBajoStock WHERE id_producto = @id_producto;
    END;

    DROP TABLE #ProductosBajoStock;
    PRINT 'Reposición de inventario completada.';
END;
GO

-- =============================================
--CASOS DE PRUEBA
-- =============================================

-- Prueba 1: sp_CalcularTotalVenta - Descuento progresivo
-- EXEC sp_CalcularTotalVenta @id_venta = 1;  -- Suponiendo venta con total $750 → 5% de descuento

-- Prueba 2: sp_GestionarStock - XML con productos válidos
DECLARE @xml XML = '
    <productos>
        <producto id="1" cantidad="440"/>
        <producto id="2" cantidad="-3"/>  -- Reducción de stock válida
    </productos>';
EXEC sp_GestionarStock @xml;

-- Prueba 3: sp_GestionarStock - XML inválido (debe fallar)
DECLARE @xml_error XML = '<productos><item id="1"/></productos>';
EXEC sp_GestionarStock @xml_error;

-- Prueba 4: sp_RegistrarVenta - Venta con productos válidos
-- Asumiendo que el cliente y empleado existen

DECLARE @xml_venta XML = '
<productos>
    <producto id="1" cantidad="2"/>  -- Pintura Acrílica Blanca (Stock: 50 → 48)
    <producto id="3" cantidad="1"/>  -- Rodillo de Lana (Stock: 100 → 99)
</productos>';

EXEC sp_RegistrarVenta
    @DUI_cliente = '987654321',
    @id_empleado = 1,
    @detalle_venta = @xml_venta;


DECLARE @Resultado BIT;
-- DUI válido (dígito verificador 9)
EXEC sp_ValidarDUI '000162979', @Resultado OUTPUT;  -- Devuelve 1
SELECT @Resultado AS ValidacionDUI_000162979;

-- DUI inválido (formato incorrecto)
EXEC sp_ValidarDUI 'A2016297', @Resultado OUTPUT;   -- Devuelve 0
SELECT @Resultado AS ValidacionDUI_A2016297;

-- DUI inválido (dígito verificador incorrecto)
EXEC sp_ValidarDUI '000162978', @Resultado OUTPUT;  -- Devuelve 0
SELECT @Resultado AS ValidacionDUI_000162978;


-- Ventas entre 01-05-2024 y 20-05-2024
EXEC sp_AplicarDescuentoVentas '2024-05-01', '2024-05-20';


-- Ejemplo de uso de sp_ReponerStock
EXEC sp_ReponerStock @nivel_minimo = 50, @cantidad_reposicion = 100;
