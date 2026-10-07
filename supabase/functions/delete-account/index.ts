// Deletes the calling user's account for good: their auth user and, through
// `on delete cascade`, every row of theirs (profile, plans, history, chats).
// For accounts created with Sign in with Apple it first revokes the Apple
// tokens from the authorization code the app sends.
//
//   POST /functions/v1/delete-account
//   Authorization: Bearer <the user's access token>
//   { "appleAuthorizationCode"?: string }
//   → 200 { "deleted": true, "appleRevoked": boolean }
//
// The service key never leaves the server: Supabase provides it to the
// function. `verify_jwt` is off in config.toml because the token is checked
// here (works with the project's asymmetric signing keys too).
import { createClient } from "npm:@supabase/supabase-js@2";
import { appleConfigFromEnv, revokeAppleTokens } from "./apple.ts";

export interface DeletedUser {
  id: string;
  /// Sign-in providers of the account ("email", "google", "apple").
  providers: string[];
}

export interface Deps {
  /// The user the access token belongs to, or null if it isn't valid.
  getUser(accessToken: string): Promise<DeletedUser | null>;
  deleteUser(id: string): Promise<void>;
  /// Revokes Apple tokens; null when Apple isn't configured.
  revokeApple: ((authorizationCode: string) => Promise<void>) | null;
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

export function createHandler(deps: Deps) {
  return async (req: Request): Promise<Response> => {
    if (req.method !== "POST") {
      return json(405, { error: "Method not allowed" });
    }
    const token = req.headers.get("Authorization")?.replace(
      /^Bearer\s+/i,
      "",
    );
    if (!token) return json(401, { error: "Not signed in" });

    let user: DeletedUser | null;
    try {
      user = await deps.getUser(token);
    } catch (error) {
      console.error("Checking the token failed:", error);
      return json(503, { error: "Could not check the session" });
    }
    if (!user) return json(401, { error: "Not signed in" });

    const body = await req.json().catch(() => ({}));
    const code = typeof body?.appleAuthorizationCode === "string"
      ? body.appleAuthorizationCode
      : null;

    // Best effort: a missing Apple setup or an Apple outage must not keep
    // anyone from deleting their account; it's logged for follow-up.
    let appleRevoked = false;
    if (user.providers.includes("apple")) {
      if (!code) {
        console.warn(`${user.id}: Apple account deleted without a code`);
      } else if (!deps.revokeApple) {
        console.warn(`${user.id}: Apple secrets not set, tokens not revoked`);
      } else {
        try {
          await deps.revokeApple(code);
          appleRevoked = true;
        } catch (error) {
          console.error(`${user.id}: Apple revocation failed:`, error);
        }
      }
    }

    try {
      await deps.deleteUser(user.id);
    } catch (error) {
      console.error(`${user.id}: deleting the user failed:`, error);
      return json(500, { error: "Could not delete the account" });
    }
    console.log(`${user.id}: account deleted`);
    return json(200, { deleted: true, appleRevoked });
  };
}

/// Supabase provides the legacy service_role key, or the new secret keys
/// as JSON ({"default": "sb_secret_..."}).
function serviceKey(): string {
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (legacy) return legacy;
  const keys = JSON.parse(Deno.env.get("SUPABASE_SECRET_KEYS") ?? "{}");
  const key = keys.default ?? Object.values(keys)[0];
  if (typeof key !== "string") throw new Error("No service key available");
  return key;
}

if (import.meta.main) {
  const admin = createClient(Deno.env.get("SUPABASE_URL")!, serviceKey(), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const apple = appleConfigFromEnv((name) => Deno.env.get(name));

  Deno.serve(createHandler({
    async getUser(accessToken) {
      const { data, error } = await admin.auth.getUser(accessToken);
      if (error) {
        // 4xx: a bad or expired token. Anything else: auth is unreachable.
        if (error.status && error.status < 500) return null;
        throw error;
      }
      const user = data.user;
      const providers = new Set<string>(
        (user.app_metadata?.providers as string[] | undefined) ?? [],
      );
      for (const identity of user.identities ?? []) {
        providers.add(identity.provider);
      }
      return { id: user.id, providers: [...providers] };
    },
    async deleteUser(id) {
      const { error } = await admin.auth.admin.deleteUser(id);
      if (error) throw error;
    },
    revokeApple: apple ? (code) => revokeAppleTokens(apple, code) : null,
  }));
}
