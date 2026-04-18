import json
import os
import boto3
from botocore.exceptions import ClientError

ses_client = boto3.client("ses")
SENDER_EMAIL = os.environ["SENDER_EMAIL"]


def lambda_handler(event, context):
    """Handle Bedrock Agent action group invocation to send a welcome email."""
    print(f"Received event: {json.dumps(event)}")

    agent = event.get("agent", {})
    action_group = event.get("actionGroup", "")
    function = event.get("function", "")
    parameters = {p["name"]: p["value"] for p in event.get("parameters", [])}

    employee_email = parameters.get("employee_email", "")
    employee_name = parameters.get("employee_name", "")
    start_date = parameters.get("start_date", "your upcoming start date")

    result_body = send_welcome_email(employee_email, employee_name, start_date)

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


def send_welcome_email(recipient, name, start_date):
    """Send a welcome email via SES."""
    subject = f"Welcome to the Team, {name}!"
    body_html = f"""
    <html>
    <body>
        <h1>Welcome aboard, {name}!</h1>
        <p>We're thrilled to have you join our team. Your start date is <strong>{start_date}</strong>.</p>
        <h2>What to Expect</h2>
        <ul>
            <li>You'll receive your equipment and access credentials on your first day</li>
            <li>An onboarding buddy will be assigned to help you get settled</li>
            <li>Please review our company policies shared with you via email</li>
            <li>Your manager will schedule a welcome meeting during your first week</li>
        </ul>
        <p>If you have any questions before your start date, feel free to reach out to HR.</p>
        <p>Best regards,<br>HR Team</p>
    </body>
    </html>
    """
    body_text = (
        f"Welcome aboard, {name}!\n\n"
        f"We're thrilled to have you join our team. Your start date is {start_date}.\n\n"
        "What to Expect:\n"
        "- You'll receive your equipment and access credentials on your first day\n"
        "- An onboarding buddy will be assigned to help you get settled\n"
        "- Please review our company policies shared with you via email\n"
        "- Your manager will schedule a welcome meeting during your first week\n\n"
        "If you have any questions before your start date, feel free to reach out to HR.\n\n"
        "Best regards,\nHR Team"
    )

    try:
        ses_client.send_email(
            Source=SENDER_EMAIL,
            Destination={"ToAddresses": [recipient]},
            Message={
                "Subject": {"Data": subject, "Charset": "UTF-8"},
                "Body": {
                    "Text": {"Data": body_text, "Charset": "UTF-8"},
                    "Html": {"Data": body_html, "Charset": "UTF-8"},
                },
            },
        )
        return f"Welcome email successfully sent to {name} at {recipient}."
    except ClientError as e:
        error_msg = e.response["Error"]["Message"]
        print(f"SES error: {error_msg}")
        return f"Failed to send welcome email to {recipient}: {error_msg}"
