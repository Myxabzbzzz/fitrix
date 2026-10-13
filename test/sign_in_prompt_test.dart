import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/main.dart';

import 'support/fake_auth.dart';

String get _path =>
    AppRouter.router.routerDelegate.currentConfiguration.uri.path;

/// The real app and router, onboarded and signed in as [signedIn], with
/// fake accounts, or without any accounts at all.
Future<(SharedPreferences, FakeAuthGateway?)> _pump(
  WidgetTester tester, {
  required bool accounts,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'onboarding_complete': true,
    if (accounts) 'account_user_id': 'user-1',
    ...prefs,
  });
  final storage = await SharedPreferences.getInstance();
  final session = AppSession(storage);
  FakeAuthGateway? auth;
  AccountService? account;
  if (accounts) {
    auth = FakeAuthGateway(users: {'a@x.com': 'user-1'})..signInAs('a@x.com');
    account = AccountService(
      prefs: storage,
      session: session,
      auth: auth,
      remote: FakeProfileRemote(),
    )..start();
    addTearDown(account.dispose);
  }
  await tester.pumpWidget(FitrixRoot(
    prefs: storage,
    session: session,
    router: AppRouter.create(session, auth: auth),
    auth: auth,
    account: account,
  ));
  await tester.pumpAndSettle();
  AppRouter.router.go(AppRouter.discover);
  // The bundled seed content loads through real I/O.
  for (var i = 0;
      i < 10 && find.text('Join challenge').evaluate().isEmpty;
      i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 500));
  }
  return (storage, auth);
}

void main() {
  testWidgets('Sign in on the prompt signs out and shows the sign-in screen',
      (tester) async {
    final (prefs, auth) =
        await _pump(tester, accounts: true, prefs: {'theme_mode': 'dark'});
    expect(_path, AppRouter.discover);

    await tester.tap(find.text('Join challenge').first);
    await tester.pumpAndSettle();
    expect(find.text('Sign in to join challenges'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(auth!.signOutCalls, 1);
    expect(_path, AppRouter.signIn);
    expect(find.byKey(const Key('email-input')), findsOneWidget);
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
