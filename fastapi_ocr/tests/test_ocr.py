import pytest
from fastapi.testclient import TestClient
from app.main import app
import io
import os

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "ocr"}

def test_upload_invalid_file_type():
    response = client.post(
        "/api/v1/process-invoice",
        files={"file": ("test.txt", "some content", "text/plain")}
    )
    assert response.status_code == 400
    assert "Invalid file type" in response.json()["detail"]

def test_upload_valid_pdf():
    # Create a mock PDF file
    file_content = b"%PDF-1.4\n..."  # Minimal PDF content
    response = client.post(
        "/api/v1/process-invoice",
        files={"file": ("test.pdf", file_content, "application/pdf")}
    )
    assert response.status_code == 200
    assert "task_id" in response.json()
    assert response.json()["status"] == "processing"

def test_task_status():
    # First create a task
    file_content = b"%PDF-1.4\n..."
    response = client.post(
        "/api/v1/process-invoice",
        files={"file": ("test.pdf", file_content, "application/pdf")}
    )
    task_id = response.json()["task_id"]
    
    # Then check its status
    response = client.get(f"/api/v1/task/{task_id}")
    assert response.status_code == 200
    assert response.json()["status"] in ["processing", "completed", "failed"]