from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    # API Configuration
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Thea OCR Service"
    
    # CORS
    CORS_ORIGINS: List[str] = ["*"]
    
    # Security
    API_KEY: str
    
    # Services URLs
    NODE_BACKEND_URL: str
    
    # RabbitMQ
    RABBITMQ_URL: str
    
    # Redis
    REDIS_URL: str
    
    # Celery
    CELERY_BROKER_URL: str
    CELERY_RESULT_BACKEND: str
    
    # OCR Settings
    OCR_CONFIDENCE_THRESHOLD: float = 0.8
    MAX_FILE_SIZE: int = 25 * 1024 * 1024  # 25MB
    ALLOWED_FILE_TYPES: List[str] = ["pdf", "jpg", "jpeg", "png", "tiff"]
    
    # Monitoring
    ENABLE_METRICS: bool = True

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()