USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROCEDURE [SQM_CATALOGS].[USP_Status]
    @Accion CHAR(1),
    @statusId INT = NULL,
    @statusName VARCHAR(80) = NULL,
    @statusCreatorId INT = NULL,
    @statusModifierId INT = NULL,
    @statusEnable BIT = NULL,
    @Pagina INT = 1,
    @Cantidad INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Inicio INT;
    SET @Inicio = (@Pagina - 1) * @Cantidad;

    IF @Accion IN ('I')
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        INSERT INTO [SQM_CATALOGS].[TBL_Status]
        SELECT
            EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @statusName)
            ),
            GETDATE(),
            @statusCreatorId,
            GETDATE(),
            NULL,
            @statusEnable;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion IN ('U')
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        UPDATE [SQM_CATALOGS].[TBL_Status]
        SET
            statusName = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @statusName)
            ),
            statusModifierId = @statusModifierId,
            statusModificationDate = GETDATE(),
            statusEnable = @statusEnable
        WHERE statusId = @statusId;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion IN ('S')
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        SELECT
            statusId,
            CAST(DecryptByKey(statusName) AS VARCHAR(80)) AS statusName,
            statusCreationDate,
            statusCreatorId,
            statusModificationDate,
            statusModifierId,
            statusEnable
        FROM [SQM_CATALOGS].[TBL_Status]
        ORDER BY statusName
        OFFSET @Inicio ROWS
        FETCH NEXT @Cantidad ROWS ONLY;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END
    ELSE
    BEGIN
        PRINT 'Seleccione una accion valida: I, U o S.';
    END
END;
GO