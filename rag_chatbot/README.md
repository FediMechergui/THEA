# RAG Chatbot Service

This service is part of the THEA Backend ecosystem, providing a Retrieval Augmented Generation (RAG) chatbot that can answer questions about invoices, clients, and projects by accessing and analyzing data from the main database.

## Features

- Natural language query processing
- Retrieval Augmented Generation using LangChain
- Vector-based semantic search with ChromaDB
- Asynchronous processing using Celery
- Redis for task queue and conversation history
- Prometheus metrics integration
- Comprehensive conversation context management

## Setup

### Prerequisites

- Docker and Docker Compose
- Python 3.11+
- Redis
- PostgreSQL
- ChromaDB

### Installation

1. Clone the repository

2. Build the Docker image:
```bash
docker-compose build
```

3. Start the services:
```bash
docker-compose up -d
```

## API Endpoints

### Chat Endpoint
```
POST /api/v1/chat
Content-Type: application/json
```

Request body:
```json
{
    "query": "What is the total amount for invoice #12345?",
    "conversation_id": "optional-conversation-id",
    "context": {
        "invoice_id": "12345"
    }
}
```

### Conversation History
```
GET /api/v1/conversations/{conversation_id}
```

### Admin Endpoints

#### Index Data
```
POST /api/v1/admin/index
Content-Type: application/json
```

Request body:
```json
{
    "data_type": "invoices",
    "options": {
        "full_refresh": true
    }
}
```

## Development

### Running Tests
```bash
pytest tests/
```

### Local Development
1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Start required services:
```bash
docker-compose up redis postgres vector_store -d
```

3. Start the FastAPI application:
```bash
uvicorn app.main:app --reload --port 8001
```

4. Start Celery worker:
```bash
celery -A app.worker.celery worker --loglevel=info
```

## Architecture

The service follows a microservices architecture pattern:

- FastAPI for the REST API
- LangChain for RAG pipeline
- ChromaDB for vector storage
- Celery for asynchronous processing
- Redis for message broker and result backend
- PostgreSQL for structured data storage
- Prometheus for metrics

## Integration

This service integrates with the main Node.js backend through a shared network and standardized API endpoints.