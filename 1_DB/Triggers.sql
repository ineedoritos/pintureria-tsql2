-----------------------------------------------------------------------------------------
-- TRIGGER PARA LA TABLA CLIENTES
-----------------------------------------------------------------------------------------
-- Verifica si el trigger ya existe antes de crearlo
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_bitacora_clientes')
BEGIN
    EXEC('
    CREATE TRIGGER trg_bitacora_clientes
    ON Clientes
    AFTER INSERT, UPDATE, DELETE  -- Se activa después de operaciones de inserción, actualización o eliminación
    AS
    BEGIN
        DECLARE @transaccion VARCHAR(10);
        
        -- Determina el tipo de operación:
        -- Si existen registros en inserted Y deleted -> Es una actualización
        -- Si solo existe inserted -> Es una inserción
        -- Si solo existe deleted -> Es una eliminación
        IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
            SET @transaccion = ''Update'';
        ELSE IF EXISTS (SELECT * FROM inserted)
            SET @transaccion = ''Insert'';
        ELSE
            SET @transaccion = ''Delete'';
        
        -- Registra en la bitácora:
        -- nombre_tabla: Indica la tabla afectada (Clientes)
        -- transaccion: Tipo de operación (Insert/Update/Delete)
        INSERT INTO Bitacora (nombre_tabla, transaccion)
        VALUES (''Clientes'', @transaccion);
    END;
    ')
END;
GO

-----------------------------------------------------------------------------------------
-- TRIGGER PARA LA TABLA EMPLEADOS (Mismo patrón con tabla específica)
-----------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_bitacora_empleados')
BEGIN
    EXEC('
    CREATE TRIGGER trg_bitacora_empleados
    ON Empleados
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        DECLARE @transaccion VARCHAR(10);
        -- Misma lógica para determinar el tipo de operación
        IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
            SET @transaccion = ''Update'';
        ELSE IF EXISTS (SELECT * FROM inserted)
            SET @transaccion = ''Insert'';
        ELSE
            SET @transaccion = ''Delete'';
        
        -- Registra la operación con el nombre de la tabla correspondiente
        INSERT INTO Bitacora (nombre_tabla, transaccion)
        VALUES (''Empleados'', @transaccion);
    END;
    ')
END;
GO

-----------------------------------------------------------------------------------------
-- TRIGGER PARA LA TABLA DIRECCIONES
-----------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_bitacora_direcciones')
BEGIN
    EXEC('
    CREATE TRIGGER trg_bitacora_direcciones
    ON Direcciones
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        DECLARE @transaccion VARCHAR(10);
        -- Mecanismo estándar para identificar el tipo de operación
        IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
            SET @transaccion = ''Update'';
        ELSE IF EXISTS (SELECT * FROM inserted)
            SET @transaccion = ''Insert'';
        ELSE
            SET @transaccion = ''Delete'';
        
        -- Registra la transacción con el nombre de la tabla
        INSERT INTO Bitacora (nombre_tabla, transaccion)
        VALUES (''Direcciones'', @transaccion);
    END;
    ')
END;
GO

-----------------------------------------------------------------------------------------
-- TRIGGER PARA LA TABLA PRODUCTOS
-----------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_bitacora_productos')
BEGIN
    EXEC('
    CREATE TRIGGER trg_bitacora_productos
    ON Productos
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        DECLARE @transaccion VARCHAR(10);
        -- Lógica común para determinar la operación
        IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
            SET @transaccion = ''Update'';
        ELSE IF EXISTS (SELECT * FROM inserted)
            SET @transaccion = ''Insert'';
        ELSE
            SET @transaccion = ''Delete'';
        
        -- Registra la operación en la bitácora
        INSERT INTO Bitacora (nombre_tabla, transaccion)
        VALUES (''Productos'', @transaccion);
    END;
    ')
END;
GO

-----------------------------------------------------------------------------------------
-- TRIGGER PARA LA TABLA VENTAS
-----------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_bitacora_ventas')
BEGIN
    EXEC('
    CREATE TRIGGER trg_bitacora_ventas
    ON Ventas
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        DECLARE @transaccion VARCHAR(10);
        -- Determina el tipo de operación DML
        IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
            SET @transaccion = ''Update'';
        ELSE IF EXISTS (SELECT * FROM inserted)
            SET @transaccion = ''Insert'';
        ELSE
            SET @transaccion = ''Delete'';
        
        -- Registra el evento en la bitácora
        INSERT INTO Bitacora (nombre_tabla, transaccion)
        VALUES (''Ventas'', @transaccion);
    END;
    ')
END;
GO

-----------------------------------------------------------------------------------------
-- TRIGGER PARA LA TABLA DETALLEVENTAS
-----------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_bitacora_detalleventas')
BEGIN
    EXEC('
    CREATE TRIGGER trg_bitacora_detalleventas
    ON DetalleVentas
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        DECLARE @transaccion VARCHAR(10);
        -- Misma lógica de detección de operaciones
        IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
            SET @transaccion = ''Update'';
        ELSE IF EXISTS (SELECT * FROM inserted)
            SET @transaccion = ''Insert'';
        ELSE
            SET @transaccion = ''Delete'';
        
        -- Registra la transacción
        INSERT INTO Bitacora (nombre_tabla, transaccion)
        VALUES (''DetalleVentas'', @transaccion);
    END;
    ')
END;
GO

-----------------------------------------------------------------------------------------
-- TRIGGER PARA LA TABLA ENVIOS
-----------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE name = 'trg_bitacora_envios')
BEGIN
    EXEC('
    CREATE TRIGGER trg_bitacora_envios
    ON Envios
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        DECLARE @transaccion VARCHAR(10);
        -- Identifica el tipo de operación
        IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
            SET @transaccion = ''Update'';
        ELSE IF EXISTS (SELECT * FROM inserted)
            SET @transaccion = ''Insert'';
        ELSE
            SET @transaccion = ''Delete'';
        
        -- Registra en la bitácora
        INSERT INTO Bitacora (nombre_tabla, transaccion)
        VALUES (''Envios'', @transaccion);
    END;
    ')
END;
GO