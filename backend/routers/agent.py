import json
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse

from backend.models.schemas import ChatHistoryResponse, ChatMessage, ChatRequest
from backend.services.bedrock_service import get_session_history, invoke_agent_streaming

router = APIRouter(prefix="/api", tags=["chat"])


@router.post("/chat")
async def chat(request: ChatRequest):
    """Send a message to the Bedrock Agent and stream the response."""
    try:
        session_id, stream = invoke_agent_streaming(request.message, request.session_id)

        def event_stream():
            # Send session_id as first event
            yield f"data: {json.dumps({'type': 'session', 'session_id': session_id})}\n\n"

            for chunk in stream:
                yield f"data: {json.dumps({'type': 'chunk', 'content': chunk})}\n\n"

            # Send completion event with sources
            history = get_session_history(session_id)
            sources = history[-1].get("sources", []) if history else []
            yield f"data: {json.dumps({'type': 'done', 'sources': sources})}\n\n"

        return StreamingResponse(
            event_stream(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/chat/{session_id}", response_model=ChatHistoryResponse)
async def get_chat_history(session_id: str):
    """Get chat history for a given session."""
    history = get_session_history(session_id)
    if history is None:
        raise HTTPException(status_code=404, detail="Session not found")

    messages = [
        ChatMessage(
            role=msg["role"],
            content=msg["content"],
            timestamp=datetime.now(timezone.utc).isoformat(),
            sources=msg.get("sources", []),
        )
        for msg in history
    ]

    return ChatHistoryResponse(session_id=session_id, messages=messages)
