import json
import os
from unittest.mock import MagicMock, patch

import boto3
import pytest
from fastapi.testclient import TestClient
from moto import mock_aws

os.environ["AWS_DEFAULT_REGION"] = "us-east-1"
os.environ["AWS_ACCESS_KEY_ID"] = "testing"
os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
os.environ["DYNAMODB_TABLE_NAME"] = "OnboardingTasks"
os.environ["BEDROCK_AGENT_ID"] = "test-agent-id"
os.environ["BEDROCK_AGENT_ALIAS_ID"] = "test-alias-id"

from backend.main import app

client = TestClient(app)


# --- Health Check ---
def test_health_check():
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "hr-onboarding-agent"


# --- Tasks Endpoints ---
@mock_aws
def setup_dynamodb():
    """Create a mock DynamoDB table."""
    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
    table = dynamodb.create_table(
        TableName="OnboardingTasks",
        KeySchema=[{"AttributeName": "task_id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "task_id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )
    table.wait_until_exists()
    return table


@mock_aws
def test_create_task():
    setup_dynamodb()

    # Patch the dynamodb_service module's table reference
    with patch("backend.services.dynamodb_service.table") as mock_table:
        mock_table.put_item = MagicMock()

        response = client.post(
            "/api/tasks",
            json={
                "title": "Setup laptop",
                "description": "Configure new employee laptop with required software",
                "assigned_to": "IT Department",
                "due_date": "2025-02-01",
            },
        )

        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Setup laptop"
        assert data["status"] == "pending"
        assert data["assigned_to"] == "IT Department"
        assert "task_id" in data


@mock_aws
def test_list_tasks():
    setup_dynamodb()

    with patch("backend.services.dynamodb_service.table") as mock_table:
        mock_table.scan.return_value = {
            "Items": [
                {
                    "task_id": "test-123",
                    "title": "Setup laptop",
                    "description": "Configure laptop",
                    "assigned_to": "IT",
                    "status": "pending",
                    "created_at": "2025-01-01T00:00:00",
                    "updated_at": "2025-01-01T00:00:00",
                }
            ]
        }

        response = client.get("/api/tasks")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["task_id"] == "test-123"


@mock_aws
def test_update_task():
    setup_dynamodb()

    with patch("backend.services.dynamodb_service.table") as mock_table:
        mock_table.update_item.return_value = {
            "Attributes": {
                "task_id": "test-123",
                "title": "Setup laptop",
                "description": "Configure laptop",
                "assigned_to": "IT",
                "status": "completed",
                "created_at": "2025-01-01T00:00:00",
                "updated_at": "2025-01-15T00:00:00",
            }
        }

        response = client.patch(
            "/api/tasks/test-123",
            json={"status": "completed"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "completed"


def test_update_task_no_fields():
    response = client.patch("/api/tasks/test-123", json={})
    assert response.status_code == 400


# --- Chat Endpoints ---
def test_chat_endpoint():
    """Test chat endpoint with mocked Bedrock agent."""
    mock_response = {
        "completion": [
            {
                "chunk": {
                    "bytes": b"Hello! Welcome to the company.",
                    "attribution": {"citations": []},
                }
            }
        ]
    }

    with patch("backend.services.bedrock_service.client") as mock_client:
        mock_client.invoke_agent.return_value = mock_response

        response = client.post(
            "/api/chat",
            json={"message": "Hello, I'm a new employee"},
        )
        assert response.status_code == 200
        assert response.headers["content-type"] == "text/event-stream; charset=utf-8"

        # Parse SSE events
        events = []
        for line in response.text.strip().split("\n"):
            if line.startswith("data: "):
                events.append(json.loads(line[6:]))

        assert any(e["type"] == "session" for e in events)
        assert any(e["type"] == "done" for e in events)


def test_get_chat_history_not_found():
    response = client.get("/api/chat/nonexistent-session")
    assert response.status_code == 404


def test_chat_with_session_id():
    """Test chat with explicit session ID."""
    mock_response = {
        "completion": [
            {
                "chunk": {
                    "bytes": b"I can help with that!",
                    "attribution": {"citations": []},
                }
            }
        ]
    }

    with patch("backend.services.bedrock_service.client") as mock_client:
        mock_client.invoke_agent.return_value = mock_response

        response = client.post(
            "/api/chat",
            json={
                "message": "What is the leave policy?",
                "session_id": "test-session-123",
            },
        )
        assert response.status_code == 200
