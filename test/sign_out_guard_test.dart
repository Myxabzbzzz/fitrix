import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/core/sync/sync_state.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/auth/presentation/sign_in_prompt.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/fake_auth.dart';
import 'support/in_memory_remote_store.dart';

/// A server that is never reachable.
class _DownRemote extends InMemoryRemoteStore {
  @override
  Future<List<RemotePlan>> fetchPlans(String userId, {DateTime? since}) =>
      throw const SocketException('offline');
}

Future<ProviderContainer> _open(
  WidgetTester tester,
  InMemoryRemoteStore remote, {
  required bool pendingDoc,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  if (pendingDoc) {
    SyncState(owner: 'u1', docTombstones: {'food/a': 1}).save(prefs);
  }
  final session = AppSession(prefs);
  final auth = FakeAuthGateway(users: {'a@x.com': 'u1'})..signInAs('a@x.com');
  final account = AccountService(
    prefs: prefs,
    session: session,
    auth: auth,
    remote: FakeProfileRemote(),
  );
  addTearDown(account.dispose);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    remoteStoreProvider.overrideWithValue(remote),
    syncUserIdProvider.overrideWithValue('u1'),
    accountServiceProvider.overrideWithValue(account),
  ]);
  container.read(syncEngineProvider);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => confirmSignOut(context, ref),
          child: const Text('go'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('go'));
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pumpAndSettle();
  return container;
}

Future<void> _end(WidgetTester tester, ProviderContainer c) async {
  await tester.pumpWidget(const SizedBox());
  c.dispose(); // cancels the engine's timers
}

void main() {
  testWidgets('unsynced changes: the dialog warns and offers Sign out anyway',
      (tester) async {
    final c = await _open(tester, _DownRemote(), pendingDoc: true);
    expect(find.textContaining("haven't reached your account"), findsOneWidget);
    expect(find.text('Sign out anyway'), findsOneWidget);
    expect(find.textContaining('saved to your account'), findsNothing);
    await _end(tester, c);
  });

  testWidgets('everything synced: the normal text', (tester) async {
    final c = await _open(tester, InMemoryRemoteStore(), pendingDoc: false);
    expect(find.textContaining('saved to your account'), findsOneWidget);
    expect(find.text('Sign out anyway'), findsNothing);
    expect(find.widgetWithText(TextButton, 'Sign out'), findsOneWidget);
    await _end(tester, c);
  });
}
