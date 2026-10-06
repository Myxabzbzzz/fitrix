// HTTP tests for auth, per-user memory and rate limiting, against a stub
// Ollama and a stub JWKS (no network, no real Supabase).
const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { ISSUER, SUPABASE_URL, makeKey, claimsFor, sign } = require('./testTokens');

const ALICE = '11111111-1111-4111-8111-111111111111';
const BOB = '22222222-2222-4222-8222-222222222222';

// Stub Ollama: replies "echo:<last user message>" and records requests.
const ollamaRequests = [];
const ollama = http.createServer((req, res) => {
  let body = '';
  req.on('data', (c) => (body += c));
  req.on('end', () => {
    const data = JSON.parse(body || '{}');
    if (req.url !== '/api/chat' || !data.messages?.length) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      return res.end('{}');
    }
    ollamaRequests.push(data);
    const last = data.messages[data.messages.length - 1].content;
    if (data.stream) {
      res.writeHead(200, { 'Content-Type': 'application/x-ndjson' });
      res.write(JSON.stringify({ message: { content: 'echo:' } }) + '\n');
      res.write(JSON.stringify({ message: { content: last } }) + '\n');
      res.end(JSON.stringify({ done: true }) + '\n');
    } else {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ message: { content: `echo:${last}` } }));
    }
  });
});

let createApp;
const key = makeKey('test-key');
const servers = [];

test.before(async () => {
  await new Promise((r) => ollama.listen(0, '127.0.0.1', r));
  process.env.OLLAMA_URL = `http://127.0.0.1:${ollama.address().port}`;
  ({ createApp } = require('./server'));
});

test.after(() => {
  ollama.close();
  for (const s of servers) s.close();
});

/** Starts an app on a random port and returns its base URL. */
async function start(options) {
  const app = createApp(options);
  const server = await new Promise((resolve) => {
    const s = app.listen(0, '127.0.0.1', () => resolve(s));
  });
  servers.push(server);
  return `http://127.0.0.1:${server.address().port}`;
}

function authedApp(extra = {}) {
  return start({
    auth: { enabled: true, supabaseUrl: SUPABASE_URL, issuer: ISSUER, jwtSecret: '' },
    verifierOptions: { fetchJwks: async () => ({ keys: [key.jwk] }) },
    rateLimit: 0,
    ...extra,
  });
}

function post(base, path, body, token) {
  return fetch(`${base}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });
}

const tokenFor = (user, overrides) => sign(key, claimsFor(user, overrides));

test('/health stays open', async () => {
  const base = await authedApp();
  const res = await fetch(`${base}/health`);
  assert.equal(res.status, 200);
  assert.equal((await res.json()).status, 'ok');
});

test('chat endpoints answer 401 without a valid token', async () => {
  const base = await authedApp();
  const body = { message: 'hi', conversationId: 'c1' };
  const expired = tokenFor(ALICE, { exp: Math.floor(Date.now() / 1000) - 120 });

  for (const path of ['/chat', '/chat/stream', '/chat/reset']) {
    const res = await post(base, path, body);
    assert.equal(res.status, 401, path);
    assert.match(res.headers.get('www-authenticate'), /^Bearer/);
    const json = await res.json();
    assert.equal(json.error, 'Unauthorized');
    assert.equal(json.code, 'missing_token');
    assert.ok(json.message);
  }

  let res = await post(base, '/chat/stream', body, 'not-a-jwt');
  assert.equal(res.status, 401);
  assert.equal((await res.json()).code, 'invalid_token');

  res = await post(base, '/chat/stream', body, expired);
  assert.equal(res.status, 401);
  const json = await res.json();
  assert.equal(json.code, 'expired_token');
  assert.match(json.message, /sign in again/);

  // A malformed header is the same as no token.
  res = await fetch(`${base}/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: tokenFor(ALICE) },
    body: JSON.stringify(body),
  });
  assert.equal(res.status, 401);
});

test('a valid token gets a streamed reply', async () => {
  const base = await authedApp();
  const res = await post(base, '/chat/stream', { message: 'hello', conversationId: 'c1' }, tokenFor(ALICE));

  assert.equal(res.status, 200);
  const lines = (await res.text()).trim().split('\n').map((l) => JSON.parse(l));
  assert.deepEqual(lines, [{ delta: 'echo:' }, { delta: 'hello' }, { done: true }]);

  const plain = await post(base, '/chat', { message: 'hey', conversationId: 'c2' }, tokenFor(ALICE));
  assert.equal(plain.status, 200);
  assert.deepEqual(await plain.json(), { reply: 'echo:hey' });
});

test('server memory is per user: same conversationId, separate conversations', async () => {
  const base = await authedApp();
  const conv = 'shared-conversation-id';

  await post(base, '/chat', { message: 'alice secret', conversationId: conv }, tokenFor(ALICE));
  ollamaRequests.length = 0;

  await post(base, '/chat', { message: 'bob here', conversationId: conv }, tokenFor(BOB));
  const bobContext = ollamaRequests[0].messages.filter((m) => m.role !== 'system');
  assert.deepEqual(bobContext, [{ role: 'user', content: 'bob here' }]);

  ollamaRequests.length = 0;
  await post(base, '/chat', { message: 'alice again', conversationId: conv }, tokenFor(ALICE));
  const aliceContext = ollamaRequests[0].messages.filter((m) => m.role !== 'system');
  assert.deepEqual(
    aliceContext.map((m) => m.content),
    ['alice secret', 'echo:alice secret', 'alice again']
  );

  // Bob can't reset Alice's conversation either.
  const bobReset = await post(base, '/chat/reset', { conversationId: conv }, tokenFor(BOB));
  assert.equal(bobReset.status, 200); // resets his own
  const bobAgain = await post(base, '/chat/reset', { conversationId: conv }, tokenFor(BOB));
  assert.equal(bobAgain.status, 404);
  const aliceReset = await post(base, '/chat/reset', { conversationId: conv }, tokenFor(ALICE));
  assert.equal(aliceReset.status, 200);
});

test('rate limit: N requests per minute per user, then 429', async () => {
  const base = await authedApp({ rateLimit: 2 });
  const body = { message: 'hi', conversationId: 'rl' };

  assert.equal((await post(base, '/chat', body, tokenFor(ALICE))).status, 200);
  assert.equal((await post(base, '/chat/stream', body, tokenFor(ALICE))).status, 200);

  const limited = await post(base, '/chat', body, tokenFor(ALICE));
  assert.equal(limited.status, 429);
  assert.ok(Number(limited.headers.get('retry-after')) >= 1);
  const json = await limited.json();
  assert.equal(json.error, 'Too many requests');
  assert.match(json.message, /too fast/);

  // Other users have their own budget; unauthenticated requests don't use it.
  assert.equal((await post(base, '/chat', body, tokenFor(BOB))).status, 200);
  assert.equal((await post(base, '/chat', body)).status, 401);
});

test('JWKS outage before the first fetch answers 503, not 401', async () => {
  const base = await authedApp({
    verifierOptions: {
      fetchJwks: async () => {
        throw new Error('ECONNREFUSED');
      },
    },
  });
  const res = await post(base, '/chat', { message: 'hi', conversationId: 'c' }, tokenFor(ALICE));
  assert.equal(res.status, 503);
});

test('with auth off, requests without a token work (local hacking)', async () => {
  const base = await start({ auth: { enabled: false }, rateLimit: 0 });
  const res = await post(base, '/chat', { message: 'yo', conversationId: 'c' });
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { reply: 'echo:yo' });
});

test('validation errors still come back as 400 for signed-in users', async () => {
  const base = await authedApp();
  const res = await post(base, '/chat', { conversationId: 'c' }, tokenFor(ALICE));
  assert.equal(res.status, 400);
  assert.equal((await res.json()).error, 'Message is required');
});
