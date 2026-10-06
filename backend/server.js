const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const axios = require('axios');
const {
  MAX_MESSAGE_LENGTH,
  MAX_CONVERSATION_ID_LENGTH,
  MAX_HISTORY_TURNS,
  sanitizeTopic,
  sanitizeProfile,
  sanitizeHistory,
  buildSystemPrompt,
} = require('./prompt');
const { createPlainTextFilter, toPlainText } = require('./plainText');

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

// Middleware
app.use(cors());
// History can carry 20 turns of non-ASCII text, so allow more than
// body-parser's 100kb default.
app.use(bodyParser.json({ limit: '1mb' }));

// Conversation turns per conversationId, for clients that don't send
// `history`. Requests that do send `history` neither read nor write this.
const conversations = new Map();

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'FITRIX Backend is running' });
});

// Chat endpoint
app.post('/chat', async (req, res) => {
  const turn = prepareTurn(req.body);
  if (turn.error) {
    return res.status(400).json({ error: turn.error, message: turn.error });
  }

  try {
    const ollamaResponse = await axios.post(
      `${OLLAMA_URL}/api/chat`,
      ollamaRequest(turn.messages, false)
    );

    const assistantMessage = toPlainText(
      ollamaResponse.data?.message?.content || ''
    );
    turn.finish(assistantMessage);

    res.json({ reply: assistantMessage });
  } catch (error) {
    turn.abort();
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
  const turn = prepareTurn(req.body);
  if (turn.error) {
    return res.status(400).json({ error: turn.error, message: turn.error });
  }
  const { conversationId } = turn;

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
  const plain = createPlainTextFilter();
  try {
    const ollamaResponse = await axios.post(
      `${OLLAMA_URL}/api/chat`,
      ollamaRequest(turn.messages, true),
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

        let data;
        try {
          data = JSON.parse(line);
        } catch {
          continue; // skip a malformed line rather than failing the reply
        }
        if (data.error) throw new Error(data.error);

        const delta = plain.push(data.message?.content || '');
        if (delta) {
          reply += delta;
          send({ delta });
        }
      }
    }
    const tail = plain.flush();
    if (tail) {
      reply += tail;
      send({ delta: tail });
    }

    turn.finish(reply);
    send({ done: true });
    res.end();
  } catch (error) {
    turn.abort();
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

/**
 * Validates a chat request body and returns what one turn needs:
 *   { conversationId, messages, finish(reply), abort() }  or  { error }.
 *
 * Body: { message, conversationId, topic?, profile?, history? }.
 * The system prompt is built per request from `topic` and `profile`.
 * With `history` (an array, even an empty one) the app is the source of
 * truth: the context is exactly what it sent and server memory is untouched.
 * Without it, the per-conversationId memory below is used as before.
 */
function prepareTurn(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return { error: 'Request body must be a JSON object' };
  }
  const { message, conversationId } = body;
  if (typeof message !== 'string' || !message.trim()) {
    return { error: 'Message is required' };
  }
  if (message.length > MAX_MESSAGE_LENGTH) {
    return {
      error: `Message is too long (max ${MAX_MESSAGE_LENGTH} characters)`,
    };
  }
  if (typeof conversationId !== 'string' || !conversationId.trim()) {
    return { error: 'conversationId is required' };
  }
  if (conversationId.length > MAX_CONVERSATION_ID_LENGTH) {
    return { error: 'conversationId is too long' };
  }

  const topic = sanitizeTopic(body.topic);
  const profile = sanitizeProfile(body.profile);
  const history = sanitizeHistory(body.history);
  const system = { role: 'system', content: buildSystemPrompt(topic, profile) };
  const user = { role: 'user', content: message.trim() };
  const tag = `[${conversationId} ${topic}` +
    (history ? ` history:${history.length}` : '') + ']';

  console.log(`\n${tag} User: ${user.content}`);

  if (history) {
    return {
      conversationId,
      messages: [system, ...history, user],
      finish: (reply) => console.log(`${tag} Felix: ${reply}`),
      abort: () => {},
    };
  }

  const turns = startTurn(conversationId, user.content);
  return {
    conversationId,
    messages: [system, ...turns],
    finish: (reply) => finishTurn(conversationId, reply, tag),
    abort: () => abortTurn(conversationId),
  };
}

// Adds the user message to the in-memory conversation and returns its turns.
function startTurn(conversationId, message) {
  if (!conversations.has(conversationId)) {
    conversations.set(conversationId, []);
  }
  const turns = conversations.get(conversationId);
  turns.push({ role: 'user', content: message });
  return turns;
}

function finishTurn(conversationId, reply, tag) {
  const turns = conversations.get(conversationId);
  if (!turns) return;
  turns.push({ role: 'assistant', content: reply });

  // Keep only the last turns to avoid context overflow
  if (turns.length > MAX_HISTORY_TURNS) {
    turns.splice(0, turns.length - MAX_HISTORY_TURNS);
  }

  console.log(`${tag} Felix: ${reply}`);
}

// Drops the unanswered user message so a retry doesn't duplicate it.
function abortTurn(conversationId) {
  const turns = conversations.get(conversationId);
  if (turns && turns[turns.length - 1]?.role === 'user') {
    turns.pop();
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
  const conversationId = req.body?.conversationId;

  if (typeof conversationId === 'string' && conversations.has(conversationId)) {
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

// Malformed JSON, oversized bodies, etc.: answer with JSON instead of HTML.
app.use((err, req, res, next) => {
  if (res.headersSent) return next(err);
  const status = err.status || err.statusCode || 500;
  const message = status < 500 ? err.message : 'Internal server error';
  if (status >= 500) console.error('Unhandled error:', err);
  res.status(status).json({ error: message, message });
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
