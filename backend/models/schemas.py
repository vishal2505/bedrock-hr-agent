from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class TaskStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in-progress"
    COMPLETED = "completed"


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4096, description="User message to send to the agent")
    session_id: Optional[str] = Field(None, description="Session ID for conversation continuity")


class ChatMessage(BaseModel):
    role: str
    content: str
    timestamp: str
    sources: list[str] = []


class ChatHistoryResponse(BaseModel):
    session_id: str
    messages: list[ChatMessage]


class TaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=256)
    description: str = Field(..., min_length=1, max_length=1024)
    assigned_to: str = Field(..., min_length=1, max_length=256)
    due_date: Optional[str] = None


class TaskUpdate(BaseModel):
    status: Optional[TaskStatus] = None
    title: Optional[str] = Field(None, max_length=256)
    description: Optional[str] = Field(None, max_length=1024)
    assigned_to: Optional[str] = Field(None, max_length=256)
    due_date: Optional[str] = None


class TaskResponse(BaseModel):
    task_id: str
    title: str
    description: str
    assigned_to: str
    status: str
    created_at: str
    updated_at: str
    due_date: Optional[str] = None


class HealthResponse(BaseModel):
    status: str = "healthy"
    service: str = "hr-onboarding-agent"
    version: str = "1.0.0"
