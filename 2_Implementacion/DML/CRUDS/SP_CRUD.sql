--------------------------
-- ELIMINAR PROCEDIMIENTOS CLIENTES
--------------------------
DROP PROCEDURE IF EXISTS sp_InsertarCliente;
DROP PROCEDURE IF EXISTS sp_ObtenerCliente;
DROP PROCEDURE IF EXISTS sp_ActualizarCliente;
DROP PROCEDURE IF EXISTS sp_EliminarCliente;
GO

--------------------------
-- ELIMINAR PROCEDIMIENTOS PRODUCTOS
--------------------------
DROP PROCEDURE IF EXISTS sp_InsertarProducto;
DROP PROCEDURE IF EXISTS sp_ObtenerProducto;
DROP PROCEDURE IF EXISTS sp_ActualizarProducto;
DROP PROCEDURE IF EXISTS sp_EliminarProducto;
GO

--------------------------
-- ELIMINAR PROCEDIMIENTOS EMPLEADOS
--------------------------
DROP PROCEDURE IF EXISTS sp_InsertarEmpleado;
DROP PROCEDURE IF EXISTS sp_ObtenerEmpleado; -- This one was missing in your original drops but present in the script
DROP PROCEDURE IF EXISTS sp_ActualizarEmpleado;
DROP PROCEDURE IF EXISTS sp_EliminarEmpleado;
GO





-- =============================================
-- CRUD PROCEDURES PARA CLIENTES
-- =============================================

CREATE PROCEDURE sp_InsertarCliente
    @DUI VARCHAR(10),
    @nombre VARCHAR(50),
    @telefono VARCHAR(8),
    @email VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EsValido BIT;

    -- Validar DUI usando el SP
    EXEC sp_ValidarDUI @DUI, @EsValido OUTPUT;

    IF @EsValido = 0
        RAISERROR('Error: DUI inválido. Verifique el formato y dígito verificador.', 16, 1);

    -- Resto de validaciones (teléfono, email, etc.)
    IF LEN(@telefono) != 8 OR @telefono NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]'
        RAISERROR('Error: Teléfono debe tener 8 dígitos numéricos.', 16, 1);

    IF EXISTS (SELECT 1 FROM Clientes WHERE email = @email)
        RAISERROR('Error: Email ya registrado.', 16, 1);

    INSERT INTO Clientes (DUI, nombre, telefono, email)
    VALUES (@DUI, @nombre, @telefono, @email);

    PRINT 'Cliente registrado exitosamente.';
END;
GO

CREATE PROCEDURE sp_ObtenerCliente
    @DUI VARCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @DUI IS NULL
            SELECT * FROM Clientes;
        ELSE
            SELECT * FROM Clientes WHERE DUI = @DUI;
            
        IF @DUI IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Clientes WHERE DUI = @DUI)
            SELECT 'Advertencia' AS Resultado, 'No se encontró el cliente con el DUI proporcionado' AS Mensaje;
    END TRY
      --ACA LO QUE SE HACE ES QUE SI HAY UN ERROR EN EL TRY SE MANDA A CATCH PARA HACER UN ROLLBACK  
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO

CREATE PROCEDURE sp_ActualizarCliente
    @DUI VARCHAR(10),
    @nuevoNombre VARCHAR(50) = NULL,
    @nuevoTelefono VARCHAR(8) = NULL,
    @nuevoEmail VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el cliente existe
        IF NOT EXISTS (SELECT 1 FROM Clientes WHERE DUI = @DUI)
            RAISERROR('Error: No existe un cliente con el DUI proporcionado', 16, 1);
            
        -- Validación de teléfono si se proporciona
        IF @nuevoTelefono IS NOT NULL AND (@nuevoTelefono NOT LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]' OR LEN(@nuevoTelefono) != 8)
            RAISERROR('Error: El teléfono debe tener 8 dígitos numéricos', 16, 1);
            
        -- Validación de email si se proporciona
        IF @nuevoEmail IS NOT NULL AND @nuevoEmail NOT LIKE '%_@__%.__%'
            RAISERROR('Error: Formato de email inválido', 16, 1);
            
        -- Verificar si el nuevo email ya existe (excepto para este cliente)
        IF @nuevoEmail IS NOT NULL AND EXISTS (SELECT 1 FROM Clientes WHERE email = @nuevoEmail AND DUI != @DUI)
            RAISERROR('Error: El email ya está registrado por otro cliente', 16, 1);
            
        -- Actualizar campos proporcionados
        UPDATE Clientes SET
            nombre = ISNULL(@nuevoNombre, nombre),
            telefono = ISNULL(@nuevoTelefono, telefono),
            email = ISNULL(@nuevoEmail, email)
        WHERE DUI = @DUI;
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Cliente actualizado correctamente' AS Mensaje;
    END TRY
      --ACA LO QUE SE HACE ES QUE SI HAY UN ERROR EN EL TRY SE MANDA A CATCH PARA HACER UN ROLLBACK  
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO

CREATE PROCEDURE sp_EliminarCliente
    @DUI VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el cliente existe
        IF NOT EXISTS (SELECT 1 FROM Clientes WHERE DUI = @DUI)
            RAISERROR('Error: No existe un cliente con el DUI proporcionado', 16, 1);
            
        -- Verificar si el cliente tiene ventas asociadas
        IF EXISTS (SELECT 1 FROM Ventas WHERE DUI_cliente = @DUI)
            RAISERROR('Error: No se puede eliminar el cliente porque tiene ventas asociadas', 16, 1);
            
        -- Verificar si el cliente tiene direcciones asociadas
        IF EXISTS (SELECT 1 FROM Direcciones WHERE DUI_cliente = @DUI)
            DELETE FROM Direcciones WHERE DUI_cliente = @DUI;
            
        -- Eliminar cliente
        DELETE FROM Clientes WHERE DUI = @DUI;
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Cliente eliminado correctamente' AS Mensaje;
    END TRY
    
    BEGIN CATCH
        -- Manejo de errores 
          --ACA LO QUE SE HACE ES QUE SI HAY UN ERROR EN EL TRY SE MANDA A CATCH PARA HACER UN ROLLBACK  

        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO

-- =============================================
-- CRUD PROCEDURES PARA PRODUCTOS
-- =============================================

CREATE PROCEDURE sp_InsertarProducto
    @nombre VARCHAR(50),
    @precio DECIMAL(10,2),
    @stock INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validación de precio positivo
        IF @precio <= 0
            RAISERROR('Error: El precio debe ser mayor que cero', 16, 1);
            
        -- Validación de stock no negativo
        IF @stock < 0
            RAISERROR('Error: El stock no puede ser negativo', 16, 1);
            
        -- Verificar si producto ya existe
        IF EXISTS (SELECT 1 FROM Productos WHERE nombre = @nombre)
            RAISERROR('Error: Ya existe un producto con ese nombre', 16, 1);
            
        -- Insertar producto
        INSERT INTO Productos (nombre, precio, stock)
        VALUES (@nombre, @precio, @stock);
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Producto registrado correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO

CREATE PROCEDURE sp_ObtenerProducto
    @id_producto INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF @id_producto IS NULL
            SELECT * FROM Productos;
        ELSE
            SELECT * FROM Productos WHERE id_producto = @id_producto;
            
        IF @id_producto IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Productos WHERE id_producto = @id_producto)
            SELECT 'Advertencia' AS Resultado, 'No se encontró el producto con el ID proporcionado' AS Mensaje;
    END TRY
    BEGIN CATCH
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO

CREATE PROCEDURE sp_ActualizarProducto
    @id_producto INT,
    @nuevoNombre VARCHAR(50) = NULL,
    @nuevoPrecio DECIMAL(10,2) = NULL,
    @nuevoStock INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el producto existe
        IF NOT EXISTS (SELECT 1 FROM Productos WHERE id_producto = @id_producto)
            RAISERROR('Error: No existe un producto con el ID proporcionado', 16, 1);
            
        -- Validación de precio si se proporciona
        IF @nuevoPrecio IS NOT NULL AND @nuevoPrecio <= 0
            RAISERROR('Error: El precio debe ser mayor que cero', 16, 1);
            
        -- Validación de stock si se proporciona
        IF @nuevoStock IS NOT NULL AND @nuevoStock < 0
            RAISERROR('Error: El stock no puede ser negativo', 16, 1);
            
        -- Verificar si el nuevo nombre ya existe (excepto para este producto)
        IF @nuevoNombre IS NOT NULL AND EXISTS (SELECT 1 FROM Productos WHERE nombre = @nuevoNombre AND id_producto != @id_producto)
            RAISERROR('Error: Ya existe otro producto con ese nombre', 16, 1);
            
        -- Actualizar campos proporcionados
        UPDATE Productos SET
            nombre = ISNULL(@nuevoNombre, nombre),
            precio = ISNULL(@nuevoPrecio, precio),
            stock = ISNULL(@nuevoStock, stock)
        WHERE id_producto = @id_producto;
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Producto actualizado correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO

CREATE PROCEDURE sp_EliminarProducto
    @id_producto INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el producto existe
        IF NOT EXISTS (SELECT 1 FROM Productos WHERE id_producto = @id_producto)
            RAISERROR('Error: No existe un producto con el ID proporcionado', 16, 1);
            
        -- Verificar si el producto tiene ventas asociadas
        IF EXISTS (SELECT 1 FROM DetalleVentas WHERE id_producto = @id_producto)
            RAISERROR('Error: No se puede eliminar el producto porque tiene ventas asociadas', 16, 1);
            
        -- Eliminar producto
        DELETE FROM Productos WHERE id_producto = @id_producto;
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Producto eliminado correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO
-- =============================================
-- CRUD PROCEDURES PARA EMPLEADOS
-- =============================================


CREATE PROCEDURE sp_InsertarEmpleado
    @DUI VARCHAR(10),
    @nombre VARCHAR(50),
    @fecha_nacimiento DATE,
    @puesto VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EsValido BIT;

    -- Validar DUI
    EXEC sp_ValidarDUI @DUI, @EsValido OUTPUT;

    IF @EsValido = 0
        RAISERROR('Error: DUI inválido. Verifique el formato y dígito verificador.', 16, 1);

    -- Validar edad mínima
    IF DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()) < 18
        RAISERROR('Error: Empleado debe ser mayor de 18 años.', 16, 1);

    INSERT INTO Empleados (DUI, nombre, fecha_nacimiento, puesto)
    VALUES (@DUI, @nombre, @fecha_nacimiento, @puesto);

    PRINT 'Empleado registrado exitosamente.';
END;
GO


CREATE PROCEDURE sp_ActualizarEmpleado
    @id_empleado INT,
    @nuevoNombre VARCHAR(50) = NULL,
    @nuevaFechaNacimiento DATE = NULL,
    @nuevoPuesto VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el empleado existe
        IF NOT EXISTS (SELECT 1 FROM Empleados WHERE id_empleado = @id_empleado)
            RAISERROR('Error: No existe un empleado con el ID proporcionado', 16, 1);
            
        -- Validación de edad si se proporciona
        IF @nuevaFechaNacimiento IS NOT NULL AND DATEDIFF(YEAR, @nuevaFechaNacimiento, GETDATE()) < 18
            RAISERROR('Error: El empleado debe ser mayor de 18 años', 16, 1);
            
        -- Validación de puesto si se proporciona
        IF @nuevoPuesto IS NOT NULL AND @nuevoPuesto NOT IN ('Vendedor', 'Almacenista', 'Gerente', 'Administrador')
            RAISERROR('Error: Puesto no válido', 16, 1);
            
        -- Actualizar campos proporcionados
        UPDATE Empleados SET
            nombre = ISNULL(@nuevoNombre, nombre),
            fecha_nacimiento = ISNULL(@nuevaFechaNacimiento, fecha_nacimiento),
            puesto = ISNULL(@nuevoPuesto, puesto)
        WHERE id_empleado = @id_empleado;
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Empleado actualizado correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO

CREATE PROCEDURE sp_EliminarEmpleado
    @id_empleado INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Verificar si el empleado existe
        IF NOT EXISTS (SELECT 1 FROM Empleados WHERE id_empleado = @id_empleado)
            RAISERROR('Error: No existe un empleado con el ID proporcionado', 16, 1);
            
        -- Verificar si el empleado tiene ventas asociadas
        IF EXISTS (SELECT 1 FROM Ventas WHERE id_empleado = @id_empleado)
            RAISERROR('Error: No se puede eliminar el empleado porque tiene ventas asociadas', 16, 1);
            
        -- Eliminar empleado
        DELETE FROM Empleados WHERE id_empleado = @id_empleado;
        
        COMMIT TRANSACTION;
        SELECT 'Éxito' AS Resultado, 'Empleado eliminado correctamente' AS Mensaje;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'Error' AS Resultado, ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO



-- =============================================
-- DATOS DE PRUEBA PARA CLIENTES
-- =============================================
-- Prueba 1: Insertar cliente válido
EXEC sp_InsertarCliente '123456789', 'Juan Pérez', '78945612', 'juan@mail.com';

-- Prueba 2: Insertar con DUI inválido (debe fallar)
EXEC sp_InsertarCliente '123', 'Ana López', '78945612', 'ana@mail.com';

-- Prueba 3: Actualizar teléfono
EXEC sp_ActualizarCliente '123456789', @nuevoTelefono = '77778888';

-- Prueba 4: Eliminar cliente sin ventas
EXEC sp_EliminarCliente '123456789';

--============================================
--DATOS DE PRUEBA PARA PRODUCTOS
-- ===========================================
-- Prueba 1: Insertar producto válido
EXEC sp_InsertarProducto 'Pintura Roja', 25.99, 50;

-- Prueba 2: Insertar con precio inválido (debe fallar)
EXEC sp_InsertarProducto 'Pintura Azul', -10.50, 30;

-- Prueba 3: Actualizar stock
EXEC sp_ActualizarProducto 1, @nuevoStock = 45;

-- Prueba 4: Eliminar producto sin ventas
EXEC sp_EliminarProducto 1;

-- =============================================
-- DATOS DE PRUEBA PARA EMPLEADOS
-- =============================================
-- Prueba 1: Insertar empleado válido
EXEC sp_InsertarEmpleado '987654321', 'Carlos Rivas', '1990-05-15', 'Vendedor';

-- Prueba 2: Insertar menor de edad (debe fallar)
EXEC sp_InsertarEmpleado '555555555', 'Pedro Niño', '2010-01-01', 'Almacenista';

-- Prueba 3: Actualizar puesto
EXEC sp_ActualizarEmpleado 1, @nuevoPuesto = 'Gerente';

-- Prueba 4: Eliminar empleado sin ventas
EXEC sp_EliminarEmpleado 1;


