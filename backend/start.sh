#!/bin/bash

# FITRIX Backend Startup Script

echo "🏋️  Starting FITRIX Backend..."
echo ""

# Check if Ollama is running
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "⚠️  WARNING: Ollama doesn't seem to be running!"
    echo ""
    echo "Please start Ollama in another terminal:"
    echo "  ollama serve"
    echo ""
    echo "And make sure you have a model pulled:"
    echo "  ollama pull llama3.2"
    echo ""
    read -p "Press Enter to continue anyway or Ctrl+C to exit..."
else
    echo "✅ Ollama is running"
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

echo ""
echo "🚀 Starting backend server..."
echo ""

npm start
