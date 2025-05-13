    USE pintureriaDB;

    -- Desactivar temporalmmente las restricciones de clave foránea (opcional, para evitar errores)
    EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

    -- Borrar datos en orden seguro
    DELETE FROM Envios;
    DELETE FROM DetalleVentas;
    DELETE FROM Ventas;
    DELETE FROM Direcciones;
    DELETE FROM Empleados;
    DELETE FROM Productos;
    DELETE FROM Clientes;

    -- Reactivar restricciones (si se desactivaron)
    EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';

    -- Reiniciar contadores de identidad (opcional)
    DBCC CHECKIDENT ('Envios', RESEED, 0);
    DBCC CHECKIDENT ('DetalleVentas', RESEED, 0);
    DBCC CHECKIDENT ('Ventas', RESEED, 0);
    DBCC CHECKIDENT ('Direcciones', RESEED, 0);
    DBCC CHECKIDENT ('Empleados', RESEED, 0);
    DBCC CHECKIDENT ('Productos', RESEED, 0);




    --> Envios → DetalleVentas → Ventas → Direcciones → Empleados → Productos → Clientes → Bitacora asi se ejeucuta 