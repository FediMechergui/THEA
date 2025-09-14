#!/bin/bash

# THEA Backend Deployment Script with Ollama Setup

echo "🚀 Starting THEA Backend deployment with Ollama..."

# Start all services except the RAG chatbot
echo "📦 Starting infrastructure services..."
docker-compose up -d mysql redis rabbitmq minio postgres vector_store ollama nodejs-backend fastapi-ocr fastapi-ocr-worker prometheus grafana

# Wait for Ollama to be ready and pull models
echo "🤖 Setting up Ollama models..."
echo "Waiting for Ollama service to be ready..."

# Wait for Ollama to be available
until curl -f http://localhost:11434/api/version >/dev/null 2>&1; do
    echo "⏳ Waiting for Ollama service..."
    sleep 10
done

echo "✅ Ollama is ready! Pulling required models..."

# Pull the main models
echo "📥 Pulling llama2 model (this may take a while)..."
docker exec -it $(docker-compose ps -q ollama) ollama pull llama2

echo "📥 Pulling llama2:7b-chat model..."
docker exec -it $(docker-compose ps -q ollama) ollama pull llama2:7b-chat

echo "✅ Models pulled successfully!"

# Now start the RAG chatbot services
echo "🤖 Starting RAG Chatbot services..."
docker-compose up -d rag-chatbot rag-chatbot-worker

echo "🎉 Deployment complete!"
echo ""
echo "Services are available at:"
echo "- Node.js Backend: http://localhost:3000"
echo "- OCR Service: http://localhost:8000"
echo "- RAG Chatbot: http://localhost:8001"
echo "- Grafana: http://localhost:3010"
echo "- Prometheus: http://localhost:9090"
echo "- Ollama: http://localhost:11434"
echo ""
echo "You can check the status with: docker-compose ps"
echo "To view logs: docker-compose logs -f [service-name]"