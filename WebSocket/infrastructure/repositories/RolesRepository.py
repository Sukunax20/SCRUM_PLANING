from infrastructure.database.connection import get_connection
from domain.entities.RolesModels import RolCreate, RolUpdate

class RolRepository:
    def insert_rol(self, rol: RolCreate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_SECURITY].[USP_ManageRoles]
                @i_rolName = ?,
                @i_rolCreatorId = ?,
                @i_rolEnable = ?,
                @w_Accion = 'I',
                @o_Numero = ? OUTPUT,
                @o_MensajeUsuario = ? OUTPUT
        """, (
            rol.rolName,
            rol.rolCreatorId,
            rol.rolEnable,
            o_Numero,
            o_Mensaje
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return {"status_code": result[0] if result else o_Numero, "message": result[1] if result else o_Mensaje}

    def update_rol(self, rol: RolUpdate):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_SECURITY].[USP_ManageRoles]
                @i_rolId = ?,
                @i_rolName = ?,
                @i_rolModificatorId = ?,
                @i_rolEnable = ?,
                @w_Accion = 'U',
                @o_Numero = ? OUTPUT,
                @o_MensajeUsuario = ? OUTPUT
        """, (
            rol.rolId,
            rol.rolName,
            rol.rolModificatorId,
            rol.rolEnable,
            o_Numero,
            o_Mensaje
        ))

        result = cursor.fetchone()
        conn.commit()
        cursor.close()
        conn.close()

        return {"status_code": result[0] if result else o_Numero, "message": result[1] if result else o_Mensaje}

    def list_roles(self, page_number: int = 1, rows_per_page: int = 10):
        conn = get_connection()
        cursor = conn.cursor()

        o_Numero = 0
        o_Mensaje = ""

        cursor.execute("""
            EXEC [SQM_SECURITY].[USP_ManageRoles]
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
