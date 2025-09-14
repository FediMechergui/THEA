# THEA Backend Deployment Script with Ollama Setup (PowerShell)

Write-Host "🚀 Starting THEA Backend deployment with Ollama..." -ForegroundColor Green

# Start all services except the RAG chatbot
Write-Host "📦 Starting infrastructure services..." -ForegroundColor Yellow
docker-compose up -d mysql redis rabbitmq minio postgres vector_store ollama nodejs-backend fastapi-ocr fastapi-ocr-worker prometheus grafana

# Wait for Ollama to be ready and pull models
Write-Host "🤖 Setting up Ollama models..." -ForegroundColor Yellow
Write-Host "Waiting for Ollama service to be ready..." -ForegroundColor Blue

# Wait for Ollama to be available
do {
    Write-Host "⏳ Waiting for Ollama service..." -ForegroundColor Blue
    Start-Sleep -Seconds 10
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:11434/api/version" -UseBasicParsing -ErrorAction Stop
        $ollamaReady = $true
    }
    catch {
        $ollamaReady = $false
    }
} while (-not $ollamaReady)

Write-Host "✅ Ollama is ready! Pulling required models..." -ForegroundColor Green

# Get Ollama container ID
$ollamaContainer = docker-compose ps -q ollama

# Pull the main models
Write-Host "📥 Pulling llama2 model (this may take a while)..." -ForegroundColor Yellow
docker exec $ollamaContainer ollama pull llama2

Write-Host "📥 Pulling llama2:7b-chat model..." -ForegroundColor Yellow
docker exec $ollamaContainer ollama pull llama2:7b-chat

Write-Host "✅ Models pulled successfully!" -ForegroundColor Green

# Now start the RAG chatbot services
Write-Host "🤖 Starting RAG Chatbot services..." -ForegroundColor Yellow
docker-compose up -d rag-chatbot rag-chatbot-worker

Write-Host "🎉 Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Services are available at:" -ForegroundColor Cyan
Write-Host "- Node.js Backend: http://localhost:3000" -ForegroundColor White
Write-Host "- OCR Service: http://localhost:8000" -ForegroundColor White
Write-Host "- RAG Chatbot: http://localhost:8001" -ForegroundColor White
Write-Host "- Grafana: http://localhost:3010" -ForegroundColor White
Write-Host "- Prometheus: http://localhost:9090" -ForegroundColor White
Write-Host "- Ollama: http://localhost:11434" -ForegroundColor White
Write-Host ""
Write-Host "You can check the status with: docker-compose ps" -ForegroundColor Yellow
Write-Host "To view logs: docker-compose logs -f [service-name]" -ForegroundColor Yellow