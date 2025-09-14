#!/bin/bash

# Ollama Model Setup Script
echo "Setting up Ollama with required models..."

# Wait for Ollama service to be ready
echo "Waiting for Ollama service to start..."
while ! curl -f http://ollama:11434/api/version >/dev/null 2>&1; do
    sleep 5
    echo "Waiting for Ollama..."
done

echo "Ollama is ready. Pulling models..."

# Pull the main model (llama2)
echo "Pulling llama2 model..."
ollama pull llama2

# Pull alternative smaller model for faster inference
echo "Pulling llama2:7b-chat model..."
ollama pull llama2:7b-chat

# You can add more models here as needed
echo "All models have been pulled successfully!"

# Keep the container running
echo "Setup complete. Ollama is ready to serve models."