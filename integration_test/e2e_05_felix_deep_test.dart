// Phase 5: Felix for real (3100 backend -> local Ollama): a full reply,
// leaving mid-reply and coming back, the "I ate..." food action applied to
// Nutrition, and the error path with the backend stopped. Also HR zones.
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_composer.dart';
import 'package:fitrix/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e.dart';
import 'support/l10n.dart';
import 'support/sign_in.dart';

Finder get _input => find.descendant(
    of: find.byKey(const ValueKey('chat-composer')),
    matching: find.byType(TextField));

Future<void> send(WidgetTester t, String text) async {
  await enter(t, _input, text);
  await tap(t, find.byIcon(Icons.arrow_circle_up), scroll: false);
  await idle(t, const Duration(seconds: 2));
}

/// Waits until Felix stops typing; returns the seconds it took.
Future<int> waitReply(WidgetTester t, {int maxSeconds = 180}) async {
  final start = DateTime.now();
  await idle(t, const Duration(seconds: 2));
  while (DateTime.now().difference(start).inSeconds < maxSeconds) {
    await idle(t, const Duration(seconds: 2));
    final composer = find.byType(ChatComposer);
    if (composer.evaluate().isNotEmpty &&
        t.widget<ChatComposer>(composer.first).enabled) {
      break;
    }
  }
  return DateTime.now().difference(start).inSeconds;
}

Future<void> openTopic(WidgetTester t, String id) async {
  await goTab(t, Icons.home_outlined, Icons.home);
  await tap(t, find.byKey(const ValueKey('felix-ring')), scroll: false);
  await idle(t, const Duration(seconds: 2));
  await scrollTap(t, find.byKey(ValueKey('topic-row-$id')));
  await idle(t, const Duration(seconds: 2));
}

void main() {
  initBinding();

  testWidgets('felix deep', (t) async {
    await Host.log('=== PHASE 5 felix deep');
    app.main();
    captureFlutterErrors();
    await idle(t, const Duration(seconds: 3));
    await signInExisting(t);

    if (want('reply')) {
      await step(t, 'felix5_running_open', () => openTopic(t, 'running'));
      await Host.videoStart('17_felix_stream');
      await step(t, 'felix5_reply_full', () async {
        await send(t, 'Сколько раз в неделю бегать, чтобы улучшить 5 км?');
        final s = await waitReply(t);
        await Host.log('felix reply took ${s}s');
      });
      await Host.videoStop();
      await step(t, 'felix5_leave_mid_reply', () async {
        await send(t, 'А какой темп для длинной пробежки?');
        await idle(t, const Duration(seconds: 3));
        await back(t);
        await idle(t, const Duration(seconds: 60));
      });
      await step(t, 'felix5_back_after_60s', () async {
        await scrollTap(t, find.byKey(const ValueKey('topic-row-running')));
        await idle(t, const Duration(seconds: 3));
        final s = await waitReply(t, maxSeconds: 120);
        await Host.log('after return waited ${s}s');
      });
    }

    if (want('food')) {
      await step(t, 'felix5_nutrition_open', () => openTopic(t, 'nutrition'));
      await step(t, 'felix5_food_action', () async {
        await send(t, 'Я съел на завтрак два яйца и кусок хлеба');
        final s = await waitReply(t);
        await Host.log('food reply took ${s}s');
        await t.drag(mainScrollable(), const Offset(0, -3000));
        await idle(t, const Duration(seconds: 2));
      });
      await step(t, 'felix5_food_applied', () async {
        final card = find.byKey(const ValueKey('chat-action-card'));
        if (!await waitFor(t, card, timeout: const Duration(seconds: 5))) {
          throw StateError('no action card for a food log message');
        }
        await t.ensureVisible(card.last);
        await tap(
            t,
            find
                .descendant(of: card.last, matching: find.byType(AppButton))
                .last,
            scroll: false);
        await idle(t, const Duration(seconds: 3));
      });
      await step(t, 'felix5_nutrition_after_action', () async {
        await goHome(t);
        await scrollTap(t, ftext(L.homeTileNutrition));
        await idle(t, const Duration(seconds: 3));
      });
    }

    if (want('error')) {
      await step(t, 'felix5_error_open', () async {
        await backend('stop');
        await openTopic(t, 'gym');
      });
      await step(t, 'felix5_error_sent', () async {
        await send(t, 'Привет, ты тут?');
        await idle(t, const Duration(seconds: 15));
      });
      await step(t, 'felix5_error_after_30s', () async {
        await idle(t, const Duration(seconds: 15));
        await t.drag(mainScrollable(), const Offset(0, -3000));
        await idle(t, const Duration(seconds: 1));
        // The question is marked, nothing was made up in Felix's place.
        if (find.text(L.chatFailedUnavailable).evaluate().isEmpty) {
          throw StateError('no "Felix is unavailable" mark');
        }
      });
      await backend('start');
      await step(t, 'felix5_retry_after_backend_back', () async {
        await idle(t, const Duration(seconds: 3));
        await tapKey(t, 'chat-retry');
        final s = await waitReply(t, maxSeconds: 120);
        await Host.log('retry reply took ${s}s');
      });
    }

    if (want('zones')) {
      await step(t, 'hr_zones', () async {
        await goTab(t, Icons.person_outline, Icons.person);
        await scrollTap(t, ftext(L.hrZonesTitle));
        await idle(t, const Duration(seconds: 2));
      });
    }
    await writeReport('05_felix_deep');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
