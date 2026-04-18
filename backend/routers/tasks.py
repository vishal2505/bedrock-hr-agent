from fastapi import APIRouter, HTTPException

from backend.models.schemas import TaskCreate, TaskResponse, TaskUpdate
from backend.services.dynamodb_service import create_task, list_tasks, update_task

router = APIRouter(prefix="/api", tags=["tasks"])


@router.get("/tasks", response_model=list[TaskResponse])
async def get_tasks():
    """List all onboarding tasks."""
    tasks = list_tasks()
    return tasks


@router.post("/tasks", response_model=TaskResponse, status_code=201)
async def add_task(task: TaskCreate):
    """Manually create a new onboarding task."""
    item = create_task(
        title=task.title,
        description=task.description,
        assigned_to=task.assigned_to,
        due_date=task.due_date,
    )
    return item


@router.patch("/tasks/{task_id}", response_model=TaskResponse)
async def patch_task(task_id: str, task: TaskUpdate):
    """Update an existing task's status or other fields."""
    updates = task.model_dump(exclude_none=True)
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")

    # Convert enum to string value
    if "status" in updates:
        updates["status"] = updates["status"].value

    updated = update_task(task_id, updates)
    if updated is None:
        raise HTTPException(status_code=404, detail="Task not found")

    return updated
