// Phase 4: data restored on a fresh install, Felix hub + chat (3100
// backend -> local Ollama), Discover/Shop/Map, Profile edit, HR zones,
// sign out -> sign in again, Connected apps -> Apple Health (native
// HealthKit sheet; last, since a test can't tap native UI).
import 'package:fitrix/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/e2e.dart';
import 'support/l10n.dart';
import 'support/sign_in.dart';

void main() {
  initBinding();

  testWidgets('felix, profile, sign out/in, health', (t) async {
    await Host.log('=== PHASE 4 felix/profile');
    app.main();
    captureFlutterErrors();
    await idle(t, const Duration(seconds: 3));
    await signInExisting(t);

    // Synced data back after a reinstall?
    await step(t, 'restored_progress', () async {
      await scrollTo(t, ftext(L.homeTileProgress));
      await tap(t, ftext(L.homeTileProgress));
      await idle(t, const Duration(seconds: 3));
    });
    await goHome(t);
    await step(t, 'restored_plan', () async {
      await scrollTap(t, find.byKey(const Key('home-today-card')));
      await idle(t, const Duration(seconds: 2));
    });
    await back(t);

    // ---- Felix
    await Host.videoStart('16_felix');
    await step(t, 'felix_hub', () async {
      await tap(t, find.byKey(const ValueKey('felix-ring')), scroll: false);
      await idle(t, const Duration(seconds: 2));
    });
    await step(t, 'felix_hub_scrolled', () async {
      await t.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await idle(t, const Duration(seconds: 1));
    });
    await step(t, 'felix_running_chat', () async {
      await scrollTap(t, find.byKey(const ValueKey('topic-row-running')));
      await idle(t, const Duration(seconds: 2));
    });
    await step(t, 'felix_sent', () async {
      final input = find.descendant(
          of: find.byKey(const ValueKey('chat-composer')),
          matching: find.byType(TextField));
      await enter(t, input, 'Как мне улучшить темп на 5 км?');
      await tap(t, find.byIcon(Icons.arrow_circle_up), scroll: false);
      await idle(t, const Duration(seconds: 3));
    });
    await Host.videoStop();
    await step(t, 'felix_reply', () async {
      // Quick replies come back when Felix stops replying.
      final end = DateTime.now().add(const Duration(seconds: 150));
      while (DateTime.now().isBefore(end)) {
        await idle(t, const Duration(seconds: 3));
        final input = find.descendant(
            of: find.byKey(const ValueKey('chat-composer')),
            matching: find.byType(TextField));
        if (input.evaluate().isNotEmpty &&
            t.widget<TextField>(input.first).enabled != false) break;
      }
      await idle(t, const Duration(seconds: 2));
    });
    await step(t, 'felix_all_chats', () async {
      await back(t);
      await idle(t, const Duration(seconds: 1));
      final all = find.text(L.felixHubSeeAll);
      if (all.evaluate().isNotEmpty) await scrollTap(t, all);
      await idle(t, const Duration(seconds: 1));
    });
    await backUntil(t, find.byKey(const ValueKey('felix-today-line')), n: 2);

    // ---- Discover, Shop, Map
    await step(t, 'discover', () async {
      await goTab(t, Icons.explore_outlined, Icons.explore);
      await idle(t, const Duration(seconds: 3));
    });
    await step(t, 'shop', () async {
      await goTab(t, Icons.shopping_cart_outlined, Icons.shopping_cart);
      await idle(t, const Duration(seconds: 3));
    });
    await step(t, 'shop_cart_added', () async {
      await tap(t, keyPrefix('add-').first);
      await idle(t, const Duration(seconds: 1));
    });
    await step(t, 'map', () async {
      await goHome(t);
      await scrollTap(t, ftext(L.homeTileMap));
      await idle(t, const Duration(seconds: 5));
    });
    await goHome(t);

    // ---- Profile
    await step(t, 'profile_tab', () async {
      await goTab(t, Icons.person_outline, Icons.person);
      await idle(t, const Duration(seconds: 2));
    });
    await step(t, 'profile_edit', () async {
      await scrollTap(t, find.byKey(const Key('profile-edit')));
      await idle(t, const Duration(seconds: 2));
    });
    await step(t, 'profile_edit_changed', () async {
      await enter(t, find.byKey(const Key('edit-weight')), '79');
      FocusManager.instance.primaryFocus?.unfocus();
      await idle(t);
    });
    await step(t, 'profile_edit_saved', () async {
      await scrollTap(t, find.byKey(const Key('edit-save')));
      await idle(t, const Duration(seconds: 2));
    });
    await step(t, 'hr_zones', () async {
      await scrollTap(t, find.byKey(const Key('profile-hr-zones')));
      await idle(t, const Duration(seconds: 2));
    });
    await back(t);
    await step(t, 'about_me', () async {
      await scrollTap(t, find.byKey(const Key('profile-about-me')));
      await idle(t, const Duration(seconds: 2));
    });
    await back(t);

    // ---- Sign out, sign in again
    await step(t, 'sign_out_dialog', () async {
      await scrollTap(t, find.byKey(const Key('sign-out')));
      await idle(t, const Duration(seconds: 1));
    });
    await step(t, 'signed_out', () async {
      final dialog = find.byType(AlertDialog);
      if (dialog.evaluate().isNotEmpty) {
        await tap(t,
            find.descendant(of: dialog, matching: find.byType(TextButton)).last,
            scroll: false);
      }
      await idle(t, const Duration(seconds: 3));
    });
    await signInExisting(t, prefix: 'again_');
    await step(t, 'again_profile', () async {
      await goTab(t, Icons.person_outline, Icons.person);
      await idle(t, const Duration(seconds: 2));
    });

    // ---- Connected apps -> Apple Health (native sheet ends the walk)
    await step(t, 'connected_apps', () async {
      await scrollTap(t, find.byKey(const Key('profile-connected-apps')));
      await idle(t, const Duration(seconds: 2));
    });
    await writeReport('04_felix_profile');
    await step(t, 'health_connect_tapped', () async {
      await tapText(t, L.connectedAppsConnect);
      await idle(t, const Duration(seconds: 4));
    });
    await step(t, 'health_after_8s', () async {
      await idle(t, const Duration(seconds: 8));
    });
    await writeReport('04_felix_profile');
  }, timeout: const Timeout(Duration(minutes: 20)));
}
