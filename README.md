# FITRIX - AI-Powered Fitness Application

Flutter app with an AI fitness coach, **Felix**, powered by a local
[Ollama](https://ollama.com) model through a small Node.js backend.

Platforms in this repo: iOS, Android, macOS and web.

## What's in the app

**Onboarding** (shown once; later launches open Home)
- Intro → language → sign-in → profile → chat with Felix → "Felix is ready"
- Sign-in with a 6-digit email code (Supabase Auth). "Continue with Google"
  and "Continue with Apple" sign in natively once configured (see
  [Google and Apple sign-in](#google-and-apple-sign-in)); until then they
  say "coming soon"

**Main app** (5-tab bar: Discover · Shop · Home · Felix · Profile)
- **Home** — tiles for My progress, My nutrition, Felix, My workouts, Shop,
  Fitrix map
- **My workouts** — sports → workout plans (today's workout, Start/Edit, add
  your own)
- **Active workout** — sets table (previous / kg / reps / done), live timer,
  collapses to a mini bar above the tab bar and survives an app restart
- **My progress** — strength charts and recent sessions from your saved
  workouts; body weight and calories are sample data for now
- **My nutrition** — calorie ring and macros (sample data)
- **Felix chats** — general assistant plus a trainer chat per sport; replies
  stream in word by word
- **About me** — profile data and Sign out (clears everything on the device)
- Discover, Shop and Fitrix map are "Coming soon" placeholders

Light and dark themes follow the system setting. The language picker saves
your choice, but the UI is English-only for now.

## Running it

See [QUICKSTART.md](QUICKSTART.md). In short:

```bash
ollama pull qwen3:8b                              # once
supabase start -x vector,logflare,edge-runtime    # local auth + database
cd backend && npm install && cp .env.example .env && npm start
flutter run                                       # from the project root
```

With no `--dart-define`, the app talks to `http://localhost:3000` on the iOS
simulator, macOS and web, and to `http://10.0.2.2:3000` on Android (the
emulator's alias for the host Mac). On a physical phone pass your Mac's LAN
address:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.103:3000
```

On a physical **Android** phone also add that IP to the cleartext allow-list
in
`android/app/src/main/res/xml/network_security_config.xml` (cleartext is
only permitted for `10.0.2.2`, `localhost` and `127.0.0.1` by default).
Over USB you can skip that with `adb reverse tcp:3000 tcp:3000` and
`--dart-define=API_BASE_URL=http://localhost:3000`.

If the backend isn't reachable at all, the onboarding chat falls back to
canned replies so the flow can still be completed. If the backend is up but
the model fails, the chat shows the error with "Tap to retry".

## Backend

`backend/server.js` (Express) proxies chat to Ollama:

- `POST /chat/stream` — streamed reply as NDJSON (`{"delta"}` … `{"done"}`),
  used by the app
- `POST /chat` — same, as a single JSON reply
- `GET /health`, `GET /models`, `POST /chat/reset`

The chat endpoints require a Supabase sign-in: the app sends the user's
access token as `Authorization: Bearer …` and the backend verifies it
against the project's public signing keys (JWKS). Missing/invalid/expired
tokens get `401` (the app shows "Please sign in again"), more than
`RATE_LIMIT_PER_MINUTE` requests per user get `429`. `/health` is open.

When the app doesn't send `history`, the server keeps the conversation in
memory per user and `conversationId`, so it resets when the server restarts.
Configuration (Supabase, model, thinking mode, keep-alive, rate limit) is
described in [backend/README.md](backend/README.md); copy
`backend/.env.example` to `backend/.env` to set it.

## Supabase (local)

Auth (email sign-in codes) and the database run on
[Supabase](https://supabase.com). For development the whole stack runs
locally in Docker via the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started):

```bash
brew install supabase/tap/supabase       # once; Docker must be running
supabase start -x vector,logflare,edge-runtime
supabase status                          # URLs and keys
```

`-x` skips services the app doesn't use (log collection, analytics, edge
functions), which makes startup faster and lighter. `supabase start`
applies the migrations in `supabase/migrations/` (tables with row level
security) on first start.

The ports are `553xx` instead of the CLI's default `543xx` (see
`supabase/config.toml`) so this stack can run next to other local Supabase
projects:

| Service | URL |
|---------|-----|
| API (auth, REST) | http://127.0.0.1:55321 |
| Database | `postgresql://postgres:postgres@127.0.0.1:55322/postgres` |
| Studio (tables, users) | http://127.0.0.1:55323 |
| Mailpit (local inbox) | http://127.0.0.1:55324 |

**Sign-in codes locally:** no real email is sent. Every sign-in code lands
in Mailpit — open http://127.0.0.1:55324, pick the newest "Your FITRIX
sign-in code" mail and type the 6 digits into the app. The email body comes
from `supabase/templates/otp_code.html`.

With no `--dart-define`, the app uses the local stack
(`http://127.0.0.1:55321`, `http://10.0.2.2:55321` on the Android emulator)
and the local publishable key. The backend needs
`SUPABASE_URL=http://127.0.0.1:55321` (already in `backend/.env.example`).

`supabase stop` stops the stack and keeps the data; `supabase db reset`
re-creates the local database from the migrations (deletes local users and
data).

## Google and Apple sign-in

Both buttons sign in **natively**: Google's account picker / Apple's sheet
returns an ID token, the app hands it to Supabase (`signInWithIdToken`), and
from there it's the same as an email code (account switch handling, profile
row → onboarding or Home). Cancelling the sheet does nothing; errors are
shown under the email field ("isn't set up on the server yet", "No
connection", …).

Everything is **off by default**, so the app builds and runs without any
of it. Three switches, all outside git:

| Where | What | Enables |
|-------|------|---------|
| `--dart-define=GOOGLE_WEB_CLIENT_ID=…` | Web client id (the token's audience) | Google button (Android, iOS) |
| `--dart-define=GOOGLE_IOS_CLIENT_ID=…` | iOS client id | Google button on iOS (needs the web id too) |
| `ios/Flutter/GoogleSignIn.local.xcconfig` | `GOOGLE_IOS_CLIENT_ID_PREFIX` | iOS URL scheme + `GIDClientID` in Info.plist |
| `--dart-define=APPLE_SIGN_IN=true` | — | Apple button (iOS/macOS; paid Apple account) |
| `supabase/.env` (local) / dashboard (cloud) | provider on + client ids | Supabase accepting the tokens |

Without the dart-defines the buttons say "coming soon"; the Apple button is
only shown on iPhone/iPad/Mac. Client ids are not secrets (they ship inside
the app), but they're kept out of git so each machine/project can use its
own. The Google **client secret is not needed** for this flow; never commit
it.

### Google: what you do in Google Cloud Console (once, by hand)

1. https://console.cloud.google.com → create or pick a project.
2. **APIs & Services → OAuth consent screen** (Google Auth Platform →
   Branding / Audience): app name "FITRIX", support email, developer email.
   User type **External**. While the app is in *Testing*, add every Google
   account that should be able to sign in under **Test users**. Scopes:
   the default `openid`, `email`, `profile` are enough.
3. **Credentials → Create credentials → OAuth client ID → Web
   application**, name "FITRIX Supabase". No origins/redirects needed for
   the app (add `https://<project-ref>.supabase.co/auth/v1/callback` only if
   you ever want browser sign-in). Copy the **client ID** →
   `GOOGLE_WEB_CLIENT_ID`. (The secret it shows is only for browser
   sign-in.)
4. **Create credentials → OAuth client ID → iOS**, bundle ID
   `com.elibayev.fitrix`. Copy the **client ID** → `GOOGLE_IOS_CLIENT_ID`.
   Its "iOS URL scheme" is the reversed id
   (`com.googleusercontent.apps.<prefix>`), built automatically from the
   prefix below.
5. **Android** (optional): **Create credentials → OAuth client ID →
   Android**, package name `com.elibayev.fitrix`, SHA-1 of the signing key.
   For debug builds:

   ```bash
   keytool -list -v -alias androiddebugkey -storepass android \
     -keystore ~/.android/debug.keystore | grep SHA1
   ```

   Release builds (and Play App Signing) need their own SHA-1 as another
   Android client. Nothing from the Android client goes into the app:
   Google matches package name + SHA-1, and the app only passes the web
   client id.

### Google: wire it into the app

1. iOS URL scheme — create `ios/Flutter/GoogleSignIn.local.xcconfig`
   (git-ignored) with the iOS client id **without**
   `.apps.googleusercontent.com`:

   ```
   GOOGLE_IOS_CLIENT_ID_PREFIX = 1234567890-abcdef
   ```

   `ios/Flutter/GoogleSignIn.xcconfig` turns it into `GIDClientID`
   (`1234567890-abcdef.apps.googleusercontent.com`) and the URL scheme
   (`com.googleusercontent.apps.1234567890-abcdef`) in `Info.plist`.
   Without the file a placeholder is used and the app still builds.
   **Don't** pass `GOOGLE_IOS_CLIENT_ID` without this file: Google's SDK
   crashes the app if the URL scheme is missing.
2. Run / build with the ids:

   ```bash
   flutter run \
     --dart-define=GOOGLE_WEB_CLIENT_ID=<web client id> \
     --dart-define=GOOGLE_IOS_CLIENT_ID=<iOS client id>
   ```

   (add the usual `API_BASE_URL` / `SUPABASE_URL` defines on a phone).
   On Android only `GOOGLE_WEB_CLIENT_ID` is needed.

### Google: tell Supabase which tokens to accept

- **Local stack** — copy `supabase/.env.example` to `supabase/.env` and set

  ```bash
  SUPABASE_AUTH_EXTERNAL_GOOGLE_ENABLED=true
  SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID=<web client id>,<iOS client id>
  ```

  then restart the stack (`supabase stop && supabase start -x
  vector,logflare,edge-runtime`; data is kept). `supabase/config.toml` reads
  these through `env(...)`; with no `.env` the provider stays off and
  `supabase start` works as before.
- **Cloud project** — Dashboard → Authentication → Sign In / Providers →
  **Google**: enable, **Client IDs** = `<web client id>,<iOS client id>`
  (web first; this is the "authorized client IDs" list the token's
  audience is checked against). Leave **Skip nonce checks** off: the app
  sends a nonce on iOS and Android. The Client Secret field is only used by
  browser sign-in (paste the web client's secret if the form insists).

### Apple (needs a paid Apple Developer account)

The code is in place but the button stays "coming soon": a free "Personal
Team" can't sign apps with the Sign in with Apple capability, and adding it
breaks signing. Once the account is paid ($99/year):

1. developer.apple.com → Certificates, IDs & Profiles → Identifiers →
   `com.elibayev.fitrix` → enable **Sign In with Apple** (as primary App ID)
   → Save.
2. Xcode → Runner target → Signing & Capabilities → pick the paid team →
   **+ Capability → Sign in with Apple**. This creates
   `ios/Runner/Runner.entitlements` with

   ```xml
   <key>com.apple.developer.applesignin</key>
   <array>
       <string>Default</string>
   </array>
   ```

   and sets `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` for the
   Runner target. Commit both.
3. Supabase: local — in `supabase/.env`

   ```bash
   SUPABASE_AUTH_EXTERNAL_APPLE_ENABLED=true
   SUPABASE_AUTH_EXTERNAL_APPLE_CLIENT_ID=com.elibayev.fitrix
   ```

   and restart the stack; cloud — Dashboard → Authentication → Sign In /
   Providers → **Apple**: enable, **Client IDs** = `com.elibayev.fitrix`.
   No secret key is needed for native sign-in (only for the web flow with a
   Services ID).
4. Build with `--dart-define=APPLE_SIGN_IN=true`.

Apple shares the user's name only on the very first sign-in; the app saves
it to the account's metadata (`full_name`).

## Cloud project (current)

The app's cloud Supabase project is `fitrix` (region eu-central-1). Its
settings (URL, publishable key, Google client IDs) live in `env/cloud.json`,
which is git-ignored; create it from the template:

```bash
cp env/cloud.example.json env/cloud.json   # then fill in the real values
```

Build with it:

```bash
flutter run --release \
  --dart-define-from-file=env/cloud.json \
  --dart-define=API_BASE_URL=http://<mac-name>.local:3000
```

iOS also needs `ios/Flutter/GoogleSignIn.local.xcconfig` (see "Google and
Apple sign-in"). Start the chat backend against the cloud project with
`SUPABASE_URL=https://<project-ref>.supabase.co npm start`.

Email-code sign-in on the cloud project needs a custom SMTP server: on the
free plan Supabase only allows changing the email templates (to show the
6-digit code) once custom SMTP is configured. Google sign-in works without it.
The database password is in the macOS keychain item
`fitrix-supabase-db-password`.

## Deploy to Supabase cloud

1. **Create a project** at https://supabase.com/dashboard (pick a region
   close to your users, keep the database password).
2. **Link and push the schema** from the project root:

   ```bash
   supabase login
   supabase link --project-ref <project-ref>   # asks for the DB password
   supabase db push                            # applies supabase/migrations/
   ```

   `<project-ref>` is the `xxxx` in `https://xxxx.supabase.co`.
   `supabase/config.toml` only configures the local stack; cloud auth
   settings are made in the dashboard (next steps).
3. **Email sign-in codes.** The app signs in with a 6-digit email code, not
   a link. In Dashboard → Authentication → Emails → Templates, set **both**
   templates to the content of `supabase/templates/otp_code.html` (it uses
   `{{ .Token }}`, the code), subject "Your FITRIX sign-in code":
   - **Magic Link** — sent to existing users signing in
   - **Confirm signup** — sent to new users on their first sign-in

   Check Authentication → Sign In / Providers → Email: Email provider
   enabled, "Email OTP Length" 6, "Email OTP Expiration" 3600 s (the app
   and template expect 6 digits / 1 hour).
4. **Real SMTP.** Supabase's built-in mailer only delivers to your team's
   addresses and a few emails per hour — fine for a smoke test, not for
   users. In Authentication → Emails → SMTP Settings enable custom SMTP
   (Resend, Postmark, SES, …) with your sender address, then raise the email
   limit in Authentication → Rate Limits.
5. **Run the app against the cloud project** (keys: Project Settings → API
   Keys; the publishable key is safe to ship, row level security protects
   the data):

   ```bash
   flutter run \
     --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_... \
     --dart-define=API_BASE_URL=https://<your-backend-host>
   ```

   Use the same `--dart-define`s for `flutter build`.
6. **Backend for the cloud project** (`backend/.env` or the host's env):

   ```bash
   SUPABASE_URL=https://<project-ref>.supabase.co
   AUTH_MODE=required             # fail at startup if SUPABASE_URL is missing
   RATE_LIMIT_PER_MINUTE=20
   # Only if Project Settings → JWT Keys still shows the legacy secret in use:
   # SUPABASE_JWT_SECRET=<legacy JWT secret>
   ```

   No service-role or secret key is needed: tokens are checked with the
   project's public keys. The backend must also reach an Ollama server
   (`OLLAMA_URL`) and should be served over HTTPS.

7. **Account deletion function** (required by the App Store and Google
   Play; see [Account deletion](#account-deletion)):

   ```bash
   supabase functions deploy delete-account   # verify_jwt off via config.toml
   # Sign in with Apple accounts: lets the function revoke Apple's tokens.
   # Key: developer.apple.com → Certificates, IDs & Profiles → Keys →
   # new key with "Sign in with Apple" for com.elibayev.fitrix.
   supabase secrets set APPLE_TEAM_ID=<team id> APPLE_KEY_ID=<key id>
   supabase secrets set APPLE_PRIVATE_KEY="$(cat AuthKey_<key id>.p8)"
   ```

   The function gets the service key from Supabase itself; it never goes
   into the app or git. Never commit the `.p8` file (`*.p8` is ignored).

## Account deletion

About me → **Delete account** (signed-in accounts only) asks twice, then
calls `supabase/functions/delete-account`, which deletes the auth user; the
database cascades that to the profile, workout plans, history and chats.
The app then clears everything on the device and returns to the intro.
Offline or on a server error nothing changes and the app says so.

Accounts that sign in with Apple are confirmed with Apple first (Face ID
sheet); the function exchanges that fresh authorization code for a token
and revokes it, as App Store guideline 5.1.1(v) requires. If the Apple
secrets are missing or Apple fails, the account is still deleted and the
function logs it.

For the stores:

- **App Store review notes:** "Account deletion: About me tab → Delete
  account."
- **Google Play** (Data safety → Account deletion) also needs a **web page**
  explaining how to delete the account, including for people who no longer
  have the app (e.g. an email address to write to), and what is deleted.
  Host it next to the privacy policy.

Run the function locally and its tests:

```bash
supabase functions serve delete-account          # local stack must be up
deno test supabase/functions/delete-account/     # unit tests, no network
FITRIX_SUPABASE_IT=1 FITRIX_FUNCTIONS_IT=1 \
  flutter test test/supabase_auth_integration_test.dart
```

## Release builds

### Android release signing

Play Store builds are signed with your own **upload key**; it never goes
into git (`key.properties`, `*.jks`, `*.keystore` are ignored). Without
`android/key.properties`, `flutter run --release` / `flutter build apk`
fall back to the debug key, and `flutter build appbundle` stops with an
error so a debug-signed bundle can't reach the Play Store.

1. **Create the key once** (needs a JDK, e.g. `brew install openjdk`; keep
   the file and both passwords in a password manager — losing them means
   asking Google to reset the upload key):

   ```bash
   mkdir -p ~/keys
   keytool -genkey -v -keystore ~/keys/fitrix-upload.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Create `android/key.properties`** (git-ignored):

   ```properties
   storePassword=<keystore password>
   keyPassword=<key password>
   keyAlias=upload
   storeFile=/Users/<you>/keys/fitrix-upload.jks
   ```

3. **Build** the bundle for the cloud project:

   ```bash
   flutter build appbundle --release \
     --dart-define-from-file=env/cloud.json \
     --dart-define=API_BASE_URL=https://<your-backend-host>
   ```

   Check the signature: `keytool -printcert -jarfile
   build/app/outputs/bundle/release/app-release.aab` must show your upload
   certificate, not "Android Debug".

4. **Play Console:** keep **Play App Signing** on (Google holds the app
   signing key; yours is only the upload key). Then add the **SHA-1 of
   Play's app signing key** (Play Console → Setup → App signing) to the
   Android OAuth client in Google Cloud Console, or Google sign-in fails in
   builds installed from the Play Store. Add the upload key's SHA-1 too
   (`keytool -list -v -keystore ~/keys/fitrix-upload.jks -alias upload`)
   for locally built release APKs.

The version comes from `pubspec.yaml` (`version: 1.0.0+1` → versionName
`1.0.0`, versionCode `1`); raise the number after `+` for every upload.

### iOS release

Signing is automatic (team `8J66M56MGN`, bundle id `com.elibayev.fitrix`).
Create the app in App Store Connect with that bundle id, then:

```bash
flutter build ipa --release \
  --dart-define-from-file=env/cloud.json \
  --dart-define=API_BASE_URL=https://<your-backend-host>
```

and upload `build/ios/ipa/*.ipa` with Transporter (or Xcode → Organizer).
`Info.plist` declares `ITSAppUsesNonExemptEncryption = false` (the app only
uses standard HTTPS), so no export-compliance question per build.

## Translations

The app is in English, Russian, Uzbek (Latin) and Spanish. The language
picked on the language screen (or restored from the account) wins;
before that the device language is used when the app has it, otherwise
English. Felix gets the app language with every chat request.

Strings live in `lib/l10n/app_<lang>.arb` (`app_en.arb` is the template);
code reads them with `AppLocalizations.of(context).<key>`. To add or change
a string, edit **all four** files, then run `flutter gen-l10n` (or
`flutter pub get`) to regenerate `lib/l10n/generated/`.
`test/l10n_test.dart` fails if a language misses a key or a placeholder.

Translated so far: intro, language picker, About me (sign-out and account
deletion). The other screens are still English and move over screen by
screen. Uzbek texts need a check by a native speaker.

## Data storage

Everything is stored on the device with `shared_preferences`: language,
email, profile, onboarding status, chat histories, workout plans, the workout
in progress and workout history. Sign out deletes all of it.

## Project structure

```
lib/
├── core/
│   ├── constants/      # API URL, storage keys, copy
│   ├── router/         # go_router routes, onboarding redirect, tab shell
│   ├── session/        # onboarding status / sign-out, preloaded prefs
│   ├── theme/          # Material themes, AppPalette design tokens
│   └── widgets/        # Logo, tiles, pills, page titles
├── features/
│   ├── intro/ language/ auth/ profile/ transition/   # onboarding
│   ├── home/ shell/                                    # Home + tab bar
│   ├── workouts/       # plans, active workout, history, storage
│   ├── progress/       # charts
│   ├── nutrition/
│   └── chat/           # Felix: streaming API client, chats, bubbles
└── main.dart           # loads storage, then starts the app
```

## Tech stack

Flutter · Riverpod · go_router · shared_preferences · dio (streaming HTTP)

## Tests

```bash
flutter test
```

Covers chat streaming and retries (against a local fake backend, including
the `Authorization` header and the 401/429 messages), workout persistence
and history, progress charts, onboarding redirect and sign-out, email-code
and Google/Apple sign-in (with fakes for Supabase and the native sheets),
and the main workout flow. Backend tests: `cd backend && npm test`.

## License

Proprietary — all rights reserved. Using, copying, modifying or distributing
this code without the author's written permission is prohibited. See
[LICENSE](LICENSE).
