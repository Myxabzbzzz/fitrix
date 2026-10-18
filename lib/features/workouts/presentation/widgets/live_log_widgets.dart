import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/text/normalize.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/active_workout_sheet.dart';
import 'package:fitrix/features/workouts/presentation/widgets/exercise_menu_sheet.dart';
import 'package:fitrix/features/workouts/presentation/widgets/rest_timer.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_format.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_exercise_cards.dart';

/// The expanded active workout: progress, exercise cards, rest bar and the
/// bottom buttons.
class LiveLog extends ConsumerStatefulWidget {
  final ActiveWorkout workout;

  /// True while a field has the keyboard: the rest bar and buttons step
  /// aside so the list gets the room.
  final bool typing;

  const LiveLog({super.key, required this.workout, this.typing = false});

  @override
  ConsumerState<LiveLog> createState() => _LiveLogState();
}

class _LiveLogState extends ConsumerState<LiveLog> {
  /// Exercise the user opened by hand; null follows the first unfinished one.
  int? _selected;

  static bool _isDone(Exercise e) =>
      e.sets.isNotEmpty && e.sets.every((s) => s.done);

  int _currentIndex(List<Exercise> exercises) {
    final selected = _selected;
    if (selected != null && selected < exercises.length) return selected;
    return exercises.indexWhere((e) => !_isDone(e));
  }

  void _toggle(int e, int s) {
    final workout = widget.workout;
    final exercise = workout.exercises[e];
    final set = exercise.sets[s];
    ref.read(activeWorkoutProvider.notifier).toggleSet(e, s);
    if (set.done || set.warmup) return;

    final l10n = AppLocalizations.of(context);
    String? next;
    var number = exercise.sets.take(s + 1).where((x) => !x.warmup).length;
    for (var t = s + 1; t < exercise.sets.length; t++) {
      final x = exercise.sets[t];
      if (x.warmup) continue;
      number++;
      if (!x.done) {
        next = l10n.workoutNextSet(number, formatKg(x.kg), x.reps);
        break;
      }
    }
    ref.read(restTimerProvider).start(
          Duration(seconds: exercise.restSeconds ?? kDefaultRestSeconds),
          next: next,
        );
    final finished = [
      for (var i = 0; i < exercise.sets.length; i++)
        i == s || exercise.sets[i].done,
    ].every((x) => x);
    if (finished && _selected == e) setState(() => _selected = null);
  }

  Future<void> _finish() async {
    final workout = widget.workout;
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final expanded = ref.read(activeWorkoutExpandedProvider.notifier);
    if (workout.completedSets == 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.workoutFinishTitle),
            content: Text(l10n.workoutFinishNoSets),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.workoutKeepGoing),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.workoutFinish),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !mounted) return;
      expanded.state = false;
      ref.read(restTimerProvider).skip();
      notifier.finish();
      return;
    }
    ref.read(pendingCompletedWorkoutProvider.notifier).state =
        CompletedWorkout.from(
            workout, finishTimeFor(workout, ref.read(clockProvider)()));
    expanded.state = false;
    ref.read(restTimerProvider).skip();
    GoRouter.of(context).go(AppRouter.workoutComplete);
  }

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(workoutHistoryProvider);
    final total = workout.totalSets;
    final done = workout.completedSets;
    final current = _currentIndex(workout.exercises);
    final records = {
      for (final r in recordsIn(
        CompletedWorkout.from(workout, DateTime.now()),
        history,
      ))
        normalizeName(r.exercise),
    };

    final caption = l10n.workoutLiveCaption(
      total == 0 ? 0 : (done + 1).clamp(1, total),
      total,
      '${formatTonnes(context, volumeKg(workout.exercises))} '
      '${l10n.unitTonnes}',
    );

    // While the sheet is dragged shut it gets shorter than the content; keep
    // laying the content out at a minimum height (clipped) instead of
    // overflowing.
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: math.max(constraints.maxHeight, _minLayoutHeight),
          maxHeight: math.max(constraints.maxHeight, _minLayoutHeight),
          child: _buildContent(
              context, caption, workout, current, history, records),
        ),
      ),
    );
  }

  static const double _minLayoutHeight = 360;

  Widget _buildContent(
    BuildContext context,
    String caption,
    ActiveWorkout workout,
    int current,
    List<CompletedWorkout> history,
    Set<String> records,
  ) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final total = workout.totalSets;
    final done = workout.completedSets;
    return Column(
      children: [
        Expanded(
          // Tapping empty space drops the keyboard; buttons inside still win.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              children: [
                Center(
                  child: Text(
                    caption,
                    key: ActiveWorkoutSheet.captionKey,
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      color: palette.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _ProgressBar(fraction: total == 0 ? 0 : done / total),
                const SizedBox(height: AppSpacing.md),
                if (workout.exercises.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.workoutNoExercises,
                      textAlign: TextAlign.center,
                      style:
                          AppText.body14.copyWith(color: palette.textSecondary),
                    ),
                  ),
                for (var e = 0; e < workout.exercises.length; e++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: e == current
                        ? CurrentExerciseCard(
                            index: e,
                            exercise: workout.exercises[e],
                            lastSets:
                                lastSetsOf(history, workout.exercises[e].name),
                            onToggle: (s) => _toggle(e, s),
                          )
                        : CollapsedExerciseCard(
                            exercise: workout.exercises[e],
                            done: _isDone(workout.exercises[e]),
                            record: records.contains(
                                normalizeName(workout.exercises[e].name)),
                            onTap: () => setState(() => _selected = e),
                          ),
                  ),
              ],
            ),
          ),
        ),
        if (!widget.typing) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
            child: RestBar(controller: ref.watch(restTimerProvider)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: l10n.workoutAddExercise,
                    style: AppButtonStyle.secondary,
                    size: AppButtonSize.large,
                    icon: Icons.add,
                    expand: true,
                    onPressed: () => openExercisePicker(context, ref),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: l10n.workoutFinishButton,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: _finish,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// 6 px accent bar whose fill animates to [fraction] over 400 ms.
class _ProgressBar extends StatelessWidget {
  final double fraction;

  const _ProgressBar({required this.fraction});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      key: ActiveWorkoutSheet.progressTrackKey,
      height: 6,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.buttonMuted,
        borderRadius: AppRadius.fullAll,
      ),
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: fraction.clamp(0.0, 1.0)),
        duration: Motion.of(context, Motion.slow),
        curve: Motion.curve,
        builder: (context, value, _) => FractionallySizedBox(
          widthFactor: value,
          child: DecoratedBox(
            key: ActiveWorkoutSheet.progressFillKey,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: AppRadius.fullAll,
            ),
          ),
        ),
      ),
    );
  }
}
