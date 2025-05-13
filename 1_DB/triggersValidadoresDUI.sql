USE PintureriaDB;
GO

--------------------------------------------------------------------------------
-- Trigger en Clientes: valida el DUI usando el procedimiento sp_ValidarDUI
-- Solo se crea si no existe previamente
--------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_validar_dui_clientes')
BEGIN
    EXEC('
    -- Creamos el trigger trg_validar_dui_clientes en la tabla Clientes
    CREATE TRIGGER trg_validar_dui_clientes
    ON Clientes
    AFTER INSERT, UPDATE     -- Se dispara tras INSERT o UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;      -- Evita mensajes de conteo de filas

        DECLARE
            @DUI VARCHAR(10),
            @EsValido BIT,
            @mensaje_error VARCHAR(200); -- Variable para construir el mensaje de error

        -- Recorremos todos los DUIs de las filas nuevas/actualizadas
        DECLARE dui_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT DUI FROM inserted;

        OPEN dui_cursor;
        FETCH NEXT FROM dui_cursor INTO @DUI;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Llamamos al SP que calcula y valida el dígito verificador
            EXEC dbo.sp_ValidarDUI @DUI, @EsValido OUTPUT;

            -- Si la validación falla, abortamos la transacción
            IF @EsValido = 0
            BEGIN
                CLOSE dui_cursor;
                DEALLOCATE dui_cursor;

                -- Construir el mensaje de error antes de THROW
                SET @mensaje_error = ''Error: DUI inválido en Clientes -> '' + @DUI;
                THROW 51001, @mensaje_error, 1; -- Pasamos la variable con el mensaje completo
            END

            FETCH NEXT FROM dui_cursor INTO @DUI;
        END

        CLOSE dui_cursor;
        DEALLOCATE dui_cursor;
    END;
    ')
END;
GO

--------------------------------------------------------------------------------
-- Trigger en Empleados: valida el DUI usando el procedimiento sp_ValidarDUI
-- Solo se crea si no existe previamente
--------------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_validar_dui_empleados')
BEGIN
    EXEC('
    -- Creamos el trigger trg_validar_dui_empleados en la tabla Empleados
    CREATE TRIGGER trg_validar_dui_empleados
    ON Empleados
    AFTER INSERT, UPDATE     -- Se dispara tras INSERT o UPDATE
    AS
    BEGIN
        SET NOCOUNT ON;      -- Evita mensajes de conteo de filas

        DECLARE
            @DUI VARCHAR(10),
            @EsValido BIT,
            @mensaje_error VARCHAR(200); -- Variable para construir el mensaje de error

        -- Recorremos todos los DUIs de las filas nuevas/actualizadas
        DECLARE dui_cursor CURSOR LOCAL FAST_FORWARD FOR
            SELECT DUI FROM inserted;

        OPEN dui_cursor;
        FETCH NEXT FROM dui_cursor INTO @DUI;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Llamamos al SP que calcula y valida el dígito verificador
            EXEC dbo.sp_ValidarDUI @DUI, @EsValido OUTPUT;

            -- Si la validación falla, abortamos la transacción
            IF @EsValido = 0
            BEGIN
                CLOSE dui_cursor;
                DEALLOCATE dui_cursor;

                -- Construir el mensaje de error antes de THROW
                SET @mensaje_error = ''Error: DUI inválido en Empleados -> '' + @DUI;
                THROW 51002, @mensaje_error, 1; -- Pasamos la variable con el mensaje completo
            END

            FETCH NEXT FROM dui_cursor INTO @DUI;
        END

        CLOSE dui_cursor;
        DEALLOCATE dui_cursor;
    END;
    ')
END;
GO
