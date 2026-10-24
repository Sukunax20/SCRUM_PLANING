USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROCEDURE [SQM_GENERAL].[USP_Tasks]
    @Accion CHAR(1),
    @IdTarea INT = NULL,
    @Resumen VARCHAR(500) = NULL,
    @Descripcion VARCHAR(2000) = NULL,
    @Responsable INT = NULL,
    @PBI INT = NULL,
    @Estimacion DECIMAL(4,2) = NULL,
    @TrabajoReal DECIMAL(4,2) = NULL,
    @TrabajoPendiente DECIMAL(4,2) = NULL,
    @Inicio DATE = NULL,
    @Finalizacion DATE = NULL,
    @Vencimiento DATE = NULL,
    @TipoActividad INT = NULL,
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

        INSERT INTO [SQM_GENERAL].[TBL_Tasks]
        (
            taskSummary,
            taskDescription,
            taskOwner,
            taskParentLink,
            taskOriginalEstimate,
            taskCompletedWork,
            taskRemainingWork,
            taskStartDate,
            taskCompletedDate,
            taskDueDate,
            taskActivityType,
            taskCreationDate,
            taskCreatorId,
            taskStatus
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
            @Responsable,
            @PBI,
            @Estimacion,
            @TrabajoReal,
            @TrabajoPendiente,
            @Inicio,
            @Finalizacion,
            @Vencimiento,
            @TipoActividad,
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
            taskId,
            CONVERT(VARCHAR(500),
                DecryptByKey(taskSummary)) AS taskSummary,
            CONVERT(VARCHAR(2000),
                DecryptByKey(taskDescription)) AS taskDescription,
            taskOwner,
            taskParentLink,
            taskOriginalEstimate,
            taskCompletedWork,
            taskRemainingWork,
            taskStartDate,
            taskCompletedDate,
            taskDueDate,
            taskActivityType,
            taskCreationDate,
            taskCreatorId,
            taskModificationDate,
            taskModificatorId,
            taskStatus
        FROM [SQM_GENERAL].[TBL_Tasks]
        ORDER BY taskId DESC
        OFFSET (@Pagina - 1) * @Cantidad ROWS
        FETCH NEXT @Cantidad ROWS ONLY;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END

    ELSE IF @Accion = 'U'
    BEGIN
        OPEN SYMMETRIC KEY [KEY_HASH]
        DECRYPTION BY CERTIFICATE [CERT_SCRUMPLANNING];

        UPDATE [SQM_GENERAL].[TBL_Tasks]
        SET
            taskSummary = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Resumen)
            ),
            taskDescription = EncryptByKey(
                KEY_GUID('KEY_HASH'),
                CONVERT(VARBINARY(MAX), @Descripcion)
            ),
            taskOwner = @Responsable,
            taskParentLink = @PBI,
            taskOriginalEstimate = @Estimacion,
            taskCompletedWork = @TrabajoReal,
            taskRemainingWork = @TrabajoPendiente,
            taskStartDate = @Inicio,
            taskCompletedDate = @Finalizacion,
            taskDueDate = @Vencimiento,
            taskActivityType = @TipoActividad,
            taskModificationDate = GETDATE(),
            taskModificatorId = @Usuario,
            taskStatus = @Estado
        WHERE taskId = @IdTarea;

        CLOSE SYMMETRIC KEY [KEY_HASH];
    END
    ELSE
    BEGIN
        PRINT 'Accion no valida. Utilice I, U o S.';
    END
END;
GO