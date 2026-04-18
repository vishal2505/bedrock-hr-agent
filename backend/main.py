import os

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from backend.models.schemas import HealthResponse
from backend.routers import agent, tasks

load_dotenv()

app = FastAPI(
    title="HR Onboarding Agent API",
    description="API for the HR Onboarding AI Agent powered by Amazon Bedrock",
    version="1.0.0",
)

# CORS configuration
frontend_url = os.getenv("FRONTEND_URL", "http://localhost:3000")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:5173",
        frontend_url,
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(agent.router)
app.include_router(tasks.router)


@app.get("/api/health", response_model=HealthResponse)
async def health_check():
    return HealthResponse()
