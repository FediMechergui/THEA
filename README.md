# THEA - Enterprise Financial Management Platform

![Thea Architecture](./DevSecOps%20diagramme.png)

> **THEA** (The Enterprise Accounting Helper) is a comprehensive microservice-based backend system designed for enterprise-grade financial management, featuring AI-powered OCR processing, intelligent document analysis, and real-time chatbot assistance.

## Table of Contents

- [🎯 Executive Summary](#-executive-summary)
- [🏗️ System Architecture](#️-system-architecture)
- [🔧 Technology Stack](#-technology-stack)
- [📦 Microservices Overview](#-microservices-overview)
  - [Node.js Backend Service](#nodejs-backend-service)
  - [FastAPI OCR Service](#fastapi-ocr-service)
  - [RAG Chatbot Service](#rag-chatbot-service)
- [🗄️ Data Architecture](#️-data-architecture)
- [🔗 Service Communication](#-service-communication)
- [🚀 Quick Start](#-quick-start)
- [📋 Prerequisites](#-prerequisites)
- [⚙️ Configuration](#️-configuration)
- [🏃‍♂️ Running the System](#️-running-the-system)
- [🔍 API Documentation](#-api-documentation)
- [🧪 Testing](#-testing)
- [📊 Monitoring & Observability](#-monitoring--observability)
- [🔒 Security](#-security)
- [🚀 Deployment](#-deployment)
- [🔧 Development](#-development)
- [📚 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## 🎯 Executive Summary

THEA is an enterprise-grade financial management platform that addresses the critical needs of modern businesses for efficient financial operations, intelligent document processing, and automated workflow management. Born from comprehensive requirements analysis, THEA provides:

### Key Business Value
- **Intelligent Invoice Processing**: AI-powered OCR with 95%+ accuracy
- **Multi-tenant Architecture**: Secure enterprise isolation
- **Real-time Assistance**: AI chatbot for operational guidance
- **DevSecOps Integration**: Security-first development lifecycle
- **Scalable Microservices**: High availability and performance

### Core Capabilities
- Enterprise financial management
- Automated document scanning and data extraction
- Intelligent verification workflows
- Real-time operational assistance
- Comprehensive audit trails
- Multi-currency support

---

## 🏗️ System Architecture

THEA follows a microservice architecture with three primary services orchestrated through Docker Compose:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Node.js       │    │   FastAPI       │    │   RAG Chatbot   │
│   Backend       │◄──►│   OCR Service   │◄──►│   Service       │
│   (Port 3000)   │    │   (Port 8000)   │    │   (Port 8001)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────────┐
                    │  Infrastructure     │
                    │  Services           │
                    └─────────────────────┘
```

### Infrastructure Components
- **MySQL 8.0**: Primary database for business data
- **PostgreSQL 13**: Secondary database for chatbot data
- **Redis**: Caching, session management, and message queuing
- **RabbitMQ**: Asynchronous task processing
- **MinIO**: Object storage for documents
- **ChromaDB**: Vector database for RAG operations
- **Ollama**: Local LLM inference service
- **Prometheus**: Metrics collection
- **Grafana**: Monitoring dashboards

---

## 🔧 Technology Stack

### Backend Services
| Service | Technology | Version | Purpose |
|---------|------------|---------|---------|
| **Node.js Backend** | Node.js, Express.js | 18+ | Core business logic and APIs |
| **FastAPI OCR** | Python, FastAPI | 0.95.2+ | AI-powered document processing |
| **RAG Chatbot** | Python, FastAPI | 0.95.2+ | Intelligent conversational AI |

### Data & Storage
| Component | Technology | Purpose |
|-----------|------------|---------|
| **Primary DB** | MySQL 8.0 | Business entities and transactions |
| **Secondary DB** | PostgreSQL 13 | Chatbot conversation data |
| **Cache** | Redis 7+ | Session management and caching |
| **Message Queue** | RabbitMQ 3.12+ | Asynchronous task processing |
| **Object Storage** | MinIO | Document and file storage |
| **Vector DB** | ChromaDB 0.4.15+ | Semantic search and embeddings |

### AI/ML Stack
| Component | Technology | Purpose |
|-----------|------------|---------|
| **OCR Engine** | Tesseract OCR | Text extraction from documents |
| **LLM** | Ollama (Llama 2/3) | Local language model inference |
| **Embeddings** | Sentence Transformers | Text vectorization |
| **RAG Framework** | LangChain | Retrieval-augmented generation |

### DevOps & Monitoring
| Component | Technology | Purpose |
|-----------|------------|---------|
| **Containerization** | Docker & Docker Compose | Service orchestration |
| **Metrics** | Prometheus | System and application metrics |
| **Visualization** | Grafana | Monitoring dashboards |
| **Logging** | Winston, Structured logging | Centralized log management |

---

## 📦 Microservices Overview

### Node.js Backend Service

**Port: 3000** | **Technology: Node.js 18+, Express.js, Prisma ORM**

#### Core Responsibilities
- **Authentication & Authorization**: JWT-based auth with role-based access control
- **Business Logic**: Enterprise, user, client, supplier, and project management
- **Invoice Processing**: Document upload, workflow management, and verification
- **API Gateway**: RESTful API endpoints for all business operations
- **Audit Logging**: Comprehensive security and compliance logging

#### Key Dependencies
```json
{
  "@prisma/client": "^5.7.1",
  "express": "^4.18.2",
  "jsonwebtoken": "^9.0.2",
  "bcryptjs": "^2.4.3",
  "redis": "^4.6.11",
  "amqplib": "^0.10.3",
  "minio": "^7.1.3",
  "winston": "^3.11.0"
}
```

#### Database Schema
- **Enterprise**: Multi-tenant organization management
- **User**: Authentication and role management (ADMIN, ACCOUNTANT, VERIFIER)
- **Invoice**: Core financial document with OCR integration
- **Client/Supplier**: External business entity management
- **Project/Stock**: Resource and inventory management
- **AuditLog**: Immutable security audit trail

#### API Endpoints Structure
```
POST   /api/auth/login           - User authentication
POST   /api/auth/register        - User registration
GET    /api/auth/me             - Current user profile
POST   /api/auth/logout         - User logout

GET    /api/enterprises         - List enterprises
POST   /api/enterprises         - Create enterprise
GET    /api/enterprises/:id     - Get enterprise details

GET    /api/users               - List users
POST   /api/users               - Create user
PUT    /api/users/:id           - Update user
DELETE /api/users/:id           - Delete user

POST   /api/invoices            - Upload invoice document
GET    /api/invoices            - List invoices
GET    /api/invoices/:id        - Get invoice details
PUT    /api/invoices/:id/status - Update invoice status
POST   /api/invoices/:id/verify - Verify invoice

GET    /api/clients             - List clients
POST   /api/clients             - Create client
PUT    /api/clients/:id         - Update client

GET    /api/suppliers           - List suppliers
POST   /api/suppliers           - Create supplier
PUT    /api/suppliers/:id       - Update supplier

GET    /api/projects            - List projects
POST   /api/projects            - Create project
PUT    /api/projects/:id        - Update project

GET    /api/stocks              - List inventory items
POST   /api/stocks              - Add inventory item
PUT    /api/stocks/:id          - Update inventory

GET    /api/metrics             - Get financial metrics
```

#### Service Architecture
```
src/
├── server.js              # Main application server
├── config/
│   ├── database.js        # Prisma database configuration
│   └── logger.js          # Winston logging configuration
├── middleware/
│   ├── auth.js            # JWT authentication middleware
│   ├── errorHandler.js    # Global error handling
│   ├── notFoundHandler.js # 404 error handling
│   └── requestLogger.js   # Request logging middleware
├── routes/
│   ├── auth.js            # Authentication endpoints
│   ├── users.js           # User management endpoints
│   ├── enterprises.js     # Enterprise management endpoints
│   ├── clients.js         # Client management endpoints
│   ├── suppliers.js       # Supplier management endpoints
│   ├── projects.js        # Project management endpoints
│   ├── invoices.js        # Invoice processing endpoints
│   ├── stocks.js          # Inventory management endpoints
│   └── metrics.js         # Metrics and reporting endpoints
└── services/
    ├── serviceInitializer.js # Infrastructure service initialization
    ├── minioService.js       # MinIO object storage service
    ├── rabbitmqService.js    # RabbitMQ message queue service
    └── redisService.js       # Redis caching service
```

### FastAPI OCR Service

**Port: 8000** | **Technology: Python 3.9+, FastAPI, Celery**

#### Core Responsibilities
- **Document Processing**: PDF and image OCR with Tesseract
- **Data Extraction**: Intelligent field recognition and extraction
- **Layout Analysis**: Document structure understanding
- **Confidence Scoring**: Quality assessment for verification workflow
- **Async Processing**: Background task processing with Celery

#### Key Dependencies
```python
fastapi>=0.95.2
uvicorn>=0.18.3
opencv-python-headless
pytesseract
pdf2image
celery
redis
numpy
prometheus-fastapi-instrumentator
```

#### Service Architecture
```
app/
├── main.py                 # FastAPI application entry point
├── core/
│   ├── config.py          # Application configuration
│   └── security.py        # Security utilities
├── models/
│   ├── ocr.py            # OCR data models
│   └── response.py       # API response models
├── routers/
│   ├── ocr.py            # OCR processing endpoints
│   └── health.py         # Health check endpoints
├── services/
│   ├── ocr_service.py    # Core OCR processing logic
│   ├── celery_app.py     # Celery task queue configuration
│   └── file_service.py   # File upload and processing
└── worker.py              # Celery worker entry point
```

#### OCR Processing Pipeline
1. **Document Upload**: Receive PDF/image files via REST API
2. **Preprocessing**: Image enhancement and noise reduction
3. **Text Extraction**: Tesseract OCR with multiple language support
4. **Layout Analysis**: Document structure recognition
5. **Field Detection**: Intelligent field identification using coordinates
6. **Data Validation**: Format validation and confidence scoring
7. **Result Storage**: Processed data storage in database

#### API Endpoints
```
POST   /api/v1/ocr/process         - Process document for OCR
GET    /api/v1/ocr/status/{task_id} - Get processing status
GET    /api/v1/ocr/results/{task_id} - Get OCR results
POST   /api/v1/ocr/batch           - Batch process multiple documents
GET    /health                     - Service health check
GET    /metrics                    - Prometheus metrics
```

#### Celery Tasks
- `process_document`: Main OCR processing task
- `extract_text`: Text extraction from images
- `analyze_layout`: Document layout analysis
- `validate_data`: Extracted data validation
- `store_results`: Result persistence

### RAG Chatbot Service

**Port: 8001** | **Technology: Python 3.9+, FastAPI, LangChain, Ollama**

#### Core Responsibilities
- **Conversational AI**: Natural language processing and response generation
- **Retrieval-Augmented Generation**: Context-aware responses using enterprise data
- **Vector Search**: Semantic search over enterprise knowledge base
- **Session Management**: Conversation context and history tracking
- **Real-time Communication**: WebSocket support for live chat

#### Key Dependencies
```python
fastapi>=0.95.2
uvicorn>=0.18.3
langchain>=0.0.300
langchain-community>=0.0.6
ollama>=0.1.7
chromadb>=0.4.15
sentence-transformers
transformers
torch
redis
celery
```

#### Service Architecture
```
app/
├── main.py                 # FastAPI application entry point
├── core/
│   ├── config.py          # Application configuration
│   └── ollama_client.py   # Ollama LLM client
├── models/
│   ├── chat.py            # Chat data models
│   └── response.py        # API response models
├── routers/
│   ├── chat.py            # Chat endpoints
│   ├── admin.py           # Administrative endpoints
│   └── health.py          # Health check endpoints
├── services/
│   ├── chat_service.py    # Core chat processing logic
│   ├── vector_service.py  # Vector database operations
│   ├── embedding_service.py # Text embedding generation
│   ├── celery_app.py      # Celery task queue configuration
│   └── session_service.py # Session management
└── worker.py              # Celery worker entry point
```

#### RAG Pipeline
1. **Query Processing**: Natural language query analysis
2. **Context Retrieval**: Semantic search over vector database
3. **Relevance Ranking**: Context ranking and filtering
4. **Prompt Engineering**: Context injection into LLM prompts
5. **Response Generation**: LLM-powered response creation
6. **Response Validation**: Output quality and safety checks
7. **Session Updates**: Conversation history persistence

#### API Endpoints
```
POST   /api/v1/chat/message        - Send chat message
GET    /api/v1/chat/history/{session_id} - Get conversation history
POST   /api/v1/chat/session       - Create new chat session
DELETE /api/v1/chat/session/{session_id} - Delete chat session
GET    /api/v1/admin/stats        - Get chatbot statistics
POST   /api/v1/admin/embeddings   - Rebuild embeddings
GET    /health                    - Service health check
GET    /metrics                   - Prometheus metrics
```

#### Vector Database Schema
- **enterprise_docs**: Enterprise-specific documents and knowledge
- **conversations**: Chat history for context retrieval
- **faqs**: Frequently asked questions and answers
- **policies**: Company policies and procedures

---

## 🗄️ Data Architecture

### Primary Database (MySQL)

#### Core Entities Relationship
```
Enterprise (1) ──── (N) User
    │                    │
    ├── (N) Client       ├── (N) Invoice (Created)
    ├── (N) Supplier     ├── (N) Invoice (Processed)
    ├── (N) Project      └── (N) Invoice (Verified)
    ├── (N) CompanyStock
    ├── (N) Metrics
    └── (N) AuditLog
```

#### Key Tables Schema

**Enterprise**
```sql
- id: VARCHAR(36) PRIMARY KEY
- name: VARCHAR(255) NOT NULL
- taxId: VARCHAR(100) UNIQUE NOT NULL
- country: VARCHAR(100) NOT NULL
- currency: VARCHAR(3) NOT NULL
- address: TEXT NOT NULL
- phone: VARCHAR(20) NOT NULL
- city: VARCHAR(100) NOT NULL
- postalCode: VARCHAR(20) NOT NULL
- invitationCode: VARCHAR(100) UNIQUE NOT NULL
- createdAt: TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- updatedAt: TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

**User**
```sql
- id: VARCHAR(36) PRIMARY KEY
- username: VARCHAR(100) UNIQUE NOT NULL
- email: VARCHAR(255) UNIQUE NOT NULL
- passwordHash: VARCHAR(255) NOT NULL
- role: ENUM('ADMIN', 'ACCOUNTANT', 'VERIFIER') DEFAULT 'ACCOUNTANT'
- phone: VARCHAR(20)
- address: TEXT
- specialty: VARCHAR(255)
- encryptedPii: TEXT
- mfaEnabled: BOOLEAN DEFAULT FALSE
- enterpriseId: VARCHAR(36) NOT NULL (FK)
- createdById: VARCHAR(36) (FK - Self-referencing)
- createdAt: TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- updatedAt: TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

**Invoice**
```sql
- id: VARCHAR(36) PRIMARY KEY
- invoiceDate: DATE NOT NULL
- dueDate: DATE NOT NULL
- totalAmount: DECIMAL(15,2) NOT NULL
- currency: VARCHAR(3) NOT NULL
- status: ENUM('PENDING', 'PAID', 'OVERDUE') DEFAULT 'PENDING'
- type: ENUM('SALE', 'PURCHASE') NOT NULL
- scanUrl: TEXT
- extractedData: JSON
- verificationStatus: ENUM('AUTO_APPROVED', 'MANUAL_VERIFICATION_NEEDED', 'VERIFIED', 'REJECTED') DEFAULT 'MANUAL_VERIFICATION_NEEDED'
- digitalSignature: VARCHAR(255)
- enterpriseId: VARCHAR(36) NOT NULL (FK)
- clientId: VARCHAR(36) (FK)
- supplierId: VARCHAR(36) (FK)
- projectId: VARCHAR(36) (FK)
- createdById: VARCHAR(36) NOT NULL (FK)
- processedById: VARCHAR(36) (FK)
- verifiedById: VARCHAR(36) (FK)
- createdAt: TIMESTAMP DEFAULT CURRENT_TIMESTAMP
- updatedAt: TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
```

### Secondary Database (PostgreSQL)

**Chatbot Data Schema**
```sql
-- Conversations table
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(36),
    enterprise_id VARCHAR(36),
    messages JSONB NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Documents table for RAG
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content TEXT NOT NULL,
    metadata JSONB,
    embedding VECTOR(384), -- Adjust dimension based on embedding model
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Sessions table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(36),
    enterprise_id VARCHAR(36),
    context JSONB,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Vector Database (ChromaDB)

**Collections Structure**
- **enterprise_docs**: Enterprise-specific documents and knowledge
- **conversations**: Chat history for context retrieval
- **faqs**: Frequently asked questions and answers
- **policies**: Company policies and procedures

---

## 🔗 Service Communication

### Synchronous Communication

#### REST API Calls
```
Node.js Backend → FastAPI OCR
- POST /api/v1/ocr/process
- Purpose: Submit document for OCR processing
- Payload: Document file + metadata
- Response: Task ID for async processing

Node.js Backend → RAG Chatbot
- POST /api/v1/chat/message
- Purpose: Send user query for processing
- Payload: Message + context + user info
- Response: AI-generated response

RAG Chatbot → Node.js Backend
- GET /api/enterprises/{id}
- Purpose: Retrieve enterprise context
- Response: Enterprise data for personalization
```

### Asynchronous Communication

#### RabbitMQ Message Queue
**Exchange: thea.exchange**
**Routing Keys:**
- `ocr.process` - Document processing requests
- `ocr.completed` - OCR processing completion
- `invoice.verified` - Invoice verification updates
- `audit.log` - Security audit events

**Message Flow:**
```
1. User uploads invoice → Node.js Backend
2. Backend publishes to 'ocr.process' queue
3. FastAPI OCR worker consumes message
4. OCR processing completes
5. Result published to 'ocr.completed' queue
6. Node.js Backend updates invoice status
```

#### Redis Pub/Sub
**Channels:**
- `chat.sessions` - Real-time chat session updates
- `notifications` - System notifications
- `cache.invalidation` - Cache invalidation signals

### Service Discovery

#### Environment Variables Configuration
```bash
# Node.js Backend
FASTAPI_OCR_URL=http://fastapi-ocr:8000
RAG_CHATBOT_URL=http://rag-chatbot:8001

# FastAPI OCR
NODEJS_BACKEND_URL=http://nodejs-backend:3000

# RAG Chatbot
NODEJS_BACKEND_URL=http://nodejs-backend:3000
OLLAMA_URL=http://ollama:11434
```

#### Health Checks
- **Node.js Backend**: `/health` endpoint
- **FastAPI OCR**: `/health` endpoint
- **RAG Chatbot**: `/health` endpoint
- **Infrastructure**: Docker health checks for all services

---

## 🚀 Quick Start

### Prerequisites Checklist
- [ ] Docker Engine 20.10+
- [ ] Docker Compose 2.0+
- [ ] Git
- [ ] 8GB RAM minimum
- [ ] 20GB free disk space
- [ ] Ports 3000, 8000, 8001, 3306, 5432, 6379, 5672, 9000, 9090, 3010 available

### One-Command Setup
```bash
# Clone repository
git clone https://github.com/FediMechergui/Thea_Backend_Microservice_DevSecOps.git
cd Thea_Backend_Microservice_DevSecOps

# Start all services
docker-compose up --build

# Verify services are running
curl http://localhost:3000/health
curl http://localhost:8000/health
curl http://localhost:8001/health
```

### Manual Setup (Development)

#### 1. Environment Setup
```bash
# Copy environment files
cp nodejs_backend/.env.example nodejs_backend/.env
cp fastapi_ocr/.env.example fastapi_ocr/.env
cp rag_chatbot/.env.example rag_chatbot/.env
```

#### 2. Database Setup
```bash
# Start infrastructure services
docker-compose up -d mysql redis rabbitmq minio postgres

# Run database migrations
cd nodejs_backend
npm run db:migrate
npm run db:seed
```

#### 3. Install Dependencies
```bash
# Node.js Backend
cd nodejs_backend
npm install

# FastAPI OCR
cd ../fastapi_ocr
pip install -r requirements.txt

# RAG Chatbot
cd ../rag_chatbot
pip install -r requirements.txt
```

#### 4. Start Services
```bash
# Terminal 1: Node.js Backend
cd nodejs_backend
npm run dev

# Terminal 2: FastAPI OCR
cd ../fastapi_ocr
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 3: RAG Chatbot
cd ../rag_chatbot
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

#### Start Celery Workers
```bash
# Terminal 4: OCR Worker
cd fastapi_ocr
celery -A app.services.celery_app worker --loglevel=info

# Terminal 5: Chatbot Worker
cd ../rag_chatbot
celery -A app.services.celery_app worker --loglevel=info
```

---

## 📋 Prerequisites

### System Requirements
- **OS**: Linux, macOS, or Windows 10/11 with WSL2
- **CPU**: 4+ cores recommended
- **RAM**: 8GB minimum, 16GB recommended
- **Storage**: 20GB free space for containers and data
- **Network**: Stable internet connection for dependency downloads

### Software Dependencies
| Component | Version | Installation |
|-----------|---------|--------------|
| **Docker** | 20.10+ | [Install Docker](https://docs.docker.com/get-docker/) |
| **Docker Compose** | 2.0+ | Included with Docker Desktop |
| **Git** | 2.30+ | [Install Git](https://git-scm.com/downloads) |
| **Node.js** | 18+ | [Install Node.js](https://nodejs.org/) |
| **Python** | 3.9+ | [Install Python](https://python.org/) |
| **MySQL Client** | 8.0+ | Optional for direct database access |

### Port Availability
Ensure these ports are available on your system:
- `3000` - Node.js Backend
- `8000` - FastAPI OCR Service
- `8001` - RAG Chatbot Service
- `3306` - MySQL Database
- `5432` - PostgreSQL Database
- `6379` - Redis Cache
- `5672` - RabbitMQ AMQP
- `15672` - RabbitMQ Management UI
- `9000` - MinIO API
- `9001` - MinIO Console
- `9090` - Prometheus
- `3010` - Grafana
- `11434` - Ollama API

---

## ⚙️ Configuration

### Environment Variables

#### Node.js Backend (.env)
```bash
# Server Configuration
NODE_ENV=development
PORT=3000
HOST=0.0.0.0

# Database
DATABASE_URL=mysql://thea_user:thea_password@mysql:3306/thea_db

# JWT
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRES_IN=24h
JWT_REFRESH_SECRET=your-refresh-token-secret
JWT_REFRESH_EXPIRES_IN=7d

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# RabbitMQ
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# MinIO
MINIO_ENDPOINT=minio
MINIO_PORT=9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_BUCKET_NAME=thea-documents

# External Services
FASTAPI_OCR_URL=http://fastapi-ocr:8000
RAG_CHATBOT_URL=http://rag-chatbot:8001

# Security
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=info
LOG_FILE=logs/thea-backend.log
```

#### FastAPI OCR Service (.env)
```bash
# Server Configuration
ENVIRONMENT=development
HOST=0.0.0.0
PORT=8000

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# RabbitMQ
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
RABBITMQ_USER=guest
RABBITMQ_PASSWORD=guest

# MinIO
MINIO_ENDPOINT=minio
MINIO_PORT=9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin

# OCR Configuration
TESSERACT_LANG=eng+fra
OCR_CONFIDENCE_THRESHOLD=0.8
MAX_FILE_SIZE=10485760

# Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Node.js Backend
NODEJS_BACKEND_URL=http://nodejs-backend:3000
```

#### RAG Chatbot Service (.env)
```bash
# Server Configuration
ENVIRONMENT=development
HOST=0.0.0.0
PORT=8001

# Database
DATABASE_URL=postgresql://user:password@postgres:5432/thea

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Vector Database
CHROMA_HOST=vector_store
CHROMA_PORT=8000

# Ollama
OLLAMA_HOST=http://ollama:11434
OLLAMA_MODEL=llama2

# LangChain
LANGCHAIN_TRACING=false

# Celery
CELERY_BROKER_URL=redis://redis:6379/0
CELERY_RESULT_BACKEND=redis://redis:6379/0

# Node.js Backend
NODEJS_BACKEND_URL=http://nodejs-backend:3000

# Embedding Configuration
EMBEDDING_MODEL=sentence-transformers/all-MiniLM-L6-v2
VECTOR_DIMENSION=384
```

### Docker Compose Configuration

#### Service Dependencies
```yaml
services:
  nodejs-backend:
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_started
      rabbitmq:
        condition: service_started
      minio:
        condition: service_healthy

  fastapi-ocr:
    depends_on:
      redis:
        condition: service_started
      minio:
        condition: service_healthy

  rag-chatbot:
    depends_on:
      redis:
        condition: service_started
      postgres:
        condition: service_healthy
      vector_store:
        condition: service_started
      ollama:
        condition: service_started
```

#### Health Checks
```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  timeout: 20s
  retries: 10
  interval: 30s
  start_period: 40s
```

---

## 🏃‍♂️ Running the System

### Development Mode

#### Start Infrastructure Services
```bash
# Start databases and message queues
docker-compose up -d mysql redis rabbitmq minio postgres vector_store ollama

# Wait for services to be healthy
docker-compose ps
```

#### Start Application Services
```bash
# Terminal 1: Node.js Backend
cd nodejs_backend
npm run dev

# Terminal 2: FastAPI OCR
cd ../fastapi_ocr
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Terminal 3: RAG Chatbot
cd ../rag_chatbot
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

#### Start Celery Workers
```bash
# Terminal 4: OCR Worker
cd fastapi_ocr
celery -A app.services.celery_app worker --loglevel=info

# Terminal 5: Chatbot Worker
cd ../rag_chatbot
celery -A app.services.celery_app worker --loglevel=info
```

### Production Mode

#### Using Docker Compose
```bash
# Build and start all services
docker-compose up --build

# Start in background
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v
```

#### Scaling Services
```bash
# Scale OCR workers
docker-compose up -d --scale fastapi-ocr-worker=3

# Scale chatbot workers
docker-compose up -d --scale rag-chatbot-worker=2
```

### Service Verification

#### Health Checks
```bash
# Node.js Backend
curl http://localhost:3000/health

# FastAPI OCR
curl http://localhost:8000/health

# RAG Chatbot
curl http://localhost:8001/health
```

#### Database Connections
```bash
# MySQL
docker-compose exec mysql mysql -u thea_user -p thea_db

# PostgreSQL
docker-compose exec postgres psql -U user -d thea

# Redis
docker-compose exec redis redis-cli
```

#### Message Queue
```bash
# RabbitMQ Management UI
open http://localhost:15672
# Username: guest, Password: guest
```

---

## 🔍 API Documentation

### Node.js Backend API

#### Authentication Endpoints
```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "john_doe",
  "email": "john@example.com",
  "password": "securePassword123",
  "enterpriseId": "uuid-here",
  "role": "ACCOUNTANT"
}
```

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securePassword123"
}
```

#### Invoice Processing
```http
POST /api/invoices
Content-Type: multipart/form-data

# Form data:
- file: [PDF/Image file]
- enterpriseId: "uuid-here"
- type: "SALE" | "PURCHASE"
- clientId?: "uuid-here"
- supplierId?: "uuid-here"
- projectId?: "uuid-here"
```

#### Response Format
```json
{
  "success": true,
  "data": {
    "id": "uuid-here",
    "status": "PENDING",
    "extractedData": null,
    "createdAt": "2024-01-01T00:00:00.000Z"
  },
  "message": "Invoice uploaded successfully"
}
```

### FastAPI OCR API

#### Document Processing
```http
POST /api/v1/ocr/process
Content-Type: multipart/form-data

# Form data:
- file: [PDF/Image file]
- language: "eng" (optional)
- confidence_threshold: 0.8 (optional)
```

#### Response Format
```json
{
  "task_id": "uuid-here",
  "status": "processing",
  "message": "Document processing started"
}
```

#### Get Results
```http
GET /api/v1/ocr/results/{task_id}
```

```json
{
  "task_id": "uuid-here",
  "status": "completed",
  "result": {
    "text": "Extracted text content...",
    "confidence": 0.92,
    "fields": {
      "invoice_number": "INV-001",
      "date": "2024-01-01",
      "total": "1500.00",
      "currency": "USD"
    },
    "coordinates": [...]
  }
}
```

### RAG Chatbot API

#### Send Message
```http
POST /api/v1/chat/message
Content-Type: application/json

{
  "message": "How do I create a new invoice?",
  "session_id": "uuid-here",
  "user_id": "uuid-here",
  "enterprise_id": "uuid-here",
  "context": {
    "current_page": "invoices",
    "user_role": "ACCOUNTANT"
  }
}
```

#### Response Format
```json
{
  "response": "To create a new invoice, navigate to the Invoices section and click the 'New Invoice' button...",
  "session_id": "uuid-here",
  "confidence": 0.89,
  "sources": [
    {
      "document_id": "uuid-here",
      "relevance_score": 0.95,
      "content": "..."
    }
  ]
}
```

---

## 🧪 Testing

### Unit Testing

#### Node.js Backend
```bash
cd nodejs_backend

# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- tests/routes/auth.test.js

# Run integration tests
npm run test:integration
```

#### FastAPI OCR Service
```bash
cd fastapi_ocr

# Run tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific tests
pytest tests/test_ocr_service.py
```

#### RAG Chatbot Service
```bash
cd rag_chatbot

# Run tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html
```

### Integration Testing

#### End-to-End Workflow Test
```bash
# 1. Create enterprise and user
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@example.com","password":"test123","enterpriseId":"test-enterprise"}'

# 2. Login and get token
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  | jq -r '.data.token')

# 3. Upload invoice
curl -X POST http://localhost:3000/api/invoices \
  -H "Authorization: Bearer $TOKEN" \
  -F "file=@sample_invoice.pdf" \
  -F "enterpriseId=test-enterprise" \
  -F "type=SALE"

# 4. Check OCR processing status
curl http://localhost:8000/api/v1/ocr/status/{task_id}

# 5. Query chatbot
curl -X POST http://localhost:8001/api/v1/chat/message \
  -H "Content-Type: application/json" \
  -d '{"message":"What is the status of my invoice?","session_id":"test-session"}'
```

### Load Testing

#### Using Artillery
```yaml
# artillery.yml
config:
  target: 'http://localhost:3000'
  phases:
    - duration: 60
      arrivalRate: 10
      name: "Warm up"
    - duration: 120
      arrivalRate: 50
      name: "Load test"

scenarios:
  - name: "Invoice upload workflow"
    weight: 70
    flow:
      - post:
          url: "/api/auth/login"
          json:
            email: "test@example.com"
            password: "test123"
      - post:
          url: "/api/invoices"
          formData:
            file: "sample_invoice.pdf"
            enterpriseId: "test-enterprise"

  - name: "Chat query"
    weight: 30
    flow:
      - post:
          url: "/api/v1/chat/message"
          json:
            message: "Help me create an invoice"
            session_id: "test-session"
```

```bash
# Run load test
npm install -g artillery
artillery run artillery.yml
```

---

## 📊 Monitoring & Observability

### Prometheus Metrics

#### Application Metrics
```prometheus
# Node.js Backend Metrics
nodejs_backend_http_requests_total{method="GET", route="/api/invoices", status="200"} 1250
nodejs_backend_http_request_duration_seconds{method="POST", route="/api/auth/login"} 0.023

# FastAPI OCR Metrics
fastapi_ocr_processing_duration_seconds{status="success"} 2.34
fastapi_ocr_ocr_confidence{average="0.89"} 0.89

# RAG Chatbot Metrics
rag_chatbot_response_time_seconds{model="llama2"} 1.23
rag_chatbot_token_usage_total{model="llama2"} 45678
```

#### Infrastructure Metrics
```prometheus
# Database Metrics
mysql_connections_active 12
mysql_queries_total 15432
postgres_connections_active 8

# Cache Metrics
redis_connected_clients 25
redis_memory_used_bytes 134217728

# Message Queue
rabbitmq_queue_messages{queue="ocr.process"} 5
rabbitmq_queue_messages{queue="chat.responses"} 12
```

### Grafana Dashboards

#### System Overview Dashboard
- Service Health Status
- Response Times
- Error Rates
- Resource Utilization (CPU, Memory, Disk)

#### Business Metrics Dashboard
- Invoice Processing Volume
- OCR Accuracy Trends
- User Activity Metrics
- Financial KPIs

#### Infrastructure Dashboard
- Database Performance
- Cache Hit Rates
- Message Queue Throughput
- Network I/O

### Logging

#### Structured Logging Format
```json
{
  "timestamp": "2024-01-01T12:00:00.000Z",
  "level": "info",
  "service": "nodejs-backend",
  "requestId": "req-12345",
  "userId": "user-67890",
  "enterpriseId": "ent-abcde",
  "method": "POST",
  "url": "/api/invoices",
  "statusCode": 200,
  "responseTime": 234,
  "userAgent": "Mozilla/5.0...",
  "ip": "192.168.1.100",
  "message": "Invoice uploaded successfully"
}
```

#### Log Aggregation
```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f nodejs-backend

# Search logs for errors
docker-compose logs | grep ERROR

# Export logs for analysis
docker-compose logs > system_logs.txt
```

### Alerting Rules

#### Critical Alerts
```yaml
groups:
  - name: thea.critical
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.service }} is down"
          description: "Service {{ $labels.service }} has been down for more than 5 minutes"

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate on {{ $labels.service }}"
          description: "Error rate > 10% for 5 minutes"
```

#### Warning Alerts
```yaml
      - alert: HighResponseTime
        expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High response time on {{ $labels.service }}"
          description: "95th percentile response time > 5s"
```

---

## 🔒 Security

### Authentication & Authorization

#### JWT Token Structure
```json
{
  "header": {
    "alg": "HS256",
    "typ": "JWT"
  },
  "payload": {
    "userId": "uuid-here",
    "enterpriseId": "uuid-here",
    "role": "ACCOUNTANT",
    "permissions": ["read:invoices", "write:invoices"],
    "iat": 1640995200,
    "exp": 1641081600,
    "iss": "thea-backend"
  },
  "signature": "base64-encoded-signature"
}
```

#### Role-Based Access Control
```javascript
const permissions = {
  ADMIN: [
    'create:enterprise',
    'read:enterprise',
    'update:enterprise',
    'delete:enterprise',
    'create:user',
    'read:user',
    'update:user',
    'delete:user',
    'create:invoice',
    'read:invoice',
    'update:invoice',
    'delete:invoice',
    'verify:invoice'
  ],
  ACCOUNTANT: [
    'create:invoice',
    'read:invoice',
    'update:invoice',
    'read:user',
    'read:enterprise'
  ],
  VERIFIER: [
    'read:invoice',
    'verify:invoice',
    'read:user',
    'read:enterprise'
  ]
};
```

### Data Security

#### Encryption at Rest
```javascript
// PII Encryption
const encryptedPII = encrypt(JSON.stringify({
  ssn: '123-45-6789',
  bankAccount: '123456789',
  creditCard: '4111111111111111'
}), process.env.ENCRYPTION_KEY);

// Database Storage
await prisma.user.update({
  where: { id: userId },
  data: { encryptedPii: encryptedPII }
});
```

#### Data Validation
```javascript
const invoiceSchema = Joi.object({
  invoiceDate: Joi.date().required(),
  dueDate: Joi.date().min(Joi.ref('invoiceDate')).required(),
  totalAmount: Joi.number().positive().precision(2).required(),
  currency: Joi.string().length(3).required(),
  type: Joi.string().valid('SALE', 'PURCHASE').required(),
  enterpriseId: Joi.string().uuid().required()
});
```

### Infrastructure Security

#### Container Security
```dockerfile
# Use non-root user
USER appuser

# Security hardening
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# No secrets in environment
ENV NODE_ENV=production
```

#### Network Security
```yaml
# Docker Compose network configuration
networks:
  thea-network:
    driver: bridge
    internal: true
    ipam:
      config:
        - subnet: 172.20.0.0/16

# Service isolation
services:
  nodejs-backend:
    networks:
      - thea-network
    security_opt:
      - no-new-privileges:true
```

### Security Monitoring

#### Audit Logging
```javascript
// Comprehensive audit trail
await prisma.auditLog.create({
  data: {
    logEventType: 'INVOICE_UPDATED',
    versionHash: generateVersionHash(invoiceData),
    immutable: true,
    enterprise: { connect: { id: enterpriseId } },
    user: { connect: { id: userId } },
    invoice: { connect: { id: invoiceId } }
  }
});
```

#### Security Headers
```javascript
// Helmet.js security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));
```

---

## 🚀 Deployment

### Production Environment Setup

#### Infrastructure Requirements
- **Load Balancer**: Nginx or AWS ALB
- **Application Servers**: 2-4 instances per service
- **Database**: Managed MySQL/PostgreSQL
- **Cache**: Redis cluster
- **Object Storage**: S3-compatible storage
- **Monitoring**: Prometheus + Grafana stack

#### Environment Configuration
```bash
# Production environment variables
NODE_ENV=production
DATABASE_URL=mysql://user:password@rds-endpoint:3306/thea_db
REDIS_URL=redis://redis-cluster:6379
RABBITMQ_URL=amqp://user:password@mq-endpoint:5672
MINIO_ENDPOINT=https://s3-endpoint
OLLAMA_HOST=https://ollama-endpoint:11434
```

### Docker Production Deployment

#### Multi-stage Dockerfile
```dockerfile
# Build stage
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

# Production stage
FROM node:18-alpine AS production
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .

USER nextjs

EXPOSE 3000
CMD ["npm", "start"]
```

#### Production Docker Compose
```yaml
version: '3.8'
services:
  nodejs-backend:
    image: thea/nodejs-backend:latest
    environment:
      - NODE_ENV=production
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Kubernetes Deployment

#### Deployment Manifest
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs-backend
  template:
    metadata:
      labels:
        app: nodejs-backend
    spec:
      containers:
      - name: nodejs-backend
        image: thea/nodejs-backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        resources:
          limits:
            cpu: "1000m"
            memory: "1Gi"
          requests:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### Service Manifest
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nodejs-backend
spec:
  selector:
    app: nodejs-backend
  ports:
    - port: 3000
      targetPort: 3000
  type: ClusterIP
```

#### Ingress Configuration
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: thea-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: api.thea.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: nodejs-backend
            port:
              number: 3000
      - path: /ocr
        pathType: Prefix
        backend:
          service:
            name: fastapi-ocr
            port:
              number: 8000
      - path: /chat
        pathType: Prefix
        backend:
          service:
            name: rag-chatbot
            port:
              number: 8001
```

### CI/CD Pipeline

#### GitHub Actions Workflow
```yaml
name: THEA CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    - name: Install dependencies
      run: npm ci
    - name: Run tests
      run: npm run test:ci
    - name: Upload coverage
      uses: codecov/codecov-action@v3

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Run Snyk
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
    - name: Run Trivy
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'

  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Build Docker images
      run: |
        docker build -t thea/nodejs-backend:latest ./nodejs_backend
        docker build -t thea/fastapi-ocr:latest ./fastapi_ocr
        docker build -t thea/rag-chatbot:latest ./rag_chatbot
    - name: Push to registry
      run: |
        echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
        docker push thea/nodejs-backend:latest
        docker push thea/fastapi-ocr:latest
        docker push thea/rag-chatbot:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
    - name: Deploy to production
      run: |
        kubectl set image deployment/nodejs-backend nodejs-backend=thea/nodejs-backend:latest
        kubectl set image deployment/fastapi-ocr fastapi-ocr=thea/fastapi-ocr:latest
        kubectl set image deployment/rag-chatbot rag-chatbot=thea/rag-chatbot:latest
```

---

## 🔧 Development

### Development Workflow

#### Branching Strategy
```bash
# Main branches
git checkout main          # Production-ready code
git checkout develop       # Integration branch

# Feature development
git checkout -b feature/user-authentication
git checkout -b feature/ocr-processing

# Bug fixes
git checkout -b bugfix/invoice-validation

# Hotfixes
git checkout -b hotfix/security-patch
```

#### Commit Convention
```bash
# Format: type(scope): description
git commit -m "feat(auth): add JWT token refresh"
git commit -m "fix(invoice): resolve date validation bug"
git commit -m "docs(api): update authentication endpoints"
git commit -m "test(ocr): add unit tests for text extraction"
git commit -m "refactor(db): optimize query performance"
```

### Code Quality

#### ESLint Configuration
```javascript
// .eslintrc.js
module.exports = {
  env: {
    node: true,
    es2022: true,
    jest: true
  },
  extends: [
    'standard'
  ],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module'
  },
  rules: {
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'warn',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'warn',
    'prefer-const': 'error',
    'no-var': 'error'
  }
};
```

#### Pre-commit Hooks
```bash
# Install husky
npm install husky --save-dev

# Initialize git hooks
npx husky install

# Add pre-commit hook
echo '#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npm run lint
npm run test:unit
' > .husky/pre-commit

chmod +x .husky/pre-commit
```

### Database Migrations

#### Prisma Migration Workflow
```bash
# Create migration
npx prisma migrate dev --name add-user-preferences

# Generate client
npx prisma generate

# View migration status
npx prisma migrate status

# Reset database (development only)
npx prisma migrate reset

# Deploy to production
npx prisma migrate deploy
```

#### Migration File Structure
```sql
-- 001_add_user_preferences.sql
ALTER TABLE users ADD COLUMN preferences JSON DEFAULT '{}';

-- 002_create_audit_logs.sql
CREATE TABLE audit_logs (
  id VARCHAR(36) PRIMARY KEY DEFAULT (UUID()),
  log_event_type VARCHAR(50) NOT NULL,
  version_hash VARCHAR(255) NOT NULL,
  immutable BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  enterprise_id VARCHAR(36),
  user_id VARCHAR(36),
  invoice_id VARCHAR(36),
  FOREIGN KEY (enterprise_id) REFERENCES enterprises(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (invoice_id) REFERENCES invoices(id)
);
```

### API Versioning

#### URL-based Versioning
```
/api/v1/auth/login
/api/v1/invoices
/api/v1/ocr/process
/api/v1/chat/message
```

#### Header-based Versioning
```http
Accept: application/vnd.thea.v1+json
```

#### Response Versioning
```json
{
  "version": "1.0.0",
  "data": { ... },
  "meta": {
    "api_version": "v1",
    "response_time": "234ms"
  }
}
```

---

## 📚 Troubleshooting

### Common Issues

#### Service Startup Failures

**Issue**: Database connection failed
```
Error: Can't connect to MySQL server on 'mysql:3306'
```

**Solutions**:
```bash
# Check if MySQL container is running
docker-compose ps mysql

# Check MySQL logs
docker-compose logs mysql

# Verify environment variables
cat nodejs_backend/.env | grep DATABASE_URL

# Test database connection
docker-compose exec mysql mysql -u thea_user -p thea_db
```

**Issue**: Redis connection timeout
```
Error: Redis connection to redis:6379 failed
```

**Solutions**:
```bash
# Check Redis container status
docker-compose ps redis

# Verify Redis is accepting connections
docker-compose exec redis redis-cli ping

# Check Redis configuration
docker-compose exec redis redis-cli config get maxmemory
```

#### OCR Processing Issues

**Issue**: Tesseract not found
```
Error: tesseract command not found
```

**Solutions**:
```bash
# Install Tesseract in container
apt-get update && apt-get install -y tesseract-ocr tesseract-ocr-eng

# Verify Tesseract installation
tesseract --version

# Check language data files
ls /usr/share/tesseract-ocr/5/tessdata/
```

**Issue**: Low OCR confidence scores
```
OCR confidence: 0.45 (below threshold 0.8)
```

**Solutions**:
```bash
# Adjust confidence threshold
export OCR_CONFIDENCE_THRESHOLD=0.6

# Preprocess images
# - Increase resolution
# - Apply noise reduction
# - Enhance contrast

# Use multiple languages
export TESSERACT_LANG=eng+fra+deu
```

#### Chatbot Issues

**Issue**: Ollama model not available
```
Error: model 'llama2' not found
```

**Solutions**:
```bash
# Pull the model
docker-compose exec ollama ollama pull llama2

# List available models
docker-compose exec ollama ollama list

# Check model status
curl http://localhost:11434/api/tags
```

**Issue**: Vector database connection failed
```
Error: Can't connect to ChromaDB on vector_store:8000
```

**Solutions**:
```bash
# Check ChromaDB container
docker-compose ps vector_store

# Verify ChromaDB API
curl http://localhost:8010/api/v1/heartbeat

# Check ChromaDB logs
docker-compose logs vector_store
```

### Performance Issues

#### Database Performance

**Slow queries**:
```sql
-- Add indexes for common queries
CREATE INDEX idx_invoices_enterprise_status ON invoices(enterprise_id, status);
CREATE INDEX idx_invoices_created_at ON invoices(created_at DESC);
CREATE INDEX idx_users_enterprise_email ON users(enterprise_id, email);

-- Analyze query performance
EXPLAIN SELECT * FROM invoices WHERE enterprise_id = ? AND status = ?;
```

**Connection pool exhaustion**:
```javascript
// Configure connection pool
const prisma = new PrismaClient({
  datasources: {
    db: {
      url: process.env.DATABASE_URL
    }
  },
  log: ['query', 'info', 'warn', 'error']
});
```

#### Memory Issues

**Node.js memory leaks**:
```bash
# Monitor memory usage
docker stats

# Check for memory leaks
npm install -g clinic
clinic heapprofiler -- node src/server.js

# Set memory limits
node --max-old-space-size=4096 src/server.js
```

**Redis memory pressure**:
```bash
# Configure Redis memory policy
docker-compose exec redis redis-cli config set maxmemory 256mb
docker-compose exec redis redis-cli config set maxmemory-policy allkeys-lru

# Monitor Redis memory
docker-compose exec redis redis-cli info memory
```

### Networking Issues

#### Container Networking

**Service discovery failures**:
```bash
# Check container networking
docker network ls
docker network inspect thea-network

# Verify service names
docker-compose exec nodejs-backend nslookup mysql
docker-compose exec nodejs-backend nslookup redis
```

**Port conflicts**:
```bash
# Check port usage
netstat -tulpn | grep :3000
netstat -tulpn | grep :8000

# Change ports in docker-compose.yml
ports:
  - "3001:3000"  # Change host port
```

#### Load Balancing

**Uneven load distribution**:
```yaml
# Configure load balancing
deploy:
  replicas: 3
  resources:
    limits:
      cpus: '1.0'
      memory: 1G
  restart_policy:
    condition: on-failure
```

### Monitoring Issues

#### Metrics Collection

**Prometheus not collecting metrics**:
```yaml
# Check Prometheus configuration
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'nodejs-backend'
    static_configs:
      - targets: ['nodejs-backend:3000']
    metrics_path: '/metrics'
```

**Grafana dashboards not loading**:
```bash
# Check Grafana logs
docker-compose logs grafana

# Verify data source configuration
# Access Grafana at http://localhost:3010
# Username: admin, Password: admin
```

### Security Issues

#### Authentication Failures

**JWT token validation errors**:
```javascript
// Debug JWT issues
const jwt = require('jsonwebtoken');

// Verify token
try {
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  console.error('Token invalid:', error.message);
} catch (error) {
  console.error('Token invalid:', error.message);
}
```

**Permission denied errors**:
```javascript
// Check user permissions
const userPermissions = await getUserPermissions(userId);
console.log('User permissions:', userPermissions);

// Verify role-based access
const hasPermission = checkPermission(userRole, requiredPermission);
console.log('Has permission:', hasPermission);
```

---

## 🤝 Contributing

### Development Setup

1. **Fork the repository**
   ```bash
   git clone https://github.com/your-username/thea-backend.git
   cd thea-backend
   ```

2. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Set up development environment**
   ```bash
   # Install dependencies
   npm install
   pip install -r fastapi_ocr/requirements.txt
   pip install -r rag_chatbot/requirements.txt

   # Start services
   docker-compose up -d mysql redis rabbitmq minio postgres
   ```

4. **Run tests**
   ```bash
   npm test
   cd fastapi_ocr && pytest
   cd ../rag_chatbot && pytest
   ```

### Code Standards

#### JavaScript/TypeScript
- Use ESLint with StandardJS configuration
- Follow async/await patterns
- Use meaningful variable names
- Add JSDoc comments for functions

#### Python
- Follow PEP 8 style guide
- Use type hints
- Write comprehensive docstrings
- Handle exceptions properly

#### Commit Messages
```
feat: add user authentication
fix: resolve invoice validation bug
docs: update API documentation
test: add unit tests for OCR service
refactor: optimize database queries
```

### Pull Request Process

1. **Update documentation** for any API changes
2. **Add tests** for new features
3. **Ensure CI passes** all checks
4. **Update CHANGELOG.md** with changes
5. **Request review** from maintainers

### Issue Reporting

**Bug Report Template**:
```markdown
## Bug Description
Brief description of the issue

## Steps to Reproduce
1. Go to '...'
2. Click on '...'
3. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., Windows 10]
- Browser: [e.g., Chrome 91]
- Version: [e.g., v1.0.0]

## Additional Context
Any other information
```

**Feature Request Template**:
```markdown
## Feature Description
Brief description of the proposed feature

## Use Case
Why is this feature needed?

## Proposed Solution
How should it be implemented?

## Alternatives Considered
Other solutions you've considered

## Additional Context
Any other information
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 📞 Support

### Documentation
- [API Documentation](./docs/api.md)
- [Deployment Guide](./docs/deployment.md)
- [Troubleshooting Guide](./docs/troubleshooting.md)

### Community
- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Ask questions and get help
- **Email**: support@thea-project.com

### Professional Services
- **Implementation**: Custom deployment and configuration
- **Training**: Team training and onboarding
- **Support**: 24/7 production support
- **Consulting**: Architecture review and optimization

---

**THEA** - Transforming Enterprise Accounting with AI-powered Intelligence

*Built with ❤️ for modern enterprises*

## Introduction

Thea is an enterprise-grade financial management platform born from a comprehensive requirements study focused on business management needs and intelligent invoice processing. The project addresses the critical demands of modern enterprises for efficient financial operations, document management, and intelligent automation.

The requirements study identified several key needs in the financial management space:

1. **Enterprise Management**: A centralized system for managing organizational structures, users, and permissions
2. **Smart Invoice Scanning**: Automated extraction of data from invoices to eliminate manual data entry
3. **Financial Workflow**: End-to-end tracking of financial documents from receipt to payment
4. **Security & Compliance**: Robust security measures and audit trails for financial operations
5. **Real-time Assistance**: Intelligent support for users navigating financial processes

Thea addresses these requirements through a microservice architecture with integrated DevSecOps practices, ensuring security, scalability, and maintainability throughout the application lifecycle.

## Project Overview

Thea is a comprehensive microservice-based backend system with integrated DevSecOps practices. The platform provides enterprise-grade accounting and invoice management capabilities with AI-powered OCR processing and real-time chatbot assistance.

### Key Features

- **Enterprise Management**: Multi-tenant system for managing organizations, users, and permissions
- **Invoice Processing**: Automated OCR scanning and data extraction for invoices
- **Financial Management**: Track clients, suppliers, projects, and stock
- **Secure Architecture**: End-to-end security with encryption and audit logging
- **DevSecOps Integration**: Continuous integration, delivery, and security monitoring

## System Architecture

Thea follows a microservice architecture with three primary services:

1. **Node.js Backend**: Core business logic and API endpoints
2. **FastAPI OCR Service**: AI-powered invoice scanning and data extraction
3. **Chatbot Microservice**: Real-time assistance via WebSocket communication

These services are supported by several infrastructure components:

- **MySQL Database**: Primary data store (via XAMPP for development)
- **Redis**: Caching and session management
- **MinIO**: Object storage for document management
- **RabbitMQ**: Message queuing for asynchronous processing

![Critical Workflow](./Thea%20Critical%20Workflow.png)

## Key Components

### Business Entities
- **Enterprise**: Organization entity with users, clients, invoices
- **User**: System users with role-based access (ADMIN, ACCOUNTANT, VERIFIER)
- **Invoice**: Core document with OCR extraction and verification workflow
- **Client/Supplier**: External business entities
- **Project/Stock**: Resource management

### Infrastructure Components
- **MinIO Storage**: Document storage and management
- **Redis Cache**: Performance optimization and session storage
- **RabbitMQ**: Asynchronous message processing
- **Audit Logging**: Security and compliance tracking

### AI/ML Components
- **OCR Processing**: Automated document scanning and data extraction
- **Layout Recognition**: Template matching for invoice formats
- **Chatbot**: Real-time assistance with Redis-backed caching

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Python 3.9+
- MySQL 8.0+ (XAMPP recommended for development)
- Docker and Docker Compose (for containerized deployment)
- MinIO Server
- Redis Server
- RabbitMQ Server

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/FediMechergui/Thea_Backend_Microservice_DevSecOps.git
   cd Thea_Backend_Microservice_DevSecOps
   ```

2. **Set up Node.js Backend**
   ```bash
   cd nodejs_backend
   npm install
   cp .env.example .env  # Configure your environment variables
   npx prisma migrate dev
   npm run dev
   ```

3. **Set up FastAPI OCR Service**
   ```bash
   cd fastapi_backend
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   uvicorn app.main:app --reload
   ```

4. **Set up Chatbot Microservice**
   ```bash
   cd chatbot_microservice
   npm install
   cp .env.example .env  # Configure your environment variables
   npm run dev
   ```

5. **Set up Infrastructure Services**
   - Follow the instructions in `VirtualBox_Setup_Guide.md` for the complete infrastructure setup
   - For local development, you can use Docker Compose (configuration provided in the deploying directory)

## Services

### Node.js Backend

The Node.js backend is the core service handling business logic, authentication, and data management.

#### Key Features
- RESTful API with Express.js
- Prisma ORM for MySQL database access
- JWT-based authentication with role-based access control
- MinIO integration for document storage
- RabbitMQ for asynchronous processing
- Redis for caching and session management
- Winston for structured logging

#### API Endpoints
- `/api/auth`: Authentication and user management
- `/api/users`: User operations
- `/api/enterprises`: Enterprise management
- `/api/clients`: Client management
- `/api/suppliers`: Supplier management
- `/api/projects`: Project management
- `/api/stocks`: Inventory management
- `/api/invoices`: Invoice processing and management

#### Configuration
The Node.js backend is configured via environment variables in the `.env` file:
- Database connection (MySQL)
- JWT secrets and expiration
- Redis connection
- RabbitMQ connection
- MinIO configuration
- FastAPI OCR service URL

### FastAPI OCR Service

The FastAPI OCR service provides AI-powered document scanning and data extraction capabilities.

#### Key Features
- REST API with FastAPI
- OCR processing for invoice scanning
- Layout detection and template matching
- Confidence scoring for verification workflow

#### API Endpoints
- `/process`: Process invoice scan and extract data
- `/health`: Service health check

#### Configuration
The FastAPI service is configured via environment variables:
- OCR confidence threshold
- Service port and host settings

### Chatbot Microservice

The Chatbot microservice provides real-time assistance via WebSocket communication.

#### Key Features
- WebSocket server for real-time communication
- Redis-based answer caching
- Session management
- Health check endpoint

#### Configuration
The Chatbot service is configured via environment variables:
- Redis connection
- WebSocket port
- Cache TTL settings

## Data Model

Thea uses a comprehensive data model implemented with Prisma ORM:

![Class Diagram](./THEA%20Class%20Diagram%20final%20full.png)

### Core Entities

#### Enterprise
```
- id: String
- name: String
- taxId: String
- country: String
- currency: String
- address: String
- phone: String
- city: String
- postalCode: String
- invitationCode: String
```

#### User
```
- id: String
- username: String
- email: String
- passwordHash: String
- role: UserRole (ADMIN, ACCOUNTANT, VERIFIER)
- encryptedPii: String
- phone: String
- address: String
- specialty: String
```

#### Invoice
```
- id: String
- invoiceDate: DateTime
- dueDate: DateTime
- totalAmount: Decimal
- currency: String
- status: InvoiceStatus (PENDING, PAID, OVERDUE)
- type: InvoiceType (SALE, PURCHASE)
- scanUrl: String
- extractedData: Json
- verificationStatus: VerificationStatus
- digitalSignature: String
```

#### InvoiceLayout
```
- id: String
- layoutData: Json
- fieldCoordinates: Json
- templateHash: String
```

Additional entities include Client, Supplier, Project, CompanyStock, AuditLog, and Metric.

## Database & ORM

Thea uses Prisma ORM as its primary database access layer, providing type-safe database queries, migrations, and schema management.

### Prisma ORM

Prisma offers several advantages for the Thea platform:

1. **Type Safety**: Automatically generated TypeScript types based on the database schema
2. **Migration Management**: Version-controlled database schema changes
3. **Query Building**: Intuitive API for building complex database queries
4. **Relationship Handling**: Simplified management of database relationships
5. **Transaction Support**: ACID-compliant database operations

### Database Relationships

The database schema implements complex relationships between entities:

1. **Enterprise-Centric Design**:
   - An Enterprise is the top-level entity that owns all other resources
   - One-to-many relationship with Users, Clients, Suppliers, Projects, Invoices, and other entities
   - Enforces multi-tenant data isolation

2. **User Management**:
   - Users belong to a single Enterprise
   - Role-based access control (ADMIN, ACCOUNTANT, VERIFIER)
   - Users can create sub-accounts and verify invoices

3. **Invoice Processing Workflow**:
   - Invoices are linked to Enterprises, Clients/Suppliers, and Projects
   - Each Invoice uses an InvoiceLayout for OCR processing
   - Verification workflow with status tracking
   - Digital signatures for non-repudiation

4. **Financial Relationships**:
   - Clients and Suppliers are linked to Invoices
   - Projects track related financial documents
   - CompanyStock manages inventory with valuation methods

5. **Audit and Metrics**:
   - AuditLog tracks all user actions with immutable records
   - Metrics aggregate financial data for reporting

### Database Technology

The system uses MySQL as the primary database, with XAMPP providing a convenient development environment. The production environment can be migrated to managed MySQL services or other compatible databases supported by Prisma.

## AI/ML Implementation

Thea incorporates several AI/ML models to power its intelligent features:

### OCR and Document Understanding

1. **Computer Vision Models**:
   - Document layout analysis for invoice structure recognition
   - Text detection and recognition with confidence scoring
   - Field extraction based on spatial coordinates

2. **Natural Language Processing**:
   - Named entity recognition for vendor, client, and product identification
   - Information extraction for invoice details (dates, amounts, line items)
   - Text classification for document type identification

3. **Machine Learning Pipeline**:
   - Template matching for known invoice layouts
   - Confidence scoring for verification workflow
   - Continuous learning from manual corrections

### Chatbot Intelligence

1. **Retrieval-Augmented Generation (RAG)**:
   - Context-aware responses based on enterprise data
   - Database-backed information retrieval
   - Natural language understanding for user queries

2. **Session Management**:
   - Conversation context tracking
   - User intent recognition
   - Redis-backed response caching

The AI models are implemented in the FastAPI backend using Python-based machine learning libraries, with the current implementation providing mock responses for testing and development purposes. The production system is designed to integrate with more sophisticated models as needed.

## DevSecOps Implementation

Thea implements a comprehensive DevSecOps workflow with security integrated throughout the entire development lifecycle:

### Complete DevSecOps Cycle

1. **Plan & Requirements**:
   - Security requirements defined at project inception
   - Threat modeling and risk assessment
   - Compliance requirements identification

2. **Development**:
   - Secure coding guidelines
   - Pre-commit hooks for security checks
   - Peer code reviews with security focus

3. **Build & Integration**:
   - Jenkins-driven CI/CD pipeline
   - SonarQube for static application security testing (SAST)
   - Snyk for software composition analysis (SCA)
   - Dependency vulnerability scanning

4. **Testing**:
   - Automated security testing
   - Unit and integration tests with security scenarios
   - API security testing

5. **Deployment**:
   - Trivy for container scanning
   - Infrastructure as Code security validation
   - Secure configuration management
   - Blue-green deployment for zero downtime

6. **Operations**:
   - Infrastructure scanning with Nessus
   - Application scanning with OWASP ZAP
   - Runtime application self-protection
   - Continuous monitoring and alerting

7. **Monitoring & Feedback**:
   - Prometheus for metrics collection
   - Grafana for visualization
   - Alertmanager for notifications
   - Security incident response process
   - Feedback loop to development

This end-to-end DevSecOps approach ensures security is built into every phase of the application lifecycle, not just added as an afterthought.

## Infrastructure Setup

The infrastructure is designed for high availability and security:

### VM Specifications
- CI/CD Server: Ubuntu 22.04, 4 CPU, 8GB RAM
- Monitoring Server: Ubuntu 22.04, 2 CPU, 4GB RAM
- Security Server: Kali Linux, 4 CPU, 8GB RAM
- Load Balancer: Ubuntu 22.04, 2 CPU, 2GB RAM
- App Servers (x2): Ubuntu 22.04, 8 CPU, 16GB RAM
- Backup Server: Ubuntu 22.04, 4 CPU, 4GB RAM, 500GB storage

### Network Configuration
- Application Network: 192.168.1.0/24
- Management Network: 10.0.2.0/24

Detailed setup instructions are available in the `VirtualBox_Setup_Guide.md` file.

## Security Features

Thea implements multiple layers of security:

### Authentication & Authorization
- JWT-based authentication
- Role-based access control (RBAC)
- Password hashing with bcrypt
- PII encryption

### Data Security
- TLS for all communications
- Encrypted sensitive data
- Audit logging for all operations
- Digital signatures for invoices

### Infrastructure Security
- Network segmentation
- Vulnerability scanning
- Container security
- Compliance monitoring

## Monitoring & Observability

Thea provides comprehensive monitoring and observability:

### Metrics
- API performance (response time, error rate)
- Data store performance (connection pool, query latency)
- Security metrics (CVEs, scan frequency)

### Alerting
- Critical alerts via PagerDuty and SMS
- High-priority alerts via email and Slack
- Medium-priority alerts via Slack

### Logging
- Structured logging with Winston
- Centralized log collection
- Audit trail for compliance

## Development Workflow

### Branching Strategy
- `main`: Production-ready code
- `develop`: Integration branch
- Feature branches: For new features
- Hotfix branches: For urgent fixes

### Code Review Process
- Pull request required for all changes
- Automated tests must pass
- Security scan must pass
- Code review by at least one team member

## Testing

Thea implements comprehensive testing:

### Unit Testing
- Jest for Node.js backend
- Pytest for FastAPI service

### Integration Testing
- API endpoint testing with Supertest
- Service integration testing

### Security Testing
- SAST with SonarQube
- DAST with OWASP ZAP
- Penetration testing

## API Documentation

API documentation is available via:
- Swagger UI for FastAPI service
- Postman collection for Node.js backend
- API reference documentation

## Deployment

Thea supports multiple deployment options:

### Docker Deployment
- Docker Compose for local development
- Kubernetes for production

### VM Deployment
- Ansible playbooks for provisioning
- Blue-green deployment for zero downtime

## Contributing

Please read the CONTRIBUTING.md file for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
