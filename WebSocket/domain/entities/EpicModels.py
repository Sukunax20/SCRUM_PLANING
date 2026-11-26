from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class EpicBase(BaseModel):
    epicId: int
    epicName: str
    epicSummary: str
    epicDescription: str
    epicParentLink: int
    epicOwner: int
    epicStartDate: Optional[datetime] = None
    epicDueDate: Optional[datetime] = None
    epicPriority: Optional[int] = None
    epicCreationDate: datetime
    epicCreatorId: int
    epicModificationDate: Optional[datetime] = None
    epicModificatorId: Optional[int] = None
    epicStatus: int

class LtsEpics(BaseModel):
    epics: List[EpicBase]

class EpicCreate(BaseModel):
    epicName: str
    epicSummary: str
    epicDescription: str
    epicParentLink: int
    epicOwner: int
    epicStartDate: Optional[datetime] = None
    epicDueDate: Optional[datetime] = None
    epicPriority: Optional[int] = None
    epicCreatorId: int
    epicStatus: int

class EpicUpdate(BaseModel):
    epicId: int
    epicName: Optional[str] = None
    epicSummary: Optional[str] = None
    epicDescription: Optional[str] = None
    epicParentLink: Optional[int] = None
    epicOwner: Optional[int] = None
    epicStartDate: Optional[datetime] = None
    epicDueDate: Optional[datetime] = None
    epicPriority: Optional[int] = None
    epicModificationDate: Optional[datetime] = None
    epicModificatorId: int
    epicStatus: Optional[int] = None