import logging
from langchain_community.vectorstores import Chroma
from langchain_huggingface import HuggingFaceEmbeddings

logger = logging.getLogger(__name__)

async def init_vector_store():
    """
    Initialize the vector store
    """
    logger.info("Initializing vector store")
    
    try:
        embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2"
        )
        
        vector_store = Chroma(
            persist_directory="./data/chroma",
            embedding_function=embeddings
        )
        
        logger.info("Vector store initialized successfully")
        return vector_store
        
    except Exception as e:
        logger.error(f"Failed to initialize vector store: {e}")
        raise