import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/exercises/domain/exercise_stats.dart';
import 'package:fitrix/features/exercises/presentation/exercise_widgets.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Picks exercises for the active workout. In replace mode it swaps the
/// exercise at [index] for one pick instead.
class AddExerciseScreen extends ConsumerStatefulWidget {
  final bool replace;
  final int index;

  const AddExerciseScreen({super.key, this.replace = false, this.index = 0});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  MuscleGroup? _group;
  bool _groupChosen = false;
  String _query = '';
  final List<String> _selected = [];

  /// Hands the screen back to the workout it was opened from.
  void _expandWorkout() {
    if (ref.read(activeWorkoutProvider) != null) {
      ref.read(activeWorkoutExpandedProvider.notifier).state = true;
    }
  }

  /// The exercise to swap, or null when not in replace mode or the index
  /// points at nothing (then the picker adds instead).
  int? _replaceIndex(ActiveWorkout? workout) {
    if (!widget.replace || workout == null) return null;
    return widget.index >= 0 && widget.index < workout.exercises.length
        ? widget.index
        : null;
  }

  void _close() {
    if (context.canPop()) {
      // The PopScope below re-expands the sheet for every kind of pop.
      context.pop();
    } else {
      _expandWorkout();
      context.go(AppRouter.workouts);
    }
  }

  void _confirm(ExerciseCatalog catalog) {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final names = [
      for (final id in _selected)
        if (catalog.byId(id) != null) catalog.byId(id)!.name,
    ];
    if (names.isNotEmpty) {
      final at = _replaceIndex(ref.read(activeWorkoutProvider));
      if (at != null) {
        notifier.replaceExercise(at, names.first);
      } else {
        notifier.addExercises(names);
      }
    }
    _close();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _expandWorkout();
        },
        child: _buildScreen(context),
      );

  Widget _buildScreen(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final workout = ref.watch(activeWorkoutProvider);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final history = ref.watch(workoutHistoryProvider);
    final today = ref.watch(todayProvider);

    final bar = Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxs, AppSpacing.xs, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            color: palette.textPrimary,
            onPressed: _close,
          ),
          Expanded(
            child: Text(
              workout == null
                  ? ''
                  : _replaceIndex(workout) != null
                      ? l10n.addExerciseSwapTitle(workout.template.name)
                      : l10n.addExerciseTitle(workout.template.name),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.headingS.copyWith(color: palette.textPrimary),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );

    if (workout == null || catalog == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(child: Column(children: [bar])),
      );
    }

    final inWorkout = <ExerciseInfo>[
      for (final e in workout.exercises)
        if (catalog.byName(e.name) != null) catalog.byName(e.name)!,
    ];
    final replaceAt = _replaceIndex(workout);

    if (!_groupChosen) {
      _groupChosen = true;
      if (replaceAt != null) {
        _group = catalog.byName(workout.exercises[replaceAt].name)?.group;
      } else if (inWorkout.isNotEmpty) {
        final counts = <MuscleGroup, int>{};
        for (final e in inWorkout) {
          counts[e.group] = (counts[e.group] ?? 0) + 1;
        }
        _group = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
      }
    }

    final names = {for (final e in inWorkout) e.id};
    final sources = replaceAt != null
        ? [
            if (catalog.byName(workout.exercises[replaceAt].name) != null)
              catalog.byName(workout.exercises[replaceAt].name)!
          ]
        : inWorkout;
    final suggested = <ExerciseInfo>[];
    for (final s in sources) {
      for (final e in catalog.similarTo(s)) {
        if (names.contains(e.id) || suggested.contains(e)) continue;
        if (_group != null && e.group != _group) continue;
        suggested.add(e);
      }
    }

    final all = filterExercises(catalog.all, group: _group, query: _query)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final sets = _group == null
        ? 0
        : weeklySets(_group!, catalog, history, weekStartOf(today));
    final showHint = _group != null && sets < kWeeklySetsTarget;

    void toggle(ExerciseInfo e) => setState(() {
          if (_selected.contains(e.id)) {
            _selected.remove(e.id);
          } else if (replaceAt != null) {
            _selected
              ..clear()
              ..add(e.id);
          } else {
            _selected.add(e.id);
          }
        });

    Widget row(ExerciseInfo e, String subtitle, {String prefix = 'pick'}) {
      final locked = names.contains(e.id);
      final on = _selected.contains(e.id);
      return ExerciseRow(
        key: ValueKey('$prefix-${e.id}'),
        name: e.name,
        subtitle: locked
            ? '${l10n.equipmentName(e.equipment)} · ${l10n.addExerciseInWorkout}'
            : subtitle,
        onTap: locked ? null : () => toggle(e),
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: on ? palette.accent : palette.background,
            borderRadius: AppRadius.smAll,
            border: Border.all(
                color: locked
                    ? palette.border
                    : on
                        ? palette.accent
                        : palette.textSecondary),
          ),
          child:
              on ? Icon(Icons.check, size: 16, color: palette.onAccent) : null,
        ),
      );
    }

    String sub(ExerciseInfo e) =>
        '${l10n.equipmentName(e.equipment)} · ${e.pattern}';

    final n = _selected.length;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            bar,
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
                children: [
                  ExerciseSearchField(
                    hint: l10n.exercisesSearchShort,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PillSelector<MuscleGroup?>(
                    bleed: AppSpacing.md,
                    items: const [null, ...MuscleGroup.values],
                    selected: _group,
                    labelOf: (g) =>
                        g == null ? l10n.exercisesAll : l10n.muscleGroupName(g),
                    onSelected: (g) => setState(() => _group = g),
                  ),
                  if (showHint) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      key: const ValueKey('weekly-hint'),
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                          color: palette.accentSoft,
                          borderRadius: AppRadius.smAll),
                      child: Text(
                        l10n.addExerciseHint(l10n.muscleGroupName(_group!),
                            sets, kWeeklySetsTarget),
                        style: AppText.bodyRegular
                            .copyWith(color: palette.textPrimary),
                      ),
                    ),
                  ],
                  if (suggested.isNotEmpty && _query.trim().isEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _header(palette, l10n.addExerciseSuggested,
                        l10n.addExerciseSelected(n)),
                    const SizedBox(height: AppSpacing.xs),
                    ExerciseListCard(children: [
                      for (final e in suggested)
                        row(e, sub(e), prefix: 'suggest')
                    ]),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _header(palette, l10n.addExerciseLibrary, '${all.length}'),
                  const SizedBox(height: AppSpacing.xs),
                  if (all.isEmpty)
                    Text(l10n.exercisesNoMatch,
                        style: AppText.bodyRegular
                            .copyWith(color: palette.textSecondary))
                  else
                    ExerciseListCard(
                        children: [for (final e in all) row(e, sub(e))]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
              child: AppButton(
                key: const ValueKey('confirm-add'),
                label: replaceAt != null
                    ? l10n.addExerciseSwap
                    : l10n.addExerciseButton(n),
                size: AppButtonSize.large,
                expand: true,
                onPressed: n == 0 ? null : () => _confirm(catalog),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppPalette palette, String title, String trailing) => Row(
        children: [
          Expanded(
            child: Text(title,
                style: AppText.headingM.copyWith(color: palette.textPrimary)),
          ),
          Text(trailing,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
        ],
      );
}
