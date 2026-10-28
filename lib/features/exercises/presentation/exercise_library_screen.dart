import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/exercises/domain/exercise_stats.dart';
import 'package:fitrix/features/exercises/presentation/exercise_widgets.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_format.dart';

/// The exercise library: filters, "Your recent" and every exercise A-Z.
class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  MuscleGroup? _group;
  Equipment? _equipment;
  String _query = '';

  static const _recentLimit = 5;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final history = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: catalog == null
            ? Column(children: [ScreenTitle(l10n.exercisesTitle)])
            : _content(context, catalog, history),
      ),
    );
  }

  Widget _content(BuildContext context, ExerciseCatalog catalog,
      List<CompletedWorkout> history) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final filtered = filterExercises(catalog.all,
            group: _group, equipment: _equipment, query: _query)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final recent = _query.trim().isEmpty
        ? _recent(catalog, history)
            .where((r) => filtered.contains(r.info))
            .take(_recentLimit)
            .toList()
        : const <_Recent>[];

    final letters = <String, List<ExerciseInfo>>{};
    for (final e in filtered) {
      letters.putIfAbsent(e.name[0].toUpperCase(), () => []).add(e);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        ScreenTitle(l10n.exercisesTitle),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: ExerciseSearchField(
            hint: l10n.exercisesSearch(catalog.all.length),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PillSelector<MuscleGroup?>(
          items: const [null, ...MuscleGroup.values],
          selected: _group,
          labelOf: (g) =>
              g == null ? l10n.exercisesAll : l10n.muscleGroupName(g),
          onSelected: (g) => setState(() => _group = g),
        ),
        const SizedBox(height: AppSpacing.xs),
        PillSelector<Equipment?>(
          items: const [null, ...Equipment.values],
          selected: _equipment,
          labelOf: (e) =>
              e == null ? l10n.exercisesAnyEquipment : l10n.equipmentName(e),
          onSelected: (e) => setState(() => _equipment = e),
        ),
        const SizedBox(height: AppSpacing.md),
        if (recent.isNotEmpty) ...[
          _header(l10n.exercisesRecent, l10n.exercisesFromWorkouts),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
            child: ExerciseListCard(children: [
              for (final r in recent)
                ExerciseRow(
                  key: ValueKey('recent-${r.info.id}'),
                  name: r.info.name,
                  subtitle: _subtitle(l10n, r.info),
                  onTap: () => context.push(AppRouter.exercise(r.info.id)),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatSetLoad(context, r.best),
                          style: AppText.headingS
                              .copyWith(color: palette.textPrimary)),
                      Text(l10n.exercisesBest,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                ),
            ]),
          ),
        ],
        _header(l10n.exercisesAZ, l10n.exercisesCount(filtered.length)),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(l10n.exercisesNoMatch,
                style:
                    AppText.bodyRegular.copyWith(color: palette.textSecondary)),
          ),
        for (final entry in letters.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Text(entry.key,
                style: AppText.captionStrong
                    .copyWith(color: palette.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ExerciseListCard(children: [
              for (final e in entry.value)
                ExerciseRow(
                  key: ValueKey('exercise-${e.id}'),
                  name: e.name,
                  subtitle: '${l10n.muscleGroupName(e.group)} · ${e.pattern}',
                  onTap: () => context.push(AppRouter.exercise(e.id)),
                  trailing:
                      Icon(Icons.chevron_right, color: palette.textSecondary),
                ),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _header(String title, String trailing) {
    final palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: AppText.headingS.copyWith(color: palette.textPrimary)),
          ),
          Text(trailing,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
        ],
      ),
    );
  }

  String _subtitle(AppLocalizations l10n, ExerciseInfo e) =>
      '${l10n.equipmentName(e.equipment)} · ${e.primary.join(', ')}';

  /// Exercises from history, most recently done first, with the best set.
  List<_Recent> _recent(
      ExerciseCatalog catalog, List<CompletedWorkout> history) {
    final sorted = [...history]
      ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
    final seen = <String>{};
    final result = <_Recent>[];
    for (final w in sorted) {
      for (final ex in w.exercises) {
        final info = catalog.byName(ex.name);
        if (info == null || !seen.add(info.id)) continue;
        final best = bestOf(sessionsOf(info, catalog, history));
        if (best != null) result.add(_Recent(info, best));
      }
    }
    return result;
  }
}

class _Recent {
  final ExerciseInfo info;
  final WorkoutSet best;
  const _Recent(this.info, this.best);
}
