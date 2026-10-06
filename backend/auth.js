// Verifies Supabase access tokens (JWTs) sent as `Authorization: Bearer …`.
//
// Supabase Auth signs user access tokens either with an asymmetric key
// (ES256 / RS256; current default, also on the local CLI stack) whose public
// half is published at `<SUPABASE_URL>/auth/v1/.well-known/jwks.json`, or,
// on older projects, with the shared "legacy JWT secret" (HS256). Both are
// supported: JWKS when SUPABASE_URL is set, HS256 only when
// SUPABASE_JWT_SECRET is set. Built on node:crypto, no dependencies.

const crypto = require('node:crypto');

const ASYMMETRIC_ALGS = {
  ES256: { hash: 'sha256', kty: 'EC', dsaEncoding: 'ieee-p1363' },
  RS256: { hash: 'sha256', kty: 'RSA' },
};

class AuthError extends Error {
  /**
   * @param {string} code  'missing_token' | 'invalid_token' | 'expired_token'
   *                       | 'auth_unavailable'
   */
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * Reads auth settings from the environment.
 *
 *   SUPABASE_URL          project URL; enables JWKS verification and sets
 *                         the expected issuer `<SUPABASE_URL>/auth/v1`
 *   SUPABASE_JWT_SECRET   optional legacy HS256 secret
 *   SUPABASE_JWT_ISSUER   optional issuer override (if the URL the backend
 *                         uses differs from the one Auth puts in `iss`)
 *   AUTH_MODE             'off' disables auth (local hacking only);
 *                         'required' insists on it. Default: required when
 *                         Supabase is configured, otherwise off.
 */
function authConfigFromEnv(env) {
  const supabaseUrl = (env.SUPABASE_URL || '').trim().replace(/\/+$/, '');
  const jwtSecret = env.SUPABASE_JWT_SECRET || '';
  const configured = Boolean(supabaseUrl || jwtSecret);
  const mode = (env.AUTH_MODE || '').trim().toLowerCase();

  if (mode && mode !== 'off' && mode !== 'required') {
    throw new Error(`AUTH_MODE must be "off" or "required", got "${env.AUTH_MODE}"`);
  }
  if (mode === 'required' && !configured) {
    throw new Error(
      'AUTH_MODE=required needs SUPABASE_URL (and/or SUPABASE_JWT_SECRET)'
    );
  }

  return {
    enabled: mode === 'off' ? false : configured,
    supabaseUrl,
    jwtSecret,
    issuer:
      (env.SUPABASE_JWT_ISSUER || '').trim() ||
      (supabaseUrl ? `${supabaseUrl}/auth/v1` : null),
  };
}

/**
 * Fetches and caches the project's JWKS. Keys are reused for [ttlMs]; an
 * unknown `kid` (key rotation) triggers a refetch, at most once per
 * [cooldownMs]. If a refetch fails, the previous keys keep working.
 */
function createJwksCache({
  url,
  fetchJwks = defaultFetchJwks,
  ttlMs = 10 * 60 * 1000,
  cooldownMs = 30 * 1000,
  now = Date.now,
}) {
  let keys = null; // Map kid -> { jwk, key }
  let fetchedAt = 0;
  let lastAttempt = -Infinity;
  let inflight = null;

  async function refresh() {
    if (!inflight) {
      lastAttempt = now();
      inflight = (async () => {
        try {
          const body = await fetchJwks(url);
          const next = new Map();
          for (const jwk of Array.isArray(body?.keys) ? body.keys : []) {
            if (jwk.kty !== 'EC' && jwk.kty !== 'RSA') continue;
            if (jwk.use && jwk.use !== 'sig') continue;
            try {
              const key = crypto.createPublicKey({ key: jwk, format: 'jwk' });
              next.set(jwk.kid ?? '', { jwk, key });
            } catch {
              // skip keys node can't import
            }
          }
          keys = next;
          fetchedAt = now();
        } catch (error) {
          if (!keys) {
            throw new AuthError(
              'auth_unavailable',
              `Could not load signing keys from ${url}: ${error.message}`
            );
          }
          console.warn(`JWKS refresh failed, using cached keys: ${error.message}`);
        } finally {
          inflight = null;
        }
      })();
    }
    return inflight;
  }

  return {
    /** Public keys that may have signed a token with this header. */
    async candidates(kid) {
      const stale = now() - fetchedAt > ttlMs && now() - lastAttempt > cooldownMs;
      if (!keys || stale) await refresh();
      if (kid !== undefined && !keys.has(kid) && now() - lastAttempt > cooldownMs) {
        await refresh();
      }
      if (kid !== undefined) {
        const entry = keys.get(kid);
        return entry ? [entry] : [];
      }
      return [...keys.values()];
    },
  };
}

async function defaultFetchJwks(url) {
  const response = await fetch(url, { signal: AbortSignal.timeout(5000) });
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  return response.json();
}

function base64UrlJson(part) {
  return JSON.parse(Buffer.from(part, 'base64url').toString('utf8'));
}

/**
 * Creates a verifier for Supabase access tokens.
 * `verify(token)` resolves to the claims or rejects with an AuthError.
 */
function createTokenVerifier({
  supabaseUrl,
  jwtSecret,
  issuer,
  audience = 'authenticated',
  clockToleranceSec = 30,
  jwks,
  fetchJwks,
  now = Date.now,
}) {
  const jwksCache =
    jwks ||
    (supabaseUrl
      ? createJwksCache({
          url: `${supabaseUrl}/auth/v1/.well-known/jwks.json`,
          fetchJwks,
          now,
        })
      : null);
  const secret = jwtSecret ? Buffer.from(jwtSecret, 'utf8') : null;

  const invalid = (why) =>
    new AuthError('invalid_token', `Invalid access token (${why}). Please sign in again.`);

  async function verifySignature(header, signingInput, signature) {
    const { alg } = header;
    if (alg === 'HS256') {
      if (!secret) throw invalid('HS256 tokens are not accepted');
      const expected = crypto
        .createHmac('sha256', secret)
        .update(signingInput)
        .digest();
      return (
        expected.length === signature.length &&
        crypto.timingSafeEqual(expected, signature)
      );
    }

    const spec = ASYMMETRIC_ALGS[alg];
    if (!spec) throw invalid(`unsupported algorithm ${JSON.stringify(alg)}`);
    if (!jwksCache) throw invalid(`${alg} tokens need SUPABASE_URL`);

    const kid = typeof header.kid === 'string' ? header.kid : undefined;
    const candidates = (await jwksCache.candidates(kid)).filter(
      ({ jwk }) => jwk.kty === spec.kty && (!jwk.alg || jwk.alg === alg)
    );
    if (candidates.length === 0) throw invalid('unknown signing key');

    return candidates.some(({ key }) => {
      try {
        return crypto.verify(
          spec.hash,
          Buffer.from(signingInput),
          spec.dsaEncoding ? { key, dsaEncoding: spec.dsaEncoding } : key,
          signature
        );
      } catch {
        return false; // e.g. a signature of the wrong length
      }
    });
  }

  return async function verify(token) {
    if (typeof token !== 'string' || !token) {
      throw new AuthError('missing_token', 'Sign in to chat with Felix.');
    }
    const parts = token.split('.');
    if (parts.length !== 3) throw invalid('malformed');

    let header;
    let claims;
    try {
      header = base64UrlJson(parts[0]);
      claims = base64UrlJson(parts[1]);
    } catch {
      throw invalid('malformed');
    }
    if (!header || typeof header !== 'object' || !claims || typeof claims !== 'object') {
      throw invalid('malformed');
    }

    const signature = Buffer.from(parts[2], 'base64url');
    const ok = await verifySignature(header, `${parts[0]}.${parts[1]}`, signature);
    if (!ok) throw invalid('bad signature');

    const nowSec = Math.floor(now() / 1000);
    if (typeof claims.exp !== 'number') throw invalid('no expiry');
    if (claims.exp + clockToleranceSec <= nowSec) {
      throw new AuthError(
        'expired_token',
        'Your session has expired. Please sign in again.'
      );
    }
    if (typeof claims.nbf === 'number' && claims.nbf - clockToleranceSec > nowSec) {
      throw invalid('not yet valid');
    }
    const audiences = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
    if (!audiences.includes(audience)) throw invalid('wrong audience');
    if (issuer && claims.iss !== issuer) throw invalid('wrong issuer');
    if (typeof claims.sub !== 'string' || !claims.sub) throw invalid('no subject');

    return claims;
  };
}

function bearerToken(req) {
  const header = req.get('authorization') || '';
  const match = /^Bearer\s+(\S+)\s*$/i.exec(header);
  return match ? match[1] : null;
}

/**
 * Express middleware: sets `req.user = { id, claims }` for a valid token,
 * otherwise answers 401 (503 if the signing keys can't be fetched).
 * With auth disabled every request passes as user "local".
 */
function requireUser(config, verifierOptions = {}) {
  if (!config.enabled) {
    return (req, res, next) => {
      req.user = { id: 'local', claims: null };
      next();
    };
  }

  const verify = createTokenVerifier({ ...config, ...verifierOptions });

  return async (req, res, next) => {
    try {
      const claims = await verify(bearerToken(req));
      req.user = { id: claims.sub, claims };
      next();
    } catch (error) {
      if (!(error instanceof AuthError)) return next(error);
      if (error.code === 'auth_unavailable') {
        console.error(error.message);
        return res.status(503).json({
          error: 'Auth unavailable',
          message: 'Felix can’t check your sign-in right now. Please try again shortly.',
        });
      }
      res.set(
        'WWW-Authenticate',
        error.code === 'missing_token'
          ? 'Bearer'
          : `Bearer error="invalid_token", error_description="${error.code}"`
      );
      res.status(401).json({
        error: 'Unauthorized',
        code: error.code,
        message: error.message,
      });
    }
  };
}

/**
 * Sliding-window rate limit per user: at most [limit] requests per
 * [windowMs]. Over the limit → 429 with Retry-After. limit <= 0 disables it.
 */
function rateLimitPerUser({ limit, windowMs = 60 * 1000, now = Date.now }) {
  if (!(limit > 0)) return (req, res, next) => next();

  const hits = new Map(); // user id -> timestamps (ms), oldest first

  const sweep = setInterval(() => {
    const cutoff = now() - windowMs;
    for (const [user, times] of hits) {
      if (!times.length || times[times.length - 1] <= cutoff) hits.delete(user);
    }
  }, windowMs);
  sweep.unref();

  return (req, res, next) => {
    const user = req.user?.id || `ip:${req.ip}`;
    const t = now();
    const times = (hits.get(user) || []).filter((h) => h > t - windowMs);

    if (times.length >= limit) {
      hits.set(user, times);
      const retryAfter = Math.max(1, Math.ceil((times[0] + windowMs - t) / 1000));
      res.set('Retry-After', String(retryAfter));
      return res.status(429).json({
        error: 'Too many requests',
        message: `You're sending messages too fast. Please wait ${retryAfter}s and try again.`,
        retryAfter,
      });
    }

    times.push(t);
    hits.set(user, times);
    next();
  };
}

module.exports = {
  AuthError,
  authConfigFromEnv,
  createJwksCache,
  createTokenVerifier,
  requireUser,
  rateLimitPerUser,
};
