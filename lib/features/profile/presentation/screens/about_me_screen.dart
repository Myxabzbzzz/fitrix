import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Profile tab: the data entered during onboarding.
class AboutMeScreen extends ConsumerWidget {
  const AboutMeScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final account = ref.read(accountServiceProvider);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOutTitle),
        content: Text(
          account == null ? l10n.signOutLocalBody : l10n.signOutAccountBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Grab these before signing out: it recreates the provider scope.
    final router = GoRouter.of(context);
    final session = ref.read(appSessionProvider);
    final sync = ref.read(syncEngineProvider);
    if (sync != null) {
      // Upload workouts/chats not yet on the server; offline, don't block.
      try {
        await sync.sync().timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    if (account != null) {
      // Ends the Supabase session (works offline), then clears local data.
      await account.signOut();
    } else {
      await session.signOut();
    }
    router.go(AppRouter.intro);
  }

  /// Account deletion (App Store / Google Play requirement): two
  /// confirmations, then the server deletes the account and all its data.
  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final account = ref.read(accountServiceProvider);
    if (account == null) return;
    final apple = account.auth.hasAppleSignIn;
    final l10n = AppLocalizations.of(context);

    Future<bool> confirm({
      required String title,
      required String content,
      required String action,
      required Key actionKey,
    }) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              key: actionKey,
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: Text(action),
            ),
          ],
        ),
      );
      return confirmed == true;
    }

    if (!await confirm(
      title: l10n.deleteAccountTitle,
      content: apple
          ? '${l10n.deleteAccountBody}\n\n${l10n.deleteAccountAppleNote}'
          : l10n.deleteAccountBody,
      action: l10n.continueButton,
      actionKey: const Key('delete-account-continue'),
    )) {
      return;
    }
    if (!context.mounted) return;
    if (!await confirm(
      title: l10n.deleteForGoodTitle,
      content: l10n.deleteForGoodBody,
      action: l10n.deleteAccount,
      actionKey: const Key('delete-account-confirm'),
    )) {
      return;
    }
    if (!context.mounted) return;

    // Grab these first: a successful deletion recreates the provider scope.
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final social = ref.read(socialSignInProvider);

    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: 20),
              Expanded(child: Text(l10n.deletingAccount)),
            ],
          ),
        ),
      ),
    ));

    try {
      final deleted = await account.deleteAccount(social: social);
      if (deleted) {
        router.go(AppRouter.intro);
        return;
      }
      navigator.pop(); // Apple's sheet was cancelled: nothing deleted.
    } on AuthFailure catch (failure) {
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.deleteAccountFailed(failure.message)),
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider).valueOrNull;
    final email = ref.watch(accountEmailProvider).valueOrNull;

    final fullName = [profile?.name, profile?.surname]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    Widget stat(String label, String? value, String unit) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: palette.tile,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  value == null || value.isEmpty ? '—' : '$value$unit',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            ScreenTitle(l10n.aboutMeTitle),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: palette.tile,
                child: Icon(Icons.person, size: 48, color: palette.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                fullName.isEmpty ? '@theboss' : fullName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ),
            if (email != null && email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Center(
                child: Text(
                  email,
                  key: const Key('account-email'),
                  style: TextStyle(fontSize: 14, color: palette.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Row(
                children: [
                  stat(l10n.age, profile?.age, ''),
                  const SizedBox(width: 12),
                  stat(l10n.weight, profile?.weight, ' ${l10n.unitKg}'),
                  const SizedBox(width: 12),
                  stat(l10n.height, profile?.height, ' ${l10n.unitCm}'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: OutlinedButton.icon(
                onPressed: () => _signOut(context, ref),
                icon: const Icon(Icons.logout),
                label: Text(l10n.signOut),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: palette.border),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            if (ref.watch(accountServiceProvider) != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  key: const Key('delete-account'),
                  onPressed: () => _deleteAccount(context, ref),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: Text(l10n.deleteAccount),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
