from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class ActivityTypeBase(BaseModel):
    activityTypeId: int
    activityTypeName: str
    activityTypeCreationDate: datetime
    activityTypeCreatorId: int
    activityTypeModificationDate: Optional[datetime] = None
    activityTypeModificatorId: Optional[int] = None
    activityTypeEnable: bool

class LtsActivity(BaseModel):
    activity: List[ActivityTypeBase]

class ActivityTypeCreate(BaseModel):
    activityTypeName: str
    activityTypeCreatorId: int

class ActivityTypeUpdate(BaseModel):
    activityTypeId: int
    activityTypeName: Optional[str] = None
    activityTypeModificationDate: Optional[datetime] = None
    activityTypeModificatorId: int
    activityTypeEnable: Optional[bool] = None