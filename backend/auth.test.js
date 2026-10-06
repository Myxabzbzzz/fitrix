const test = require('node:test');
const assert = require('node:assert/strict');
const {
  AuthError,
  authConfigFromEnv,
  createJwksCache,
  createTokenVerifier,
} = require('./auth');
const {
  ISSUER,
  SUPABASE_URL,
  HS_SECRET,
  makeKey,
  claimsFor,
  sign,
  signHs256,
  unsigned,
} = require('./testTokens');

const USER = '4d1349ec-673c-47fb-93e1-630a0bd82279';

function verifierWith(keys, options = {}) {
  const fetches = [];
  const verify = createTokenVerifier({
    supabaseUrl: SUPABASE_URL,
    issuer: ISSUER,
    fetchJwks: async (url) => {
      fetches.push(url);
      return { keys: keys.map((k) => k.jwk) };
    },
    ...options,
  });
  return { verify, fetches };
}

async function rejectsWith(promise, code) {
  await assert.rejects(promise, (error) => {
    assert.ok(error instanceof AuthError, `expected AuthError, got ${error}`);
    assert.equal(error.code, code);
    return true;
  });
}

test('accepts an ES256 token signed by a key in the JWKS', async () => {
  const key = makeKey('k1', 'ES256');
  const { verify, fetches } = verifierWith([key]);

  const claims = await verify(sign(key, claimsFor(USER)));

  assert.equal(claims.sub, USER);
  assert.deepEqual(fetches, [`${SUPABASE_URL}/auth/v1/.well-known/jwks.json`]);
});

test('accepts RS256 tokens too', async () => {
  const key = makeKey('rsa-1', 'RS256');
  const { verify } = verifierWith([key]);
  assert.equal((await verify(sign(key, claimsFor(USER)))).sub, USER);
});

test('caches the JWKS between requests', async () => {
  const key = makeKey();
  const { verify, fetches } = verifierWith([key]);

  await verify(sign(key, claimsFor(USER)));
  await verify(sign(key, claimsFor(USER)));
  await verify(sign(key, claimsFor('other-user')));

  assert.equal(fetches.length, 1);
});

test('refetches the JWKS for an unknown kid (key rotation), with a cooldown', async () => {
  const oldKey = makeKey('old');
  const newKey = makeKey('new');
  let published = [oldKey];
  let clock = 1_000_000;
  let fetches = 0;
  const jwks = createJwksCache({
    url: 'http://supabase.test/jwks',
    fetchJwks: async () => {
      fetches++;
      return { keys: published.map((k) => k.jwk) };
    },
    cooldownMs: 30_000,
    now: () => clock,
  });
  const verify = createTokenVerifier({ issuer: ISSUER, jwks });

  await verify(sign(oldKey, claimsFor(USER)));
  assert.equal(fetches, 1);

  // Within the cooldown an unknown kid doesn't hammer the auth server.
  clock += 1000;
  await rejectsWith(verify(sign(newKey, claimsFor(USER))), 'invalid_token');
  assert.equal(fetches, 1);

  published = [oldKey, newKey];
  clock += 60_000;
  assert.equal((await verify(sign(newKey, claimsFor(USER)))).sub, USER);
  assert.equal(fetches, 2);
});

test('keeps using cached keys if a JWKS refresh fails', async () => {
  const key = makeKey();
  let clock = 0;
  let fail = false;
  const jwks = createJwksCache({
    url: 'x',
    fetchJwks: async () => {
      if (fail) throw new Error('down');
      return { keys: [key.jwk] };
    },
    ttlMs: 1000,
    cooldownMs: 0,
    now: () => clock,
  });
  const verify = createTokenVerifier({ issuer: ISSUER, jwks });
  await verify(sign(key, claimsFor(USER)));

  fail = true;
  clock += 5000; // past the TTL
  assert.equal((await verify(sign(key, claimsFor(USER)))).sub, USER);
});

test('reports auth_unavailable when the JWKS was never loaded', async () => {
  const key = makeKey();
  const verify = createTokenVerifier({
    supabaseUrl: SUPABASE_URL,
    issuer: ISSUER,
    fetchJwks: async () => {
      throw new Error('ECONNREFUSED');
    },
  });
  await rejectsWith(verify(sign(key, claimsFor(USER))), 'auth_unavailable');
});

test('rejects missing, malformed, tampered and foreign tokens', async () => {
  const key = makeKey('k1');
  const stranger = makeKey('k1'); // same kid, different key
  const { verify } = verifierWith([key]);

  await rejectsWith(verify(null), 'missing_token');
  await rejectsWith(verify(''), 'missing_token');
  await rejectsWith(verify('garbage'), 'invalid_token');
  await rejectsWith(verify('a.b.c'), 'invalid_token');
  await rejectsWith(verify(sign(stranger, claimsFor(USER))), 'invalid_token');

  const [h, , s] = sign(key, claimsFor(USER)).split('.');
  const forged = Buffer.from(JSON.stringify(claimsFor('someone-else'))).toString('base64url');
  await rejectsWith(verify(`${h}.${forged}.${s}`), 'invalid_token');

  await rejectsWith(verify(sign(key, claimsFor(USER)).slice(0, -4)), 'invalid_token');
});

test('rejects alg "none" and HS256 when no secret is configured', async () => {
  const key = makeKey();
  const { verify } = verifierWith([key]);

  await rejectsWith(verify(unsigned(claimsFor(USER))), 'invalid_token');
  await rejectsWith(verify(signHs256(claimsFor(USER))), 'invalid_token');
});

test('rejects expired tokens with a distinct code', async () => {
  const key = makeKey();
  const { verify } = verifierWith([key]);
  const past = Math.floor(Date.now() / 1000) - 3600;

  await rejectsWith(
    verify(sign(key, claimsFor(USER, { iat: past - 3600, exp: past }))),
    'expired_token'
  );
  await rejectsWith(
    verify(sign(key, claimsFor(USER, { exp: undefined }))),
    'invalid_token'
  );
});

test('checks audience, issuer, subject and nbf', async () => {
  const key = makeKey();
  const { verify } = verifierWith([key]);
  const future = Math.floor(Date.now() / 1000) + 600;

  // The anon / service_role API keys are JWTs too, but not user tokens.
  await rejectsWith(verify(sign(key, claimsFor(USER, { aud: undefined, role: 'anon' }))), 'invalid_token');
  await rejectsWith(verify(sign(key, claimsFor(USER, { aud: 'other' }))), 'invalid_token');
  await rejectsWith(
    verify(sign(key, claimsFor(USER, { iss: 'https://evil.example/auth/v1' }))),
    'invalid_token'
  );
  await rejectsWith(verify(sign(key, claimsFor(''))), 'invalid_token');
  await rejectsWith(verify(sign(key, claimsFor(USER, { nbf: future }))), 'invalid_token');

  const multi = await verify(sign(key, claimsFor(USER, { aud: ['x', 'authenticated'] })));
  assert.equal(multi.sub, USER);
});

test('accepts legacy HS256 tokens when SUPABASE_JWT_SECRET is set', async () => {
  const verify = createTokenVerifier({ jwtSecret: HS_SECRET, issuer: ISSUER });

  assert.equal((await verify(signHs256(claimsFor(USER)))).sub, USER);
  await rejectsWith(verify(signHs256(claimsFor(USER), 'wrong-secret')), 'invalid_token');
  // No SUPABASE_URL, so asymmetric tokens can't be checked.
  await rejectsWith(verify(sign(makeKey(), claimsFor(USER))), 'invalid_token');
});

test('auth config: required when Supabase is configured, AUTH_MODE=off disables', () => {
  assert.deepEqual(authConfigFromEnv({}), {
    enabled: false,
    supabaseUrl: '',
    jwtSecret: '',
    issuer: null,
  });

  const local = authConfigFromEnv({ SUPABASE_URL: 'http://127.0.0.1:55321/' });
  assert.equal(local.enabled, true);
  assert.equal(local.supabaseUrl, 'http://127.0.0.1:55321');
  assert.equal(local.issuer, 'http://127.0.0.1:55321/auth/v1');

  assert.equal(authConfigFromEnv({ SUPABASE_JWT_SECRET: 's' }).enabled, true);
  assert.equal(
    authConfigFromEnv({ SUPABASE_URL: 'http://x', AUTH_MODE: 'off' }).enabled,
    false
  );
  assert.equal(
    authConfigFromEnv({ SUPABASE_URL: 'http://x', SUPABASE_JWT_ISSUER: 'http://y/auth/v1' })
      .issuer,
    'http://y/auth/v1'
  );
  assert.throws(() => authConfigFromEnv({ AUTH_MODE: 'required' }), /SUPABASE_URL/);
  assert.throws(() => authConfigFromEnv({ AUTH_MODE: 'maybe' }), /AUTH_MODE/);
});
