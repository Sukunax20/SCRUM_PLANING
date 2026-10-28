USE [DB_SCRUM_PLANNING]
GO

CREATE PROCEDURE [SQM_GENERAL].[USP_ManageFeatures]
    @w_Accion CHAR(1),
    @i_featureId INT = NULL,
    @i_featureSummary VARCHAR(500) = NULL,
    @i_featureDescription VARCHAR(2000) = NULL,
    @i_featuresAcceptanceCriteria VARCHAR(4000) = NULL,
    @i_featureParentLink INT = NULL,
    @i_featureOwner INT = NULL,
    @i_featureStartDate DATE = NULL,
    @i_featureDueDate DATE = NULL,
    @i_featurePriority INT = NULL,
    @i_featureCreationDate DATETIME = NULL,
    @i_featureCreatorId INT = NULL,
    @i_featureModificationDate DATETIME = NULL,
    @i_featureModificatorId INT = NULL,
    @i_featureStatus INT = NULL,
    @i_PageNumber INT = 1,
    @i_RowsPerPage INT = 10,
    @o_Numero INT = OUTPUT,
    @o_MensajeUsuario VARCHAR(150) = OUTPUT,
    @o_MensajeTecnico VARCHAR(MAX) = OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    SET @o_Numero = 0;
    SET @o_MensajeUsuario = '';
    SET @o_MensajeTecnico = '';
 
    IF @i_featureCreationDate IS NULL
        SET @i_featureCreationDate=GETDATE();

    IF @i_featureModificationDate IS NULL
        SET @i_featureModificationDate=GETDATE();

    IF @w_Accion = 'I'
    BEGIN
        IF ISNULL(@i_featureSummary,'')=''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA FEATURE ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_featureDescription,'')=''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA DESCRIPCION DE LA FEATURE ES OBLIGATORIA';
            RETURN;
        END

        ELSE IF ISNULL(@i_featuresAcceptanceCriteria,'')=''
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LOS CRITERIOS DE ACEPTACION SON OBLIGATORIOS';
            RETURN;
        END

        ELSE IF ISNULL(@i_featureParentLink,0)=0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario ='EL PARENT LINK DE LA EPICA ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_featureOwner,0)=0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL DUEÑO DE LA FEATURE ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_featureCreatorId,0)=0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL CREADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_featureStatus,0)=0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO DE LA FEATURE ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureSummary=@i_featureSummary AND featureParentLink=@i_featureParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA FEATURE YA EXISTE EN ESTA EPICA';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK) WHERE epicId=@i_featureParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA EPICA REFERENCIADA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId=@i_featureOwner AND userEnable=1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId=@i_featureCreatorId AND userEnable=1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO CREADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_featurePriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId=@i_featurePriority)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD ASIGNADA NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId=@i_featureStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

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
                featureModificationDate,
                featureModificatorId,
                featureStatus
            )
            VALUES
            (
                @i_featureSummary,
                @i_featureDescription,
                @i_featuresAcceptanceCriteria,
                @i_featureParentLink,
                @i_featureOwner,
                @i_featureStartDate,
                @i_featureDueDate,
                @i_featurePriority,
                @i_featureCreationDate,
                @i_featureCreatorId,
                NULL,
                NULL,
                @i_featureStatus
            );

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO INSERTADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT>0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL INSERTAR LA FEATURE';
            SET @o_MensajeTecnico = CONCAT_WS(' - ','ERROR AL INSERTAR',ERROR_PROCEDURE(),ERROR_LINE(),ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'U'
    BEGIN
        IF ISNULL(@i_featureId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DE LA FEATURE ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF ISNULL(@i_featureModificatorId,0) = 0
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ID DEL MODIFICADOR ES OBLIGATORIO';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureId=@i_featureId)
        BEGIN
            SET @o_Numero = 404;
            SET @o_MensajeUsuario = 'LA FEATURE NO EXISTE';
            RETURN;
        END

        ELSE IF NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId=@i_featureModificatorId AND userEnable=1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO MODIFICADOR NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_featureParentLink IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Epics] (NOLOCK) WHERE epicId=@i_featureParentLink)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA EPICA REFERENCIADA NO EXISTE';
            RETURN;
        END

        ELSE IF @i_featureOwner IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_SECURITY].[TBL_Users] (NOLOCK) WHERE userId=@i_featureOwner AND userEnable=1)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL USUARIO DUEÑO NO EXISTE O NO ESTÁ ACTIVO';
            RETURN;
        END

        ELSE IF @i_featurePriority IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Priorities] (NOLOCK) WHERE priorityId=@i_featurePriority)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'LA PRIORIDAD ASIGNADA NO EXISTE';
            RETURN;
        END

        ELSE IF @i_featureStatus IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [SQM_CATALOGS].[TBL_Status] (NOLOCK) WHERE statusId=@i_featureStatus)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL ESTADO ASIGNADO NO EXISTE';
            RETURN;
        END

        ELSE IF @i_featureSummary IS NOT NULL AND EXISTS (SELECT 1 FROM [SQM_GENERAL].[TBL_Features] (NOLOCK) WHERE featureSummary=@i_featureSummary AND featureParentLink=ISNULL(@i_featureParentLink,featureParentLink) AND featureId<>@i_featureId)
        BEGIN
            SET @o_Numero = 400;
            SET @o_MensajeUsuario = 'EL RESUMEN DE LA FEATURE YA EXISTE EN ESTA EPICA';
            RETURN;
        END

        BEGIN TRY
            BEGIN TRANSACTION;

            UPDATE [SQM_GENERAL].[TBL_Features]
            SET featureSummary = ISNULL(@i_featureSummary,featureSummary),
                featureDescription = ISNULL(@i_featureDescription,featureDescription),
                featuresAcceptanceCriteria = ISNULL(@i_featuresAcceptanceCriteria,featuresAcceptanceCriteria),
                featureParentLink = ISNULL(@i_featureParentLink,featureParentLink),
                featureOwner = ISNULL(@i_featureOwner,featureOwner),
                featureStartDate = ISNULL(@i_featureStartDate,featureStartDate),
                featureDueDate = ISNULL(@i_featureDueDate,featureDueDate),
                featurePriority = ISNULL(@i_featurePriority,featurePriority),
                featureModificationDate = @i_featureModificationDate,
                featureModificatorId = @i_featureModificatorId,
                featureStatus = ISNULL(@i_featureStatus,featureStatus)
            WHERE featureId = @i_featureId;

            COMMIT TRANSACTION;

            SET @o_Numero = 200;
            SET @o_MensajeUsuario = 'REGISTRO ACTUALIZADO CORRECTAMENTE';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT>0
                ROLLBACK TRANSACTION;

            SET @o_Numero = 500;
            SET @o_MensajeUsuario = 'ERROR AL ACTUALIZAR LA FEATURE';
            SET @o_MensajeTecnico=CONCAT_WS(' - ','ERROR AL ACTUALIZAR',ERROR_PROCEDURE(),ERROR_LINE(),ERROR_MESSAGE());
        END CATCH
    END

    ELSE IF @w_Accion = 'S'
    BEGIN
        BEGIN TRY
            DECLARE @w_totalRows INT = 0;

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
            FROM [SQM_GENERAL].[TBL_Features] (NOLOCK)
            ORDER BY featureId
            OFFSET (@i_PageNumber-1)*@i_RowsPerPage ROWS
            FETCH NEXT @i_RowsPerPage ROWS ONLY;

            SET @w_totalRows = @@ROWCOUNT;

            IF (@w_totalRows>0)
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
            SET @o_MensajeUsuario = 'ERROR AL LISTAR LAS FEATURES';
            SET @o_MensajeTecnico = CONCAT_WS(' - ','ERROR AL LISTAR FEATURES',ERROR_PROCEDURE(),ERROR_LINE(),ERROR_MESSAGE());
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
