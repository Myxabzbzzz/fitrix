const path = require('node:path');
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
  sanitizeLanguage,
  buildSystemPrompt,
} = require('./prompt');
const { createPlainTextFilter, toPlainText } = require('./plainText');
const { authConfigFromEnv, requireUser, rateLimitPerUser } = require('./auth');

// `npm start` reads backend/.env if present (real env vars win). Tests
// require this file without it.
if (require.main === module) {
  try {
    process.loadEnvFile(path.join(__dirname, '.env'));
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
}

const PORT = process.env.PORT || 3000;
const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || 'qwen3:8b';
// Reasoning ("thinking") models like qwen3 take ~20s per reply with it on
// vs ~2-3s off. Set OLLAMA_THINK=true to re-enable.
const OLLAMA_THINK = process.env.OLLAMA_THINK === 'true';
// Ollama unloads idle models after 5 min; reloading adds several seconds
// to the next reply. Keep it in memory longer.
const OLLAMA_KEEP_ALIVE = process.env.OLLAMA_KEEP_ALIVE || '30m';
// Chat requests per signed-in user per minute; 0 disables the limit.
const RATE_LIMIT_PER_MINUTE = parseWholeNumber(
  'RATE_LIMIT_PER_MINUTE',
  process.env.RATE_LIMIT_PER_MINUTE,
  20
);
// Max silence from Ollama (no response / no new tokens) before giving up.
const OLLAMA_TIMEOUT_MS = parseWholeNumber(
  'OLLAMA_TIMEOUT_MS',
  process.env.OLLAMA_TIMEOUT_MS,
  120000
);
// Chat messages and replies are users' personal data (age, weight, health),
// so logs only carry their length unless this is turned on for debugging.
const LOG_CHAT_CONTENT = process.env.LOG_CHAT_CONTENT === 'true';

// Server-side conversation memory (clients that don't send `history`):
// forgotten after an hour without messages, and capped so it can't grow
// without bound; the least recently used conversation goes first.
const MEMORY_IDLE_MS = 60 * 60 * 1000;
const MEMORY_MAX_CONVERSATIONS = 1000;

function parseWholeNumber(name, value, fallback) {
  if (value === undefined || value === '') return fallback;
  const n = Number(value);
  if (!Number.isInteger(n) || n < 0) {
    throw new Error(`${name} must be a whole number >= 0, got "${value}"`);
  }
  return n;
}

/**
 * Builds the Express app.
 *   auth:            from authConfigFromEnv(); { enabled: false } = no auth
 *   verifierOptions: test hooks for the token verifier (fetchJwks, now)
 *   rateLimit:       chat requests per user per minute (0 = unlimited)
 *   memory:          server conversation memory limits
 *                    { idleMs, maxConversations, now } (now: test clock)
 */
function createApp({
  auth = { enabled: false },
  verifierOptions = {},
  rateLimit = RATE_LIMIT_PER_MINUTE,
  memory = {},
} = {}) {
  const app = express();

  // Middleware
  app.use(cors());
  // History can carry 20 turns of non-ASCII text, so allow more than
  // body-parser's 100kb default.
  app.use(bodyParser.json({ limit: '1mb' }));

  // Conversation turns per user and conversationId, for clients that don't
  // send `history`. Requests that do send `history` neither read nor write
  // this. Keyed by user so nobody can continue someone else's conversation.
  const conversations = createConversationMemory(memory);

  // Every /chat route needs a signed-in user (Supabase access token);
  // /health and /models stay open.
  const user = requireUser(auth, verifierOptions);
  const limit = rateLimitPerUser({ limit: rateLimit });

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({ status: 'ok', message: 'FITRIX Backend is running' });
  });

  // Chat endpoint
  app.post('/chat', user, limit, async (req, res) => {
    const turn = prepareTurn(req.body, req.user.id, conversations);
    if (turn.error) {
      return res.status(400).json({ error: turn.error, message: turn.error });
    }

    try {
      const ollamaResponse = await axios.post(
        `${OLLAMA_URL}/api/chat`,
        ollamaRequest(turn.messages, false),
        { timeout: OLLAMA_TIMEOUT_MS }
      );

      const assistantMessage = toPlainText(
        ollamaResponse.data?.message?.content || ''
      );
      turn.finish(assistantMessage);

      res.json({ reply: assistantMessage });
    } catch (error) {
      turn.abort();
      const { status, body } = describeOllamaError(error);
      console.error('Error calling Ollama:', error.message);
      res.status(status).json(body);
    }
  });

  // Streaming chat endpoint: responds with NDJSON lines
  //   {"delta":"text"}  … as tokens arrive
  //   {"done":true}     when the reply is complete
  //   {"error":"…"}     if Ollama fails mid-stream
  // Errors before the first token are returned as a normal JSON error status.
  app.post('/chat/stream', user, limit, async (req, res) => {
    const turn = prepareTurn(req.body, req.user.id, conversations);
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
        {
          responseType: 'stream',
          signal: controller.signal,
          timeout: OLLAMA_TIMEOUT_MS,
        }
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
      console.error('Error calling Ollama:', error.message);
      if (!res.headersSent) {
        res.status(status).json(body);
      } else {
        send({ error: body.message });
        res.end();
      }
    }
  });

  // Reset conversation endpoint (optional)
  app.post('/chat/reset', user, (req, res) => {
    const key = memoryKey(req.user.id, req.body?.conversationId);

    if (key && conversations.has(key)) {
      conversations.delete(key);
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

  return app;
}

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
 * Body: { message, conversationId, topic?, profile?, history?, language? }.
 * The system prompt is built per request from `topic` and `profile`.
 * With `history` (an array, even an empty one) the app is the source of
 * truth: the context is exactly what it sent and server memory is untouched.
 * Without it, the per-conversationId memory below is used as before.
 */
function prepareTurn(body, userId, conversations) {
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
  const language = sanitizeLanguage(body.language);
  const system = {
    role: 'system',
    content: buildSystemPrompt(topic, profile, language),
  };
  const user = { role: 'user', content: message.trim() };
  const tag = `[${userId.slice(0, 8)} ${conversationId} ${topic}` +
    (history ? ` history:${history.length}` : '') + ']';

  logChat(`\n${tag}`, 'User', user.content);

  if (history) {
    return {
      conversationId,
      messages: [system, ...history, user],
      finish: (reply) => logChat(tag, 'Felix', reply),
      abort: () => {},
    };
  }

  const key = memoryKey(userId, conversationId);
  const turns = startTurn(conversations, key, user.content);
  return {
    conversationId,
    messages: [system, ...turns],
    finish: (reply) => finishTurn(conversations, key, reply, tag),
    abort: () => abortTurn(conversations, key),
  };
}

// Server memory is per user: the same conversationId from two users is two
// separate conversations. User ids are UUIDs (or "local" with auth off).
function memoryKey(userId, conversationId) {
  if (typeof conversationId !== 'string' || !conversationId) return null;
  return `${userId}:${conversationId}`;
}

// Adds the user message to the in-memory conversation and returns its turns.
function startTurn(conversations, key, message) {
  const turns = conversations.touch(key);
  turns.push({ role: 'user', content: message });
  return turns;
}

/**
 * Conversation turns by key, least recently used first. Conversations idle
 * for longer than [idleMs] are dropped, and the oldest ones beyond
 * [maxConversations], so memory stays bounded however many users chat.
 */
function createConversationMemory({
  idleMs = MEMORY_IDLE_MS,
  maxConversations = MEMORY_MAX_CONVERSATIONS,
  now = Date.now,
} = {}) {
  const entries = new Map(); // key -> { turns, usedAt }

  function prune() {
    const cutoff = now() - idleMs;
    // Oldest first: stop at the first entry that is recent enough while
    // the map is within its cap; everything after it is newer.
    for (const [key, entry] of entries) {
      if (entry.usedAt > cutoff && entries.size <= maxConversations) break;
      entries.delete(key);
    }
  }

  return {
    /** The conversation's turns (created if missing), marked as just used. */
    touch(key) {
      prune(); // first, so an expired conversation starts over
      const entry = entries.get(key) || { turns: [] };
      entries.delete(key); // re-insert to move it to the newest end
      entry.usedAt = now();
      entries.set(key, entry);
      if (entries.size > maxConversations) prune();
      return entry.turns;
    },
    get(key) {
      prune();
      return entries.get(key)?.turns;
    },
    has(key) {
      prune();
      return entries.has(key);
    },
    delete(key) {
      return entries.delete(key);
    },
    get size() {
      return entries.size;
    },
  };
}

function finishTurn(conversations, key, reply, tag) {
  const turns = conversations.get(key);
  if (!turns) return;
  turns.push({ role: 'assistant', content: reply });

  // Keep only the last turns to avoid context overflow
  if (turns.length > MAX_HISTORY_TURNS) {
    turns.splice(0, turns.length - MAX_HISTORY_TURNS);
  }

  logChat(tag, 'Felix', reply);
}

// Message text is personal data: only its length is logged by default.
function logChat(tag, who, text) {
  const shown = LOG_CHAT_CONTENT ? text : `<${text.length} chars>`;
  console.log(`${tag} ${who}: ${shown}`);
}

// Drops the unanswered user message so a retry doesn't duplicate it.
function abortTurn(conversations, key) {
  const turns = conversations.get(key);
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
  if (error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT') {
    return {
      status: 504,
      body: {
        error: 'Felix took too long to reply',
        message: 'Felix took too long to reply. Please try again.',
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
    // The real error is logged; clients get no internal details.
    body: {
      error: 'Failed to process message',
      message: 'Felix could not reply. Please try again.',
    },
  };
}

function main() {
  const auth = authConfigFromEnv(process.env);
  const app = createApp({ auth });

  app.listen(PORT, () => {
    console.log(`\n🚀 FITRIX Backend Server running on http://localhost:${PORT}`);
    console.log(`📡 Ollama URL: ${OLLAMA_URL}`);
    console.log(`🧠 Model: ${OLLAMA_MODEL} (thinking ${OLLAMA_THINK ? 'on' : 'off'})`);
    if (auth.enabled) {
      console.log(
        `🔐 Auth: Supabase access token required (issuer ${auth.issuer || 'not checked'}` +
          `${auth.jwtSecret ? ', HS256 secret set' : ''})`
      );
    } else {
      console.warn(
        `⚠️  Auth: OFF — anyone who can reach this server can use the model.` +
          ` Set SUPABASE_URL to require sign-in.`
      );
    }
    console.log(`⏱️  Ollama timeout: ${OLLAMA_TIMEOUT_MS / 1000}s of silence`);
    if (LOG_CHAT_CONTENT) {
      console.warn('📝 LOG_CHAT_CONTENT=true: chat messages are written to the log');
    }
    console.log(`🚦 Rate limit: ${RATE_LIMIT_PER_MINUTE > 0 ? `${RATE_LIMIT_PER_MINUTE} chat requests/min per user` : 'off'}`);
    console.log(`\n✅ Endpoints:`);
    console.log(`   GET  /health       - Health check`);
    console.log(`   POST /chat         - Send message to Felix (auth)`);
    console.log(`   POST /chat/stream  - Same, streamed as NDJSON (auth)`);
    console.log(`   POST /chat/reset   - Reset conversation (auth)`);
    console.log(`   GET  /models       - List Ollama models`);
    console.log(`\n💡 Make sure Ollama is running: ollama serve\n`);
    warmUpModel();
  });
}

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
    // Known causes get the friendly hint; anything else the real error.
    const { status, body } = describeOllamaError(error);
    const reason = status === 500 ? error.message : body.message;
    console.warn(`⚠️  Could not preload ${OLLAMA_MODEL}: ${reason}`);
  }
}

if (require.main === module) {
  main();
}

module.exports = { createApp };
