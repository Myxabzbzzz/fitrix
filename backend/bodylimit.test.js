// Large bodies must not be read before the caller is authenticated.
const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { ISSUER, SUPABASE_URL, makeKey, claimsFor, sign } = require('./testTokens');

const ALICE = '11111111-1111-4111-8111-111111111111';
const ollama = http.createServer((req, res) => {
  req.resume();
  req.on('end', () => {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ message: { content: 'ok' } }));
  });
});
const key = makeKey('k');
let base;
let server;

test.before(async () => {
  await new Promise((r) => ollama.listen(0, '127.0.0.1', r));
  process.env.OLLAMA_URL = `http://127.0.0.1:${ollama.address().port}`;
  const { createApp } = require('./server');
  server = await new Promise((r) => {
    const s = createApp({
      auth: { enabled: true, supabaseUrl: SUPABASE_URL, issuer: ISSUER, jwtSecret: '' },
      verifierOptions: { fetchJwks: async () => ({ keys: [key.jwk] }) },
      rateLimit: 0,
    }).listen(0, '127.0.0.1', () => r(s));
  });
  base = `http://127.0.0.1:${server.address().port}`;
});
test.after(() => {
  server.close();
  ollama.closeAllConnections();
  ollama.close();
});

const jpeg = (bytes) => Buffer.concat([Buffer.from([0xff, 0xd8, 0xff]), Buffer.alloc(bytes)]).toString('base64');
const send = (path, body, token) =>
  fetch(base + path, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  });

test('2.9 MB body without a token is 401, not parsed', async () => {
  const body = { message: 'x', conversationId: 'c', pad: 'a'.repeat(2.9 * 1024 * 1024) };
  for (const path of ['/chat', '/chat/stream']) {
    const res = await send(path, body);
    assert.equal(res.status, 401, path);
  }
});

test('authed photo request (1.4 MB image, >1 MB body) works', async () => {
  const token = sign(key, claimsFor(ALICE));
  const res = await send('/chat', { message: 'look', conversationId: 'c', history: [], images: [jpeg(1.4 * 1024 * 1024)] }, token);
  assert.equal(res.status, 200);
  assert.equal((await res.json()).reply, 'ok');
});

test('/chat/reset keeps the 1 MB limit', async () => {
  const token = sign(key, claimsFor(ALICE));
  const res = await send('/chat/reset', { conversationId: 'a'.repeat(1.5 * 1024 * 1024) }, token);
  assert.equal(res.status, 413);
});
