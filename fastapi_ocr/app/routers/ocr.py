from fastapi import APIRouter, UploadFile, File, HTTPException, BackgroundTasks
from ..worker import process_invoice
from ..models.invoice import InvoiceResponse
import logging
import os
import uuid
from pathlib import Path

router = APIRouter()
logger = logging.getLogger(__name__)

@router.post("/process-invoice", response_model=InvoiceResponse)
async def upload_invoice(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = None
):
    """
    Process an invoice using OCR and return structured data
    """
    try:
        # Validate file type
        if not file.content_type in ["application/pdf", "image/jpeg", "image/png"]:
            raise HTTPException(
                status_code=400,
                detail="Invalid file type. Only PDF, JPEG, and PNG are supported."
            )
        
        # Save file to disk for Celery processing
        uploads_dir = Path("/app/uploads")
        uploads_dir.mkdir(exist_ok=True)
        
        file_extension = Path(file.filename).suffix or ".tmp"
        unique_filename = f"{uuid.uuid4()}{file_extension}"
        file_path = uploads_dir / unique_filename
        
        # Save uploaded file
        content = await file.read()
        with open(file_path, "wb") as f:
            f.write(content)
        
        # Process invoice asynchronously with file path
        task = process_invoice.delay(str(file_path))
        
        return {
            "status": "processing",
            "task_id": task.id,
            "message": "Invoice is being processed"
        }
    except Exception as e:
        logger.error(f"Error processing invoice: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error processing invoice: {str(e)}"
        )

@router.get("/task/{task_id}", response_model=InvoiceResponse)
async def get_task_result(task_id: str):
    """
    Get the result of an invoice processing task
    """
    try:
        task = process_invoice.AsyncResult(task_id)
        
        if task.ready():
            if task.successful():
                return {
                    "status": "completed",
                    "task_id": task_id,
                    "data": task.get()
                }
            else:
                return {
                    "status": "failed",
                    "task_id": task_id,
                    "error": str(task.result)
                }
        else:
            return {
                "status": "processing",
                "task_id": task_id,
                "message": "Task is still processing"
            }
    except Exception as e:
        logger.error(f"Error checking task status: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Error checking task status: {str(e)}"
        )