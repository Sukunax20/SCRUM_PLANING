USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROCEDURE [SQM_GENERAL].[USP_ProductBacklogItems]
    @Accion CHAR(1),
    @PBIId INT = NULL,
    @Resumen VARCHAR(500) = NULL,
    @Descripcion VARCHAR(2000) = NULL,
    @Criterios VARCHAR(4000) = NULL,
    @Propietario INT = NULL,
    @FeatureId INT = NULL,
    @PuntosHistoria INT = NULL,
    @FechaInicio DATE = NULL,
    @FechaVencimiento DATE = NULL,
    @Prioridad INT = NULL,
    @Estado INT = NULL,
    @Usuario INT = NULL,
    @Pagina INT = 1,
    @Cantidad INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'I'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        INSERT INTO [SQM_GENERAL].[TBL_ProductBacklogItems]
        (
            PBISummary,
            PBIDescription,
            PBIAcceptanceCriteria,
            PBIOwner,
            PBIParentLink,
            PBIStoryPoint,
            PBIStartDate,
            PBIDueDate,
            PBIPriority,
            PBICreationDate,
            PBICreatorId,
            PBIStatus
        )
        VALUES
        (
            EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Resumen)
            ),
            EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Descripcion)
            ),
            EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Criterios)
            ),
            @Propietario,
            @FeatureId,
            @PuntosHistoria,
            @FechaInicio,
            @FechaVencimiento,
            @Prioridad,
            GETDATE(),
            @Usuario,
            @Estado
        );

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion = 'S'
    BEGIN
        IF @Pagina < 1 OR @Cantidad < 1
        BEGIN
            PRINT 'La pagina y la cantidad deben ser mayores que cero.';
        END;

        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        SELECT
            PBIId,
            CONVERT(VARCHAR(500), DecryptByKey(PBISummary))
                AS PBISummary,
            CONVERT(VARCHAR(2000), DecryptByKey(PBIDescription))
                AS PBIDescription,
            CONVERT(VARCHAR(4000), DecryptByKey(PBIAcceptanceCriteria))
                AS PBIAcceptanceCriteria,
            PBIOwner,
            PBIParentLink,
            PBIStoryPoint,
            PBIStartDate,
            PBIDueDate,
            PBIPriority,
            PBICreationDate,
            PBICreatorId,
            PBIModificationDate,
            PBIModificatorId,
            PBIStatus
        FROM [SQM_GENERAL].[TBL_ProductBacklogItems]
        ORDER BY PBIId DESC
        OFFSET (@Pagina - 1) * @Cantidad ROWS
        FETCH NEXT @Cantidad ROWS ONLY;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion = 'U'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        UPDATE [SQM_GENERAL].[TBL_ProductBacklogItems]
        SET
            PBISummary = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Resumen)
            ),
            PBIDescription = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Descripcion)
            ),
            PBIAcceptanceCriteria = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Criterios)
            ),
            PBIOwner = @Propietario,
            PBIParentLink = @FeatureId,
            PBIStoryPoint = @PuntosHistoria,
            PBIStartDate = @FechaInicio,
            PBIDueDate = @FechaVencimiento,
            PBIPriority = @Prioridad,
            PBIModificationDate = GETDATE(),
            PBIModificatorId = @Usuario,
            PBIStatus = @Estado
        WHERE PBIId = @PBIId;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END
    ELSE
    BEGIN
        PRINT 'Accion no valida. Utilice I, U o S.';
    END
END;
GO