// Sign in with Apple token revocation, required by App Store guideline
// 5.1.1(v) when an account created with Apple is deleted: the app hands over
// a fresh authorization code, we exchange it for a refresh token and revoke
// that, which also removes the app from the user's "Sign in with Apple" list.
//
// https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens

const APPLE_AUTH = "https://appleid.apple.com";

export interface AppleConfig {
  /// Apple Developer team id (10 characters).
  teamId: string;
  /// Id of the "Sign in with Apple" key (.p8) in Certificates, IDs & Profiles.
  keyId: string;
  /// The .p8 file's contents (PKCS#8 PEM).
  privateKey: string;
  /// The app's bundle id: the audience of its Apple tokens.
  clientId: string;
}

/// Reads the config from function secrets; null when Apple isn't set up.
export function appleConfigFromEnv(
  env: (name: string) => string | undefined,
): AppleConfig | null {
  const teamId = env("APPLE_TEAM_ID");
  const keyId = env("APPLE_KEY_ID");
  // Secrets set from a shell often carry "\n" instead of real newlines.
  const privateKey = env("APPLE_PRIVATE_KEY")?.replaceAll("\\n", "\n");
  const clientId = env("APPLE_CLIENT_ID") ?? "com.elibayev.fitrix";
  if (!teamId || !keyId || !privateKey) return null;
  return { teamId, keyId, privateKey, clientId };
}

function base64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : data;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(
    /=+$/,
    "",
  );
}

function pemToDer(pem: string): Uint8Array<ArrayBuffer> {
  const binary = atob(pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, ""));
  const der = new Uint8Array(new ArrayBuffer(binary.length));
  for (let i = 0; i < binary.length; i++) der[i] = binary.charCodeAt(i);
  return der;
}

/// The client secret Apple's token endpoints expect: an ES256 JWT signed
/// with the .p8 key, valid for five minutes.
export async function appleClientSecret(
  config: AppleConfig,
  now: number = Math.floor(Date.now() / 1000),
): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(config.privateKey),
    { name: "ECDSA", namedCurve: "P-256" },
    false,
    ["sign"],
  );
  const header = { alg: "ES256", kid: config.keyId };
  const claims = {
    iss: config.teamId,
    iat: now,
    exp: now + 300,
    aud: APPLE_AUTH,
    sub: config.clientId,
  };
  const input = `${base64url(JSON.stringify(header))}.${
    base64url(JSON.stringify(claims))
  }`;
  // WebCrypto's ECDSA signature is r||s, the JWS format.
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      { name: "ECDSA", hash: "SHA-256" },
      key,
      new TextEncoder().encode(input),
    ),
  );
  return `${input}.${base64url(signature)}`;
}

async function postForm(
  fetchFn: typeof fetch,
  path: string,
  form: Record<string, string>,
): Promise<Response> {
  return await fetchFn(`${APPLE_AUTH}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(form),
  });
}

/// Exchanges [authorizationCode] for a refresh token and revokes it.
/// Throws when Apple refuses either step.
export async function revokeAppleTokens(
  config: AppleConfig,
  authorizationCode: string,
  fetchFn: typeof fetch = fetch,
): Promise<void> {
  const clientSecret = await appleClientSecret(config);
  const tokenResponse = await postForm(fetchFn, "/auth/token", {
    client_id: config.clientId,
    client_secret: clientSecret,
    code: authorizationCode,
    grant_type: "authorization_code",
  });
  if (!tokenResponse.ok) {
    throw new Error(
      `Apple token exchange failed: ${tokenResponse.status} ${await tokenResponse
        .text()}`,
    );
  }
  const tokens = await tokenResponse.json();
  const token = tokens.refresh_token ?? tokens.access_token;
  if (!token) throw new Error("Apple returned no token to revoke");

  const revokeResponse = await postForm(fetchFn, "/auth/revoke", {
    client_id: config.clientId,
    client_secret: clientSecret,
    token,
    token_type_hint: tokens.refresh_token ? "refresh_token" : "access_token",
  });
  if (!revokeResponse.ok) {
    throw new Error(
      `Apple token revocation failed: ${revokeResponse.status} ${await revokeResponse
        .text()}`,
    );
  }
}
