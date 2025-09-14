import time
import httpx
import logging
from ..core.config import settings

logger = logging.getLogger(__name__)

async def wait_for_ollama():
    """Wait for Ollama service to be ready"""
    max_attempts = 30
    attempt = 0
    
    while attempt < max_attempts:
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{settings.OLLAMA_BASE_URL}/api/version")
                if response.status_code == 200:
                    logger.info("Ollama service is ready")
                    return True
        except Exception as e:
            logger.warning(f"Waiting for Ollama service... (attempt {attempt + 1}/{max_attempts})")
            attempt += 1
            time.sleep(5)
    
    logger.error("Failed to connect to Ollama service")
    return False

async def ensure_model_available():
    """Ensure the required model is available in Ollama"""
    try:
        async with httpx.AsyncClient() as client:
            # List available models
            response = await client.get(f"{settings.OLLAMA_BASE_URL}/api/tags")
            if response.status_code == 200:
                models = response.json().get("models", [])
                model_names = [model["name"] for model in models]
                
                if settings.OLLAMA_MODEL not in model_names:
                    logger.warning(f"Model {settings.OLLAMA_MODEL} not found. Available models: {model_names}")
                    # Try to pull the model
                    await pull_model(settings.OLLAMA_MODEL)
                else:
                    logger.info(f"Model {settings.OLLAMA_MODEL} is available")
                    return True
    except Exception as e:
        logger.error(f"Error checking model availability: {e}")
        return False

async def pull_model(model_name: str):
    """Pull a model from Ollama"""
    try:
        async with httpx.AsyncClient(timeout=300.0) as client:  # 5 minute timeout for model pulling
            response = await client.post(
                f"{settings.OLLAMA_BASE_URL}/api/pull",
                json={"name": model_name}
            )
            if response.status_code == 200:
                logger.info(f"Successfully pulled model {model_name}")
                return True
            else:
                logger.error(f"Failed to pull model {model_name}: {response.text}")
                return False
    except Exception as e:
        logger.error(f"Error pulling model {model_name}: {e}")
        return False