// deno test supabase/functions/delete-account/
import {
  assert,
  assertEquals,
} from "jsr:@std/assert@1";
import { createHandler, type DeletedUser, type Deps } from "./index.ts";
import {
  type AppleConfig,
  appleClientSecret,
  appleConfigFromEnv,
  revokeAppleTokens,
} from "./apple.ts";

const ALICE: DeletedUser = { id: "alice", providers: ["email"] };
const APPLE_USER: DeletedUser = { id: "apple-user", providers: ["apple"] };

function fakeDeps(users: Record<string, DeletedUser>, overrides: Partial<Deps> = {}) {
  const deleted: string[] = [];
  const revoked: string[] = [];
  const deps: Deps = {
    getUser: async (token) => users[token] ?? null,
    deleteUser: async (id) => {
      deleted.push(id);
    },
    revokeApple: async (code) => {
      revoked.push(code);
    },
    ...overrides,
  };
  return { deps, deleted, revoked };
}

function request(token: string | null, body: unknown = {}, method = "POST") {
  return new Request("http://localhost/delete-account", {
    method,
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: method === "POST" ? JSON.stringify(body) : undefined,
  });
}

Deno.test("deletes the caller's own account", async () => {
  const { deps, deleted } = fakeDeps({ "alice-token": ALICE });
  const res = await createHandler(deps)(request("alice-token"));
  assertEquals(res.status, 200);
  assertEquals(await res.json(), { deleted: true, appleRevoked: false });
  assertEquals(deleted, ["alice"]);
});

Deno.test("refuses without a valid token", async () => {
  const { deps, deleted } = fakeDeps({ "alice-token": ALICE });
  const handler = createHandler(deps);
  assertEquals((await handler(request(null))).status, 401);
  assertEquals((await handler(request("forged"))).status, 401);
  assertEquals((await handler(request("alice-token", {}, "GET"))).status, 405);
  assertEquals(deleted, []);
});

Deno.test("auth outage answers 503 and deletes nothing", async () => {
  const { deps, deleted } = fakeDeps({}, {
    getUser: () => Promise.reject(new Error("auth down")),
  });
  assertEquals((await createHandler(deps)(request("t"))).status, 503);
  assertEquals(deleted, []);
});

Deno.test("Apple accounts: tokens revoked, then deleted", async () => {
  const { deps, deleted, revoked } = fakeDeps({ t: APPLE_USER });
  const res = await createHandler(deps)(
    request("t", { appleAuthorizationCode: "code-1" }),
  );
  assertEquals(await res.json(), { deleted: true, appleRevoked: true });
  assertEquals(revoked, ["code-1"]);
  assertEquals(deleted, ["apple-user"]);
});

Deno.test("Apple revocation failing or unconfigured still deletes", async () => {
  for (
    const revokeApple of [
      () => Promise.reject(new Error("apple down")),
      null,
    ]
  ) {
    const { deps, deleted } = fakeDeps({ t: APPLE_USER }, { revokeApple });
    const res = await createHandler(deps)(
      request("t", { appleAuthorizationCode: "code" }),
    );
    assertEquals(await res.json(), { deleted: true, appleRevoked: false });
    assertEquals(deleted, ["apple-user"]);
  }
});

Deno.test("an Apple code for a non-Apple account is ignored", async () => {
  const { deps, revoked } = fakeDeps({ t: ALICE });
  await createHandler(deps)(request("t", { appleAuthorizationCode: "code" }));
  assertEquals(revoked, []);
});

Deno.test("delete failure answers 500", async () => {
  const { deps } = fakeDeps({ t: ALICE }, {
    deleteUser: () => Promise.reject(new Error("db down")),
  });
  assertEquals((await createHandler(deps)(request("t"))).status, 500);
});

// --- Apple --------------------------------------------------------------

async function testAppleConfig(): Promise<{ config: AppleConfig; publicKey: CryptoKey }> {
  const pair = await crypto.subtle.generateKey(
    { name: "ECDSA", namedCurve: "P-256" },
    true,
    ["sign", "verify"],
  ) as CryptoKeyPair;
  const der = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${
    btoa(String.fromCharCode(...der))
  }\n-----END PRIVATE KEY-----`;
  return {
    config: { teamId: "TEAM123456", keyId: "KEY1234567", privateKey: pem, clientId: "com.elibayev.fitrix" },
    publicKey: pair.publicKey,
  };
}

function decode(part: string): Uint8Array<ArrayBuffer> {
  const b64 = part.replace(/-/g, "+").replace(/_/g, "/");
  const binary = atob(b64 + "=".repeat((4 - b64.length % 4) % 4));
  const bytes = new Uint8Array(new ArrayBuffer(binary.length));
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

Deno.test("client secret is an ES256 JWT Apple accepts", async () => {
  const { config, publicKey } = await testAppleConfig();
  const jwt = await appleClientSecret(config, 1_000_000);
  const [header, claims, signature] = jwt.split(".");
  assertEquals(JSON.parse(new TextDecoder().decode(decode(header))), { alg: "ES256", kid: "KEY1234567" });
  assertEquals(JSON.parse(new TextDecoder().decode(decode(claims))), {
    iss: "TEAM123456",
    iat: 1_000_000,
    exp: 1_000_300,
    aud: "https://appleid.apple.com",
    sub: "com.elibayev.fitrix",
  });
  assert(
    await crypto.subtle.verify(
      { name: "ECDSA", hash: "SHA-256" },
      publicKey,
      decode(signature),
      new TextEncoder().encode(`${header}.${claims}`),
    ),
  );
});

Deno.test("revocation exchanges the code, then revokes the refresh token", async () => {
  const { config } = await testAppleConfig();
  const calls: { url: string; form: URLSearchParams }[] = [];
  const fakeFetch = (async (url: string, init: RequestInit) => {
    const form = new URLSearchParams(init.body as URLSearchParams);
    calls.push({ url, form });
    if (url.endsWith("/auth/token")) {
      return Response.json({ access_token: "a", refresh_token: "r" });
    }
    return new Response(null, { status: 200 });
  }) as typeof fetch;

  await revokeAppleTokens(config, "the-code", fakeFetch);
  assertEquals(calls.map((c) => c.url), [
    "https://appleid.apple.com/auth/token",
    "https://appleid.apple.com/auth/revoke",
  ]);
  assertEquals(calls[0].form.get("code"), "the-code");
  assertEquals(calls[0].form.get("grant_type"), "authorization_code");
  assertEquals(calls[1].form.get("token"), "r");
  assertEquals(calls[1].form.get("token_type_hint"), "refresh_token");
  assertEquals(calls[1].form.get("client_id"), "com.elibayev.fitrix");
});

Deno.test("Apple refusing the code throws", async () => {
  const { config } = await testAppleConfig();
  const fakeFetch = (async () => new Response("invalid_grant", { status: 400 })) as typeof fetch;
  let threw = false;
  try {
    await revokeAppleTokens(config, "bad", fakeFetch);
  } catch {
    threw = true;
  }
  assert(threw);
});

Deno.test("Apple config needs team, key id and key", () => {
  assertEquals(appleConfigFromEnv(() => undefined), null);
  const env: Record<string, string> = {
    APPLE_TEAM_ID: "T",
    APPLE_KEY_ID: "K",
    APPLE_PRIVATE_KEY: "line1\\nline2",
  };
  assertEquals(appleConfigFromEnv((n) => env[n]), {
    teamId: "T",
    keyId: "K",
    privateKey: "line1\nline2",
    clientId: "com.elibayev.fitrix",
  });
});
