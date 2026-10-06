# FITRIX Backend Server

Node.js/Express backend that connects the FITRIX Flutter app to Ollama LLM.

## Features

- ✅ REST API for chat functionality
- ✅ Conversation history management
- ✅ Ollama integration with context preservation
- ✅ CORS enabled for Flutter app
- ✅ Error handling and health checks

## Prerequisites

1. **Node.js** (v16 or higher)
   ```bash
   node --version
   ```

2. **Ollama** installed and running
   ```bash
   # Install Ollama: https://ollama.ai
   ollama --version

   # Pull a model (default: qwen3:8b)
   ollama pull qwen3:8b

   # Start Ollama server
   ollama serve
   ```

## Installation

1. Install dependencies:
   ```bash
   cd backend
   npm install
   ```

2. (Optional) Configure environment:
   ```bash
   # Create .env file if you want to customize
   PORT=3000
   OLLAMA_URL=http://localhost:11434
   OLLAMA_MODEL=qwen3:8b      # any model from `ollama list`
   OLLAMA_THINK=false         # true re-enables reasoning (~10x slower replies)
   OLLAMA_KEEP_ALIVE=30m      # keep the model loaded between messages
   ```

## Running the Server

### Development Mode (with auto-reload)
```bash
npm run dev
```

### Production Mode
```bash
npm start
```

Server will start on: `http://localhost:3000`

## API Endpoints

### 1. Health Check
```bash
GET /health

Response:
{
  "status": "ok",
  "message": "FITRIX Backend is running"
}
```

### 2. Send Chat Message
```bash
POST /chat

Request:
{
  "message": "I want to build muscle",
  "conversationId": "uuid-here"
}

Response:
{
  "reply": "Great choice! Building muscle requires..."
}
```

### 3. Reset Conversation
```bash
POST /chat/reset

Request:
{
  "conversationId": "uuid-here"
}

Response:
{
  "message": "Conversation reset successfully"
}
```

### 4. List Available Models
```bash
GET /models

Response:
{
  "models": [...]
}
```

## Testing

### Test with curl:
```bash
# Health check
curl http://localhost:3000/health

# Send message
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello Felix!",
    "conversationId": "test-123"
  }'
```

### Test with Postman:
1. Import the endpoints above
2. Set method to POST
3. Add JSON body
4. Send request

## Configuration

### Change Ollama Model

```bash
OLLAMA_MODEL=llama3.2 npm start
```

The model is preloaded at startup so the first reply isn't delayed.

### Streaming

`POST /chat/stream` takes the same body as `/chat` and answers with
newline-delimited JSON as tokens are generated:

```
{"delta":"Bench"}
{"delta":" press"}
{"done":true}
```

If the model fails mid-reply the last line is `{"error":"..."}`. The Flutter
app uses this endpoint so replies appear word by word.

### Change Port

Start with custom port:
```bash
PORT=8080 npm start
```

Or edit the PORT constant in `server.js`.

### Customize Felix's Personality

Edit the system prompt in `server.js` (lines 41-57) to change how Felix responds.

## Connecting to Flutter App

1. Start this backend server
2. Update Flutter app configuration:
   ```dart
   // lib/core/constants/app_constants.dart
   static const String apiBaseUrl = 'http://localhost:3000';
   ```

3. Run Flutter app:
   ```bash
   flutter run -d macos
   ```

## Troubleshooting

### Error: "Ollama is not running"
```bash
# Start Ollama in a separate terminal
ollama serve
```

### Error: "ECONNREFUSED"
- Make sure Ollama is running on port 11434
- Check `OLLAMA_URL` configuration

### Error: "Model not found"
```bash
# Pull the configured model first (or set OLLAMA_MODEL to one you have)
ollama pull qwen3:8b
```

### Port already in use
```bash
# Change port
PORT=3001 npm start
```

## Development

### File Structure
```
backend/
├── server.js          # Main server file
├── package.json       # Dependencies
└── README.md         # This file
```

### Adding Features

To add new endpoints, edit `server.js`:
```javascript
app.post('/your-endpoint', async (req, res) => {
  // Your logic here
});
```

## Production Deployment

For production, consider:
- Using environment variables for configuration
- Adding authentication/API keys
- Implementing rate limiting
- Adding request logging
- Using PM2 or similar for process management

```bash
# Install PM2
npm install -g pm2

# Start with PM2
pm2 start server.js --name fitrix-backend

# Monitor
pm2 logs fitrix-backend
```

## License

Part of the FITRIX fitness application.
