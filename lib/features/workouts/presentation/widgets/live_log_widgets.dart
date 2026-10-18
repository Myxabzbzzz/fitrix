import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

/// Tonnes with one decimal in the user's number format: "4.1".
String formatTonnes(BuildContext context, double kg) =>
    NumberFormat('#,##0.0', Localizations.localeOf(context).toString())
        .format(kg / 1000);

bool _sameName(String a, String b) =>
    a.trim().toLowerCase() == b.trim().toLowerCase();

/// "72.5 × 8" for a set, "BW × 8" for a bodyweight one.
String formatSetLoad(BuildContext context, WorkoutSet s) {
  final kg = s.kg > 0
      ? formatKg(s.kg)
      : AppLocalizations.of(context).workoutBodyweight;
  return '$kg × ${s.reps}';
}

/// The most recent finished workout's sets of [name], or null.
List<WorkoutSet>? lastSetsOf(List<CompletedWorkout> history, String name) {
  for (final w in history) {
    for (final e in w.exercises) {
      if (_sameName(e.name, name)) return e.sets;
    }
  }
  return null;
}

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
        r.exercise.trim().toLowerCase(),
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
                        ? _CurrentExerciseCard(
                            index: e,
                            exercise: workout.exercises[e],
                            lastSets:
                                lastSetsOf(history, workout.exercises[e].name),
                            onToggle: (s) => _toggle(e, s),
                          )
                        : _CollapsedExerciseCard(
                            exercise: workout.exercises[e],
                            done: _isDone(workout.exercises[e]),
                            record: records.contains(
                                workout.exercises[e].name.trim().toLowerCase()),
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

/// Done and upcoming exercises: one row. Tapping opens it.
class _CollapsedExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool done;
  final bool record;
  final VoidCallback onTap;

  const _CollapsedExerciseCard({
    required this.exercise,
    required this.done,
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final working = exercise.sets.where((s) => !s.warmup).toList();
    final String subtitle;
    if (done) {
      final best = bestSet(exercise.sets);
      subtitle = [
        l10n.workoutSetCount(working.length),
        if (best != null) l10n.workoutBestShort(formatSetLoad(context, best)),
      ].join(' · ');
    } else {
      subtitle = [
        if (working.isNotEmpty) '${working.length} × ${working.first.reps}',
        if (working.isNotEmpty && working.first.kg > 0)
          '${formatKg(working.first.kg)} ${l10n.unitKg}',
      ].join(' · ');
    }

    return Material(
      color: palette.sheet,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: done ? palette.textSecondary : palette.buttonMuted,
                  shape: done ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: done ? null : AppRadius.smAll,
                ),
                child: Icon(
                  done ? Icons.check : Icons.fitness_center,
                  size: 18,
                  color: done ? palette.background : palette.textPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: AppText.headingS.copyWith(
                        color:
                            done ? palette.textSecondary : palette.textPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: AppText.body14
                            .copyWith(color: palette.textSecondary),
                      ),
                  ],
                ),
              ),
              if (done && record)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: palette.accentSoft,
                    borderRadius: AppRadius.fullAll,
                  ),
                  child: Text(
                    l10n.workoutPr,
                    style:
                        AppText.captionStrong.copyWith(color: palette.accent),
                  ),
                )
              else if (!done)
                Icon(Icons.chevron_right, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// The exercise being worked on: header, Felix line and the sets table.
class _CurrentExerciseCard extends ConsumerWidget {
  final int index;
  final Exercise exercise;
  final List<WorkoutSet>? lastSets;
  final ValueChanged<int> onToggle;

  const _CurrentExerciseCard({
    required this.index,
    required this.exercise,
    required this.lastSets,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final working = exercise.sets.where((s) => !s.warmup).toList();

    final suggested = lastSets == null ? null : suggestNextKg(lastSets!);
    final last = lastSets == null ? null : bestSet(lastSets!);
    final meta = [
      if (working.isNotEmpty) '${working.length} × ${working.first.reps}',
      l10n.workoutRestShort(formatClock(
          Duration(seconds: exercise.restSeconds ?? kDefaultRestSeconds))),
    ].join(' · ');

    // 1-based number among working sets; null for warm-ups.
    final numbers = <int?>[];
    var counted = 0;
    for (final s in exercise.sets) {
      numbers.add(s.warmup ? null : ++counted);
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.sheet,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style:
                          AppText.headingM.copyWith(color: palette.textPrimary),
                    ),
                    Text(
                      meta,
                      style:
                          AppText.body14.copyWith(color: palette.textSecondary),
                    ),
                    if (exercise.note != null)
                      Text(
                        exercise.note!,
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                  ],
                ),
              ),
              IconButton(
                key: ValueKey('exerciseMenu-$index'),
                onPressed: () => showExerciseMenuSheet(context, index),
                icon: Icon(Icons.more_horiz, color: palette.textPrimary),
              ),
            ],
          ),
          if (suggested != null && last != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _FelixLine(
              text: l10n.workoutFelixLine(
                formatSetLoad(context, last),
                formatKg(suggested),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          const _TableHeader(),
          for (var s = 0; s < exercise.sets.length; s++)
            _SetRow(
              key: ValueKey('set-$index-$s'),
              label: numbers[s],
              set: exercise.sets[s],
              onToggle: () => onToggle(s),
              onKgChanged: (kg) => notifier.setKg(index, s, kg),
              onRepsChanged: (reps) => notifier.setReps(index, s, reps),
              onRpe: () => showRpePicker(
                context,
                setNumber: numbers[s]!,
                initial: exercise.sets[s].rpe,
                onPick: (rpe) => notifier.setRpe(index, s, rpe),
              ),
              rpeKey: ValueKey('rpe-$index-$s'),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => notifier.addSet(index),
              icon: const Icon(Icons.add, size: 16),
              label: Text(l10n.workoutAddSet),
              style: TextButton.styleFrom(
                foregroundColor: palette.accent,
                textStyle: AppText.captionStrong,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FelixLine extends StatelessWidget {
  final String text;

  const _FelixLine({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: palette.accentSoft,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/felix_avatar.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const SizedBox(width: 24, height: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: AppText.body14.copyWith(color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with 1-10 and the "reps left in the tank" caption. The
/// pick is saved at once; Done closes the sheet.
Future<void> showRpePicker(
  BuildContext context, {
  required int setNumber,
  required int? initial,
  required ValueChanged<int> onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppPalette.of(context).background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _RpeSheet(
      setNumber: setNumber,
      initial: initial,
      onPick: onPick,
    ),
  );
}

class _RpeSheet extends StatefulWidget {
  final int setNumber;
  final int? initial;
  final ValueChanged<int> onPick;

  const _RpeSheet({
    required this.setNumber,
    required this.initial,
    required this.onPick,
  });

  @override
  State<_RpeSheet> createState() => _RpeSheetState();
}

class _RpeSheetState extends State<_RpeSheet> {
  late int? _rpe = widget.initial;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.workoutRpeTitle(widget.setNumber).toUpperCase(),
              style:
                  AppText.captionStrong.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            RpeScale(
              keyPrefix: 'rpePick',
              selected: _rpe,
              onPick: (n) {
                setState(() => _rpe = n);
                widget.onPick(n);
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _rpe == null
                  ? l10n.workoutOverallHint
                  : l10n.workoutRpeCaption(_rpe!, 10 - _rpe!),
              style: AppText.body14.copyWith(color: palette.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: l10n.workoutKeyboardDone,
              size: AppButtonSize.large,
              expand: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of the numbers 1-10; the picked one is filled with the accent.
class RpeScale extends StatelessWidget {
  final String keyPrefix;
  final int? selected;
  final ValueChanged<int> onPick;
  final Color? cellColor;

  const RpeScale({
    super.key,
    required this.keyPrefix,
    required this.selected,
    required this.onPick,
    this.cellColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        for (var n = 1; n <= 10; n++) ...[
          if (n > 1) const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: GestureDetector(
              key: ValueKey('$keyPrefix-$n'),
              onTap: () => onPick(n),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == n
                      ? palette.accent
                      : cellColor ?? palette.tile,
                  borderRadius: AppRadius.smAll,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$n',
                    style: AppText.headingS.copyWith(
                      color: selected == n
                          ? palette.onAccent
                          : palette.textPrimary,
                    ),
                  ),
                ),
              ),
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

/// Six-column grid: Set · Previous · Kg · Reps · RPE · check.
const _colSet = 28.0;
const _colRpe = 36.0;
const _colCheck = 36.0;
const _gap = AppSpacing.xxs;

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final style = AppText.microStrong.copyWith(color: palette.textSecondary);
    Widget hd(String text) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text.toUpperCase(), style: style),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        children: [
          SizedBox(
              width: _colSet, child: Center(child: hd(l10n.workoutColSet))),
          const SizedBox(width: _gap),
          Expanded(child: Center(child: hd(l10n.workoutColPrevious))),
          const SizedBox(width: _gap),
          Expanded(child: Center(child: hd(l10n.workoutColKg))),
          const SizedBox(width: _gap),
          Expanded(child: Center(child: hd(l10n.workoutColReps))),
          const SizedBox(width: _gap),
          SizedBox(
              width: _colRpe, child: Center(child: hd(l10n.workoutColRpe))),
          const SizedBox(width: _gap),
          const SizedBox(width: _colCheck),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  /// 1-based number among working sets; null for a warm-up ("W").
  final int? label;
  final WorkoutSet set;
  final VoidCallback onToggle;
  final VoidCallback onRpe;
  final Key rpeKey;
  final ValueChanged<double> onKgChanged;
  final ValueChanged<int> onRepsChanged;

  const _SetRow({
    super.key,
    required this.label,
    required this.set,
    required this.onToggle,
    required this.onRpe,
    required this.rpeKey,
    required this.onKgChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final textStyle = AppText.body14.copyWith(
      color: palette.textPrimary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    Widget cell({required Widget child, bool plain = false}) => Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: plain ? Colors.transparent : palette.tableCell,
            borderRadius: AppRadius.smAll,
          ),
          child: child,
        );

    final hasPrevious =
        !set.warmup && (set.previousKg > 0 || set.previousReps > 0);
    final rpeText = set.rpe == null ? '—' : '${set.rpe}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: _colSet,
            child: cell(
              plain: true,
              child: Text(
                label == null ? 'W' : '$label',
                style: textStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: label == null ? palette.accent : palette.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: cell(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  hasPrevious
                      ? '${formatKg(set.previousKg)}×${set.previousReps}'
                      : '—',
                  style: textStyle.copyWith(color: palette.textSecondary),
                ),
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: cell(
              child: _NumberField(
                initialValue: formatKg(set.kg),
                decimal: true,
                style: textStyle,
                onChanged: (value) {
                  final kg = double.tryParse(value.replaceAll(',', '.'));
                  if (kg != null) onKgChanged(kg);
                },
              ),
            ),
          ),
          const SizedBox(width: _gap),
          Expanded(
            child: cell(
              child: _NumberField(
                initialValue: '${set.reps}',
                decimal: false,
                style: textStyle,
                onChanged: (value) {
                  final reps = int.tryParse(value);
                  if (reps != null) onRepsChanged(reps);
                },
              ),
            ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _colRpe,
            child: set.warmup
                ? const SizedBox(height: 32)
                : GestureDetector(
                    key: rpeKey,
                    onTap: onRpe,
                    behavior: HitTestBehavior.opaque,
                    child: cell(
                      child: Text(
                        rpeText,
                        style: textStyle.copyWith(
                          color: set.rpe == null
                              ? palette.textSecondary
                              : palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: _gap),
          SizedBox(
            width: _colCheck,
            child: Center(
              child: _CheckButton(
                label: label == null
                    ? l10n.workoutSetDone(0)
                    : l10n.workoutSetDone(label!),
                done: set.done,
                onToggle: onToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The check cell: 32×32, fills with the accent when done. The icon pops
/// (scale 0.3 → 1 with a spring-like overshoot) only on the set whose
/// state just changed, with a light haptic tap.
class _CheckButton extends StatefulWidget {
  final String label;
  final bool done;
  final VoidCallback onToggle;

  const _CheckButton({
    required this.label,
    required this.done,
    required this.onToggle,
  });

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: 1,
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.3, end: 1)
      .animate(CurvedAnimation(parent: _pop, curve: Curves.easeOutBack));

  @override
  void didUpdateWidget(_CheckButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.done != widget.done && !Motion.reduced(context)) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final done = widget.done;

    return Semantics(
      button: true,
      checked: done,
      label: widget.label,
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedContainer(
          key: ActiveWorkoutSheet.checkKey,
          duration: Motion.of(context, Motion.fast),
          curve: Motion.curve,
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? palette.accent : palette.tableCell,
            borderRadius: AppRadius.smAll,
          ),
          child: ScaleTransition(
            scale: _scale,
            child: Icon(
              Icons.check,
              size: 18,
              color: done ? palette.onAccent : palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact numeric input that sits inside a table cell; selects all on focus.
class _NumberField extends StatefulWidget {
  final String initialValue;
  final bool decimal;

  final TextStyle style;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.initialValue,
    required this.decimal,
    required this.style,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.selection =
            TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
      }
    });
  }

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The row can show another set after warm-ups, a swap or a removal;
    // follow the model unless the user is typing here.
    if (!_focusNode.hasFocus && _controller.text != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textAlign: TextAlign.center,
      style: widget.style,
      scrollPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20 + kDoneBarHeight),
      keyboardType: TextInputType.numberWithOptions(decimal: widget.decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(widget.decimal ? r'[0-9.,]' : r'[0-9]'),
        ),
      ],
      decoration: const InputDecoration.collapsed(
        hintText: '',
        filled: false,
      ),
      onChanged: widget.onChanged,
    );
  }
}
