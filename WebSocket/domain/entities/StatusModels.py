from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class StatusBase(BaseModel):
    statusId: int
    statusName: str
    statusCreationDate: datetime
    statusCreatorId: Optional[int] = None
    statusModificationDate: Optional[datetime] = None
    statusModificatorId: Optional[int] = None
    statusEnable: bool

class StatusCreate(BaseModel):
    statusName: str
    statusCreationDate: datetime
    statusCreatorId: int
    statusModificationDate: datetime
    statusEnable: bool

class Update(BaseModel):
    statusId: int
    statusName: Optional[str] = None
    statusCreationDate: Optional[datetime] = None
    statusCreatorId = Optional[int] = None
    statusModificationDate: Optional[datetime] = None
    statusModificatorId: Optional[int] = None
    statusEnable: Optional[bool] = None