from infrastructure.database.connection import get_connection
from domain.entities.FeaturesModels import FeatureCreate, FeatureUpdate

class FeatureRepository:
    def insert_feature(self, feature: FeatureCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Features]
                @i_featureSummary = ?,
                @i_featureDescription = ?,
                @i_featuresAcceptanceCriteria = ?,
                @i_featureParentLink = ?,
                @i_featureOwner = ?,
                @i_featureStartDate = ?,
                @i_featureDueDate = ?,
                @i_featurePriority = ?,
                @i_featureCreatorId = ?,
                @i_featureStatus = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_MensajeUsuario = ? OUTPUT
        """, (
            feature.featureSummary,
            feature.featureDescription,
            feature.featuresAcceptanceCriteria,
            feature.featureParentLink,
            feature.featureOwner,
            feature.featureStartDate,
            feature.featureDueDate,
            feature.featurePriority,
            feature.featureCreatorId,
            feature.featureStatus,
            o_Numero,
            o_Mensaje
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return {"status_code": result[0] if result else o_Numero, "message": result[1] if result else o_Mensaje}

    def update_feature(self, feature: FeatureUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Features]
                @i_featureId = ?,
                @i_featureSummary = ?,
                @i_featureDescription = ?,
                @i_featuresAcceptanceCriteria = ?,
                @i_featureParentLink = ?,
                @i_featureOwner = ?,
                @i_featureStartDate = ?,
                @i_featureDueDate = ?,
                @i_featurePriority = ?,
                @i_featureModificatorId = ?,
                @i_featureStatus = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_MensajeUsuario = ? OUTPUT
        """, (
            feature.featureId,
            feature.featureSummary,
            feature.featureDescription,
            feature.featuresAcceptanceCriteria,
            feature.featureParentLink,
            feature.featureOwner,
            feature.featureStartDate,
            feature.featureDueDate,
            feature.featurePriority,
            feature.featureModificatorId,
            feature.featureStatus,
            o_Numero,
            o_Mensaje
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return {"status_code": result[0] if result else o_Numero, "message": result[1] if result else o_Mensaje}

    def list_features(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_GENERAL].[USP_Features]
                @i_PageNumber = ?,
                @i_RowsPerPage = ?,
                @w_Accion = 'S',
                @o_Numero = ? OUTPUT,
                @o_MensajeUsuario = ? OUTPUT
        """, (page_number, rows_per_page, o_Numero, o_Mensaje))

        columns = [col[0] for col in cursor.description]
        data = [dict(zip(columns, row)) for row in cursor.fetchall()]

        conn.commit()
        cursor.close()
        conn.close()

        return {"status_code": o_Numero, "message": o_Mensaje, "data": data}
