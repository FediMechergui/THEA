# Environment Configuration Guide

This guide explains how to set up environment variables for all THEA services.

## Overview

The THEA system consists of three main services:
- **Node.js Backend**: Main API and business logic
- **FastAPI OCR Service**: Invoice processing and OCR
- **RAG Chatbot Service**: Intelligent query processing

## Environment Files

### Development Environment

For local development, use the `.env.example` files:

1. **Node.js Backend**: `nodejs_backend/.env.example` (already exists)
2. **FastAPI OCR**: `fastapi_ocr/.env.example`
3. **RAG Chatbot**: `rag_chatbot/.env.example`

Copy these files to `.env` in their respective directories:

```bash
# Node.js Backend
cp nodejs_backend/.env.example nodejs_backend/.env

# FastAPI OCR Service
cp fastapi_ocr/.env.example fastapi_ocr/.env

# RAG Chatbot Service
cp rag_chatbot/.env.example rag_chatbot/.env
```

### Docker Environment

For Docker deployment, use the `.env.docker` files:

1. **Node.js Backend**: `nodejs_backend/.env.docker`
2. **FastAPI OCR**: `fastapi_ocr/.env.docker`
3. **RAG Chatbot**: `rag_chatbot/.env.docker`

These files are automatically used by `docker-compose.yml`.

## Key Configuration Points

### 1. API Keys and Security

All services use the same API key for inter-service communication:
```bash
API_KEY=thea-microservices-api-key-2024
```

### 2. Service URLs

Services communicate using Docker network names:
- Node.js Backend: `http://nodejs-backend:3000`
- OCR Service: `http://fastapi-ocr:8000`
- Chatbot Service: `http://rag-chatbot:8001`

### 3. Database Configuration

**MySQL (Main Database):**
- Host: `mysql` (Docker) / `localhost` (Local)
- Database: `thea_db`
- User: `thea_user` / `root`
- Password: `thea_password` / (empty for local)

**PostgreSQL (RAG Service):**
- Host: `postgres` (Docker) / `localhost` (Local)
- Database: `thea`
- User: `user`
- Password: `password`

### 4. Redis Configuration

Used for caching and Celery task queues:
- Host: `redis` (Docker) / `localhost` (Local)
- Port: `6379`
- DB: `0`

### 5. MinIO Configuration

Object storage for files:
- Endpoint: `minio` (Docker) / `localhost` (Local)
- Port: `9000`
- Access Key: `minioadmin`
- Secret Key: `minioadmin`
- Bucket: `thea-invoices`

## Required External Configuration

### Ollama Configuration

The RAG Chatbot service uses Ollama for local LLM inference instead of OpenAI:
```bash
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_MODEL=llama2
```

Available models include:
- `llama2` - Standard Llama2 model
- `llama2:7b-chat` - Optimized chat version
- `codellama` - Code-focused model
- `mistral` - Alternative lightweight model

### Email Configuration (Optional)

For email notifications:
```bash
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
```

## Development Setup

1. **Copy environment files:**
   ```bash
   cp nodejs_backend/.env.example nodejs_backend/.env
   cp fastapi_ocr/.env.example fastapi_ocr/.env
   cp rag_chatbot/.env.example rag_chatbot/.env
   ```

2. **Update local environment files with your values:**
   - Set your OpenAI API key
   - Configure your local database connections
   - Set any other required keys

3. **Start services individually:**
   ```bash
   # Start Node.js backend
   cd nodejs_backend && npm run dev

   # Start OCR service
   cd fastapi_ocr && uvicorn app.main:app --reload --port 8000

   # Start Chatbot service
   cd rag_chatbot && uvicorn app.main:app --reload --port 8001
   ```

## Docker Deployment

1. **Ensure Docker environment files are properly configured**

2. **Start all services:**
   ```bash
   docker-compose up --build
   ```

3. **Services will be available at:**
   - Node.js Backend: http://localhost:3000
   - OCR Service: http://localhost:8000
   - Chatbot Service: http://localhost:8001
   - Grafana: http://localhost:3010
   - Prometheus: http://localhost:9090

## Environment Variables Reference

### Common Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `API_KEY` | Inter-service communication key | Required |
| `LOG_LEVEL` | Logging level | INFO |
| `ENABLE_METRICS` | Enable Prometheus metrics | true |

### Node.js Backend Specific

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | MySQL connection string | Required |
| `JWT_SECRET` | JWT signing secret | Required |
| `REDIS_URL` | Redis connection string | Required |

### OCR Service Specific

| Variable | Description | Default |
|----------|-------------|---------|
| `OCR_CONFIDENCE_THRESHOLD` | Minimum OCR confidence | 0.8 |
| `MAX_FILE_SIZE` | Maximum upload size in bytes | 26214400 |
| `PROCESSING_TIMEOUT` | OCR timeout in seconds | 300 |

### Chatbot Service Specific

| Variable | Description | Default |
|----------|-------------|---------|
| `OLLAMA_BASE_URL` | Ollama service URL | http://ollama:11434 |
| `OLLAMA_MODEL` | LLM model to use | llama2 |
| `VECTOR_STORE_PATH` | ChromaDB storage path | ./data/chroma |
| `RAG_CHUNK_SIZE` | Text chunk size for indexing | 1000 |

## Security Notes

1. **Never commit `.env` files to version control**
2. **Use strong, unique passwords in production**
3. **Rotate API keys regularly**
4. **Use environment-specific configurations**
5. **Enable SSL/TLS in production**

## Troubleshooting

### Common Issues

1. **Service communication failures**: Check that service URLs use correct hostnames
2. **Database connection errors**: Verify database is running and credentials are correct
3. **Missing API keys**: Ensure all required keys are set
4. **Port conflicts**: Make sure ports are not already in use

### Logs

Check service logs:
```bash
# Docker logs
docker-compose logs nodejs-backend
docker-compose logs fastapi-ocr
docker-compose logs rag-chatbot

# Local development logs
# Check console output or log files in logs/ directories
```