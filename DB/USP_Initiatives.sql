USE [DB_SCRUM_PLANNING]
GO

CREATE PROCEDURE [SQM_GENERAL].[USP_Initiatives]
    @i_initiativeId INT = NULL,
    @i_initiativeSummary VARCHAR(200) = NULL,
    @i_initiativeDescription VARCHAR(2000)= NULL,
    @i_initiativeOwner INT = NULL,
    @i_initiativeGoals VARCHAR(255) = NULL,
    @i_initiativeBusinessValue INT = NULL,
    @i_initiativeTargetStart DATE = NULL,
    @i_initiativeTargetEnd DATE = NULL,
    @i_initiativeCreationDate DATETIME = NULL,
    @i_initiativeCreatorId INT = NULL,
    @i_initiativeModificationDate DATETIME = NULL,
    @i_initiativeModificatorId INT = NULL,
    @i_initiativeStatus INT = NULL,
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

    SET @o_Numero         = 0;
    SET @o_MensajeUsuario = '';
    SET @o_MensajeTecnico = '';

    IF @i_initiativeCreationDate IS NULL
        SET @i_initiativeCreationDate = GETDATE();

    IF @i_initiativeModificationDate IS NULL
        SET @i_initiativeModificationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_initiativeSummary, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA INICIATIVA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_initiativeDescription, '') = ''
        BEGIN
            SET @o_Numero         = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DE LA INICIATIVA ES OBLIGATORIA';
            RETURN;
        END

        ELSE IF ISNULL(@i_initiativeOwner, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DE LA INICIATIVA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_initiativeBusinessValue, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO DE LA INICIATIVA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_initiativeCreatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_initiativeStatus, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DE LA INICIATIVA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_initiativeOwner AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueId = @i_initiativeBusinessValue)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO REFERENCIADO NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_initiativeCreatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO CREADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_initiativeStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            INSERT INTO [SQM_GENERAL].[TBL_Initiatives]
            (
                initiativeSummary,
                initiativeDescription,
                initiativeOwner,
                initiativeGoals,
                initiativeBusinessValue,
                initiativeTargetStart,
                initiativeTargetEnd,
                initiativeCreationDate,
                initiativeCreatorId,
                initiativeModificationDate,
                initiativeModificatorId,
                initiativeStatus
            )
            VALUES
            (
                @i_initiativeSummary,
                @i_initiativeDescription,
                @i_initiativeOwner,
                @i_initiativeGoals,
                @i_initiativeBusinessValue,
                @i_initiativeTargetStart,
                @i_initiativeTargetEnd,
                @i_initiativeCreationDate,
                @i_initiativeCreatorId,
                NULL,
                NULL,
                @i_initiativeStatus
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO INSERTADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL INSERTAR LA INICIATIVA';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL INSERTAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_initiativeId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA INICIATIVA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_initiativeModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Initiatives] (NOLOCK) WHERE initiativeId = @i_initiativeId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA INICIATIVA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_initiativeModificatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO MODIFICADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_initiativeOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_initiativeOwner AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_initiativeBusinessValue IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueId = @i_initiativeBusinessValue)
        BEGIN
            SET @o_Numero         = 400;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO REFERENCIADO NO EXISTE';
            RETURN;
        END

        ELSE IF @i_initiativeStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId = @i_initiativeStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            UPDATE [SQM_GENERAL].[TBL_Initiatives]
            SET initiativeSummary = ISNULL(@i_initiativeSummary, initiativeSummary),
                initiativeDescription = ISNULL(@i_initiativeDescription, initiativeDescription),
                initiativeOwner = ISNULL(@i_initiativeOwner, initiativeOwner),
                initiativeGoals = ISNULL(@i_initiativeGoals, initiativeGoals),
                initiativeBusinessValue = ISNULL(@i_initiativeBusinessValue, initiativeBusinessValue),
                initiativeTargetStart = ISNULL(@i_initiativeTargetStart, initiativeTargetStart),
                initiativeTargetEnd = ISNULL(@i_initiativeTargetEnd, initiativeTargetEnd),
                initiativeModificationDate = @i_initiativeModificationDate,
                initiativeModificatorId = @i_initiativeModificatorId,
                initiativeStatus = ISNULL(@i_initiativeStatus, initiativeStatus)
            WHERE initiativeId = @i_initiativeId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR LA INICIATIVA';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            DECLARE @w_totalRows INT = 0;

            SELECT 
                initiativeId,
                initiativeSummary,
                initiativeDescription,
                initiativeOwner,
                initiativeGoals,
                initiativeBusinessValue,
                initiativeTargetStart,
                initiativeTargetEnd,
                initiativeCreationDate,
                initiativeCreatorId,
                initiativeModificationDate,
                initiativeModificatorId,
                initiativeStatus
            FROM [SQM_GENERAL].[TBL_Initiatives] (NOLOCK)
            ORDER BY initiativeId
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
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS INICIATIVAS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR INICIATIVAS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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