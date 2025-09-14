from fastapi import APIRouter, HTTPException, Depends
from ..services.indexing_service import get_indexing_service
from ..models.admin import IndexingRequest, IndexingResponse
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/index", response_model=IndexingResponse)
async def index_data(
    request: IndexingRequest,
    indexing_service = Depends(get_indexing_service)
):
    """
    Index new data into the vector store
    """
    try:
        task = indexing_service.index_data.delay(request.data_type)
        return {
            "status": "processing",
            "task_id": task.id,
            "message": f"Indexing {request.data_type} data"
        }
    except Exception as e:
        logger.error(f"Error starting indexing task: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error starting indexing task: {str(e)}"
        )

@router.get("/index/status/{task_id}", response_model=IndexingResponse)
async def get_indexing_status(
    task_id: str,
    indexing_service = Depends(get_indexing_service)
):
    """
    Get the status of an indexing task
    """
    try:
        status = indexing_service.get_task_status(task_id)
        return status
    except Exception as e:
        logger.error(f"Error checking indexing status: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error checking indexing status: {str(e)}"
        )