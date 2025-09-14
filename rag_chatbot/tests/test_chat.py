import pytest
from fastapi.testclient import TestClient
from app.main import app
import json

client = TestClient(app)

def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "rag-chatbot"}

def test_chat_endpoint():
    test_request = {
        "query": "What is the total amount for invoice #12345?",
        "conversation_id": None,
        "context": {"invoice_id": "12345"}
    }
    
    response = client.post("/api/v1/chat", json=test_request)
    assert response.status_code == 200
    data = response.json()
    assert "response" in data
    assert "sources" in data
    assert "conversation_id" in data

def test_index_data():
    test_request = {
        "data_type": "invoices",
        "options": {"full_refresh": True}
    }
    
    response = client.post("/api/v1/admin/index", json=test_request)
    assert response.status_code == 200
    data = response.json()
    assert "task_id" in data
    assert data["status"] == "processing"

def test_get_conversation_history():
    # First create a conversation
    chat_request = {
        "query": "Test question",
        "conversation_id": None
    }
    chat_response = client.post("/api/v1/chat", json=chat_request)
    conversation_id = chat_response.json()["conversation_id"]
    
    # Then get its history
    response = client.get(f"/api/v1/conversations/{conversation_id}")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) > 0