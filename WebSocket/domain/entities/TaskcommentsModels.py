from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class TaskCommentBase(BaseModel):
    taskCommentId: int
    taskCommentParentLink: int
    taskCommentOwner: int
    taskCommentText: str
    taskCommentCreationDate: datetime
    taskCommentCreatorId: int
    taskCommentModificationDate: Optional[datetime] = None
    taskCommentModificatorId: Optional[int] = None
    taskCommentStatus: bool

class LtsTaskComment(BaseModel):
    taskcomment: List[TaskCommentBase]

class TaskCommentCreate(BaseModel):
    taskCommentParentLink: int
    taskCommentOwner: int
    taskCommentText: str
    taskCommentCreatorId: int
    taskCommentStatus: bool

class TaskCommentUpdate(BaseModel):
    taskCommentId: int
    taskCommentText: Optional[str] = None
    taskCommentModificationDate: Optional[datetime] = None
    taskCommentModificatorId: int
    taskCommentStatus: Optional[bool] = None