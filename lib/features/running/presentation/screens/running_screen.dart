import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/core/widgets/section_header.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/widgets/run_history_list.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/features/workouts/presentation/widgets/sport_coach_card.dart';
import 'package:fitrix/features/workouts/presentation/widgets/workouts_grid.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/data/location_source.dart';
import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Runs saved on the device, newest first.
final runHistoryProvider = Provider<List<RunEntry>>((ref) {
  final details = ref.watch(runsProvider);
  final workouts = ref.watch(workoutHistoryProvider);
  final ids = {
    for (final w in workouts)
      if (w.sport == Sport.running) w.id
  };
  final runs = [
    for (final e in details.entries)
      if (ids.contains(e.key)) (id: e.key, details: e.value),
  ]..sort((a, b) => b.details.startedAt.compareTo(a.details.startedAt));
  return runs;
});

/// Running: Start run, this week's totals, the history and the plans.
class RunningScreen extends ConsumerWidget {
  const RunningScreen({super.key});

  Future<void> _startFree(BuildContext context, WidgetRef ref) async {
    final router = GoRouter.of(context);
    // A run that exists is reopened, never replaced by a second one.
    if (ref.read(runRecorderProvider) != null) {
      router.push(AppRouter.liveRun);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final access = await ref.read(runRecorderProvider.notifier).start();
    if (!context.mounted) return;
    if (access == LocationAccess.granted) {
      router.push(AppRouter.liveRun);
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
    final runs = ref.watch(runHistoryProvider);
    final weekStart = weekStartOf(ref.watch(todayProvider));
    final thisWeek = [
      for (final r in runs)
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
            ScreenTitle(Sport.running.localizedLabel(l10n)),
            PillSelector<Sport>(
              items: Sport.values,
              selected: Sport.running,
              labelOf: (s) => s.localizedLabel(l10n),
              onSelected: (s) {
                if (s != Sport.running) {
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
                    AppButton(
                      key: const ValueKey('run-start'),
                      label: l10n.runStartRun,
                      size: AppButtonSize.large,
                      expand: true,
                      onPressed: () => _startFree(context, ref),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.runThisWeek),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Figure(
                            key: const ValueKey('run-week-km'),
                            value: formatKm(weekMeters, locale),
                            unit: l10n.runUnitKm,
                          ),
                        ),
                        Expanded(
                          child: _Figure(
                            key: const ValueKey('run-week-runs'),
                            value: l10n.runWeekRuns(thisWeek.length),
                          ),
                        ),
                      ],
                    ),
                    SportCoachCard(
                      sport: Sport.running,
                      onStart: (t) => startWorkout(context, ref, t),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.runHistory),
                    const SizedBox(height: AppSpacing.xs),
                    RunHistoryList(runs: runs),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.runWorkouts),
                    const SizedBox(height: AppSpacing.xs),
                    WorkoutsGrid(
                      sport: Sport.running,
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
