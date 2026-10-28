USE [DB_SCRUM_PLANNING]
GO

CREATE PROCEDURE [SQM_CATALOGS].[USP_BusinessValues]
    @i_businessValueId INT = NULL,
    @i_businessValueName VARCHAR(80) = NULL,
    @i_businessValueCreationDate DATETIME = NULL,
    @i_businessValueCreatorId INT = NULL,
    @i_businessValueModificationDate DATETIME = NULL,
    @i_businessValueModificatorId INT = NULL,
    @i_businessValueEnable BIT = NULL,
    @w_Accion CHAR(1),
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @o_Numero INT OUTPUT,
    @o_MensajeUsuario VARCHAR(150) OUTPUT,
    @o_MensajeTecnico VARCHAR(MAX) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    IF @i_businessValueCreationDate IS NULL
        SET @i_businessValueCreationDate = GETDATE();

    IF @i_businessValueModificationDate IS NULL
        SET @i_businessValueModificationDate = GETDATE();

  
    IF @w_Accion = 'I'
    BEGIN
       
        IF ISNULL(@i_businessValueName, '') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL VALOR DE NEGOCIO ES OBLIGATORIO';
            RETURN;
        END
        ELSE IF ISNULL(@i_businessValueCreatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueName = @i_businessValueName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO YA EXISTE';
            RETURN;
        END
        
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_businessValueCreatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO CREADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        BEGIN TRY
            INSERT INTO [SQM_CATALOGS].[TBL_BusinessValues]
            (
                businessValueName,
                businessValueCreationDate,
                businessValueCreatorId,
                businessValueModificationDate,
                businessValueModificatorId,
                businessValueEnable
            )
            VALUES
            (
                @i_businessValueName,
                @i_businessValueCreationDate,
                @i_businessValueCreatorId,
                NULL,
                NULL,
                ISNULL(@i_businessValueEnable, 1)
            );

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO INSERTADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL INSERTAR EL VALOR DE NEGOCIO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL INSERTAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'U'
    BEGIN
    
        IF ISNULL(@i_businessValueId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL VALOR DE NEGOCIO ES OBLIGATORIO';
            RETURN;
        END
        ELSE IF ISNULL(@i_businessValueModificatorId, 0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END
    
        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueId = @i_businessValueId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL VALOR DE NEGOCIO NO EXISTE';
            RETURN;
        END
    
        ELSE IF @i_businessValueName IS NOT NULL AND EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK) WHERE businessValueName = @i_businessValueName AND businessValueId <> @i_businessValueId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DEL VALOR DE NEGOCIO YA EXISTE EN OTRO REGISTRO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_businessValueModificatorId AND userEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO MODIFICADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        BEGIN TRY
            UPDATE [SQM_CATALOGS].[TBL_BusinessValues]
            SET businessValueName = ISNULL(@i_businessValueName, businessValueName),
                businessValueModificationDate = @i_businessValueModificationDate,
                businessValueModificatorId = @i_businessValueModificatorId,
                businessValueEnable = ISNULL(@i_businessValueEnable, businessValueEnable)
            WHERE businessValueId = @i_businessValueId;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR EL VALOR DE NEGOCIO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END
    
    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            DECLARE @w_totalRows INT = 0;

            SELECT 
                businessValueId,
                businessValueName,
                businessValueCreationDate,
                businessValueCreatorId,
                businessValueModificationDate,
                businessValueModificatorId,
                businessValueEnable
            FROM [SQM_CATALOGS].[TBL_BusinessValues] (NOLOCK)
            ORDER BY businessValueId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT;

            -- Validación de respuestas vacías (Imagen 5)
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
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS VALORES DE NEGOCIO';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR VALORES', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
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