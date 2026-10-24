USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROCEDURE [SQM_CATALOGS].[USP_ActivityTypes]
    @Accion CHAR(1),
    @Id INT = NULL,
    @Nombre VARCHAR(80) = NULL,
    @Usuario INT = NULL,
    @Habilitado BIT = NULL,
    @Pagina INT = 1,
    @Registros INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'I'
    BEGIN
        INSERT INTO [SQM_CATALOGS].[TBL_ActivityTypes]
        (
            activityTypeName,
            activityTypeCreationDate,
            activityTypeCreatorId,
            activityTypeEnable
        )
        VALUES
        (
            @Nombre,
            GETDATE(),
            @Usuario,
            @Habilitado
        );

        RETURN;
    END

    ELSE IF @Accion = 'S'
    BEGIN
        IF @Pagina < 1 OR @Registros < 1
        BEGIN
            PRINT 'La pagina y los registros deben ser mayores que cero.';
        END;

        SELECT
            activityTypeId,
            activityTypeName,
            activityTypeCreationDate,
            activityTypeCreatorId,
            activityTypeModificationDate,
            activityTypeModificatorId,
            activityTypeEnable
        FROM [SQM_CATALOGS].[TBL_ActivityTypes]
        ORDER BY activityTypeId DESC
        OFFSET (@Pagina - 1) * @Registros ROWS
        FETCH NEXT @Registros ROWS ONLY;

        RETURN;
    END

    ELSE IF @Accion = 'U'
    BEGIN
        UPDATE [SQM_CATALOGS].[TBL_ActivityTypes]
        SET
            activityTypeName = @Nombre,
            activityTypeModificationDate = GETDATE(),
            activityTypeModificatorId = @Usuario,
            activityTypeEnable = @Habilitado
        WHERE activityTypeId = @Id;

        RETURN;
    END

    ELSE
    BEGIN
        PRINT 'Accion no valida. Utilice I, U o S.';
    END
END;
GO