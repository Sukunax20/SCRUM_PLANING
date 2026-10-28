USE [DB_SCRUM_PLANNING]
GO

CREATE PROCEDURE [SQM_CATALOGS].[USP_ActivityTypes]
    @i_activityTypeId INT = NULL,
    @i_activityTypeName VARCHAR(80) = NULL,
    @i_activityTypeCreationDate DATETIME = NULL,
    @i_activityTypeCreatorId INT = NULL,
    @i_activityTypeModificationDate DATETIME = NULL,
    @i_activityTypeModificatorId INT = NULL,
    @i_activityTypeEnable BIT = NULL,
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

    IF @i_activityTypeCreationDate IS NULL
        SET @i_activityTypeCreationDate = GETDATE();

    IF @i_activityTypeModificationDate IS NULL
        SET @i_activityTypeModificationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_activityTypeName, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL TIPO DE ACTIVIDAD ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_activityTypeCreatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeName = @i_activityTypeName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD YA EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_activityTypeCreatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO CREADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            INSERT INTO [SQM_CATALOGS].[TBL_ActivityTypes]
            (
                activityTypeName,
                activityTypeCreationDate,
                activityTypeCreatorId,
                activityTypeModificationDate,
                activityTypeModificatorId,
                activityTypeEnable
            )
            VALUES
            (
                @i_activityTypeName,
                @i_activityTypeCreationDate,
                @i_activityTypeCreatorId,
                NULL,
                NULL,
                ISNULL(@i_activityTypeEnable, 1)
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO INSERTADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL INSERTAR EL TIPO DE ACTIVIDAD';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL INSERTAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_activityTypeId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL TIPO DE ACTIVIDAD ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_activityTypeModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeId = @i_activityTypeId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL TIPO DE ACTIVIDAD NO EXISTE';
            RETURN;
        END

        ELSE IF @i_activityTypeName IS NOT NULL AND EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK) WHERE activityTypeName = @i_activityTypeName AND activityTypeId <> @i_activityTypeId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL TIPO DE ACTIVIDAD YA EXISTE EN OTRO REGISTRO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_activityTypeModificatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO MODIFICADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            UPDATE [SQM_CATALOGS].[TBL_ActivityTypes]
            SET activityTypeName = ISNULL(@i_activityTypeName, activityTypeName),
                activityTypeModificationDate = @i_activityTypeModificationDate,
                activityTypeModificatorId = @i_activityTypeModificatorId,
                activityTypeEnable = ISNULL(@i_activityTypeEnable, activityTypeEnable)
            WHERE activityTypeId = @i_activityTypeId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL TIPO DE ACTIVIDAD';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            DECLARE @w_totalRows INT = 0;

            SELECT 
                activityTypeId,
                activityTypeName,
                activityTypeCreationDate,
                activityTypeCreatorId,
                activityTypeModificationDate,
                activityTypeModificatorId,
                activityTypeEnable
            FROM [SQM_CATALOGS].[TBL_ActivityTypes] (NOLOCK)
            ORDER BY activityTypeId
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
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS TIPOS DE ACTIVIDAD';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR TIPOS DE ACTIVIDAD', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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
