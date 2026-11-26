from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class PriorityBase(BaseModel):
    priorityId: int
    priorityName: str
    priorityCreationDate: datetime
    priorityCreatorId: int
    priorityModificationDate: Optional[datetime] = None
    priorityModifierId: Optional[int] = None
    priorityEnable: bool

class LtsPriority(BaseModel):
    priority: List[PriorityBase]

class PriorityCreate(BaseModel):
    priorityName: str
    priorityCreatorId: int

class PriorityUpdate(BaseModel):
    priorityId: int
    priorityName: Optional[str] = None
    priorityModificationDate: Optional[datetime] = None
    priorityModifierId: int
    priorityEnable: Optional[bool] = None