import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/widgets/sheet_safe_area.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The apps FITRIX shows. Apple Health (iOS) or Health Connect (Android) can
/// be connected; the others only explain how to send their data there.
enum ConnectableApp {
  appleHealth('Apple Health', 'apple-health', Icons.favorite_border),
  healthConnect('Health Connect', 'health-connect', Icons.favorite_border),
  garmin('Garmin Connect', 'garmin', Icons.watch_outlined),
  strava('Strava', 'strava', Icons.directions_run),
  whoop('WHOOP', 'whoop', Icons.monitor_heart_outlined);

  const ConnectableApp(this.title, this.slug, this.icon);

  /// Brand name, not translated.
  final String title;
  final String slug;
  final IconData icon;

  bool get isHealth => this == appleHealth || this == healthConnect;

  String description(AppLocalizations l10n) => switch (this) {
        appleHealth || healthConnect => l10n.connectedAppsHealthDesc,
        garmin => l10n.connectedAppsGarminDesc,
        strava => l10n.connectedAppsStravaDesc,
        whoop => l10n.connectedAppsWhoopDesc,
      };
}

/// The tiles shown on this phone: its health store first, then the rest.
List<ConnectableApp> connectableApps(HealthPlatform platform) => [
      platform == HealthPlatform.appleHealth
          ? ConnectableApp.appleHealth
          : ConnectableApp.healthConnect,
      ConnectableApp.garmin,
      ConnectableApp.strava,
      ConnectableApp.whoop,
    ];

final connectableAppsProvider = Provider<List<ConnectableApp>>(
    (ref) => connectableApps(ref.watch(healthSourceProvider).platform));

/// How many apps are connected.
final connectedAppsCountProvider = Provider<int>(
    (ref) => ref.watch(healthConnectionProvider).connected ? 1 : 0);

int connectedAppsCount(WidgetRef ref) => ref.watch(connectedAppsCountProvider);

class ConnectedAppsScreen extends ConsumerWidget {
  const ConnectedAppsScreen({super.key});

  void _openSheet(BuildContext context, ConnectableApp app, String health) {
    showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => _ConnectSheet(app: app, health: health),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final apps = ref.watch(connectableAppsProvider);
    final health = apps.first.title;

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
                        Text(
                            apps.first == ConnectableApp.healthConnect
                                ? l10n.connectedAppsWhyBodyAndroid(health)
                                : l10n.connectedAppsWhyBody(health),
                            style: AppText.bodyRegular
                                .copyWith(color: palette.textPrimary)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(l10n.connectedAppsPrivacy,
                            style: AppText.bodyRegular
                                .copyWith(color: palette.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final app in apps) ...[
                    app.isHealth
                        ? _HealthTile(app: app)
                        : _OtherTile(
                            app: app,
                            onConnect: () => _openSheet(context, app, health)),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(l10n.connectedAppsDeleteHelp(health),
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary)),
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

class _AppIcon extends StatelessWidget {
  const _AppIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppRadius.smAll,
      ),
      child: Icon(icon, size: 24, color: palette.accent),
    );
  }
}

class _OtherTile extends StatelessWidget {
  const _OtherTile({required this.app, required this.onConnect});

  final ConnectableApp app;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          _AppIcon(app.icon),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.title,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                Text(l10n.connectedAppsNotConnected,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
                Text(app.description(l10n),
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppButton(
            key: Key('connect-${app.slug}'),
            label: l10n.connectedAppsConnect,
            size: AppButtonSize.small,
            onPressed: onConnect,
          ),
        ],
      ),
    );
  }
}

/// Apple Health / Health Connect: the one tile that really connects.
class _HealthTile extends ConsumerStatefulWidget {
  const _HealthTile({required this.app});

  final ConnectableApp app;

  @override
  ConsumerState<_HealthTile> createState() => _HealthTileState();
}

class _HealthTileState extends ConsumerState<_HealthTile> {
  bool _busy = false;
  bool _justDisconnected = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the Play Store: Health Connect may be installed now.
    _lifecycle = AppLifecycleListener(
        onResume: () => ref.invalidate(healthAvailabilityProvider));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  bool get _android => widget.app == ConnectableApp.healthConnect;

  Future<void> _connect() async {
    final l10n = AppLocalizations.of(context);
    final denied = _android
        ? l10n.connectedAppsDeniedAndroid
        : l10n.connectedAppsDeniedIos;
    setState(() => _busy = true);
    final ok = await ref.read(healthConnectionProvider.notifier).connect();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _justDisconnected = false;
    });
    if (!ok) showAppSnack(context, denied);
  }

  Future<void> _disconnect() async {
    await ref.read(healthConnectionProvider.notifier).disconnect();
    if (mounted) setState(() => _justDisconnected = true);
  }

  String _time(BuildContext context, DateTime at) {
    final locale = Localizations.localeOf(context).toString();
    final now = ref.read(clockProvider)();
    final today =
        at.year == now.year && at.month == now.month && at.day == now.day;
    return today
        ? DateFormat.Hm(locale).format(at)
        : DateFormat('d MMM, HH:mm', locale).format(at);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final conn = ref.watch(healthConnectionProvider);
    final app = widget.app;
    final caption = AppText.caption.copyWith(color: palette.textSecondary);

    // Health Connect may be missing; Apple Health is always there.
    final availability = _android && !conn.connected
        ? ref.watch(healthAvailabilityProvider).valueOrNull
        : HealthAvailability.available;

    final String status;
    if (conn.connected) {
      status = l10n.connectedAppsConnected;
    } else {
      status = switch (availability) {
        HealthAvailability.notInstalled => l10n.connectedAppsNotInstalled,
        HealthAvailability.needsUpdate => l10n.connectedAppsNeedsUpdate,
        HealthAvailability.unsupported => l10n.connectedAppsUnavailable,
        _ => l10n.connectedAppsNotConnected,
      };
    }

    Widget? action;
    if (!conn.connected) {
      action = switch (availability) {
        HealthAvailability.notInstalled ||
        HealthAvailability.needsUpdate =>
          AppButton(
            key: const Key('health-install'),
            label: availability == HealthAvailability.needsUpdate
                ? l10n.connectedAppsUpdate
                : l10n.connectedAppsInstall,
            size: AppButtonSize.small,
            onPressed: () => ref.read(healthSourceProvider).openInstall(),
          ),
        HealthAvailability.unsupported => null,
        _ => AppButton(
            key: Key('connect-${app.slug}'),
            label: l10n.connectedAppsConnect,
            size: AppButtonSize.small,
            onPressed: _busy ? null : _connect,
          ),
      };
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AppIcon(app.icon),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.title,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                    Text(status,
                        style: caption.copyWith(
                            color: conn.connected ? palette.accent : null)),
                    if (conn.connected)
                      Text(
                          conn.lastReadAt == null
                              ? l10n.connectedAppsReading
                              : l10n.connectedAppsLastRead(
                                  _time(context, conn.lastReadAt!)),
                          style: caption)
                    else
                      Text(app.description(l10n), style: caption),
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: AppSpacing.xs),
                action,
              ],
            ],
          ),
          if (conn.connected) ...[
            const SizedBox(height: AppSpacing.sm),
            _HealthSummaryBlock(app: app, android: _android),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.connectedAppsWriteWorkouts(app.title),
                      style: AppText.bodyRegular
                          .copyWith(color: palette.textPrimary)),
                ),
                Switch(
                  key: const Key('health-write-toggle'),
                  value: conn.writeWorkouts,
                  onChanged: (v) => ref
                      .read(healthConnectionProvider.notifier)
                      .setWriteWorkouts(v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(
                key: const Key('health-disconnect'),
                label: l10n.connectedAppsDisconnect,
                style: AppButtonStyle.secondary,
                size: AppButtonSize.small,
                onPressed: _disconnect,
              ),
            ),
          ] else if (_justDisconnected) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
                _android
                    ? l10n.connectedAppsDisconnectedAndroid
                    : l10n.connectedAppsDisconnectedIos,
                style: caption),
          ],
        ],
      ),
    );
  }
}

/// The last 7 days of what came from / went to Health: label on the left,
/// a plain number on the right.
class _HealthSummaryBlock extends ConsumerWidget {
  const _HealthSummaryBlock({required this.app, required this.android});

  final ConnectableApp app;
  final bool android;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sum = ref.watch(healthSummaryProvider);
    if (sum == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final caption = AppText.caption.copyWith(color: palette.textSecondary);
    final rows = [
      (l10n.connectedAppsSummarySteps, sum.stepsDays),
      (l10n.connectedAppsSummarySleep, sum.sleepNights),
      (l10n.connectedAppsSummaryRhr, sum.restingHrDays),
      (l10n.connectedAppsSummaryHrv, sum.hrvDays),
      (l10n.connectedAppsSummaryWeight(app.title), sum.weighIns),
      (l10n.connectedAppsSummaryImported(app.title), sum.workoutsImported),
      (l10n.connectedAppsSummaryWritten(app.title), sum.workoutsWritten),
    ];
    return Column(
      key: const Key('health-summary'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.connectedAppsSummaryTitle(app.title),
            style: AppText.bodyStrong.copyWith(color: palette.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(r.$1, style: caption)),
                const SizedBox(width: AppSpacing.xs),
                Text('${r.$2}',
                    style: AppText.bodyStrong
                        .copyWith(color: palette.textPrimary)),
              ],
            ),
          ),
        if (sum.noWatchData) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
              android
                  ? l10n.connectedAppsSummaryHintAndroid
                  : l10n.connectedAppsSummaryHintIos,
              key: const Key('health-summary-hint'),
              style: caption),
        ],
      ],
    );
  }
}

class _ConnectSheet extends StatelessWidget {
  const _ConnectSheet({required this.app, required this.health});

  final ConnectableApp app;
  final String health;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return SheetSafeArea(
        child: SingleChildScrollView(
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
          Text(l10n.connectedAppsSheetSoon(app.title, health),
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
    ));
  }
}
