import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/sync_engine.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// How long the guard waits for a sync before counting what is left.
const _guardSyncTimeout = Duration(seconds: 5);

/// Tries to upload everything (bounded), then returns how many local
/// changes are still not on the server.
Future<int> pendingAfterSync(SyncEngine? sync) async {
  if (sync == null) return 0;
  try {
    await sync.sync().timeout(_guardSyncTimeout);
  } catch (_) {}
  return sync.pendingCount();
}

/// Asks before signing out. Signed in, it first syncs (a spinner shows
/// meanwhile) and warns if changes still haven't reached the account, since
/// signing out deletes them. With [onlyIfPending] the dialog is skipped
/// when nothing would be lost. Returns whether to go ahead.
Future<bool> confirmSignOut(
  BuildContext context,
  WidgetRef ref, {
  bool onlyIfPending = false,
}) async {
  final account = ref.read(accountServiceProvider);
  final sync = ref.read(syncEngineProvider);
  final l10n = AppLocalizations.of(context);
  final danger = AppPalette.of(context).danger;
  var pending = 0;
  if (account != null && sync != null) {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    pending = await pendingAfterSync(sync);
    navigator.pop();
  }
  if (onlyIfPending && pending == 0) return true;
  if (!context.mounted) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.signOutTitle),
      content: Text(
        account == null
            ? l10n.signOutLocalBody
            : pending > 0
                ? l10n.signOutPendingBody(pending)
                : l10n.signOutAccountBody,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: danger),
          child: Text(pending > 0 ? l10n.signOutAnyway : l10n.signOut),
        ),
      ],
    ),
  );
  return confirmed == true;
}

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
            onPressed: () async {
              // The session was rejected, so a sync can't succeed: warn
              // when that leaves unsent changes behind.
              if (context.mounted &&
                  !await confirmSignOut(context, ref, onlyIfPending: true)) {
                return;
              }
              await signOutAndGo(ref, router, AppRouter.signIn);
            },
          )
        : null,
  ));
}
