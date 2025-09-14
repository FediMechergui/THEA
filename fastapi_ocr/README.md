# FastAPI OCR Service

This service is part of the THEA Backend ecosystem, responsible for processing invoices using OCR technology and extracting structured data according to the system's schema.

## Features

- PDF and image (JPEG, PNG) invoice processing
- Asynchronous processing using Celery
- Redis for task queue management
- Prometheus metrics integration
- Comprehensive error handling
- Containerized deployment
- Automatic text extraction and data structuring

## Setup

### Prerequisites

- Docker and Docker Compose
- Python 3.11+
- Tesseract OCR
- Redis

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

### Health Check
```
GET /health
```

### Process Invoice
```
POST /api/v1/process-invoice
Content-Type: multipart/form-data
```

### Check Task Status
```
GET /api/v1/task/{task_id}
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

2. Run Redis:
```bash
docker-compose up redis -d
```

3. Start the FastAPI application:
```bash
uvicorn app.main:app --reload
```

4. Start Celery worker:
```bash
celery -A app.worker.celery worker --loglevel=info
```

## Architecture

The service follows a microservices architecture pattern:

- FastAPI for the REST API
- Celery for asynchronous task processing
- Redis as message broker and result backend
- Tesseract OCR for text extraction
- OpenCV for image processing
- Prometheus for metrics

## Integration

This service integrates with the main Node.js backend through a shared network and standardized API endpoints.