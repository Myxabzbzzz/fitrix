import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Signs out the way the Profile tab does: uploads what is not on the server
/// yet (offline, don't block), ends the session and clears local data, then
/// goes to [destination]. Everything is read from [ref] before the first
/// await because signing out recreates the provider scope.
Future<void> signOutAndGo(
  WidgetRef ref,
  GoRouter router,
  String destination,
) async {
  final account = ref.read(accountServiceProvider);
  final session = ref.read(appSessionProvider);
  final sync = ref.read(syncEngineProvider);
  if (sync != null) {
    try {
      await sync.sync().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
  if (account != null) {
    await account.signOut();
  } else {
    await session.signOut();
  }
  router.go(destination);
}

/// Tells the user that [message] needs an account. With accounts on, the
/// "Sign in" action signs out (the session is missing or rejected) and lands
/// on the sign-in screen; with accounts off there is nothing to sign in to,
/// so the user only hears that accounts are unavailable.
void showSignInPrompt(BuildContext context, WidgetRef ref, String message) {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);
  final accountsOn = ref.read(accountServiceProvider) != null;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(accountsOn ? message : l10n.signInUnavailable),
    action: accountsOn
        ? SnackBarAction(
            label: l10n.discoverSignIn,
            onPressed: () => signOutAndGo(ref, router, AppRouter.signIn),
          )
        : null,
  ));
}
