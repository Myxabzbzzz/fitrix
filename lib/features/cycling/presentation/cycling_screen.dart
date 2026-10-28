import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/core/widgets/section_header.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/features/cycling/presentation/indoor_ride_sheet.dart';
import 'package:fitrix/features/health/presentation/widgets/imported_workouts.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/start_activity.dart';
import 'package:fitrix/features/running/presentation/widgets/activity_settings_sheet.dart';
import 'package:fitrix/features/running/presentation/widgets/run_history_list.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/features/workouts/presentation/widgets/sport_coach_card.dart';
import 'package:fitrix/features/workouts/presentation/widgets/workouts_grid.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Rides (outdoor and indoor) saved on the device, newest first.
final rideHistoryProvider = Provider<List<RunEntry>>((ref) {
  final details = ref.watch(runsProvider);
  final ids = {
    for (final w in ref.watch(workoutHistoryProvider))
      if (w.sport == Sport.cycling) w.id
  };
  return [
    for (final e in details.entries)
      if (ids.contains(e.key)) (id: e.key, details: e.value),
  ]..sort((a, b) => b.details.startedAt.compareTo(a.details.startedAt));
});

/// Cycling: Start ride, Log indoor ride, this week, the history and the plans.
class CyclingScreen extends ConsumerWidget {
  const CyclingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final rides = ref.watch(rideHistoryProvider);
    final weekStart = weekStartOf(ref.watch(todayProvider));
    final thisWeek = [
      for (final r in rides)
        if (!r.details.startedAt.toLocal().isBefore(weekStart)) r
    ];
    final weekMeters = thisWeek.fold<double>(0, (a, r) => a + r.details.meters);
    final locale = l10n.localeName;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(Sport.cycling.localizedLabel(l10n)),
            PillSelector<Sport>(
              items: Sport.values,
              selected: Sport.cycling,
              labelOf: (s) => s.localizedLabel(l10n),
              onSelected: (s) {
                if (s != Sport.cycling) {
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
                            key: const ValueKey('cy-start'),
                            label: l10n.cyclingStart,
                            size: AppButtonSize.large,
                            expand: true,
                            onPressed: () => startFreeActivity(
                                context, ref, ActivityKind.ride),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          key: const ValueKey('cy-settings'),
                          tooltip: l10n.activitySettingsTitle,
                          icon: Icon(Icons.settings_outlined,
                              color: palette.textSecondary),
                          onPressed: () => showActivitySettingsSheet(
                              context, ActivityKind.ride),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppButton(
                      key: const ValueKey('cy-log'),
                      label: l10n.cyclingLog,
                      style: AppButtonStyle.secondary,
                      size: AppButtonSize.large,
                      expand: true,
                      onPressed: () => showIndoorRideSheet(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.runThisWeek),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Figure(
                            key: const ValueKey('cy-week-km'),
                            value: formatKm(weekMeters, locale),
                            unit: l10n.runUnitKm,
                          ),
                        ),
                        Expanded(
                          child: _Figure(
                            key: const ValueKey('cy-week-rides'),
                            value: '${thisWeek.length}',
                            unit: l10n.cyclingUnitRides(thisWeek.length),
                          ),
                        ),
                      ],
                    ),
                    SportCoachCard(
                      sport: Sport.cycling,
                      onStart: (t) => startWorkout(context, ref, t),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.cyclingHistory),
                    const SizedBox(height: AppSpacing.xs),
                    if (rides.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(l10n.cyclingHistoryEmpty,
                            style: AppText.body14
                                .copyWith(color: palette.textSecondary)),
                      )
                    else
                      for (final r in rides)
                        _RideRow(key: ValueKey('cy-row-${r.id}'), ride: r),
                    const ImportedWorkoutsSection(sport: Sport.cycling),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.cyclingWorkouts),
                    const SizedBox(height: AppSpacing.xs),
                    WorkoutsGrid(
                      sport: Sport.cycling,
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

/// A ride in the history. An outdoor ride opens its summary, an indoor one
/// its log to edit.
class _RideRow extends ConsumerWidget {
  const _RideRow({super.key, required this.ride});

  final RunEntry ride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final d = ride.details;
    final known = d.meters > 0;
    final text = d.indoor
        ? [
            l10n.cyclingIndoorTag,
            '${d.moving.inMinutes} ${l10n.footballMinShort}',
            if (known) '${formatKm(d.meters, locale)} ${l10n.runUnitKm}',
            if (d.avgPowerW != null) '${d.avgPowerW} ${l10n.unitWatts}',
          ].join(' · ')
        : '${formatKm(d.meters, locale)} ${l10n.runUnitKm}'
            ' · ${formatClock(d.moving)}'
            ' · ${formatSpeed(averageSpeed(d.meters, d.moving), locale)} ${l10n.unitKmh}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: palette.tile,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: () => d.indoor
              ? showIndoorRideSheet(context, ref, editId: ride.id)
              : context.push(AppRouter.runSummary(ride.id)),
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
