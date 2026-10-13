import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/settings/theme_mode_provider.dart';
import 'package:fitrix/core/sync/sync_providers.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/language/presentation/screens/language_screen.dart';
import 'package:fitrix/features/profile/domain/streak.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Profile tab: identity, stats, settings, and the account actions.
class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

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
    final history = ref.watch(workoutHistoryProvider);
    final themeMode = ref.watch(themeModeProvider);
    final language = ref.watch(selectedLanguageProvider);
    final hasAccount = ref.watch(accountServiceProvider) != null;

    final fullName = [profile?.name, profile?.surname]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    final displayName = fullName.isEmpty ? '@theboss' : fullName;
    final initial = displayName.characters.first.toUpperCase();
    final streak = currentStreak(
      [for (final w in history) w.finishedAt],
      DateTime.now(),
    );
    final weight = profile?.weight;

    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: palette.tile,
              borderRadius: AppRadius.mdAll,
            ),
            child: Column(
              children: [
                Text(value,
                    style: AppText.headingL.copyWith(
                      color: palette.textPrimary,
                    )),
                const SizedBox(height: AppSpacing.xxs),
                Text(label,
                    style: AppText.caption.copyWith(
                      color: palette.textSecondary,
                    )),
              ],
            ),
          ),
        );

    Widget row({
      Key? key,
      required IconData icon,
      required String label,
      Color? color,
      Widget? trailing,
      VoidCallback? onTap,
    }) =>
        InkWell(
          key: key,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: color ?? palette.textPrimary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(label,
                        style: AppText.bodyStrong.copyWith(
                          color: color ?? palette.textPrimary,
                        )),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        );

    Widget list(List<Widget> rows) => Container(
          decoration: BoxDecoration(
            color: palette.tile,
            borderRadius: AppRadius.mdAll,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: rows),
        );

    Widget chevron() =>
        Icon(Icons.chevron_right, size: 20, color: palette.textSecondary);

    Widget seg(String label, ThemeMode mode) {
      final selected = themeMode == mode;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(themeModeProvider.notifier).set(mode),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.background : Colors.transparent,
            borderRadius: AppRadius.smAll,
          ),
          child: Text(label,
              style: AppText.captionStrong.copyWith(
                color: selected ? palette.textPrimary : palette.textSecondary,
              )),
        ),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            ScreenTitle(l10n.profileTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.tile,
                      shape: BoxShape.circle,
                    ),
                    child: Text(initial,
                        style: AppText.displayMedium.copyWith(
                          color: palette.accent,
                        )),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: AppText.headingM.copyWith(
                              color: palette.textPrimary,
                            )),
                        if (email != null && email.isNotEmpty)
                          Text(email,
                              key: const Key('account-email'),
                              style: AppText.caption.copyWith(
                                color: palette.textSecondary,
                              )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  stat('${history.length}', l10n.profileWorkouts),
                  const SizedBox(width: AppSpacing.sm),
                  stat('$streak', l10n.profileDayStreak),
                  const SizedBox(width: AppSpacing.sm),
                  stat(weight == null || weight.isEmpty ? '—' : weight,
                      l10n.profileKgNow),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: list([
                row(
                  key: const Key('profile-about-me'),
                  icon: Icons.person_outline,
                  label: l10n.aboutMeTitle,
                  trailing: chevron(),
                  onTap: () => context.push(AppRouter.aboutMe),
                ),
                row(
                  key: const Key('profile-language'),
                  icon: Icons.language,
                  label: l10n.profileLanguage,
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(AppConstants.languages[language] ?? language,
                        style: AppText.caption.copyWith(
                          color: palette.textSecondary,
                        )),
                    chevron(),
                  ]),
                  // The picker screen itself, pushed directly: the
                  // /language route is redirected away once onboarded.
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const LanguageScreen(),
                  )),
                ),
                row(
                  icon: Icons.dark_mode_outlined,
                  label: l10n.profileTheme,
                  trailing: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxs / 2),
                    decoration: BoxDecoration(
                      color: palette.buttonMuted,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      seg(l10n.profileThemeAuto, ThemeMode.system),
                      seg(l10n.profileThemeLight, ThemeMode.light),
                      seg(l10n.profileThemeDark, ThemeMode.dark),
                    ]),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: list([
                row(
                  key: const Key('sign-out'),
                  icon: Icons.logout,
                  label: l10n.signOut,
                  color: palette.danger,
                  onTap: () => _signOut(context, ref),
                ),
                if (hasAccount)
                  row(
                    key: const Key('delete-account'),
                    icon: Icons.delete_outline,
                    label: l10n.deleteAccount,
                    color: palette.danger,
                    onTap: () => _deleteAccount(context, ref),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
