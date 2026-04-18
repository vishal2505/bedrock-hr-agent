import json
import os
import uuid
from datetime import datetime, timezone

import boto3

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]
table = dynamodb.Table(TABLE_NAME)


def lambda_handler(event, context):
    """Handle Bedrock Agent action group invocation to log an onboarding task."""
    print(f"Received event: {json.dumps(event)}")

    agent = event.get("agent", {})
    action_group = event.get("actionGroup", "")
    function = event.get("function", "")
    parameters = {p["name"]: p["value"] for p in event.get("parameters", [])}

    task_title = parameters.get("task_title", "")
    task_description = parameters.get("task_description", "")
    assigned_to = parameters.get("assigned_to", "")
    due_date = parameters.get("due_date", "")

    result_body = log_task(task_title, task_description, assigned_to, due_date)

    response = {
        "messageVersion": "1.0",
        "response": {
            "actionGroup": action_group,
            "function": function,
            "functionResponse": {
                "responseBody": {
                    "TEXT": {"body": result_body}
                }
            },
        },
    }

    print(f"Response: {json.dumps(response)}")
    return response


def log_task(title, description, assigned_to, due_date):
    """Write a task record to DynamoDB."""
    task_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()

    item = {
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

    try:
        table.put_item(Item=item)
        return f"Onboarding task '{title}' logged successfully with ID {task_id}. Assigned to {assigned_to}."
    except Exception as e:
        print(f"DynamoDB error: {e}")
        return f"Failed to log task: {e}"
