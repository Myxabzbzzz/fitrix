// Phase 1: first launch -> language -> email code sign-in -> profile ->
// onboarding chat with Felix -> transition -> Home.
//
// Run through tool/e2e/run.sh (needs the host helper, local Supabase and
// the 3100 backend). E2E_EMAIL picks the account.
import 'package:fitrix/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e.dart';
import 'support/l10n.dart';

const email =
    String.fromEnvironment('E2E_EMAIL', defaultValue: 'e2e@fitrix.test');

void main() {
  initBinding();

  testWidgets('onboarding', (t) async {
    await Host.log('=== PHASE 1 onboarding as $email');
    await Host.setLocation(41.3111, 69.2797);
    await Host.videoStart('01_launch_intro');
    app.main();
    captureFlutterErrors();
    await idle(t, const Duration(seconds: 3));

    await step(t, 'intro', () async {
      await waitFor(t, find.byType(ElevatedButton));
    });
    await step(t, 'language', () async {
      // The intro follows the device language, not E2E_LANG.
      await tap(t, find.byType(ElevatedButton).last);
      await waitFor(t, find.text(langLabel));
      await idle(t, const Duration(seconds: 1));
      await tapText(t, langLabel);
    });
    await Host.videoStop();

    await step(t, 'sign_in_email', () async {
      await tapText(t, L.continueButton);
      await waitFor(t, find.byKey(const Key('email-input')));
      await enter(t, find.byKey(const Key('email-input')), email);
    });
    await step(t, 'sign_in_code_step', () async {
      await Host.markMail(email);
      await tapText(t, L.signInGetCode);
      if (!await waitFor(t, find.byKey(const Key('code-input')),
          timeout: const Duration(seconds: 20))) {
        throw StateError('code step never showed');
      }
    });
    await step(t, 'sign_in_code_entered', () async {
      final code = await Host.otp(email);
      await Host.log('got code ${code.length} digits');
      await t.enterText(find.byKey(const Key('code-input')), code);
      await idle(t, const Duration(seconds: 1));
    });
    // onCompleted verifies on the 6th digit; Continue is there if not.
    await idle(t, const Duration(seconds: 4));
    if (find.byKey(const Key('code-input')).evaluate().isNotEmpty &&
        find.text(L.continueButton).evaluate().isNotEmpty) {
      await tapText(t, L.continueButton);
      await idle(t, const Duration(seconds: 4));
    }
    await Host.shot('after_verify');

    await step(t, 'profile_form', () async {
      await waitFor(t, find.byKey(const Key('profile-name')),
          timeout: const Duration(seconds: 20));
      await enter(t, find.byKey(const Key('profile-name')), 'Eli');
      await enter(t, find.byKey(const Key('profile-surname')), 'Tester');
      await enter(t, find.byKey(const Key('profile-age')), '29');
      await enter(t, find.byKey(const Key('profile-weight')), '78');
      await enter(t, find.byKey(const Key('profile-height')), '181');
      FocusManager.instance.primaryFocus?.unfocus();
      await idle(t);
    });
    await step(t, 'chat_open', () async {
      await tapText(t, L.continueButton);
      await waitFor(t, find.text('Build muscle and strength'),
          timeout: const Duration(seconds: 60));
    });

    await Host.videoStart('02_onboarding_chat');
    for (final answer in [
      'Build muscle and strength',
      'Running',
      'A few times a week',
      'Intermediate'
    ]) {
      await step(t, 'chat_${answer.split(' ').first}', () async {
        // Quick replies hide while Felix is replying.
        if (!await waitFor(t, find.text(answer),
            timeout: const Duration(seconds: 150))) {
          throw StateError('quick reply "$answer" never offered');
        }
        await tapText(t, answer);
        await idle(t, const Duration(seconds: 2));
      });
    }
    await step(t, 'chat_done_start', () async {
      if (!await waitFor(t, find.text(L.chatStart),
          timeout: const Duration(seconds: 180))) {
        throw StateError('Start never showed');
      }
    });
    await Host.videoStop();

    await Host.videoStart('03_start_circle_transition');
    await step(t, 'transition', () async {
      await tapText(t, L.chatStart);
      await waitFor(t, find.text('I am ready'),
          timeout: const Duration(seconds: 15));
      await idle(t, const Duration(seconds: 4));
    });
    await step(t, 'home_first', () async {
      await tapText(t, 'I am ready');
      await idle(t, const Duration(seconds: 4));
    });
    await Host.videoStop();
    await idle(t, const Duration(seconds: 2));
    await writeReport('01_onboarding');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
