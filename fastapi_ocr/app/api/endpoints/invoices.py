from fastapi import APIRouter, HTTPException, BackgroundTasks, UploadFile, File
from fastapi.responses import JSONResponse
from typing import Optional, Dict, Any
import httpx
import aio_pika
import json
from ..services.ocr_service import process_invoice
from ..core.config import settings
from ..models.invoice import InvoiceCreate, InvoiceResponse
from ..services.rabbitmq import get_rabbitmq_connection

router = APIRouter()

@router.post("/process", response_model=InvoiceResponse)
async def process_invoice_endpoint(
    background_tasks: BackgroundTasks,
    invoice_file: UploadFile = File(...),
    invoice_data: Optional[Dict[str, Any]] = None
):
    try:
        # Process the invoice in the background
        task_id = await process_invoice(
            invoice_file,
            invoice_data,
            background_tasks
        )
        
        return JSONResponse({
            "status": "processing",
            "task_id": task_id,
            "message": "Invoice processing started"
        })
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/callback/{invoice_id}")
async def process_callback(invoice_id: str, data: Dict[str, Any]):
    try:
        # Send the processed data back to Node.js backend
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{settings.NODE_BACKEND_URL}/api/invoices/{invoice_id}/ocr-result",
                json=data,
                headers={"Authorization": f"Bearer {settings.API_KEY}"}
            )
            response.raise_for_status()
            
        return {"status": "success", "message": "Callback processed successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/health")
async def health_check():
    return {"status": "healthy", "service": "ocr"}