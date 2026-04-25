from __future__ import annotations

import os
import uuid
from collections.abc import Generator

import boto3

AGENT_ID = os.getenv("BEDROCK_AGENT_ID", "")
AGENT_ALIAS_ID = os.getenv("BEDROCK_AGENT_ALIAS_ID", "")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

client = boto3.client("bedrock-agent-runtime", region_name=AWS_REGION)

# In-memory session store (use Redis/DynamoDB in production)
_session_history: dict[str, list[dict]] = {}


def invoke_agent_streaming(
    message: str, session_id: str | None = None
) -> tuple[str, Generator[str, None, None]]:
    """Invoke the Bedrock Agent and return a streaming generator of response chunks."""
    if not session_id:
        session_id = str(uuid.uuid4())

    # Store user message
    _session_history.setdefault(session_id, []).append(
        {"role": "user", "content": message, "sources": []}
    )

    # Capture session_id in closure (it's now a definite str)
    _session_id = session_id

    def _stream() -> Generator[str, None, None]:
        response = client.invoke_agent(
            agentId=AGENT_ID,
            agentAliasId=AGENT_ALIAS_ID,
            sessionId=_session_id,
            inputText=message,
            enableTrace=True,
        )

        full_response = ""
        sources: list[str] = []

        for event in response.get("completion", []):
            # DEBUG: Log trace events so we can see internal agent failures
            if "trace" in event:
                import json
                print(f"[TRACE] {json.dumps(event['trace'], default=str)[:2000]}", flush=True)

            if "chunk" in event:
                chunk_data = event["chunk"]
                text = chunk_data.get("bytes", b"").decode("utf-8")
                full_response += text
                yield text

                # Extract citations/sources
                attribution = chunk_data.get("attribution", {})
                for citation in attribution.get("citations", []):
                    for ref in citation.get("retrievedReferences", []):
                        location = ref.get("location", {})
                        s3_loc = location.get("s3Location", {})
                        uri = s3_loc.get("uri", "")
                        if uri and uri not in sources:
                            sources.append(uri)

        # Store assistant response
        _session_history[_session_id].append(
            {"role": "assistant", "content": full_response, "sources": sources}
        )

    return _session_id, _stream()


def get_session_history(session_id: str) -> list[dict] | None:
    """Get chat history for a session."""
    return _session_history.get(session_id)
