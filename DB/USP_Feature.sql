USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROCEDURE [SQM_GENERAL].[USP_Features]
    @Accion CHAR(1),
    @FeatureId INT = NULL,
    @Resumen VARCHAR(500) = NULL,
    @Descripcion VARCHAR(2000) = NULL,
    @Criterios VARCHAR(4000) = NULL,
    @EpicId INT = NULL,
    @ResponsableId INT = NULL,
    @FechaInicio DATE = NULL,
    @FechaLimite DATE = NULL,
    @PrioridadId INT = NULL,
    @UsuarioId INT = NULL,
    @EstadoId INT = NULL,
    @NumPagina INT = 1,
    @Filas INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'S'
    BEGIN
        IF @NumPagina < 1 OR @Filas < 1
        BEGIN
            PRINT 'La pagina y las filas deben ser mayores que cero.';
        END;

        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        SELECT
            featureId,
            CONVERT(VARCHAR(500),
                DecryptByKey(featureSummary)) AS featureSummary,
            CONVERT(VARCHAR(2000),
                DecryptByKey(featureDescription)) AS featureDescription,
            CONVERT(VARCHAR(4000),
                DecryptByKey(featuresAcceptanceCriteria))
                AS featuresAcceptanceCriteria,
            featureParentLink,
            featureOwner,
            featureStartDate,
            featureDueDate,
            featurePriority,
            featureCreationDate,
            featureCreatorId,
            featureModificationDate,
            featureModifierId,
            featureStatus
        FROM [SQM_GENERAL].[TBL_Features]
        ORDER BY featureId DESC
        OFFSET (@NumPagina - 1) * @Filas ROWS
        FETCH NEXT @Filas ROWS ONLY;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion = 'I'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        INSERT INTO [SQM_GENERAL].[TBL_Features]
        (
            featureSummary,
            featureDescription,
            featuresAcceptanceCriteria,
            featureParentLink,
            featureOwner,
            featureStartDate,
            featureDueDate,
            featurePriority,
            featureCreationDate,
            featureCreatorId,
            featureStatus
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
            @EpicId,
            @ResponsableId,
            @FechaInicio,
            @FechaLimite,
            @PrioridadId,
            GETDATE(),
            @UsuarioId,
            @EstadoId
        );

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion = 'U'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        UPDATE [SQM_GENERAL].[TBL_Features]
        SET
            featureSummary = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Resumen)
            ),
            featureDescription = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Descripcion)
            ),
            featuresAcceptanceCriteria = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Criterios)
            ),
            featureParentLink = @EpicId,
            featureOwner = @ResponsableId,
            featureStartDate = @FechaInicio,
            featureDueDate = @FechaLimite,
            featurePriority = @PrioridadId,
            featureModificationDate = GETDATE(),
            featureModifierId = @UsuarioId,
            featureStatus = @EstadoId
        WHERE featureId = @FeatureId;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END
    ELSE
    BEGIN
        PRINT 'Accion no valida. Use I, U o S.';
    END
END;
GO