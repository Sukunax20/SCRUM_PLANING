USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROCEDURE [SQM_CATALOGS].[USP_Priorities]
(
    @Operacion CHAR(1),
    @IdPrioridad INT = NULL,
    @NombrePrioridad VARCHAR(80) = NULL,
    @Creador INT = NULL,
    @Modificador INT = NULL,
    @Habilitada BIT = NULL,
    @NumeroPagina INT = 1,
    @Limite INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @NumeroPagina < 1 OR @Limite < 1
    BEGIN
        PRINT 'La pagina y el limite deben ser mayores que cero.';
        RETURN;
    END;

    IF @Operacion = 'S'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        SELECT
            priorityId,
            CONVERT(VARCHAR(80),
                DecryptByKey(priorityName)) AS priorityName,
            priorityCreationDate,
            priorityCreatorId,
            priorityModificationDate,
            priorityModifierId,
            priorityEnable
        FROM [SQM_CATALOGS].[TBL_Priorities]
        ORDER BY priorityId
        OFFSET (@NumeroPagina - 1) * @Limite ROWS
        FETCH NEXT @Limite ROWS ONLY;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END
    ELSE IF @Operacion = 'I'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        INSERT INTO [SQM_CATALOGS].[TBL_Priorities]
        (
            priorityName,
            priorityCreationDate,
            priorityCreatorId,
            priorityEnable
        )
        VALUES
        (
            EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @NombrePrioridad)
            ),
            GETDATE(),
            @Creador,
            @Habilitada
        );

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END
    ELSE IF @Operacion = 'U'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        UPDATE [SQM_CATALOGS].[TBL_Priorities]
        SET
            priorityName = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @NombrePrioridad)
            ),
            priorityModificationDate = GETDATE(),
            priorityModifierId = @Modificador,
            priorityEnable = @Habilitada
        WHERE priorityId = @IdPrioridad;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END
    ELSE
    BEGIN
        PRINT 'Operacion no valida. Use I, U o S.';
    END
END;
GO
