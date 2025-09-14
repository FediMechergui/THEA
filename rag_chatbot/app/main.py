from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from prometheus_fastapi_instrumentator import Instrumentator
from .routers import chat, health, admin
from .services.ollama_client import wait_for_ollama, ensure_model_available
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="THEA RAG Chatbot",
    description="Retrieval Augmented Generation Chatbot for THEA Backend",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add Prometheus metrics
Instrumentator().instrument(app).expose(app)

# Include routers
app.include_router(health.router)
app.include_router(chat.router, prefix="/api/v1")
app.include_router(admin.router, prefix="/api/v1/admin")

@app.on_event("startup")
async def startup_event():
    logger.info("Starting up RAG Chatbot service")
    
    # Wait for Ollama to be ready
    logger.info("Waiting for Ollama service...")
    await wait_for_ollama()
    
    # Ensure the required model is available
    logger.info("Ensuring model availability...")
    await ensure_model_available()