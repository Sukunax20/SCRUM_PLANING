USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_SECURITY].[USP_Roles]
(
    @i_rolId INT = NULL,
    @i_rolName VARCHAR(80) = NULL,
    @i_rolCreationDate DATETIME = NULL,
    @i_rolCreatorId INT = NULL,
    @i_rolModificationDate DATETIME = NULL,
    @i_rolModificatorId INT = NULL,
    @i_rolEnable BIT = NULL,
    @i_rolPassword VARCHAR(256) = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeRol VARCHAR(500) = NULL OUT
)
AS
BEGIN
    DECLARE @w_rolPasswordEncrypted VARBINARY(256)
    DECLARE @w_totalRows INT

    IF @i_rolCreationDate IS NULL
        SET @i_rolCreationDate = GETDATE();

    IF @i_rolModificationDate IS NULL
        SET @i_rolModificationDate = GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_rolName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeRol = 'EL NOMBRE DEL ROL ES OBLIGATORIO';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK) WHERE rolName = @i_rolName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeRol = 'EL NOMBRE DEL ROL YA EXISTE';
        END;

        ELSE
        BEGIN

            BEGIN TRANSACTION TRX_INS_ROL;
            BEGIN TRY

                OPEN SYMMETRIC KEY KEY_HASH
                DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;

                SET @w_rolPasswordEncrypted = [SQM_SECURITY].[Fn_EncryptByKey](@i_rolPassword);

                CLOSE SYMMETRIC KEY KEY_HASH;

                INSERT INTO [SQM_SECURITY].[TBL_Roles](rolName,rolCreationDate,rolCreatorId,rolEnable)
                VALUES(@i_rolName,@i_rolCreationDate,@i_rolCreatorId,1);

                COMMIT TRANSACTION TRX_INS_ROL;

                SET @o_Numero = 201;
                SET @o_MensajeRol = 'ROL REGISTRADO CORRECTAMENTE';

            END TRY

            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_INS_ROL;

                SET @o_Numero = 500;
                SET @o_MensajeRol = 'ERROR AL REGISTRAR ROL';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR ROL', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH   
        END
    END

    ELSE IF @Accion = 'U'
    BEGIN
        IF ISNULL(@i_rolId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeRol = 'EL ID DEL ROL ES OBLIGATORIO';
        END;

        IF ISNULL(@i_rolModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeRol = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK) WHERE rolId = @i_rolId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
        END;

        ELSE IF @i_rolName IS NOT NULL AND EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK) WHERE rolName = @i_rolName
        AND rolId <> @i_rolId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeRol = 'EL NOMBRE DE ROL YA EXISTE';
        END;

        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_ROL;
            BEGIN TRY
                IF @i_rolPassword IS NOT NULL
                BEGIN
                    OPEN SYMMETRIC KEY KEY_HASH
                    DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;
                        SET @w_rolPasswordEncrypted = [SQM_SECURITY].Fn_EncryptByKey(@i_rolPassword);
                    CLOSE SYMMETRIC KEY KEY_HASH;
                END

                UPDATE [SQM_SECURITY].[TBL_Roles]
                SET rolName = COALESCE(@i_rolName,rolName),
                    rolModificationDate = @i_rolModificationDate,
                    rolModificatorId = @i_rolModificatorId,
                    rolEnable = COALESCE(@i_rolEnable,rolEnable)
                WHERE rolId = @i_rolId;

                COMMIT TRANSACTION TRX_UPD_ROL;

                SET @o_Numero = 200;
                SET @o_MensajeRol = 'ROL ACTUALIZADO CORRECTAMENTE';
            END TRY

            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_ROL;

                SET @o_Numero = 500;
                SET @o_MensajeRol = 'ERROR AL ACTUALIZAR USUARIO'
                SET @o_MensajeTecnico =  CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR ROL', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
            END CATCH
        END 
    END

    ELSE IF @Accion = 'S'
    BEGIN
        BEGIN TRY

            SELECT 
                rolId, 
                rolName,
                rolCreationDate,
                rolCreatorId,
                rolModificationDate,
                rolModificatorId,
                rolEnable
            FROM [SQM_SECURITY].[TBL_Roles] (NOLOCK)
            ORDER BY rolId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeRol = 'ROL LISTADO CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeRol = 'NO HAY MAS REGISTROS PARA EL ROL A LISTAR';
            END
        END TRY

        BEGIN CATCH
            SET @o_Numero = 500;
            SET @o_MensajeRol = 'ERROR AL LISTAR LOS ROLES';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR EL ROL', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());
        END CATCH
    END

    ELSE
    BEGIN
        SET @o_Numero = 405;
        SET @o_MensajeRol = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';
    END
END
GO