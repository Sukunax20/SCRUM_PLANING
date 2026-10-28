from pydantic import BaseModel
from datetime import datetime
from typing import Optional, List

class TaskBase(BaseModel):
    taskId: int
    taskSummary: str
    taskDescription: str
    taskOwner: int
    taskParentLink: int
    taskOriginalEstimate: Optional[float] = None
    taskCompletedWork: Optional[float] = None
    taskRemaningWork: Optional[float] = None
    taskStartDate: Optional[datetime] = None
    taskCompletedDate: Optional[datetime] = None
    taskDueDate: Optional[datetime] = None
    taskActivityType: Optional[int] = None
    taskCreationDate: datetime
    taskCreatorId: int
    taskModificationDate: datetime
    taskModificatorId: Optional[int] = None
    taskStatus: int

class TaskCreate(BaseModel):
    taskSummary: str
    taskDescription: str
    taskOwner: int
    taskParentLink: int
    taskOriginalEstimate: Optional[float] = None
    taskCompletedWork: Optional[float] = None
    taskRemaningWork: Optional[float] = None
    taskStartDate: Optional[datetime] = None
    taskCompletedDate: Optional[datetime] = None
    taskDueDate: Optional[datetime] = None
    taskActivityType: Optional[int] = None
    taskCreationDate: datetime
    taskCreatorId: int
    taskModificationDate: datetime
    taskStatus: int

class TaskUpdate(BaseModel):
    taskSummary: Optional[str] = None
    taskDescription: Optional[str] = None
    taskOwner: Optional[int] = None
    taskParentLink: Optional[int] = None
    taskOriginalEstimate: Optional[float] = None
    taskCompletedWork: Optional[float] = None
    taskRemaningWork: Optional[float] = None
    taskStartDate: Optional[datetime] = None
    taskCompletedDate: Optional[datetime] = None
    taskDueDate: Optional[datetime] = None
    taskActivityType: Optional[int] = None
    taskCreationDate: Optional[datetime] = None
    taskCreatorId: Optional[int] = None
    taskModificationDate: Optional[datetime] = None
    taskStatus: Optional[int]