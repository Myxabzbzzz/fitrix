// Test helpers: sign Supabase-style access tokens locally (no network).
const crypto = require('node:crypto');

const ISSUER = 'http://supabase.test/auth/v1';
const SUPABASE_URL = 'http://supabase.test';
const HS_SECRET = 'test-legacy-jwt-secret-with-at-least-32-chars';

function b64url(value) {
  return Buffer.from(typeof value === 'string' ? value : JSON.stringify(value)).toString(
    'base64url'
  );
}

/** An ES256 key pair plus its public JWK, like Supabase's signing keys. */
function makeKey(kid = 'key-1', alg = 'ES256') {
  const pair =
    alg === 'RS256'
      ? crypto.generateKeyPairSync('rsa', { modulusLength: 2048 })
      : crypto.generateKeyPairSync('ec', { namedCurve: 'P-256' });
  const jwk = { ...pair.publicKey.export({ format: 'jwk' }), kid, alg, use: 'sig' };
  return { kid, alg, privateKey: pair.privateKey, jwk };
}

function claimsFor(sub, overrides = {}) {
  const now = Math.floor(Date.now() / 1000);
  return {
    iss: ISSUER,
    aud: 'authenticated',
    sub,
    role: 'authenticated',
    iat: now,
    exp: now + 3600,
    ...overrides,
  };
}

/** Signs [claims] with an asymmetric [key] from makeKey(). */
function sign(key, claims, headerOverrides = {}) {
  const header = { alg: key.alg, kid: key.kid, typ: 'JWT', ...headerOverrides };
  const input = `${b64url(header)}.${b64url(claims)}`;
  const signature =
    key.alg === 'RS256'
      ? crypto.sign('sha256', Buffer.from(input), key.privateKey)
      : crypto.sign('sha256', Buffer.from(input), {
          key: key.privateKey,
          dsaEncoding: 'ieee-p1363',
        });
  return `${input}.${signature.toString('base64url')}`;
}

/** Signs [claims] with the legacy HS256 secret. */
function signHs256(claims, secret = HS_SECRET) {
  const input = `${b64url({ alg: 'HS256', typ: 'JWT' })}.${b64url(claims)}`;
  const signature = crypto.createHmac('sha256', secret).update(input).digest();
  return `${input}.${signature.toString('base64url')}`;
}

function unsigned(claims) {
  return `${b64url({ alg: 'none', typ: 'JWT' })}.${b64url(claims)}.`;
}

module.exports = {
  ISSUER,
  SUPABASE_URL,
  HS_SECRET,
  makeKey,
  claimsFor,
  sign,
  signHs256,
  unsigned,
};
