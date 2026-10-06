import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthApiException;

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/main.dart';

import 'support/fake_auth.dart';

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class _Harness {
  _Harness(this.prefs, this.session, this.auth, this.remote, this.account);
  final SharedPreferences prefs;
  final AppSession session;
  final FakeAuthGateway auth;
  final FakeProfileRemote remote;
  final AccountService account;
}

/// The real app with fake Supabase auth and profile table.
Future<_Harness> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  String? signedInAs,
  void Function(FakeAuthGateway auth, FakeProfileRemote remote)? setUp,
}) async {
  _phoneSize(tester);
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await SharedPreferences.getInstance();
  final session = AppSession(storage);
  final auth = FakeAuthGateway(users: {'old@x.com': 'user-old'});
  final remote = FakeProfileRemote();
  setUp?.call(auth, remote);
  if (signedInAs != null) auth.signInAs(signedInAs);
  final account = AccountService(
    prefs: storage,
    session: session,
    auth: auth,
    remote: remote,
  )..start();
  addTearDown(account.dispose);

  await tester.pumpWidget(FitrixRoot(
    prefs: storage,
    session: session,
    router: AppRouter.create(session, auth: auth),
    auth: auth,
    account: account,
  ));
  await tester.pumpAndSettle();
  return _Harness(storage, session, auth, remote, account);
}

Future<void> _enterEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byKey(const Key('email-input')), email);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
  await tester.pumpAndSettle();
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(const Key('code-input')), code);
  await tester.pumpAndSettle();
}

String? _errorText(WidgetTester tester) {
  final finder = find.byKey(const Key('sign-in-error'));
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<Text>(finder).data;
}

void main() {
  group('local-only mode (no Supabase)', () {
    Future<void> pumpLocal(WidgetTester tester) async {
      _phoneSize(tester);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final session = AppSession(prefs);
      await tester.pumpWidget(FitrixRoot(
        prefs: prefs,
        session: session,
        router: AppRouter.create(session),
      ));
      AppRouter.router.go(AppRouter.signIn);
      await tester.pumpAndSettle();
    }

    testWidgets('any valid email continues to the profile step',
        (tester) async {
      await pumpLocal(tester);
      expect(find.text('Create an account'), findsOneWidget);

      await _enterEmail(tester, 'not-an-email');
      expect(_errorText(tester), 'Enter a valid email address.');

      await _enterEmail(tester, 'me@example.com');
      expect(find.byKey(const Key('profile-name')), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_email'), 'me@example.com');
    });

    testWidgets('Google and Apple say "coming soon"', (tester) async {
      await pumpLocal(tester);
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();
      expect(find.textContaining('Google is coming soon'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
    });
  });

  group('email code sign-in', () {
    testWidgets('new account: email → code (wrong, then right) → profile',
        (tester) async {
      final h = await _pumpApp(tester);
      AppRouter.router.go(AppRouter.signIn);
      await tester.pumpAndSettle();

      await _enterEmail(tester, 'new@x.com');
      expect(h.auth.codesSentTo, ['new@x.com']);
      expect(find.text('Check your email'), findsOneWidget);
      expect(find.textContaining('new@x.com'), findsOneWidget);
      expect(find.text('Resend code in 1:00'), findsOneWidget);

      await _enterCode(tester, '000000');
      expect(_errorText(tester), contains('wrong or has expired'));
      expect(find.text('Check your email'), findsOneWidget);

      // Pasting text with the code in it works too.
      await _enterCode(tester, 'Your code: 123 456');
      expect(find.byKey(const Key('profile-name')), findsOneWidget);
      expect(h.session.accountUserId, h.auth.userId);
      expect(h.session.onboardingComplete, isFalse);
    });

    testWidgets('returning account goes straight Home with its profile',
        (tester) async {
      final h = await _pumpApp(tester, setUp: (auth, remote) {
        auth.users['back@x.com'] = 'user-back';
        remote.rows['user-back'] = {
          'id': 'user-back',
          'name': 'Alex',
          'surname': 'Smith',
          'age': 30,
          'weight_kg': 72.5,
          'height_cm': 180,
          'language': 'en',
          'onboarding_complete': true,
        };
      });
      AppRouter.router.go(AppRouter.signIn);
      await tester.pumpAndSettle();

      await _enterEmail(tester, 'back@x.com');
      await _enterCode(tester, '123456');
      expect(find.text('FELIX'), findsOneWidget);
      expect(h.session.onboardingComplete, isTrue);

      AppRouter.router.go(AppRouter.me);
      await tester.pumpAndSettle();
      expect(find.text('Alex Smith'), findsOneWidget);
      expect(find.text('back@x.com'), findsOneWidget);
      expect(find.text('72.5 kg'), findsOneWidget);
    });

    testWidgets('errors: rate limit and no connection', (tester) async {
      final h = await _pumpApp(tester);
      AppRouter.router.go(AppRouter.signIn);
      await tester.pumpAndSettle();

      h.auth.sendError = const AuthApiException('slow down',
          statusCode: '429', code: 'over_email_send_rate_limit');
      await _enterEmail(tester, 'a@x.com');
      expect(_errorText(tester), contains('Too many attempts'));
      expect(find.text('Create an account'), findsOneWidget);

      h.auth.sendError = null;
      await _enterEmail(tester, 'a@x.com');
      h.auth.verifyError = const AuthApiException('offline');
      await _enterCode(tester, '123456');
      expect(_errorText(tester), contains('No connection'));
    });

    testWidgets('resend has a cooldown; the email can be changed',
        (tester) async {
      final h = await _pumpApp(tester);
      AppRouter.router.go(AppRouter.signIn);
      await tester.pumpAndSettle();
      await _enterEmail(tester, 'typo@x.com');

      final resend = find.widgetWithText(TextButton, 'Resend code in 1:00');
      expect(tester.widget<TextButton>(resend).onPressed, isNull);
      await tester.pump(const Duration(seconds: 61));
      await tester.tap(find.widgetWithText(TextButton, 'Resend code'));
      await tester.pumpAndSettle();
      expect(h.auth.codesSentTo, ['typo@x.com', 'typo@x.com']);
      expect(find.text('We sent a new code to typo@x.com'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Change email'));
      await tester.pumpAndSettle();
      expect(find.text('Create an account'), findsOneWidget);
      await _enterEmail(tester, 'right@x.com');
      expect(find.textContaining('right@x.com'), findsOneWidget);
    });

    testWidgets('profile load failure after the code offers a retry',
        (tester) async {
      final h = await _pumpApp(tester);
      AppRouter.router.go(AppRouter.signIn);
      await tester.pumpAndSettle();
      await _enterEmail(tester, 'a@x.com');

      h.remote.fetchError = const AuthApiException('offline');
      await _enterCode(tester, '123456');
      expect(_errorText(tester), contains("profile couldn't be loaded"));

      h.remote.fetchError = null;
      await tester.tap(find.widgetWithText(ElevatedButton, 'Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-name')), findsOneWidget);
    });
  });

  group('profile step', () {
    testWidgets('validates, saves locally and upserts the account row',
        (tester) async {
      final h = await _pumpApp(
        tester,
        prefs: {'language': 'ru'},
        signedInAs: 'a@x.com',
      );
      // Wide enough for the chat's quick replies in the test font.
      tester.view.physicalSize = const Size(2400, 2532);
      await h.session.setAccountUserId(h.auth.userId!);
      AppRouter.router.go(AppRouter.profile);
      await tester.pumpAndSettle();

      Future<void> fill(String field, String text) => tester.enterText(
          find.byKey(Key('profile-$field')), text);
      await fill('name', 'Alex');
      await fill('age', '300');
      await fill('weight', 'heavy');
      await fill('height', '180');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();
      expect(find.text('Age must be between 5 and 120'), findsOneWidget);
      expect(find.text('Enter your weight as a number'), findsOneWidget);
      expect(h.remote.upserts, 0);

      await fill('age', '30');
      await fill('weight', '72,5');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final row = h.remote.rows[h.auth.userId]!;
      expect(row['name'], 'Alex');
      expect(row['age'], 30);
      expect(row['weight_kg'], 72.5);
      expect(row['height_cm'], 180.0);
      expect(row['language'], 'ru');
      expect(row['onboarding_complete'], isFalse);
      expect(h.prefs.getString('user_weight'), '72.5');
      expect(h.account.hasPendingUpload, isFalse);
    });
  });

  group('session and account changes', () {
    testWidgets('session ended elsewhere → sign in again, same data kept',
        (tester) async {
      final h = await _pumpApp(
        tester,
        prefs: {
          'onboarding_complete': true,
          'account_user_id': 'user-old',
          'user_name': 'Alex',
        },
        signedInAs: 'old@x.com',
      );
      expect(find.text('FELIX'), findsOneWidget);

      h.auth.revoke();
      await tester.pumpAndSettle();
      expect(find.text('Sign in again'), findsOneWidget);

      await _enterEmail(tester, 'old@x.com');
      await _enterCode(tester, '123456');
      expect(find.text('FELIX'), findsOneWidget);
      expect(h.prefs.getString('user_name'), 'Alex');
    });

    testWidgets('a different account clears the previous account\'s data',
        (tester) async {
      final h = await _pumpApp(tester, prefs: {
        'onboarding_complete': true,
        'account_user_id': 'user-old',
        'user_name': 'Alex',
        'workout_history': '[]',
      });
      // No session: the onboarded device asks to sign in.
      expect(find.text('Sign in again'), findsOneWidget);

      await _enterEmail(tester, 'someone-else@x.com');
      await _enterCode(tester, '123456');
      expect(find.byKey(const Key('profile-name')), findsOneWidget);
      expect(h.prefs.getString('user_name'), isNull);
      expect(h.prefs.getString('workout_history'), isNull);
      expect(h.session.onboardingComplete, isFalse);
      expect(h.session.accountUserId, h.auth.userId);
    });

    testWidgets('About me shows the email; sign out ends the session',
        (tester) async {
      final h = await _pumpApp(
        tester,
        prefs: {
          'onboarding_complete': true,
          'account_user_id': 'user-old',
          'user_name': 'Alex',
        },
        signedInAs: 'old@x.com',
      );
      AppRouter.router.go(AppRouter.me);
      await tester.pumpAndSettle();
      expect(find.text('old@x.com'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(h.auth.signOutCalls, 1);
      expect(h.auth.userId, isNull);
      expect(find.text('Start your journey'), findsOneWidget);
      expect(h.prefs.getKeys(), isEmpty);
    });
  });
}
