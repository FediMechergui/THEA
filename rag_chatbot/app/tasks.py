from .services.celery_app import celery
from .services.indexing_service import IndexingService
import logging

logger = logging.getLogger(__name__)

@celery.task
def index_document(document_data: dict, enterprise_id: str):
    """
    Background task to index a document in the vector store
    """
    try:
        indexing_service = IndexingService()
        indexing_service.update_index(document_data, enterprise_id)
        logger.info(f"Successfully indexed document for enterprise {enterprise_id}")
        return {"status": "success", "message": "Document indexed successfully"}
    except Exception as e:
        logger.error(f"Error indexing document: {e}")
        return {"status": "error", "message": str(e)}

@celery.task
def batch_index_documents(documents: list, enterprise_id: str):
    """
    Background task to index multiple documents
    """
    try:
        indexing_service = IndexingService()
        for doc in documents:
            indexing_service.update_index(doc, enterprise_id)
        logger.info(f"Successfully indexed {len(documents)} documents for enterprise {enterprise_id}")
        return {"status": "success", "message": f"Indexed {len(documents)} documents"}
    except Exception as e:
        logger.error(f"Error batch indexing documents: {e}")
        return {"status": "error", "message": str(e)}