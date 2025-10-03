from celery import Celery
import os
import pytesseract
import cv2
import numpy as np
from pdf2image import convert_from_path
import re
from datetime import datetime
import logging
from typing import Dict, Any, List
from pathlib import Path

logger = logging.getLogger(__name__)

celery = Celery(
    'ocr_tasks',
    broker=os.getenv('CELERY_BROKER_URL', 'redis://localhost:6379/0'),
    backend=os.getenv('CELERY_RESULT_BACKEND', 'redis://localhost:6379/0')
)

celery.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
)

@celery.task
def process_invoice(file_path: str) -> Dict[str, Any]:
    """
    Process invoice file and extract relevant information using OCR
    """
    try:
        file_path_obj = Path(file_path)
        
        # Read file content to determine type
        with open(file_path_obj, 'rb') as f:
            file_content = f.read(4)
        
        # Convert PDF to images if needed
        if file_content.startswith(b'%PDF'):
            images = convert_from_path(file_path)
            image = np.array(images[0])
        else:
            # Handle image files
            image = cv2.imread(str(file_path))
            if image is None:
                raise ValueError("Could not read image file")

        # Preprocess image
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        thresh = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]

        # Extract text using OCR
        text = pytesseract.image_to_string(thresh)

        # Extract invoice details using regex patterns
        invoice_data = {
            "invoiceNumber": extract_invoice_number(text),
            "date": extract_date(text),
            "dueDate": extract_due_date(text),
            "totalAmount": extract_total_amount(text),
            "taxAmount": extract_tax_amount(text),
            "status": "PENDING",  # Default status
            "clientId": extract_client_id(text),
            "projectId": extract_project_id(text),
            "description": extract_description(text),
            "items": extract_items(text)
        }

        return invoice_data

    except Exception as e:
        logger.error(f"Error processing invoice: {str(e)}")
        raise
    finally:
        # Clean up temporary file
        try:
            if file_path_obj.exists():
                file_path_obj.unlink()
                logger.info(f"Cleaned up temporary file: {file_path}")
        except Exception as cleanup_error:
            logger.warning(f"Could not clean up file {file_path}: {cleanup_error}")

def extract_invoice_number(text: str) -> str:
    """Extract invoice number from text"""
    patterns = [
        r'Invoice\s*#?\s*(\d+)',
        r'Invoice\s*Number\s*:?\s*(\d+)',
        r'Invoice\s*ID\s*:?\s*(\d+)'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1)
    
    return "Unknown"

def extract_date(text: str) -> str:
    """Extract invoice date from text"""
    date_patterns = [
        r'Date\s*:?\s*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',
        r'Invoice\s*Date\s*:?\s*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',
    ]
    
    for pattern in date_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                date_str = match.group(1)
                return datetime.strptime(date_str, "%d/%m/%Y").isoformat()
            except ValueError:
                continue
    
    return datetime.now().isoformat()

def extract_due_date(text: str) -> str:
    """Extract due date from text"""
    patterns = [
        r'Due\s*Date\s*:?\s*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})',
        r'Payment\s*Due\s*:?\s*(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                date_str = match.group(1)
                return datetime.strptime(date_str, "%d/%m/%Y").isoformat()
            except ValueError:
                continue
    
    return None

def extract_total_amount(text: str) -> float:
    """Extract total amount from text"""
    patterns = [
        r'Total\s*:?\s*[\$€£]?\s*(\d+[.,]\d{2})',
        r'Amount\s*Due\s*:?\s*[\$€£]?\s*(\d+[.,]\d{2})'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                amount_str = match.group(1).replace(',', '.')
                return float(amount_str)
            except ValueError:
                continue
    
    return 0.0

def extract_tax_amount(text: str) -> float:
    """Extract tax amount from text"""
    patterns = [
        r'Tax\s*:?\s*[\$€£]?\s*(\d+[.,]\d{2})',
        r'VAT\s*:?\s*[\$€£]?\s*(\d+[.,]\d{2})'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            try:
                amount_str = match.group(1).replace(',', '.')
                return float(amount_str)
            except ValueError:
                continue
    
    return 0.0

def extract_client_id(text: str) -> str:
    """Extract client ID from text"""
    patterns = [
        r'Client\s*ID\s*:?\s*(\w+)',
        r'Customer\s*ID\s*:?\s*(\w+)'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1)
    
    return "Unknown"

def extract_project_id(text: str) -> str:
    """Extract project ID from text"""
    patterns = [
        r'Project\s*ID\s*:?\s*(\w+)',
        r'Project\s*Number\s*:?\s*(\w+)'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1)
    
    return None

def extract_description(text: str) -> str:
    """Extract invoice description from text"""
    patterns = [
        r'Description\s*:?\s*([^\n]+)',
        r'Details\s*:?\s*([^\n]+)'
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            return match.group(1).strip()
    
    return None

def extract_items(text: str) -> List[Dict[str, Any]]:
    """Extract invoice line items"""
    items = []
    
    # Try to find item table or list in text
    lines = text.split('\n')
    current_item = {}
    
    for line in lines:
        # Look for patterns that might indicate an item line
        if re.search(r'\d+\s*x\s*[\$€£]?\s*\d+[.,]\d{2}', line):
            if current_item:
                items.append(current_item)
            current_item = {}
            
            # Try to extract quantity and price
            qty_match = re.search(r'(\d+)\s*x', line)
            price_match = re.search(r'[\$€£]?\s*(\d+[.,]\d{2})', line)
            desc_match = re.search(r'([a-zA-Z].+?)\s+\d+\s*x', line)
            
            if qty_match and price_match:
                current_item = {
                    "description": desc_match.group(1) if desc_match else "Unknown item",
                    "quantity": int(qty_match.group(1)),
                    "unitPrice": float(price_match.group(1).replace(',', '.')),
                    "totalPrice": float(price_match.group(1).replace(',', '.')) * int(qty_match.group(1))
                }
    
    # Add last item if exists
    if current_item:
        items.append(current_item)
    
    return items