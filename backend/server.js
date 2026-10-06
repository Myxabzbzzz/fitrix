const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'qwen3:8b';
// Reasoning ("thinking") models like qwen3 take ~20s per reply with it on
// vs ~2-3s off. Set OLLAMA_THINK=true to re-enable.
const OLLAMA_THINK = process.env.OLLAMA_THINK === 'true';
// Ollama unloads idle models after 5 min; reloading adds several seconds
// to the next reply. Keep it in memory longer.
const OLLAMA_KEEP_ALIVE = process.env.OLLAMA_KEEP_ALIVE || '30m';

const SYSTEM_PROMPT = `You are Felix, a personal AI fitness coach in the FITRIX app. You help users:
- Set and achieve fitness goals
- Create personalized workout plans
- Track progress and stay motivated
- Make healthy lifestyle choices

Be friendly, encouraging, and concise. Ask follow-up questions to understand the user's:
- Fitness goals (muscle building, weight loss, endurance, etc.)
- Current activity level and preferences
- Experience level
- Available time and equipment

Keep responses short and actionable. Use a conversational tone.
Write plain text only: no markdown (no **bold**, # headings or tables).
For lists use simple lines like "1. Bench press - 3x10".`;

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

    const history = startTurn(conversationId, message);

    // Call Ollama API
    const ollamaResponse = await axios.post(
      `${OLLAMA_URL}/api/chat`,
      ollamaRequest(history, false)
    );

    const assistantMessage = ollamaResponse.data.message.content;
    finishTurn(conversationId, assistantMessage);

    res.json({ reply: assistantMessage });

  } catch (error) {
    abortTurn(req.body.conversationId);
    const { status, body } = describeOllamaError(error);
    console.error('Error calling Ollama:', body.message);
    res.status(status).json(body);
  }
});

// Streaming chat endpoint: responds with NDJSON lines
//   {"delta":"text"}  … as tokens arrive
//   {"done":true}     when the reply is complete
//   {"error":"…"}     if Ollama fails mid-stream
// Errors before the first token are returned as a normal JSON error status.
app.post('/chat/stream', async (req, res) => {
  const { message, conversationId } = req.body;

  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }
  if (!conversationId) {
    return res.status(400).json({ error: 'conversationId is required' });
  }

  console.log(`\n[${conversationId}] User: ${message}`);
  const history = startTurn(conversationId, message);

  // Stop generating if the app goes away mid-reply.
  const controller = new AbortController();
  res.on('close', () => {
    if (!res.writableEnded) controller.abort();
  });

  const send = (obj) => {
    if (!res.headersSent) {
      res.writeHead(200, {
        'Content-Type': 'application/x-ndjson; charset=utf-8',
        'Cache-Control': 'no-cache',
        'X-Accel-Buffering': 'no',
      });
    }
    res.write(JSON.stringify(obj) + '\n');
  };

  let reply = '';
  try {
    const ollamaResponse = await axios.post(
      `${OLLAMA_URL}/api/chat`,
      ollamaRequest(history, true),
      { responseType: 'stream', signal: controller.signal }
    );

    let buffer = '';
    for await (const chunk of ollamaResponse.data) {
      buffer += chunk.toString('utf8');
      let newline;
      while ((newline = buffer.indexOf('\n')) >= 0) {
        const line = buffer.slice(0, newline).trim();
        buffer = buffer.slice(newline + 1);
        if (!line) continue;

        const data = JSON.parse(line);
        if (data.error) throw new Error(data.error);

        const delta = data.message?.content || '';
        if (delta) {
          reply += delta;
          send({ delta });
        }
      }
    }

    finishTurn(conversationId, reply);
    send({ done: true });
    res.end();
  } catch (error) {
    abortTurn(conversationId);
    if (controller.signal.aborted) {
      console.log(`[${conversationId}] Client disconnected, generation stopped`);
      return;
    }
    const { status, body } = describeOllamaError(error);
    console.error('Error calling Ollama:', body.message);
    if (!res.headersSent) {
      res.status(status).json(body);
    } else {
      send({ error: body.message });
      res.end();
    }
  }
});

function ollamaRequest(messages, stream) {
  return {
    model: OLLAMA_MODEL,
    messages,
    stream,
    think: OLLAMA_THINK,
    keep_alive: OLLAMA_KEEP_ALIVE,
    options: {
      temperature: 0.7,
      top_p: 0.9,
    },
  };
}

// Adds the user message to the conversation and returns its history.
function startTurn(conversationId, message) {
  if (!conversations.has(conversationId)) {
    conversations.set(conversationId, [
      { role: 'system', content: SYSTEM_PROMPT },
    ]);
  }
  const history = conversations.get(conversationId);
  history.push({ role: 'user', content: message });
  return history;
}

function finishTurn(conversationId, reply) {
  const history = conversations.get(conversationId);
  history.push({ role: 'assistant', content: reply });

  // Keep only last 20 messages to avoid context overflow
  if (history.length > 21) { // 20 messages + system prompt
    history.splice(1, history.length - 21);
  }

  console.log(`[${conversationId}] Felix: ${reply}`);
}

// Drops the unanswered user message so a retry doesn't duplicate it.
function abortTurn(conversationId) {
  const history = conversations.get(conversationId);
  if (history && history[history.length - 1]?.role === 'user') {
    history.pop();
  }
}

function describeOllamaError(error) {
  if (error.code === 'ECONNREFUSED') {
    return {
      status: 503,
      body: {
        error: 'Ollama is not running',
        message: 'Please start Ollama with: ollama serve',
      },
    };
  }
  if (error.response?.status === 404) {
    return {
      status: 502,
      body: {
        error: 'Model not found',
        message: `Ollama has no model "${OLLAMA_MODEL}". Run: ollama pull ${OLLAMA_MODEL} (or set OLLAMA_MODEL)`,
      },
    };
  }
  return {
    status: 500,
    body: { error: 'Failed to process message', message: error.message },
  };
}

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
  console.log(`🧠 Model: ${OLLAMA_MODEL} (thinking ${OLLAMA_THINK ? 'on' : 'off'})`);
  console.log(`\n✅ Endpoints:`);
  console.log(`   GET  /health       - Health check`);
  console.log(`   POST /chat         - Send message to Felix`);
  console.log(`   POST /chat/stream  - Same, streamed as NDJSON`);
  console.log(`   POST /chat/reset   - Reset conversation`);
  console.log(`   GET  /models       - List Ollama models`);
  console.log(`\n💡 Make sure Ollama is running: ollama serve\n`);
  warmUpModel();
});

// Loads the model into memory at startup so the first reply isn't slow.
async function warmUpModel() {
  try {
    await axios.post(`${OLLAMA_URL}/api/chat`, {
      model: OLLAMA_MODEL,
      messages: [],
      keep_alive: OLLAMA_KEEP_ALIVE,
    });
    console.log(`🔥 Model ${OLLAMA_MODEL} loaded`);
  } catch (error) {
    console.warn(`⚠️  Could not preload ${OLLAMA_MODEL}: ${describeOllamaError(error).body.message}`);
  }
}
