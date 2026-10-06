// End-to-end sign-in against the local Supabase stack (real network).
//
// Skipped unless FITRIX_SUPABASE_IT=1. Needs `supabase start` (API on
// 55321, Mailpit on 55324):
//   FITRIX_SUPABASE_IT=1 flutter test test/supabase_auth_integration_test.dart
// Optional overrides: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, MAILPIT_URL.
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/data/auth_gateway.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/data/repositories/profile_remote.dart';
import 'package:fitrix/features/profile/data/repositories/profile_repository.dart';

final _env = Platform.environment;
final _url = _env['SUPABASE_URL'] ?? 'http://127.0.0.1:55321';
final _key = _env['SUPABASE_PUBLISHABLE_KEY'] ??
    'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
final _mailpit = _env['MAILPIT_URL'] ?? 'http://127.0.0.1:55324';

Future<String> _get(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

/// Waits for the [count]th email to [email] and returns its 6-digit code.
Future<String> _codeFromMailpit(String email, {int count = 1}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    final search = await _get(
        '$_mailpit/api/v1/search?query=${Uri.encodeQueryComponent('to:"$email"')}');
    // Newest first. Regex instead of jsonDecode: message bodies may hold
    // raw control characters.
    final ids = RegExp(r'"ID":"([^"]+)"')
        .allMatches(search)
        .map((m) => m.group(1)!)
        .toList();
    if (ids.length >= count) {
      // The HTML comes JSON-escaped ("\u003e596030\u003c").
      final message = (await _get('$_mailpit/api/v1/message/${ids.first}'))
          .replaceAll(r'\u003e', '>')
          .replaceAll(r'\u003c', '<');
      final code = RegExp(r'>\s*(\d{6})\s*<').firstMatch(message)?.group(1);
      if (code != null) return code;
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
  throw StateError('No sign-in email for $email');
}

/// One "device": its own storage, Supabase client and account service.
class _Device {
  _Device._(this.prefs, this.session, this.client, this.auth, this.account);

  static Future<_Device> create() async {
    SharedPreferences.setMockInitialValues({'language': 'ru'});
    final prefs = await SharedPreferences.getInstance();
    final session = AppSession(prefs);
    final client = SupabaseClient(
      _url,
      _key,
      authOptions: const AuthClientOptions(authFlowType: AuthFlowType.implicit),
    );
    final auth = SupabaseAuthGateway(client);
    final account = AccountService(
      prefs: prefs,
      session: session,
      auth: auth,
      remote: SupabaseProfileRemote(client),
    )..start();
    return _Device._(prefs, session, client, auth, account);
  }

  final SharedPreferences prefs;
  final AppSession session;
  final SupabaseClient client;
  final SupabaseAuthGateway auth;
  final AccountService account;

  Future<SignInDestination> signIn(String email, {int emailNumber = 1}) async {
    // The local stack allows one email per address per second.
    for (var attempt = 1;; attempt++) {
      try {
        await auth.sendCode(email);
        break;
      } catch (e) {
        if (attempt == 5 ||
            AuthFailure.from(e).kind != AuthFailureKind.rateLimited) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
    }
    final code = await _codeFromMailpit(email, count: emailNumber);
    final userId = await auth.verifyCode(email: email, code: code);
    return account.completeSignIn(userId);
  }

  Future<void> dispose() async {
    account.dispose();
    auth.dispose();
    await client.dispose();
  }
}

void main() {
  final enabled = _env['FITRIX_SUPABASE_IT'] == '1';

  test('email code sign-in, profile upsert and returning sign-in', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final email = 'auth-it-$stamp@fitrix.test';
    final otherEmail = 'auth-it-$stamp-other@fitrix.test';

    // --- Device 1: new account --------------------------------------------
    final phone = await _Device.create();
    addTearDown(phone.dispose);

    // A wrong code is rejected with a clear error.
    await phone.auth.sendCode(email);
    await _codeFromMailpit(email);
    try {
      await phone.auth.verifyCode(email: email, code: '000000');
      fail('wrong code accepted');
    } catch (e) {
      expect(AuthFailure.from(e, verifying: true).kind,
          AuthFailureKind.invalidCode);
      print('wrong code → ${AuthFailure.from(e, verifying: true).message}');
    }

    final code = await _codeFromMailpit(email);
    final userId = await phone.auth.verifyCode(email: email, code: code);
    expect(await phone.account.completeSignIn(userId),
        SignInDestination.profile);
    print('new account $userId → profile step');

    await ProfileRepository().saveProfile(UserProfile(
      name: 'Alex',
      surname: 'Tester',
      age: '30',
      weight: '72.5',
      height: '180',
    ));
    expect(await phone.account.profileChanged(), isTrue);
    var row = await SupabaseProfileRemote(phone.client).fetch(userId);
    expect(row!.name, 'Alex');
    expect(row.weightKg, 72.5);
    expect(row.language, 'ru');
    expect(row.onboardingComplete, isFalse);

    await phone.session.completeOnboarding();
    expect(await phone.account.profileChanged(), isTrue);
    row = await SupabaseProfileRemote(phone.client).fetch(userId);
    expect(row!.onboardingComplete, isTrue);
    print('profile upserted: ${row.toUpsert()}');

    // --- Device 2: same account signs in on a new device ------------------
    final tablet = await _Device.create();
    addTearDown(tablet.dispose);
    expect(await tablet.signIn(email, emailNumber: 2), SignInDestination.home);
    expect(tablet.session.onboardingComplete, isTrue);
    final restored = await ProfileRepository().getProfile();
    expect(restored!.name, 'Alex');
    expect(restored.weight, '72.5');
    print('returning sign-in on a new device → home, profile restored');

    // --- Another account on device 2: previous data cleared, RLS holds ----
    expect(await tablet.signIn(otherEmail), SignInDestination.profile);
    expect(tablet.session.onboardingComplete, isFalse);
    expect(await ProfileRepository().getProfile(), isNull);
    final otherId = tablet.auth.userId!;
    expect(otherId, isNot(userId));
    expect(await SupabaseProfileRemote(tablet.client).fetch(userId), isNull,
        reason: "row level security hides the other account's row");
    print('account switch cleared local data; RLS hides other rows');

    // --- Sign out ------------------------------------------------------------
    await tablet.account.signOut();
    expect(tablet.auth.userId, isNull);
    expect(tablet.prefs.getKeys(), isEmpty);
    // Let the background server-side sign-out finish before tear-down.
    await Future<void>.delayed(const Duration(seconds: 1));
    print('signed out');
  },
      skip: enabled ? false : 'Set FITRIX_SUPABASE_IT=1 to run',
      timeout: const Timeout(Duration(minutes: 2)));
}
