from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Thea RAG Chatbot"
    
    # CORS
    CORS_ORIGINS: List[str] = ["*"]
    
    # Security
    API_KEY: str
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    
    # Services URLs
    NODE_BACKEND_URL: str
    
    # Database
    DATABASE_URL: str
    
    # Vector Store
    VECTOR_STORE_PATH: str = "./data/chroma"
    
    # Ollama LLM Configuration
    OLLAMA_BASE_URL: str
    OLLAMA_MODEL: str = "llama2"
    LLM_TEMPERATURE: float = 0.7
    LLM_MAX_TOKENS: int = 1000
    
    # Monitoring
    ENABLE_METRICS: bool = True

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()