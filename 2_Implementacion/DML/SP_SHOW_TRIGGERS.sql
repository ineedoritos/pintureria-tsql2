    CREATE PROCEDURE SHOW_TRIGGERS
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT 
            t.name AS trigger_name,
            OBJECT_NAME(t.parent_id) AS table_name,
            s.name AS schema_name,
            t.type_desc AS trigger_type,
            m.definition AS trigger_definition
        FROM sys.triggers t
        JOIN sys.sql_modules m ON t.object_id = m.object_id
        JOIN sys.objects o ON t.parent_id = o.object_id
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE t.is_ms_shipped = 0
        ORDER BY table_name;
    END;
    GO


    CREATE PROCEDURE SHOW_PROCEDURES
    AS
    BEGIN
        SET NOCOUNT ON;

        SELECT 
            p.name AS NombreProcedimiento,
            s.name AS Esquema,
            m.definition AS CodigoFuente
        FROM 
            sys.procedures p
        INNER JOIN 
            sys.schemas s ON p.schema_id = s.schema_id
        INNER JOIN 
            sys.sql_modules m ON p.object_id = m.object_id
        ORDER BY 
            s.name, p.name;
    END;
    GO


