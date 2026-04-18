from __future__ import annotations

import os
import uuid
from datetime import datetime, timezone

import boto3
from boto3.dynamodb.conditions import Attr

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
TABLE_NAME = os.getenv("DYNAMODB_TABLE_NAME", "OnboardingTasks")

dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
table = dynamodb.Table(TABLE_NAME)


def list_tasks() -> list[dict]:
    """Scan and return all onboarding tasks."""
    response = table.scan()
    items = response.get("Items", [])

    # Handle pagination
    while "LastEvaluatedKey" in response:
        response = table.scan(ExclusiveStartKey=response["LastEvaluatedKey"])
        items.extend(response.get("Items", []))

    return sorted(items, key=lambda x: x.get("created_at", ""), reverse=True)


def create_task(
    title: str,
    description: str,
    assigned_to: str,
    due_date: str | None = None,
) -> dict:
    """Create a new onboarding task."""
    task_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    item: dict = {
        "task_id": task_id,
        "title": title,
        "description": description,
        "assigned_to": assigned_to,
        "status": "pending",
        "created_at": now,
        "updated_at": now,
    }

    if due_date:
        item["due_date"] = due_date

    table.put_item(Item=item)
    return item


def update_task(task_id: str, updates: dict) -> dict | None:
    """Update an existing task. Returns the updated item or None if not found."""
    update_parts = []
    expression_values = {}
    expression_names = {}

    updates["updated_at"] = datetime.now(timezone.utc).isoformat()

    for key, value in updates.items():
        if value is not None:
            placeholder = f":{key}"
            name_placeholder = f"#{key}"
            update_parts.append(f"{name_placeholder} = {placeholder}")
            expression_values[placeholder] = value
            expression_names[name_placeholder] = key

    if not update_parts:
        return None

    update_expression = "SET " + ", ".join(update_parts)

    try:
        response = table.update_item(
            Key={"task_id": task_id},
            UpdateExpression=update_expression,
            ExpressionAttributeValues=expression_values,
            ExpressionAttributeNames=expression_names,
            ReturnValues="ALL_NEW",
            ConditionExpression=Attr("task_id").exists(),
        )
        return response.get("Attributes")
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        return None


def get_task(task_id: str) -> dict | None:
    """Get a single task by ID."""
    response = table.get_item(Key={"task_id": task_id})
    return response.get("Item")
