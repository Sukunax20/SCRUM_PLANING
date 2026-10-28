USE [DB_SCRUM_PLANNING]
GO

CREATE PROCEDURE [SQM_GENERAL].[USP_Tasks]
    @i_taskId INT = NULL,
    @i_taskSummary VARCHAR(500) = NULL,
    @i_taskDescription VARCHAR(2000) = NULL,
    @i_taskOwner INT = NULL,
    @i_taskParentLink INT = NULL,
    @i_taskOriginalEstimate DECIMAL(4,2) = NULL,
    @i_taskCompletedWork DECIMAL(4,2) = NULL,
    @i_taskRemaningWork DECIMAL(4,2) = NULL,
    @i_taskStartDate DATE = NULL,
    @i_taskCompletedDate DATE = NULL,
    @i_taskDueDate DATE = NULL,
    @i_taskActivityType INT = NULL,
    @i_taskCreationDate DATETIME = NULL,
    @i_taskCreatorId INT = NULL,
    @i_taskModificationDate DATETIME = NULL,
    @i_taskModificatorId INT = NULL,
    @i_taskStatus INT = NULL,
    @w_Accion CHAR(1),
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @o_Numero INT OUTPUT,
    @o_MensajeUsuario VARCHAR(150) OUTPUT,
    @o_MensajeTecnico VARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @o_Numero = 0;
    SET @o_MensajeUsuario = '';
    SET @o_MensajeTecnico = '';

    IF @i_taskCreationDate IS NULL
        SET @i_taskCreationDate = GETDATE();

    IF @i_taskModificationDate IS NULL
        SET @i_taskModificationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_taskSummary, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA TAREA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_taskDescription, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DE LA TAREA ES OBLIGATORIA';
            RETURN;
        END

        ELSE IF ISNULL(@i_taskOwner, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DE LA TAREA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_taskParentLink, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL PARENT LINK DEL PRODUCT BACKLOG ITEM ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_taskCreatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_taskStatus, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DE LA TAREA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Tasks] (NOLOCK) WHERE taskSummary = @i_taskSummary AND taskParentLink = @i_taskParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA TAREA YA EXISTE EN ESTE PBI';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBIId = @i_taskParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL PRODUCT BACKLOG ITEM REFERENCIADO NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_taskOwner AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_taskCreatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO CREADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_taskActivityType IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeId = @i_taskActivityType)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD ASIGNADO NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_taskStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            INSERT INTO [SQM_GENERAL].[TBL_Tasks]
            (
                taskSummary,
                taskDescription,
                taskOwner,
                taskParentLink,
                taskOriginalEstimate,
                taskCompletedWork,
                taskRemaningWork,
                taskStartDate,
                taskCompletedDate,
                taskDueDate,
                taskActivityType,
                taskCreationDate,
                taskCreatorId,
                taskModificationDate,
                taskModificatorId,
                taskStatus
            )
            VALUES
            (
                @i_taskSummary,
                @i_taskDescription,
                @i_taskOwner,
                @i_taskParentLink,
                @i_taskOriginalEstimate,
                @i_taskCompletedWork,
                @i_taskRemaningWork,
                @i_taskStartDate,
                @i_taskCompletedDate,
                @i_taskDueDate,
                @i_taskActivityType,
                @i_taskCreationDate,
                @i_taskCreatorId,
                NULL,
                NULL,
                @i_taskStatus
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO INSERTADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL INSERTAR LA TAREA';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL INSERTAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_taskId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA TAREA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_taskModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Tasks] (NOLOCK) WHERE taskId = @i_taskId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA TAREA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_taskModificatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO MODIFICADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_taskParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBIId = @i_taskParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL PRODUCT BACKLOG ITEM REFERENCIADO NO EXISTE';
            RETURN;
        END

        ELSE IF @i_taskOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_taskOwner AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_taskActivityType IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeId = @i_taskActivityType)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD ASIGNADO NO EXISTE';
            RETURN;
        END

        ELSE IF @i_taskStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_taskStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        ELSE IF @i_taskSummary IS NOT NULL AND EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Tasks] (NOLOCK) WHERE taskSummary = @i_taskSummary AND taskParentLink = ISNULL(@i_taskParentLink, taskParentLink) AND taskId <> @i_taskId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA TAREA YA EXISTE EN ESTE PBI';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            UPDATE [SQM_GENERAL].[TBL_Tasks]
            SET taskSummary = ISNULL(@i_taskSummary, taskSummary),
                taskDescription = ISNULL(@i_taskDescription, taskDescription),
                taskOwner = ISNULL(@i_taskOwner, taskOwner),
                taskParentLink = ISNULL(@i_taskParentLink, taskParentLink),
                taskOriginalEstimate = ISNULL(@i_taskOriginalEstimate, taskOriginalEstimate),
                taskCompletedWork = ISNULL(@i_taskCompletedWork, taskCompletedWork),
                taskRemaningWork = ISNULL(@i_taskRemaningWork, taskRemaningWork),
                taskStartDate = ISNULL(@i_taskStartDate, taskStartDate),
                taskCompletedDate = ISNULL(@i_taskCompletedDate, taskCompletedDate),
                taskDueDate = ISNULL(@i_taskDueDate, taskDueDate),
                taskActivityType = ISNULL(@i_taskActivityType, taskActivityType),
                taskModificationDate = @i_taskModificationDate,
                taskModificatorId = @i_taskModificatorId,
                taskStatus = ISNULL(@i_taskStatus, taskStatus)
            WHERE taskId = @i_taskId;

            COMMIT TRANSACTION;
            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR LA TAREA';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            DECLARE @w_totalRows INT = 0;

            SELECT 
                taskId,
                taskSummary,
                taskDescription,
                taskOwner,
                taskParentLink,
                taskOriginalEstimate,
                taskCompletedWork,
                taskRemaningWork,
                taskStartDate,
                taskCompletedDate,
                taskDueDate,
                taskActivityType,
                taskCreationDate,
                taskCreatorId,
                taskModificationDate,
                taskModificatorId,
                taskStatus
            FROM [SQM_GENERAL].[TBL_Tasks] (NOLOCK)
            ORDER BY taskId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT;

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'REGISTROS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS TAREAS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR TAREAS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END
END;
GO
