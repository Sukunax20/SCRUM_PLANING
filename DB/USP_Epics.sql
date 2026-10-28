USE [DB_SCRUM_PLANNING]
GO

CREATE PROCEDURE [SQM_GENERAL].[USP_Epics]
    @i_epicId INT = NULL,
    @i_epicName VARCHAR(100) = NULL,
    @i_epicSummary VARCHAR(500) = NULL,
    @i_epicDescription VARCHAR(4000)= NULL,
    @i_epicParentLink INT = NULL,
    @i_epicOwner INT = NULL,
    @i_epicStartDate DATE = NULL,
    @i_epicDueDate DATE = NULL,
    @i_epicPriority INT = NULL,
    @i_epicCreationDate DATETIME = NULL,
    @i_epicCreatorId INT = NULL,
    @i_epicModificationDate DATETIME = NULL,
    @i_epicModificatorId INT = NULL,
    @i_epicStatus INT = NULL,
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

    IF @i_epicCreationDate IS NULL
        SET @i_epicCreationDate = GETDATE();

    IF @i_epicModificationDate IS NULL
        SET @i_epicModificationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_epicName, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE LA EPICA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_epicSummary, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA EPICA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_epicDescription, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DE LA EPICA ES OBLIGATORIA';
            RETURN;
        END

        ELSE IF ISNULL(@i_epicParentLink, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL PARENT LINK DE LA INICIATIVA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_epicOwner, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DE LA EPICA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_epicCreatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_epicStatus, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DE LA EPICA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK) WHERE epicName = @i_epicName AND epicParentLink = @i_epicParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE LA EPICA YA EXISTE EN ESTA INICIATIVA';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Initiatives] (NOLOCK) WHERE initiativeId = @i_epicParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA INICIATIVA REFERENCIADA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_epicOwner AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_epicCreatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO CREADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_epicPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_epicPriority)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD ASIGNADA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_epicStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

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
                epicModificationDate,
                epicModificatorId,
                epicStatus
            )
            VALUES
            (
                @i_epicName,
                @i_epicSummary,
                @i_epicDescription,
                @i_epicParentLink,
                @i_epicOwner,
                @i_epicStartDate,
                @i_epicDueDate,
                @i_epicPriority,
                @i_epicCreationDate,
                @i_epicCreatorId,
                NULL,
                NULL,
                @i_epicStatus
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO INSERTADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL INSERTAR LA EPICA';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL INSERTAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_epicId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA EPICA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_epicModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK) WHERE epicId = @i_epicId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA EPICA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_epicModificatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO MODIFICADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_epicParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Initiatives] (NOLOCK) WHERE initiativeId = @i_epicParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA INICIATIVA REFERENCIADA NO EXISTE';
            RETURN;
        END

        ELSE IF @i_epicOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_epicOwner AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_epicPriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId = @i_epicPriority)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD ASIGNADA NO EXISTE';
            RETURN;
        END

        ELSE IF @i_epicStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_epicStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        ELSE IF @i_epicName IS NOT NULL AND EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK) WHERE epicName = @i_epicName AND epicParentLink = ISNULL(@i_epicParentLink, epicParentLink) AND epicId <> @i_epicId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE LA EPICA YA EXISTE EN ESTA INICIATIVA';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            UPDATE [SQM_GENERAL].[TBL_Epics]
            SET epicName = ISNULL(@i_epicName, epicName),
                epicSummary = ISNULL(@i_epicSummary, epicSummary),
                epicDescription = ISNULL(@i_epicDescription, epicDescription),
                epicParentLink = ISNULL(@i_epicParentLink, epicParentLink),
                epicOwner = ISNULL(@i_epicOwner, epicOwner),
                epicStartDate = ISNULL(@i_epicStartDate, epicStartDate),
                epicDueDate = ISNULL(@i_epicDueDate, epicDueDate),
                epicPriority = ISNULL(@i_epicPriority, epicPriority),
                epicModificationDate = @i_epicModificationDate,
                epicModificatorId = @i_epicModificatorId,
                epicStatus = ISNULL(@i_epicStatus, epicStatus)
                WHERE epicId = @i_epicId;

            COMMIT TRANSACTION;
            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR LA EPICA';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            DECLARE @w_totalRows INT = 0;

            SELECT 
                epicId,
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
                epicModificationDate,
                epicModificatorId,
                epicStatus
            FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK)
            ORDER BY epicId
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
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS EPICAS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR EPICAS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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
