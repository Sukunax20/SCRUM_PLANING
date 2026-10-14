USE [DB_SCRUM_PLANNING]
GO

CREATE OR ALTER PROC [SQM_SECURITY].[USP_Users]
(
    @i_userId INT = NULL,
    @i_userFullName VARCHAR(80) = NULL,
    @i_userName VARCHAR(80) = NULL,
    @i_userEmail VARCHAR(80) = NULL,
    @i_userPassword VARCHAR(256) = NULL,
    @i_userRolId INT = NULL,
    @i_userCreationDate DATETIME = NULL,
    @i_userCreatorId INT = NULL,
    @i_userModificationDate DATETIME = NULL,
    @i_userModificatorId INT = NULL,
    @i_userEnable BIT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUT
)
AS
BEGIN

    DECLARE @w_userPasswordEncrypted VARBINARY(256), @w_totalRows INT;

    IF @i_userCreationDate IS NULL
        SET @i_userCreationDate = GETDATE();

    IF @i_userModificationDate IS NULL
        SET @i_userModificationDate = GETDATE();

    -- INSERTAR USER --
    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_userFullName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE COMPLETO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userName,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userEmail,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO ELECTRONICO ES OBLIGATORIO';
        END;

        ELSE IF ISNULL(@i_userPassword,'') = ''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA CONTRASEÑA ES OBLIGATORIA';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userName = @i_userName)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO YA EXISTE';
        END;

        ELSE IF EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userEmail = @i_userEmail)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO YA EXISTE';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Roles] (NOLOCK) WHERE rolId = @i_userRolId AND rolEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_INS_USER;

            BEGIN TRY

                OPEN SYMMETRIC KEY KEY_HASH
                DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;

                SET @w_userPasswordEncrypted = [SQM_SECURITY].[Fn_EncryptByKey](@i_userPassword);

                CLOSE SYMMETRIC KEY KEY_HASH;

                INSERT INTO [SQM_SECURITY].[TBL_Users](userFullName,userName,userEmail,userPassword,userRolId,userCreationDate,userCreatorId,userEnable)
                VALUES(@i_userFullName,@i_userName,@i_userEmail,@w_userPasswordEncrypted,@i_userRolId,@i_userCreationDate,@i_userCreatorId,1);

                COMMIT TRANSACTION TRX_INS_USER;

                SET @o_Numero = 201;
                SET @o_MensajeUsuario = 'USUARIO REGISTRADO CORRECTAMENTE';

            END TRY

            BEGIN CATCH

                ROLLBACK TRANSACTION TRX_INS_USER;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL REGISTRAR USUARIO';
                SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL REGISTRAR USUARIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

            END CATCH
        END
    END

    -- UPDATE USER --
    ELSE IF @w_Accion = 'U'
    BEGIN

        IF ISNULL(@i_userId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL USUARIO ES OBLIGATORIO';
        END;

        IF ISNULL(@i_userModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
        END;

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId = @i_userId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'EL USUARIO NO EXISTE';
        END;

        ELSE IF @i_userName IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userName = @i_userName
        AND userId <> @i_userId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL NOMBRE DE USUARIO YA EXISTE';
        END;

        ELSE IF @i_userEmail IS NOT NULL AND
            EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userEmail = @i_userEmail
        AND userId <> @i_userId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL CORREO YA EXISTE';
        END;

        ELSE IF @i_userRolId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Roles] (NOLOCK) 
		WHERE rolId = @i_userRolId AND rolEnable = 1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ROL NO EXISTE';
        END;
        
        ELSE
        BEGIN
            BEGIN TRANSACTION TRX_UPD_USER;

            BEGIN TRY

                IF @i_userPassword IS NOT NULL
                BEGIN
                    OPEN SYMMETRIC KEY KEY_HASH
                    DECRYPTION BY CERTIFICATE CERT_SCRUMPLANNING;
                        SET @w_userPasswordEncrypted = [SQM_SECURITY].Fn_EncryptByKey(@i_userPassword);
                    CLOSE SYMMETRIC KEY KEY_HASH;
                END

                UPDATE [SQM_SECURITY].[TBL_Users]
                SET userFullName = COALESCE(@i_userFullName,userFullName),
                    userName = COALESCE(@i_userName,userName),
                    userEmail = COALESCE(@i_userEmail,userEmail),
                    userPassword = COALESCE(@w_userPasswordEncrypted,userPassword),
                    userRolId = COALESCE(@i_userRolId,userRolId),
                    userModificationDate = @i_userModificationDate,
                    userModificatorId = @i_userModificatorId,
                    userEnable = COALESCE(@i_userEnable,userEnable)
                WHERE userId = @i_userId;

                COMMIT TRANSACTION TRX_UPD_USER;

                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'USUARIO ACTUALIZADO CORRECTAMENTE';

            END TRY

            BEGIN CATCH
                ROLLBACK TRANSACTION TRX_UPD_USER;

                SET @o_Numero = 500;
                SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR USUARIO'
                SET @o_MensajeTecnico =  CONCAT_WS(' - ', 'ERROR AL ACTUALIZAR USUARIO', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

            END CATCH
        END
    END

-- SELECT USER --
    ELSE IF @w_Accion = 'S'
    BEGIN

        BEGIN TRY

            SELECT 
                userId, 
                userFullName,
                userName,
                userEmail,
                userRolId,
                userCreationDate,
                userCreatorId,
                userModificationDate,
                userModificatorId,
                userEnable
            FROM [SQM_SECURITY].[TBL_Users] (NOLOCK)
            ORDER BY userId
            OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT

            IF (@w_totalRows > 0)
            BEGIN
                SET @o_Numero = 200;
                SET @o_MensajeUsuario = 'USUARIOS LISTADOS CORRECTAMENTE';
            END
            ELSE
            BEGIN
                SET @o_Numero = 204;
                SET @o_MensajeUsuario = 'NO HAY MAS REGISTROS PARA LISTAR';
            END
        END TRY

        BEGIN CATCH

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LOS USUARIOS';
            SET @o_MensajeTecnico = CONCAT_WS(' - ', 'ERROR AL LISTAR USUARIOS', ERROR_PROCEDURE(), ERROR_LINE(), ERROR_MESSAGE());

        END CATCH

    END

 -- ACCION INVALIDA --
    ELSE
    BEGIN

        SET @o_Numero = 405;
        SET @o_MensajeUsuario = 'METODO NO HABILITADO';
        SET @o_MensajeTecnico = 'EL PROCEDIMIENTO ALMACENADO NO TIENE HABILITADA ESA OPCION';

    END

END;
GO
--==============================================================================================
CREATE OR ALTER PROC [SQM_CATALOGOS].[USP_Status]
(
    @i_statusId INT = NULL,
    @i_statusName VARCHAR(80) = NULL,
    @i_statusCreatorId INT = NULL,
    @i_statusModifierId INT = NULL,
    @i_statusEnable BIT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @o_Numero = 200;
    SET @o_MensajeTecnico = '';
    SET @o_MensajeUsuario = '';

    BEGIN TRY

        -- INSERTAR STATUS
        IF @w_Accion = 'I'
        BEGIN
            IF ISNULL(@i_statusName, '') = ''
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'EL NOMBRE DEL STATUS ES OBLIGATORIO';
            END
            ELSE IF @i_statusCreatorId IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'EL ID DEL CREADOR ES OBLIGATORIO';
            END
            ELSE
            BEGIN
                INSERT INTO [SQM_CATALOGOS].[TBL_Status](
                    statusName,
                    statusCreationDate,
                    statusCreatorId,
                    statusModificationDate,
                    statusModifierId,
                    statusEnable
                )
                VALUES
                (
                    @i_statusName,
                    GETDATE(),
                    @i_statusCreatorId,
                    GETDATE(),
                    @i_statusModifierId,
                    ISNULL(@i_statusEnable, 1)
                );
                SET @o_MensajeUsuario = 'STATUS INSERTADO CORRECTAMENTE';
            END
        END

        -- ACTUALIZAR STATUS
        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_statusId, 0) = 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL ID DEL STATUS ES OBLIGATORIO';
            END
            ELSE IF NOT EXISTS
            (
                SELECT 1
                FROM [SQM_CATALOGOS].[TBL_Status]
                WHERE statusId = @i_statusId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeUsuario = 'EL STATUS NO EXISTE';
            END
            ELSE IF ISNULL(@i_statusName, '') = ''
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL NOMBRE DEL STATUS ES OBLIGATORIO';
            END
            ELSE
            BEGIN
                UPDATE [SQM_CATALOGOS].[TBL_Status]
                SET
                    statusName = @i_statusName,
                    statusModificationDate = GETDATE(),
                    statusModifierId = @i_statusModifierId,
                    statusEnable = @i_statusEnable
                WHERE statusId = @i_statusId;

                SET @o_MensajeUsuario = 'STATUS ACTUALIZADO CORRECTAMENTE';
            END
        END

        -- LISTAR STATUS CON PAGINACION
        ELSE IF @w_Accion = 'S'
        BEGIN
            IF ISNULL(@i_PageNumber, 0) <= 0
                OR ISNULL(@i_RowsPerPage, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'PAGINA Y REGISTROS POR PAGINA DEBEN SER MAYORES QUE CERO';
            END
            ELSE
            BEGIN
                SELECT
                    statusId,
                    statusName,
                    statusCreationDate,
                    statusCreatorId,
                    statusModificationDate,
                    statusModifierId,
                    statusEnable
                FROM [SQM_CATALOGOS].[TBL_Status]
                ORDER BY statusId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @o_MensajeUsuario = 'STATUS LISTADOS CORRECTAMENTE';
            END
        END

        ELSE
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'METODO NO HABILITADO';
            SET @o_MensajeTecnico = 'LA ACCION DEBE SER I, U O S';
        END

    END TRY
    BEGIN CATCH
        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'ERROR AL PROCESAR LOS STATUS';
    END CATCH
END;
GO
--====================================================================================
CREATE OR ALTER PROC [SQM_SECURITY].[USP_Roles]
(
    @i_rolId INT = NULL,
    @i_rolName VARCHAR(80) = NULL,
    @i_rolCreatorId INT = NULL,
    @i_rolModifierId INT = NULL,
    @i_rolEnable BIT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),

    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @o_Numero = 200;
    SET @o_MensajeTecnico = '';
    SET @o_MensajeUsuario = '';

    BEGIN TRY

        -- INSERTAR ROL
        IF @w_Accion = 'I'
        BEGIN
            IF ISNULL(@i_rolName, '') = ''
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL NOMBRE DEL ROL ES OBLIGATORIO';
            END
            ELSE IF @i_rolCreatorId IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            END
            ELSE
            BEGIN
                INSERT INTO [SQM_SECURITY].[TBL_Roles]
                (
                    rolName,
                    rolCreationDate,
                    rolCreatorId,
                    rolModificationDate,
                    rolModifierId,
                    rolEnable
                )
                VALUES
                (
                    @i_rolName,
                    GETDATE(),
                    @i_rolCreatorId,
                    GETDATE(),
                    @i_rolModifierId,
                    ISNULL(@i_rolEnable, 1)
                );

                SET @o_MensajeUsuario = 'ROL INSERTADO CORRECTAMENTE';
            END
        END

        -- ACTUALIZAR ROL
        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_rolId, 0) = 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL ID DEL ROL ES OBLIGATORIO';
            END
            ELSE IF NOT EXISTS
            (
                SELECT 1
                FROM [SQM_SECURITY].[TBL_Roles]
                WHERE rolId = @i_rolId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeUsuario ='EL ROL NO EXISTE';
            END
            ELSE IF ISNULL(@i_rolName, '') = ''
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL NOMBRE DEL ROL ES OBLIGATORIO';
            END
            ELSE
            BEGIN
                UPDATE [SQM_SECURITY].[TBL_Roles]
                SET
                    rolName = @i_rolName,
                    rolModificationDate = GETDATE(),
                    rolModifierId = @i_rolModifierId,
                    rolEnable = ISNULL(@i_rolEnable, rolEnable)
                WHERE rolId = @i_rolId;

                SET @o_MensajeUsuario = 'ROL ACTUALIZADO CORRECTAMENTE';
            END
        END

        -- LISTAR ROLES CON PAGINACION
        ELSE IF @w_Accion = 'S'
        BEGIN
            IF ISNULL(@i_PageNumber, 0) <= 0
                OR ISNULL(@i_RowsPerPage, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'PAGINA Y REGISTROS POR PAGINA DEBEN SER MAYORES QUE CERO';
            END
            ELSE
            BEGIN
                SELECT
                    rolId,
                    rolName,
                    rolCreationDate,
                    rolCreatorId,
                    rolModificationDate,
                    rolModifierId,
                    rolEnable
                FROM [SQM_SECURITY].[TBL_Roles]
                ORDER BY rolId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @o_MensajeUsuario = 'ROLES LISTADOS CORRECTAMENTE';
            END
        END

        ELSE
        BEGIN
            SET @o_Numero = 405;
            SET @o_MensajeUsuario = 'METODO NO HABILITADO';
            SET @o_MensajeTecnico = 'LA ACCION DEBE SER I, U O S';
        END

    END TRY
    BEGIN CATCH
        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'ERROR AL PROCESAR LOS ROLES';
    END CATCH
END;
GO

--===================================================================================
CREATE OR ALTER PROCEDURE [SQM_SECURITY].[USP_Users]
(
    @i_userId INT = NULL,
    @i_userFullname VARCHAR(80) = NULL,
    @i_userName VARCHAR(80) = NULL,
    @i_userEmail VARCHAR(80) = NULL,
    @i_userPassword VARBINARY(256) = NULL,
    @i_userRolId INT = NULL,
    @i_userCreatorId INT = NULL,
    @i_userModifierId INT = NULL,
    @i_userEnable BIT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1) = NULL,
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @o_Numero = 200;
    SET @o_MensajeTecnico = '';
    SET @o_MensajeUsuario = '';

    BEGIN TRY

        -- INSERTAR
        IF @w_Accion = 'I'
        BEGIN
            IF @i_userFullname IS NULL
               OR @i_userName IS NULL
               OR @i_userEmail IS NULL
               OR @i_userPassword IS NULL
               OR @i_userRolId IS NULL
               OR @i_userCreatorId IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario =
                    'FALTAN CAMPOS OBLIGATORIOS';
            END
            ELSE
            BEGIN
                INSERT INTO [SQM_SECURITY].[TBL_Users]
                (
                    userFullname,
                    userName,
                    userEmail,
                    userPassword,
                    userRolId,
                    userCreationDate,
                    userCreatorId,
                    userModificationDate,
                    userModifierId,
                    userEnable
                )
                VALUES
                (
                    @i_userFullname,
                    @i_userName,
                    @i_userEmail,
                    @i_userPassword,
                    @i_userRolId,
                    GETDATE(),
                    @i_userCreatorId,
                    GETDATE(),
                    @i_userModifierId,
                    ISNULL(@i_userEnable, 1)
                );

                SET @o_MensajeUsuario = 'USUARIO INSERTADO CORRECTAMENTE';
            END
        END

        ELSE IF @w_Accion = 'U'
        BEGIN
            IF @i_userId IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL ID DEL USUARIO ES OBLIGATORIO';
            END
            ELSE IF NOT EXISTS
            (
                SELECT 1
                FROM [SQM_SECURITY].[TBL_Users]
                WHERE userId = @i_userId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeUsuario = 'EL USUARIO NO EXISTE';
            END
            ELSE
            BEGIN
                UPDATE [SQM_SECURITY].[TBL_Users]
                SET
                    userFullname =
                        ISNULL(@i_userFullname, userFullname),
                    userName =
                        ISNULL(@i_userName, userName),
                    userEmail =
                        ISNULL(@i_userEmail, userEmail),
                    userPassword =
                        ISNULL(@i_userPassword, userPassword),
                    userRolId =
                        ISNULL(@i_userRolId, userRolId),
                    userModificationDate = GETDATE(),
                    userModifierId = @i_userModifierId,
                    userEnable =
                        ISNULL(@i_userEnable, userEnable)
                WHERE userId = @i_userId;

                SET @o_MensajeUsuario = 'USUARIO ACTUALIZADO CORRECTAMENTE';
            END
        END

        ELSE IF @w_Accion = 'S'
        BEGIN
            IF ISNULL(@i_PageNumber, 0) <= 0
               OR ISNULL(@i_RowsPerPage, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'PAGINA O CANTIDAD DE REGISTROS INVALIDA';
            END
            ELSE
            BEGIN
                SELECT
                    userId,
                    userFullname,
                    userName,
                    userEmail,
                    userRolId,
                    userCreationDate,
                    userCreatorId,
                    userModificationDate,
                    userModifierId,
                    userEnable
                FROM [SQM_SECURITY].[TBL_Users]
                ORDER BY userId
                OFFSET (@i_PageNumber - 1)
                    * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @o_MensajeUsuario = 'USUARIOS LISTADOS CORRECTAMENTE';
            END
        END

        ELSE
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeTecnico = 'ACCION INVALIDA: USE I, U O S';
            SET @o_MensajeUsuario = 'LA ACCION SOLICITADA NO ES VALIDA';
        END

    END TRY
    BEGIN CATCH
        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'ERROR AL PROCESAR LOS USUARIOS';
    END CATCH
END;
GO
--==================================================================================
CREATE OR ALTER PROC [SQM_CATALOGOS].[USP_BusinessValues]
(
    @i_businessValueId INT = NULL,
    @i_businessValueName VARCHAR(80) = NULL,
    @i_businessValueCreatorId INT = NULL,
    @i_businessValueModifierId INT = NULL,
    @i_businessValueEnable BIT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1),

    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @o_Numero = 200;
    SET @o_MensajeTecnico = '';
    SET @o_MensajeUsuario = '';

    BEGIN TRY

        -- INSERTAR BUSINESS VALUES
        IF @w_Accion = 'I'
        BEGIN
            IF ISNULL(@i_businessValueName, '') = ''
               OR @i_businessValueCreatorId IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL NOMBRE Y EL ID DEL CREADOR SON OBLIGATORIOS';
            END
            ELSE
            BEGIN
                INSERT INTO [SQM_CATALOGOS].[TBL_BusinessValues]
                (
                    businessValueName,
                    businessValueCreationDate,
                    businessValueCreatorId,
                    businessValueModificationDate,
                    businessValueModifierId,
                    businessValueEnable
                )
                VALUES
                (
                    @i_businessValueName,
                    GETDATE(),
                    @i_businessValueCreatorId,
                    GETDATE(),
                    @i_businessValueModifierId,
                    ISNULL(@i_businessValueEnable, 1)
                );

                SET @o_MensajeUsuario = 'BUSINESS VALUE INSERTADO CORRECTAMENTE';
            END
        END

        -- ACTUALIZAR BUSINESS VALUES
        ELSE IF @w_Accion = 'U'
        BEGIN
            IF ISNULL(@i_businessValueId, 0) = 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL ID DEL BUSINESS VALUE ES OBLIGATORIO';
            END
            ELSE IF NOT EXISTS
            (
                SELECT 1
                FROM [SQM_CATALOGOS].[TBL_BusinessValues]
                WHERE businessValueId = @i_businessValueId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeUsuario = 'EL BUSINESS VALUE NO EXISTE';
            END
            ELSE
            BEGIN
                UPDATE [SQM_CATALOGOS].[TBL_BusinessValues]
                SET
                    businessValueName = COALESCE(
                        @i_businessValueName, businessValueName),
                    businessValueModificationDate = GETDATE(),
                    businessValueModifierId = @i_businessValueModifierId,
                    businessValueEnable = COALESCE(
                        @i_businessValueEnable, businessValueEnable)
                WHERE businessValueId = @i_businessValueId;

                SET @o_MensajeUsuario = 'BUSINESS VALUE ACTUALIZADO CORRECTAMENTE';
            END
        END

        -- LISTAR BUSINESS VALUES CON PAGINACION
        ELSE IF @w_Accion = 'S'
        BEGIN
            IF ISNULL(@i_PageNumber, 0) <= 0
               OR ISNULL(@i_RowsPerPage, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'PAGINA Y REGISTROS POR PAGINA DEBEN SER MAYORES QUE CERO';
            END
            ELSE
            BEGIN
                SELECT
                    businessValueId,
                    businessValueName,
                    businessValueCreationDate,
                    businessValueCreatorId,
                    businessValueModificationDate,
                    businessValueModifierId,
                    businessValueEnable
                FROM [SQM_CATALOGOS].[TBL_BusinessValues]
                ORDER BY businessValueId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @o_MensajeUsuario = 'BUSINESS VALUES LISTADOS CORRECTAMENTE';
            END
        END

        ELSE
        BEGIN
            SET @o_Numero = 405;
            SET @o_MensajeUsuario = 'METODO NO HABILITADO';
            SET @o_MensajeTecnico = 'LA ACCION DEBE SER I, U O S';
        END

    END TRY
    BEGIN CATCH
        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'ERROR AL PROCESAR LOS BUSINESS VALUES';
    END CATCH
END;
GO
--==================================================================================
CREATE OR ALTER PROCEDURE [SQM_GENERAL].[USP_Initiatives]
(
    @i_initiativeId INT = NULL,
    @i_initiativeSummary VARCHAR(200) = NULL,
    @i_initiativeDescription VARCHAR(2000) = NULL,
    @i_initiativeOwner INT = NULL,
    @i_initiativeGoals VARCHAR(255) = NULL,
    @i_initiativeBusinessValue INT = NULL,
    @i_initiativeTargetStart DATE = NULL,
    @i_initiativeTargetEnd DATE = NULL,
    @i_initiativeCreatorId INT = NULL,
    @i_initiativeModifierId INT = NULL,
    @i_initiativeStatus INT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1) = NULL,

    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @o_Numero = 200;
    SET @o_MensajeTecnico = '';
    SET @o_MensajeUsuario = '';

    BEGIN TRY

        IF @w_Accion = 'I'
        BEGIN
            IF @i_initiativeSummary IS NULL
               OR @i_initiativeDescription IS NULL
               OR @i_initiativeOwner IS NULL
               OR @i_initiativeBusinessValue IS NULL
               OR @i_initiativeCreatorId IS NULL
               OR @i_initiativeStatus IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'FALTAN CAMPOS OBLIGATORIOS';
            END
            ELSE
            BEGIN
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
                    initiativeModifierId,
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
                    GETDATE(),
                    @i_initiativeCreatorId,
                    NULL,
                    NULL,
                    @i_initiativeStatus
                );

                SET @o_MensajeUsuario = 'INICIATIVA INSERTADA CORRECTAMENTE';
            END
        END

        ELSE IF @w_Accion = 'U'
        BEGIN
            IF @i_initiativeId IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL ID DE LA INICIATIVA ES OBLIGATORIO';
            END
            ELSE IF NOT EXISTS
            (
                SELECT 1
                FROM [SQM_GENERAL].[TBL_Initiatives]
                WHERE initiativeId = @i_initiativeId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeUsuario = 'LA INICIATIVA NO EXISTE';
            END
            ELSE
            BEGIN
                UPDATE [SQM_GENERAL].[TBL_Initiatives]
                SET
                    initiativeSummary =
                        ISNULL(@i_initiativeSummary, initiativeSummary),
                    initiativeDescription =
                        ISNULL(@i_initiativeDescription, initiativeDescription),
                    initiativeOwner =
                        ISNULL(@i_initiativeOwner, initiativeOwner),
                    initiativeGoals =
                        ISNULL(@i_initiativeGoals, initiativeGoals),
                    initiativeBusinessValue =
                        ISNULL(@i_initiativeBusinessValue, initiativeBusinessValue),
                    initiativeTargetStart =
                        ISNULL(@i_initiativeTargetStart, initiativeTargetStart),
                    initiativeTargetEnd =
                        ISNULL(@i_initiativeTargetEnd, initiativeTargetEnd),
                    initiativeModificationDate = GETDATE(),
                    initiativeModifierId = @i_initiativeModifierId,
                    initiativeStatus =
                        ISNULL(@i_initiativeStatus, initiativeStatus)
                WHERE initiativeId = @i_initiativeId;

                SET @o_MensajeUsuario = 'INICIATIVA ACTUALIZADA CORRECTAMENTE';
            END
        END

        ELSE IF @w_Accion = 'S'
        BEGIN
            IF ISNULL(@i_PageNumber, 0) <= 0
               OR ISNULL(@i_RowsPerPage, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'PAGINA O CANTIDAD DE REGISTROS INVALIDA';
            END
            ELSE
            BEGIN
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
                    initiativeModifierId,
                    initiativeStatus
                FROM [SQM_GENERAL].[TBL_Initiatives]
                ORDER BY initiativeId
                OFFSET (@i_PageNumber - 1)
                    * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @o_MensajeUsuario = 'INICIATIVAS LISTADAS CORRECTAMENTE';
            END
        END

        ELSE
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeTecnico = 'ACCION INVALIDA: USE I, U O S';
            SET @o_MensajeUsuario = 'LA ACCION SOLICITADA NO ES VALIDA';
        END

    END TRY
    BEGIN CATCH
        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'ERROR AL PROCESAR LAS INICIATIVAS';
    END CATCH
END;
GO
--================================================================================================
CREATE OR ALTER PROCEDURE [SQM_CATALOGOS].[USP_Priorities]
(
    @i_priorityId INT = NULL,
    @i_priorityName VARCHAR(80) = NULL,
    @i_priorityCreatorId INT = NULL,
    @i_priorityModifierId INT = NULL,
    @i_priorityEnable BIT = NULL,
    @i_PageNumber INT = NULL,
    @i_RowsPerPage INT = NULL,
    @w_Accion CHAR(1) = NULL,
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @o_Numero = 200;
    SET @o_MensajeTecnico = '';
    SET @o_MensajeUsuario = '';

    BEGIN TRY

        -- INSERTAR PRIORIDAD
        IF @w_Accion = 'I'
        BEGIN
            IF @i_priorityName IS NULL
               OR @i_priorityCreatorId IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL NOMBRE Y EL CREADOR SON OBLIGATORIOS';
            END
            ELSE
            BEGIN
                INSERT INTO [SQM_CATALOGOS].[TBL_Priorities]
                (
                    priorityName,
                    priorityCreationDate,
                    priorityCreatorId,
                    priorityModificationDate,
                    priorityModifierId,
                    priorityEnable
                )
                VALUES
                (
                    @i_priorityName,
                    GETDATE(),
                    @i_priorityCreatorId,
                    NULL,
                    NULL,
                    ISNULL(@i_priorityEnable, 1)
                );

                SET @o_MensajeUsuario = 'PRIORIDAD INSERTADA CORRECTAMENTE';
            END
        END

        -- ACTUALIZAR PRIORIDAD
        ELSE IF @w_Accion = 'U'
        BEGIN
            IF @i_priorityId IS NULL
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'EL ID DE LA PRIORIDAD ES OBLIGATORIO';
            END
            ELSE IF NOT EXISTS
            (
                SELECT 1
                FROM [SQM_CATALOGOS].[TBL_Priorities]
                WHERE priorityId = @i_priorityId
            )
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeUsuario = 'LA PRIORIDAD NO EXISTE';
            END
            ELSE
            BEGIN
                UPDATE [SQM_CATALOGOS].[TBL_Priorities]
                SET
                    priorityName = ISNULL(@i_priorityName, priorityName),
                    priorityModificationDate = GETDATE(),
                    priorityModifierId = @i_priorityModifierId,
                    priorityEnable = ISNULL(@i_priorityEnable, priorityEnable)
                WHERE priorityId = @i_priorityId;

                SET @o_MensajeUsuario = 'PRIORIDAD ACTUALIZADA CORRECTAMENTE';
            END
        END

        -- LISTAR PRIORIDADES CON PAGINACION
        ELSE IF @w_Accion = 'S'
        BEGIN
            IF ISNULL(@i_PageNumber, 0) <= 0
               OR ISNULL(@i_RowsPerPage, 0) <= 0
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'PAGINA O CANTIDAD DE REGISTROS INVALIDA';
            END
            ELSE
            BEGIN
                SELECT
                    priorityId,
                    priorityName,
                    priorityCreationDate,
                    priorityCreatorId,
                    priorityModificationDate,
                    priorityModifierId,
                    priorityEnable
                FROM [SQM_CATALOGOS].[TBL_Priorities]
                ORDER BY priorityId
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @o_MensajeUsuario = 'PRIORIDADES LISTADAS CORRECTAMENTE';
            END
        END

        ELSE
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeTecnico = 'ACCION INVALIDA: USE I, U O S';
            SET @o_MensajeUsuario = 'LA ACCION SOLICITADA NO ES VALIDA';
        END

    END TRY
    BEGIN CATCH
        SET @o_Numero = 500;
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'ERROR AL PROCESAR LAS PRIORIDADES';
    END CATCH
END;
GO
--=========================================================================================================
CREATE OR ALTER PROCEDURE [SQM_GENERAL].[USP_Epics]
(
    @i_epicId INT = NULL,
    @i_epicName VARCHAR(100) = NULL,
    @i_epicSummary VARCHAR(500) = NULL,
    @i_epicDescription VARCHAR(4000) = NULL,
    @i_epicParentLink INT = NULL,
    @i_epicOwner INT = NULL,
    @i_epicStartDate DATE = NULL,
    @i_epicDueDate DATE = NULL,
    @i_epicPriority INT = NULL,
    @i_epicCreatorId INT = NULL,
    @i_epicModifierId INT = NULL,
    @i_epicStatus INT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @w_Accion CHAR(1),
    @o_Numero INT = NULL OUTPUT,
    @o_MensajeTecnico VARCHAR(500) = NULL OUTPUT,
    @o_MensajeUsuario VARCHAR(500) = NULL OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        @o_Numero = 200,
        @o_MensajeTecnico = '',
        @o_MensajeUsuario = '';

    BEGIN TRY

        IF @w_Accion = 'I'
        BEGIN
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
                epicModifierId,
                epicStatus
            )
            SELECT
                @i_epicName,
                @i_epicSummary,
                @i_epicDescription,
                @i_epicParentLink,
                @i_epicOwner,
                @i_epicStartDate,
                @i_epicDueDate,
                @i_epicPriority,
                GETDATE(),
                @i_epicCreatorId,
                NULL,
                NULL,
                @i_epicStatus
            WHERE
                @i_epicName IS NOT NULL
                AND @i_epicSummary IS NOT NULL
                AND @i_epicDescription IS NOT NULL
                AND @i_epicParentLink IS NOT NULL
                AND @i_epicOwner IS NOT NULL
                AND @i_epicCreatorId IS NOT NULL
                AND @i_epicStatus IS NOT NULL;

            IF @@ROWCOUNT = 1
                SET @o_MensajeUsuario = 'EPIC REGISTRADO';
            ELSE
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'COMPLETE LOS CAMPOS OBLIGATORIOS';
            END
        END

        ELSE IF @w_Accion = 'U'
        BEGIN
            IF EXISTS
            (
                SELECT epicId
                FROM [SQM_GENERAL].[TBL_Epics]
                WHERE epicId = @i_epicId
            )
            BEGIN
                UPDATE [SQM_GENERAL].[TBL_Epics]
                SET
                    epicName = COALESCE(@i_epicName, epicName),
                    epicSummary = COALESCE(@i_epicSummary, epicSummary),
                    epicDescription = COALESCE(@i_epicDescription, epicDescription),
                    epicParentLink = COALESCE(@i_epicParentLink, epicParentLink),
                    epicOwner = COALESCE(@i_epicOwner, epicOwner),
                    epicStartDate = COALESCE(@i_epicStartDate, epicStartDate),
                    epicDueDate = COALESCE(@i_epicDueDate, epicDueDate),
                    epicPriority = COALESCE(@i_epicPriority, epicPriority),
                    epicModificationDate = GETDATE(),
                    epicModifierId = @i_epicModifierId,
                    epicStatus = COALESCE(@i_epicStatus, epicStatus)
                WHERE epicId = @i_epicId;

                SET @o_MensajeUsuario = 'EPIC MODIFICADO';
            END
            ELSE
            BEGIN
                SET @o_Numero = 404;
                SET @o_MensajeUsuario = 'NO SE ENCONTRO EL EPIC';
            END
        END

        ELSE IF @w_Accion = 'S'
        BEGIN
            IF @i_PageNumber < 1 OR @i_RowsPerPage < 1
            BEGIN
                SET @o_Numero = 400;
                SET @o_MensajeUsuario = 'PARAMETROS DE PAGINACION INVALIDOS';
            END
            ELSE
            BEGIN
                SELECT *
                FROM [SQM_GENERAL].[TBL_Epics]
                ORDER BY epicId DESC
                OFFSET (@i_PageNumber - 1) * @i_RowsPerPage ROWS
                FETCH NEXT @i_RowsPerPage ROWS ONLY;

                SET @o_MensajeUsuario = 'CONSULTA DE EPICS COMPLETADA';
            END
        END

        ELSE
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeTecnico = 'ACCION NO RECONOCIDA';
            SET @o_MensajeUsuario = 'USE I PARA INSERTAR, U PARA ACTUALIZAR O S PARA LISTAR';
        END

    END TRY
    BEGIN CATCH
        SET @o_Numero = ERROR_NUMBER();
        SET @o_MensajeTecnico = ERROR_MESSAGE();
        SET @o_MensajeUsuario = 'NO SE PUDO COMPLETAR LA OPERACION';
    END CATCH
END;
GO
--=====================================================================================================
CREATE PROCEDURE [SQM_GENERAL].[USP_Features]
    @w_Accion CHAR(1) = 'S',
    @featureId INT = NULL,
    @featureSummary VARCHAR(500) = NULL,
    @featureDescription VARCHAR(2000) = NULL,
    @featuresAcceptanceCriteria VARCHAR(4000) = NULL,
    @featureParentLink INT = NULL,
    @featureOwner INT = NULL,
    @featureStartDate DATE = NULL,
    @featureDueDate DATE = NULL,
    @featurePriority INT = NULL,
    @featureCreatorId INT = NULL,
    @featureStatus INT = NULL,
    @Pagina INT = 1,
    @RegistrosPorPagina INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- VALIDAR ACCION
        IF @w_Accion NOT IN ('I', 'U', 'S')
        BEGIN
            SELECT 'Accion no valida.' AS Mensaje;
            RETURN;
        END;

        -- INSERTAR
        IF @w_Accion = 'I'
        BEGIN
            IF @featureSummary IS NULL
               OR @featureDescription IS NULL
               OR @featuresAcceptanceCriteria IS NULL
               OR @featureParentLink IS NULL
               OR @featureOwner IS NULL
               OR @featureCreatorId IS NULL
               OR @featureStatus IS NULL
            BEGIN
                SELECT 'Debe completar los campos obligatorios.'
                    AS Mensaje;
                RETURN;
            END;

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
                @featureSummary,
                @featureDescription,
                @featuresAcceptanceCriteria,
                @featureParentLink,
                @featureOwner,
                @featureStartDate,
                @featureDueDate,
                @featurePriority,
                GETDATE(),
                @featureCreatorId,
                @featureStatus
            );

            SELECT 'Feature insertada correctamente.' AS Mensaje;
        END;

        ELSE IF @w_Accion = 'U'
        BEGIN
            IF @featureId IS NULL
            BEGIN
                SELECT 'Debe indicar el ID de la Feature.'
                    AS Mensaje;
                RETURN;
            END;

            IF NOT EXISTS
            (
                SELECT 1
                FROM [SQM_GENERAL].[TBL_Features]
                WHERE featureId = @featureId
            )
            BEGIN
                SELECT 'La Feature no existe.' AS Mensaje;
                RETURN;
            END;

            IF @featureSummary IS NULL
               OR @featureDescription IS NULL
               OR @featuresAcceptanceCriteria IS NULL
               OR @featureParentLink IS NULL
               OR @featureOwner IS NULL
               OR @featureStatus IS NULL
            BEGIN
                SELECT 'Debe completar los campos obligatorios.'
                    AS Mensaje;
                RETURN;
            END;

            UPDATE [SQM_GENERAL].[TBL_Features]
            SET
                featureSummary = @featureSummary,
                featureDescription = @featureDescription,
                featuresAcceptanceCriteria = @featuresAcceptanceCriteria,
                featureParentLink = @featureParentLink,
                featureOwner = @featureOwner,
                featureStartDate = @featureStartDate,
                featureDueDate = @featureDueDate,
                featurePriority = @featurePriority,
                featureModificationDate = GETDATE(),
                featureStatus = @featureStatus
            WHERE featureId = @featureId;

            SELECT 'Feature actualizada correctamente.' AS Mensaje;
        END;

        -- LISTAR CON PAGINACION
        ELSE IF @w_Accion = 'S'
        BEGIN
            IF @Pagina < 1 OR @RegistrosPorPagina < 1
            BEGIN
                SELECT 'La pagina y los registros deben ser mayores que cero.'
                    AS Mensaje;
                RETURN;
            END;

            SELECT
                featureId,
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
                featureModificationDate,
                featureModificatorId,
                featureStatus
            FROM [SQM_GENERAL].[TBL_Features]
            ORDER BY featureId
            OFFSET (@Pagina - 1) * @RegistrosPorPagina ROWS
            FETCH NEXT @RegistrosPorPagina ROWS ONLY;
        END;

    END TRY
    BEGIN CATCH
        SELECT ERROR_MESSAGE() AS Mensaje;
    END CATCH;
END;
GO
--=======================================================================================================
CREATE PROCEDURE [SQM_GENERAL].[USP_ProductBacklogItems]
(
    @PBIIId INT = NULL,
    @PBISummary VARCHAR(500) = NULL,
    @PBIDescription VARCHAR(2000) = NULL,
    @PBIIsAcceptanceCriteria VARCHAR(4000) = NULL,
    @PBIOwner INT = NULL,
    @PBIParentLink INT = NULL,
    @PBIStoryPoint INT = NULL,
    @PBIStartDate DATE = NULL,
    @PBIDueDate DATE = NULL,
    @PBIPriority INT = NULL,
    @PBICreatorId INT = NULL,
    @PBIModificatorId INT = NULL,
    @PBIStatus INT = NULL,
    @Accion CHAR(1),
    @PageNumber INT = 1,
    @RowsPerPage INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'I'
        INSERT INTO [SQM_GENERAL].[TBL_ProductBacklogItems]
        (PBISummary, PBIDescription, PBIIsAcceptanceCriteria,
         PBIOwner, PBIParentLink, PBIStoryPoint, PBIStartDate,
         PBIDueDate, PBIPriority, PBICreationDate, PBICreatorId, PBIStatus)
        VALUES
        (@PBISummary, @PBIDescription, @PBIIsAcceptanceCriteria,
         @PBIOwner, @PBIParentLink, @PBIStoryPoint, @PBIStartDate,
         @PBIDueDate, @PBIPriority, GETDATE(), @PBICreatorId, @PBIStatus);

    ELSE IF @Accion = 'U'
        UPDATE [SQM_GENERAL].[TBL_ProductBacklogItems]
        SET PBISummary = @PBISummary,
            PBIDescription = @PBIDescription,
            PBIIsAcceptanceCriteria = @PBIIsAcceptanceCriteria,
            PBIOwner = @PBIOwner,
            PBIParentLink = @PBIParentLink,
            PBIStoryPoint = @PBIStoryPoint,
            PBIStartDate = @PBIStartDate,
            PBIDueDate = @PBIDueDate,
            PBIPriority = @PBIPriority,
            PBIModificationDate = GETDATE(),
            PBIModificatorId = @PBIModificatorId,
            PBIStatus = @PBIStatus
        WHERE PBIIId = @PBIIId;

    ELSE IF @Accion = 'S'
        SELECT * FROM [SQM_GENERAL].[TBL_ProductBacklogItems]
        ORDER BY PBIIId
        OFFSET (@PageNumber - 1) * @RowsPerPage ROWS
        FETCH NEXT @RowsPerPage ROWS ONLY;
END;
GO

--============================================================================================================

CREATE OR ALTER PROC [SQM_CATALOGS].[USP_ActivityTypes]
(
    @activityTypeId INT = NULL,
    @activityTypeName VARCHAR(80) = NULL,
    @activityTypeCreatorId INT = NULL,
    @activityTypeModificatorId INT = NULL,
    @activityTypeEnable BIT = NULL,
    @Accion CHAR(1),
    @PageNumber INT = 1,
    @RowsPerPage INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'I'
        INSERT INTO [SQM_CATALOGS].[TBL_ActivityTypes]
        (activityTypeName, activityTypeCreationDate,
         activityTypeCreatorId, activityTypeEnable)
        VALUES
        (@activityTypeName, GETDATE(),
         @activityTypeCreatorId, @activityTypeEnable);

    ELSE IF @Accion = 'U'
        UPDATE [SQM_CATALOGS].[TBL_ActivityTypes]
        SET activityTypeName = @activityTypeName,
            activityTypeModificationDate = GETDATE(),
            activityTypeModificatorId = @activityTypeModificatorId,
            activityTypeEnable = @activityTypeEnable
        WHERE activityTypeId = @activityTypeId;

    ELSE IF @Accion = 'S'
        SELECT *
        FROM [SQM_CATALOGS].[TBL_ActivityTypes]
        ORDER BY activityTypeId
        OFFSET (@PageNumber - 1) * @RowsPerPage ROWS
        FETCH NEXT @RowsPerPage ROWS ONLY;
END 
GO

--==================================================================================================
CREATE OR ALTER PROC [SQM_CATALOGS].[USP_ActivityTypes]
(
    @activityTypeId INT = NULL,
    @activityTypeName VARCHAR(80) = NULL,
    @activityTypeCreatorId INT = NULL,
    @activityTypeModificatorId INT = NULL,
    @activityTypeEnable BIT = NULL,
    @Accion CHAR(1),
    @PageNumber INT = 1,
    @RowsPerPage INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'I'
        INSERT INTO [SQM_CATALOGS].[TBL_ActivityTypes]
        (activityTypeName, activityTypeCreationDate,
         activityTypeCreatorId, activityTypeEnable)
        VALUES
        (@activityTypeName, GETDATE(),
         @activityTypeCreatorId, @activityTypeEnable);

    ELSE IF @Accion = 'U'
        UPDATE [SQM_CATALOGS].[TBL_ActivityTypes]
        SET activityTypeName = @activityTypeNam…
--================================================================================================

CREATE OR ALTER PROC [SQM_GENERAL].[USP_TaskComments]
(
    @taskCommentId INT = NULL,
    @taskCommentParentLink INT = NULL,
    @taskCommentOwner INT = NULL,
    @taskCommentText NVARCHAR(4000) = NULL,
    @taskCommentCreatorId INT = NULL,
    @taskCommentModificatorId INT = NULL,
    @taskCommentStatus BIT = NULL,
    @Accion CHAR(1),
    @PageNumber INT = 1,
    @RowsPerPage INT = 10
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Accion = 'I'
        INSERT INTO [SQM_GENERAL].[TBL_TaskComments]
        (
            taskCommentParentLink,
            taskCommentOwner,
            taskCommentText,
            taskCommentCreationDate,
            taskCommentCreatorId,
            taskCommentStatus
        )
        VALUES
        (
            @taskCommentParentLink,
            @taskCommentOwner,
            @taskCommentText,
            GETDATE(),
            @taskCommentCreatorId,
            @taskCommentStatus
        );

    ELSE IF @Accion = 'U'
        UPDATE [SQM_GENERAL].[TBL_TaskComments]
        SET taskCommentParentLink = @taskCommentParentLink,
            taskCommentOwner = @taskCommentOwner,
            taskCommentText = @taskCommentText,
            taskCommentModificationDate = GETDATE(),
            taskCommentModificatorId = @taskCommentModificatorId,
            taskCommentStatus = @taskCommentStatus
        WHERE taskCommentId = @taskCommentId;

    ELSE IF @Accion = 'S'
        SELECT *
        FROM [SQM_GENERAL].[TBL_TaskComments]
        ORDER BY taskCommentId
        OFFSET (@PageNumber - 1) * @RowsPerPage ROWS
        FETCH NEXT @RowsPerPage ROWS ONLY;
END;
