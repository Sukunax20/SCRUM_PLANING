USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROCEDURE [SQM_GENERAL].[USP_Epics]
    @Accion CHAR(1),
    @Epic INT = NULL,
    @Nombre VARCHAR(100) = NULL,
    @Resumen VARCHAR(500) = NULL,
    @Descripcion VARCHAR(4000) = NULL,
    @Iniciativa INT = NULL,
    @Responsable INT = NULL,
    @Inicio DATE = NULL,
    @Vencimiento DATE = NULL,
    @Prioridad INT = NULL,
    @Estado INT = NULL,
    @Usuario INT = NULL,
    @Pagina INT = 1,
    @CantidadRegistros INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'S'
    BEGIN
        IF @Pagina < 1 OR @CantidadRegistros < 1
        BEGIN
            PRINT 'La pagina y la cantidad deben ser mayores que cero.';
        END;

        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        SELECT
            epicId,
            CONVERT(VARCHAR(100), DecryptByKey(epicName)) AS epicName,
            CONVERT(VARCHAR(500), DecryptByKey(epicSummary)) AS epicSummary,
            CONVERT(VARCHAR(4000), DecryptByKey(epicDescription)) AS epicDescription,
            epicParentLink,
            epicOwner,
            epicStartDate,
            epicDueDate,
            epicPriority,
            epicCreationDate,
            epicCreatorId,
            epicModificationDate,
            epicModifierId,
            epicStatus
        FROM [SQM_GENERAL].[TBL_Epics]
        ORDER BY epicId DESC
        OFFSET (@Pagina - 1) * @CantidadRegistros ROWS
        FETCH NEXT @CantidadRegistros ROWS ONLY;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion = 'U'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        UPDATE [SQM_GENERAL].[TBL_Epics]
        SET
            epicName = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Nombre)
            ),
            epicSummary = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Resumen)
            ),
            epicDescription = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Descripcion)
            ),
            epicParentLink = @Iniciativa,
            epicOwner = @Responsable,
            epicStartDate = @Inicio,
            epicDueDate = @Vencimiento,
            epicPriority = @Prioridad,
            epicStatus = @Estado,
            epicModificationDate = GETDATE(),
            epicModifierId = @Usuario
        WHERE epicId = @Epic;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion = 'I'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        INSERT INTO [SQM_GENERAL].[TBL_Epics]
        (
            epicName,
            epicSummary,
            epicDescription,
            epicParentLink,
            epicOwner,
            epicStartDate,
            epicDueDate,
            epicPriority,
            epicCreationDate,
            epicCreatorId,
            epicStatus
        )
        VALUES
        (
            EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Nombre)
            ),
            EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Resumen)
            ),
            EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Descripcion)
            ),
            @Iniciativa,
            @Responsable,
            @Inicio,
            @Vencimiento,
            @Prioridad,
            GETDATE(),
            @Usuario,
            @Estado
        );

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END
    ELSE
    BEGIN
        PRINT 'Accion no valida. Utilice I, U o S.';
    END
END;
GO