from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class RolBase(BaseModel):
    rolId: int
    rolName: str
    rolCreationDate: datetime
    rolCreatorId: int
    rolModificationDate: datetime
    rolModificatorId: Optional[int] = None
    rolEnable: bool

class RolCreate(BaseModel):
    rolName: str
    rolCreatorId: int
    rolModificationDate: datetime
    rolEnable: bool

class RolUpdate(BaseModel):
    rolId: int
    rolName: Optional[str] = None
    rolModificationDate: datetime
    rolModificatorId: int
    rolEnable: Optional[bool] = None