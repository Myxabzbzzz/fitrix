const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Store conversation history per conversationId
const conversations = new Map();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'FITRIX Backend is running' });
});

// Chat endpoint
app.post('/chat', async (req, res) => {
  try {
    const { message, conversationId } = req.body;

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    if (!conversationId) {
      return res.status(400).json({ error: 'conversationId is required' });
    }

    console.log(`\n[${conversationId}] User: ${message}`);

    // Get or initialize conversation history
    if (!conversations.has(conversationId)) {
      conversations.set(conversationId, [
        {
          role: 'system',
          content: `You are Felix, a personal AI fitness coach in the FITRIX app. You help users:
- Set and achieve fitness goals
- Create personalized workout plans
- Track progress and stay motivated
- Make healthy lifestyle choices

Be friendly, encouraging, and concise. Ask follow-up questions to understand the user's:
- Fitness goals (muscle building, weight loss, endurance, etc.)
- Current activity level and preferences
- Experience level
- Available time and equipment

Keep responses short and actionable. Use a conversational tone.`
        }
      ]);
    }

    const history = conversations.get(conversationId);

    // Add user message to history
    history.push({
      role: 'user',
      content: message
    });

    // Call Ollama API
    const ollamaResponse = await axios.post(`${OLLAMA_URL}/api/chat`, {
      model: 'llama3.2', // Change this to your preferred model
      messages: history,
      stream: false,
      options: {
        temperature: 0.7,
        top_p: 0.9,
      }
    });

    const assistantMessage = ollamaResponse.data.message.content;

    // Add assistant response to history
    history.push({
      role: 'assistant',
      content: assistantMessage
    });

    // Keep only last 20 messages to avoid context overflow
    if (history.length > 21) { // 20 messages + system prompt
      history.splice(1, history.length - 21);
    }

    console.log(`[${conversationId}] Felix: ${assistantMessage}`);

    res.json({ reply: assistantMessage });

  } catch (error) {
    console.error('Error calling Ollama:', error.message);

    if (error.code === 'ECONNREFUSED') {
      return res.status(503).json({
        error: 'Ollama is not running',
        message: 'Please start Ollama with: ollama serve'
      });
    }

    res.status(500).json({
      error: 'Failed to process message',
      message: error.message
    });
  }
});

// Reset conversation endpoint (optional)
app.post('/chat/reset', (req, res) => {
  const { conversationId } = req.body;

  if (conversationId && conversations.has(conversationId)) {
    conversations.delete(conversationId);
    res.json({ message: 'Conversation reset successfully' });
  } else {
    res.status(404).json({ error: 'Conversation not found' });
  }
});

// List available models endpoint (optional)
app.get('/models', async (req, res) => {
  try {
    const response = await axios.get(`${OLLAMA_URL}/api/tags`);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch models' });
  }
});

app.listen(PORT, () => {
  console.log(`\n🚀 FITRIX Backend Server running on http://localhost:${PORT}`);
  console.log(`📡 Ollama URL: ${OLLAMA_URL}`);
  console.log(`\n✅ Endpoints:`);
  console.log(`   GET  /health       - Health check`);
  console.log(`   POST /chat         - Send message to Felix`);
  console.log(`   POST /chat/reset   - Reset conversation`);
  console.log(`   GET  /models       - List Ollama models`);
  console.log(`\n💡 Make sure Ollama is running: ollama serve\n`);
});
