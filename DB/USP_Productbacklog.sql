USE [DB_SCRUM_PLANNING]
GO

CREATE PROCEDURE [SQM_GENERAL].[USP_ManageProductBacklogItems]
    @w_Accion CHAR(1),
    @i_PBIId INT = NULL,
    @i_PBISummary VARCHAR(500) = NULL,
    @i_PBIDescription VARCHAR(2000) = NULL,
    @i_PBIsAcceptanceCriteria VARCHAR(4000) = NULL,
    @i_PBIOwner INT = NULL,
    @i_PBIParentLink INT = NULL,
    @i_PBIStoryPoint INT = NULL,
    @i_PBIStartDate DATE = NULL,
    @i_PBIDueDate DATE = NULL,
    @i_PBIPriority INT = NULL,
    @i_PBICreationDate DATETIME = NULL,
    @i_PBICreatorId INT = NULL,
    @i_PBIModificationDate DATETIME = NULL,
    @i_PBIModificatorId INT = NULL,
    @i_PBIStatus INT = NULL,
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

    IF @i_PBICreationDate IS NULL
        SET @i_PBICreationDate = GETDATE();

    IF @i_PBIModificationDate IS NULL
        SET @i_PBIModificationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_PBISummary, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DEL PBI ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_PBIDescription, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DEL PBI ES OBLIGATORIA';
            RETURN;
        END

        ELSE IF ISNULL(@i_PBIsAcceptanceCriteria, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS CRITERIOS DE ACEPTACION SON OBLIGATORIOS';
            RETURN;
        END

        ELSE IF ISNULL(@i_PBIOwner, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DEL PBI ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_PBIParentLink, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL PARENT LINK DE LA FEATURE ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_PBICreatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_PBIStatus, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DEL PBI ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBISummary = @i_PBISummary AND PBIParentLink = @i_PBIParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DEL PBI YA EXISTE EN ESTA FEATURE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureId = @i_PBIParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA FEATURE REFERENCIADA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_PBIOwner AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_PBICreatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO CREADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_PBIPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_PBIPriority)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD ASIGNADA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_PBIStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            INSERT INTO [SQM_GENERAL].[TBL_ProductBacklogItems]
            (
                PBISummary,
                PBIDescription,
                PBIsAcceptanceCriteria,
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
            )
            VALUES
            (
                @i_PBISummary,
                @i_PBIDescription,
                @i_PBIsAcceptanceCriteria,
                @i_PBIOwner,
                @i_PBIParentLink,
                @i_PBIStoryPoint,
                @i_PBIStartDate,
                @i_PBIDueDate,
                @i_PBIPriority,
                @i_PBICreationDate,
                @i_PBICreatorId,
                NULL,
                NULL,
                @i_PBIStatus
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO INSERTADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL INSERTAR EL PBI';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL INSERTAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_PBIId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL PBI ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_PBIModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBIId = @i_PBIId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL PBI NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_PBIModificatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO MODIFICADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_PBIParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureId = @i_PBIParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA FEATURE REFERENCIADA NO EXISTE';
            RETURN;
        END

        ELSE IF @i_PBIOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_PBIOwner AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_PBIPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_PBIPriority)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD ASIGNADA NO EXISTE';
            RETURN;
        END

        ELSE IF @i_PBIStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_PBIStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        ELSE IF @i_PBISummary IS NOT NULL AND EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK) WHERE PBISummary = @i_PBISummary AND PBIParentLink = ISNULL(@i_PBIParentLink, PBIParentLink) AND PBIId <> @i_PBIId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DEL PBI YA EXISTE EN ESTA FEATURE';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            UPDATE [SQM_GENERAL].[TBL_ProductBacklogItems]
            SET PBISummary = ISNULL(@i_PBISummary, PBISummary),
                PBIDescription = ISNULL(@i_PBIDescription, PBIDescription),
                PBIsAcceptanceCriteria = ISNULL(@i_PBIsAcceptanceCriteria, PBIsAcceptanceCriteria),
                PBIOwner = ISNULL(@i_PBIOwner, PBIOwner),
                PBIParentLink = ISNULL(@i_PBIParentLink, PBIParentLink),
                PBIStoryPoint = ISNULL(@i_PBIStoryPoint, PBIStoryPoint),
                PBIStartDate = ISNULL(@i_PBIStartDate, PBIStartDate),
                PBIDueDate = ISNULL(@i_PBIDueDate, PBIDueDate),
                PBIPriority = ISNULL(@i_PBIPriority, PBIPriority),
                PBIModificationDate = @i_PBIModificationDate,
                PBIModificatorId = @i_PBIModificatorId,
                PBIStatus = ISNULL(@i_PBIStatus, PBIStatus)
            WHERE PBIId = @i_PBIId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL PBI';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            DECLARE @w_totalRows INT = 0;

            SELECT 
                PBIId,
                PBISummary,
                PBIDescription,
                PBIsAcceptanceCriteria,
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
            FROM [SQM_GENERAL].[TBL_ProductBacklogItems] (NOLOCK)
            ORDER BY PBIId
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
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS PRODUCT BACKLOG ITEMS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR PBI', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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
