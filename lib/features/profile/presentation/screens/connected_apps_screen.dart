import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The apps FITRIX plans to read from. None can be connected yet, so every
/// one is "Not connected" and Connect only explains that.
enum ConnectableApp {
  appleHealth('Apple Health', 'apple-health', Icons.favorite_border),
  garmin('Garmin Connect', 'garmin', Icons.watch_outlined),
  strava('Strava', 'strava', Icons.directions_run),
  whoop('WHOOP', 'whoop', Icons.monitor_heart_outlined);

  const ConnectableApp(this.title, this.slug, this.icon);

  /// Brand name, not translated.
  final String title;
  final String slug;
  final IconData icon;

  String description(AppLocalizations l10n) => switch (this) {
        appleHealth => l10n.connectedAppsAppleDesc,
        garmin => l10n.connectedAppsGarminDesc,
        strava => l10n.connectedAppsStravaDesc,
        whoop => l10n.connectedAppsWhoopDesc,
      };
}

/// How many apps are connected (none until connecting is built).
const connectedAppsCount = 0;

class ConnectedAppsScreen extends StatelessWidget {
  const ConnectedAppsScreen({super.key});

  void _openSheet(BuildContext context, ConnectableApp app) {
    final palette = AppPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: palette.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => _ConnectSheet(app: app),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenTitle(l10n.connectedAppsTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.tile,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.connectedAppsWhyHeader,
                            style: AppText.microStrong
                                .copyWith(color: palette.accent)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(l10n.connectedAppsWhyBody,
                            style: AppText.bodyRegular
                                .copyWith(color: palette.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final app in ConnectableApp.values) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: palette.tile,
                        borderRadius: AppRadius.mdAll,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.background,
                              borderRadius: AppRadius.smAll,
                            ),
                            child:
                                Icon(app.icon, size: 24, color: palette.accent),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(app.title,
                                    style: AppText.headingS
                                        .copyWith(color: palette.textPrimary)),
                                Text(l10n.connectedAppsNotConnected,
                                    style: AppText.caption.copyWith(
                                        color: palette.textSecondary)),
                                Text(app.description(l10n),
                                    style: AppText.caption.copyWith(
                                        color: palette.textSecondary)),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppButton(
                            key: Key('connect-${app.slug}'),
                            label: l10n.connectedAppsConnect,
                            size: AppButtonSize.small,
                            onPressed: () => _openSheet(context, app),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.connectedAppsFooter,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectSheet extends StatelessWidget {
  const _ConnectSheet({required this.app});

  final ConnectableApp app;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(app.icon, size: 24, color: palette.onAccent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.connectedAppsSheetTitle(app.title),
                        style: AppText.headingM
                            .copyWith(color: palette.textPrimary)),
                    Text(l10n.connectedAppsSheetSubtitle,
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.connectedAppsClose,
                icon: Icon(Icons.close, color: palette.accent),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(app.description(l10n),
              style: AppText.bodyStrong.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: palette.accentSoft,
              borderRadius: AppRadius.mdAll,
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 20, color: palette.textPrimary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(l10n.connectedAppsSheetPrivacy,
                      style: AppText.bodyRegular
                          .copyWith(color: palette.textPrimary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.connectedAppsSheetSoon,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            key: const Key('connect-coming-soon'),
            label: l10n.connectedAppsComingSoon,
            size: AppButtonSize.large,
            expand: true,
            onPressed: null,
          ),
        ],
      ),
    );
  }
}
