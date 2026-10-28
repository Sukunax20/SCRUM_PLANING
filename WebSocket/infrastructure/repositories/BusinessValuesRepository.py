from infrastructure.database.connection import get_connection
from domain.entities.BusinessModels import BusinessValueCreate, BusinessValueUpdate

class BusinessValueRepository:
    def insert_business_value(self, business_value: BusinessValueCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ManageBusinessValues]
                @i_businessValueName = ?,
                @i_businessValueCreatorId = ?,
                @i_businessValueEnable = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_MensajeUsuario = ? OUTPUT
        """, (
            business_value.businessValueName,
            business_value.businessValueCreatorId,
            business_value.businessValueEnable,
            o_Numero,
            o_Mensaje
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return {"status_code": result[0] if result else o_Numero, "message": result[1] if result else o_Mensaje}

    def update_business_value(self, business_value: BusinessValueUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ManageBusinessValues]
                @i_businessValueId = ?,
                @i_businessValueName = ?,
                @i_businessValueModificatorId = ?,
                @i_businessValueEnable = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_MensajeUsuario = ? OUTPUT
        """, (
            business_value.businessValueId,
            business_value.businessValueName,
            business_value.businessValueModificatorId,
            business_value.businessValueEnable,
            o_Numero,
            o_Mensaje
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return {"status_code": result[0] if result else o_Numero, "message": result[1] if result else o_Mensaje}

    def list_business_values(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_CATALOGS].[USP_ManageBusinessValues]
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
