import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/core/widgets/section_header.dart';
import 'package:fitrix/core/widgets/sync_refresh.dart';
import 'package:fitrix/features/football/data/match_log.dart';
import 'package:fitrix/features/football/data/match_store.dart';
import 'package:fitrix/features/football/presentation/match_log_sheet.dart';
import 'package:fitrix/features/health/presentation/widgets/imported_workouts.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/features/workouts/presentation/widgets/sport_coach_card.dart';
import 'package:fitrix/features/workouts/presentation/widgets/workouts_grid.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// A logged game or training in the history.
typedef FootballEntry = ({String id, MatchLog log});

/// Football logs of workouts still in history, newest first.
final footballHistoryProvider = Provider<List<FootballEntry>>((ref) {
  final logs = ref.watch(matchesProvider);
  final ids = {
    for (final w in ref.watch(workoutHistoryProvider))
      if (w.sport == Sport.football) w.id
  };
  return [
    for (final e in logs.entries)
      if (ids.contains(e.key)) (id: e.key, log: e.value),
  ]..sort((a, b) => b.log.date.compareTo(a.log.date));
});

/// Football: Log a game or training, the history, and the plans.
class FootballScreen extends ConsumerWidget {
  const FootballScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(footballHistoryProvider);
    final imported = ref.watch(importedWorkoutsProvider(Sport.football));
    void log(WorkoutTemplate t) => startWorkout(context, ref, t);
    // Logs and workouts from Health in one list, newest first.
    final rows = <({DateTime at, Widget row})>[
      for (final e in entries) (at: e.log.date, row: _Row(entry: e)),
      for (final e in imported)
        (at: e.workout.finishedAt, row: ImportedWorkoutRow(entry: e)),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(Sport.football.localizedLabel(l10n)),
            PillSelector<Sport>(
              items: Sport.values,
              selected: Sport.football,
              labelOf: (s) => s.localizedLabel(l10n),
              onSelected: (s) {
                if (s != Sport.football) {
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
                      key: const ValueKey('fb-log'),
                      label: l10n.footballLog,
                      size: AppButtonSize.large,
                      expand: true,
                      onPressed: () => showMatchLogSheet(context, ref),
                    ),
                    SportCoachCard(sport: Sport.football, onStart: log),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.footballHistory),
                    const SizedBox(height: AppSpacing.xs),
                    if (entries.isEmpty && imported.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Text(l10n.footballHistoryEmpty,
                            style: AppText.body14
                                .copyWith(color: palette.textSecondary)),
                      )
                    else
                      for (final r in rows) r.row,
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(l10n.footballWorkouts),
                    const SizedBox(height: AppSpacing.xs),
                    WorkoutsGrid(
                      sport: Sport.football,
                      actionLabel: l10n.footballLog,
                      onAction: log,
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

class _Row extends ConsumerWidget {
  const _Row({required this.entry});

  final FootballEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final log = entry.log;
    final match = log.type == FootballType.match;
    final result = match && log.goalsFor != null && log.goalsAgainst != null
        ? '${log.goalsFor}–${log.goalsAgainst}'
        : null;
    final details = [
      match ? l10n.footballTypeMatch : l10n.footballTypeTraining,
      if (match && log.format != null) formatLabel(log.format!),
      '${log.minutes} ${l10n.footballMinShort}',
      if (result != null) result,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: palette.tile,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          key: ValueKey('fb-row-${entry.id}'),
          borderRadius: AppRadius.smAll,
          onTap: () => showMatchLogSheet(context, ref, editId: entry.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.MMMEd(l10n.localeName)
                        .format(log.date.toLocal()),
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary),
                  ),
                  Text(details,
                      style: AppText.bodyStrong
                          .copyWith(color: palette.textPrimary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
