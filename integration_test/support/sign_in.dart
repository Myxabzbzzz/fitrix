import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'e2e.dart';
import 'l10n.dart';

const email =
    String.fromEnvironment('E2E_EMAIL', defaultValue: 'e2e@fitrix.test');

/// `flutter test` installs the app fresh each run, so every phase starts
/// like a reinstall: intro -> language -> email code -> the account's data
/// comes back from the (local) cloud and the app lands on Home.
Future<void> signInExisting(WidgetTester t, {String prefix = ''}) async {
  await step(t, '${prefix}reinstall_intro', () async {
    // Still signed in (the app survived the last run): nothing to do.
    await idle(t, const Duration(seconds: 2));
    if (find.byKey(const Key('home-today-card')).evaluate().isNotEmpty) return;
    if (!await waitFor(t, find.byType(ElevatedButton),
        timeout: const Duration(seconds: 15))) {
      throw StateError('intro not shown');
    }
    // The intro follows the device language, not E2E_LANG.
    await tap(t, find.byType(ElevatedButton).last);
    await tapText(t, langLabel);
    await tapText(t, L.continueButton);
    await enter(t, find.byKey(const Key('email-input')), email);
    await Host.markMail(email);
    await tapText(t, L.signInGetCode);
    if (!await waitFor(t, find.byKey(const Key('code-input')))) {
      throw StateError('code step never showed');
    }
    final code = await Host.otp(email);
    await t.enterText(find.byKey(const Key('code-input')), code);
    await idle(t, const Duration(seconds: 3));
  });
  await step(t, '${prefix}signed_in_home', () async {
    if (!await waitFor(t, find.byKey(const Key('home-today-card')),
        timeout: const Duration(seconds: 30))) {
      throw StateError(
          'Home not reached after sign-in of an onboarded account');
    }
    await idle(t, const Duration(seconds: 3));
  });
}
