import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/settings/theme_mode_provider.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/auth/presentation/sign_in_prompt.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/language/presentation/screens/language_screen.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/features/profile/domain/streak.dart';
import 'package:fitrix/features/profile/presentation/screens/connected_apps_screen.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
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
            style: TextButton.styleFrom(
                foregroundColor: AppPalette.of(context).danger),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await signOutAndGo(ref, GoRouter.of(context), AppRouter.intro);
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
              style: TextButton.styleFrom(
                  foregroundColor: AppPalette.of(context).danger),
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
    final perf = ref.watch(performanceProfileProvider);

    String dash(String? v) => v == null || v.isEmpty ? '—' : v;
    String levelLabel(String level) => switch (level) {
          'Beginner' => l10n.programLevelBeginner,
          'Intermediate' => l10n.programLevelMedium,
          'Advanced' => l10n.programLevelAdvanced,
          _ => level,
        };
    String goalLabel(String goal) {
      final i = AppConstants.fitnessGoals.indexOf(goal);
      return switch (i) {
        0 => l10n.aboutGoalBuild,
        1 => l10n.aboutGoalEndurance,
        2 => l10n.aboutGoalLose,
        3 => l10n.aboutGoalHealthy,
        4 => l10n.aboutGoalTrack,
        _ => goal,
      };
    }

    final subtitle = [
      if (profile != null && profile.experience.trim().isNotEmpty)
        levelLabel(profile.experience.trim()),
      if (profile != null && profile.goal.trim().isNotEmpty)
        goalLabel(profile.goal.trim()),
    ].join(' · ');
    final selectedSports = [
      for (final s in Sport.values)
        if (profile?.sports
                .any((x) => x.toLowerCase() == s.label.toLowerCase()) ??
            false)
          s,
    ];
    final hrSummary = perf.restingHr != null && perf.maxHr != null
        ? l10n.profileHrZonesSummary(perf.restingHr!, perf.maxHr!)
        : l10n.profileHrZonesSetUp;

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
      String? subtitle,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: AppText.bodyStrong.copyWith(
                              color: color ?? palette.textPrimary,
                            )),
                        if (subtitle != null)
                          Text(subtitle,
                              style: AppText.caption.copyWith(
                                color: palette.textSecondary,
                              )),
                      ],
                    ),
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
      return Semantics(
          button: true,
          selected: selected,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref.read(themeModeProvider.notifier).set(mode),
            child: Container(
              constraints: const BoxConstraints(minHeight: 32, minWidth: 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? palette.background : Colors.transparent,
                borderRadius: AppRadius.smAll,
              ),
              child: Text(label,
                  style: AppText.captionStrong.copyWith(
                    color:
                        selected ? palette.textPrimary : palette.textSecondary,
                  )),
            ),
          ));
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          children: [
            ScreenTitle(
              l10n.profileTitle,
              trailing: IconButton(
                key: const Key('profile-edit'),
                tooltip: l10n.profileEditTooltip,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: palette.textPrimary,
                onPressed: () => context.push(AppRouter.editProfile),
              ),
            ),
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
                        if (subtitle.isNotEmpty)
                          Text(subtitle,
                              key: const Key('profile-subtitle'),
                              style: AppText.caption.copyWith(
                                color: palette.textSecondary,
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
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  stat(dash(weight), l10n.profileWeightLabel),
                  const SizedBox(width: AppSpacing.sm),
                  stat(dash(profile?.height), l10n.profileHeightLabel),
                  const SizedBox(width: AppSpacing.sm),
                  stat(dash(profile?.age), l10n.profileAgeLabel),
                ],
              ),
            ),
            if (selectedSports.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(l10n.profileMySports,
                            style: AppText.headingS
                                .copyWith(color: palette.textPrimary)),
                      ),
                      Text(l10n.profileSportsSelected(selectedSports.length),
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                    ]),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final s in selectedSports)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xxs),
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.fullAll,
                              border: Border.all(color: palette.textPrimary),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.check,
                                  size: 14, color: palette.textPrimary),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(s.localizedLabel(l10n),
                                  style: AppText.captionStrong
                                      .copyWith(color: palette.textPrimary)),
                            ]),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: list([
                row(
                  key: const Key('profile-hr-zones'),
                  icon: Icons.favorite_border,
                  label: l10n.hrZonesTitle,
                  subtitle: hrSummary,
                  trailing: chevron(),
                  onTap: () => context.push(AppRouter.hrZones),
                ),
                row(
                  key: const Key('profile-connected-apps'),
                  icon: Icons.sync,
                  label: l10n.profileConnectedApps,
                  subtitle: l10n.profileConnectedAppsCount(
                      connectedAppsCount, ConnectableApp.values.length),
                  trailing: chevron(),
                  onTap: () => context.push(AppRouter.connectedApps),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(l10n.profileSettings,
                  style: AppText.headingS.copyWith(color: palette.textPrimary)),
            ),
            const SizedBox(height: AppSpacing.xs),
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
                  // The picker screen in settings mode, pushed over the tab bar
                  // (the /language route is redirected away once onboarded).
                  onTap: () {
                    final navigator =
                        Navigator.of(context, rootNavigator: true);
                    navigator.push(MaterialPageRoute(
                      builder: (_) => LanguageScreen(onContinue: navigator.pop),
                    ));
                  },
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
