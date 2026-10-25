import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/core/widgets/section_header.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/features/health/presentation/widgets/imported_workouts.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';
import 'package:fitrix/features/running/presentation/widgets/activity_settings_sheet.dart';
import 'package:fitrix/features/running/presentation/widgets/run_history_list.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/features/workouts/presentation/widgets/sport_coach_card.dart';
import 'package:fitrix/features/workouts/presentation/widgets/workouts_grid.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Ski days saved on the device, newest first.
final skiHistoryProvider = Provider<List<RunEntry>>((ref) {
  final details = ref.watch(runsProvider);
  final ids = {
    for (final w in ref.watch(workoutHistoryProvider))
      if (w.sport == Sport.winterSports) w.id
  };
  return [
    for (final e in details.entries)
      if (ids.contains(e.key) && e.value.kind == ActivityKind.ski)
        (id: e.key, details: e.value),
  ]..sort((a, b) => b.details.startedAt.compareTo(a.details.startedAt));
});

/// Skiing: Start ski day, this week, the history and the plans.
class SkiingScreen extends ConsumerWidget {
  const SkiingScreen({super.key});

  Future<void> _startFree(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    // A recording that exists is reopened, never replaced by a second one.
    if (ref.read(runRecorderProvider) != null) {
      openLiveRun(router);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final access = await ref
        .read(runRecorderProvider.notifier)
        .start(kind: ActivityKind.ski);
    if (!context.mounted) return;
    if (access == LocationAccess.granted) {
      openLiveRun(router);
      return;
    }
    final serviceOff = access == LocationAccess.serviceOff;
    showAppSnack(
      context,
      serviceOff ? l10n.runLocationServiceOff : l10n.runLocationOff,
      action: SnackBarAction(
        label: l10n.runOpenSettings,
        onPressed: () => serviceOff
            ? Geolocator.openLocationSettings()
            : Geolocator.openAppSettings(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final days = ref.watch(skiHistoryProvider);
    final weekStart = weekStartOf(ref.watch(todayProvider));
    final thisWeek = [
      for (final r in days)
        if (!r.details.startedAt.toLocal().isBefore(weekStart)) r
    ];
    final weekDescents = thisWeek.fold<int>(
        0, (a, r) => a + (r.details.ski?.descents.length ?? 0));
    final weekVertical = thisWeek.fold<double>(
        0, (a, r) => a + (r.details.ski?.verticalDown ?? 0));
    final locale = l10n.localeName;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(Sport.winterSports.localizedLabel(l10n)),
            PillSelector<Sport>(
              items: Sport.values,
              selected: Sport.winterSports,
              labelOf: (s) => s.localizedLabel(l10n),
              onSelected: (s) {
                if (s != Sport.winterSports) {
                  context.pushReplacement(AppRouter.sportWorkouts(s));
                }
              },
            ),
            Expanded(
              child: SyncRefresh(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            key: const ValueKey('ski-start'),
                            label: l10n.skiStart,
                            size: AppButtonSize.large,
                            expand: true,
                            onPressed: () => _startFree(context, ref),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          key: const ValueKey('ski-settings'),
                          tooltip: l10n.activitySettingsTitle,
                          icon: Icon(Icons.settings_outlined,
                              color: palette.textSecondary),
                          onPressed: () => showActivitySettingsSheet(
                              context, ActivityKind.ski),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.runThisWeek),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Figure(
                            key: const ValueKey('ski-week-days'),
                            value: '${thisWeek.length}',
                            unit: l10n.skiUnitDays,
                          ),
                        ),
                        Expanded(
                          child: _Figure(
                            key: const ValueKey('ski-week-descents'),
                            value: '$weekDescents',
                            unit: l10n.skiDescents,
                          ),
                        ),
                        Expanded(
                          child: _Figure(
                            key: const ValueKey('ski-week-vertical'),
                            value: formatMeters(weekVertical, locale),
                            unit: l10n.skiUnitM,
                          ),
                        ),
                      ],
                    ),
                    SportCoachCard(
                      sport: Sport.winterSports,
                      onStart: (t) => startWorkout(context, ref, t),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.skiHistory),
                    const SizedBox(height: AppSpacing.xs),
                    if (days.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(l10n.skiHistoryEmpty,
                            style: AppText.body14
                                .copyWith(color: palette.textSecondary)),
                      )
                    else
                      for (final r in days)
                        _DayRow(key: ValueKey('ski-row-${r.id}'), day: r),
                    const ImportedWorkoutsSection(sport: Sport.winterSports),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.skiWorkouts),
                    const SizedBox(height: AppSpacing.xs),
                    WorkoutsGrid(
                      sport: Sport.winterSports,
                      actionLabel: l10n.gymStart,
                      onAction: (t) => startWorkout(context, ref, t),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A ski day in the history; it opens the summary.
class _DayRow extends StatelessWidget {
  const _DayRow({super.key, required this.day});

  final RunEntry day;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final d = day.details;
    final text = '${l10n.skiDescents}: ${d.ski?.descents.length ?? 0}'
        ' · ${formatMeters(d.ski?.verticalDown ?? 0, locale)} ${l10n.skiUnitM}'
        ' · ${formatClock(d.moving)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: palette.tile,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: () => context.push(AppRouter.runSummary(day.id)),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.MMMEd(locale)
                        .add_Hm()
                        .format(d.startedAt.toLocal()),
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary),
                  ),
                  Text(
                    text,
                    style: AppText.bodyStrong.copyWith(
                      color: palette.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({super.key, required this.value, this.unit});

  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: AppSpacing.xxs,
      children: [
        Text(value,
            style: AppText.headingM.copyWith(color: palette.textPrimary)),
        if (unit != null)
          Text(unit!,
              style: AppText.body14.copyWith(color: palette.textSecondary)),
      ],
    );
  }
}
