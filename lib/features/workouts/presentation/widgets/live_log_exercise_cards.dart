import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/exercise_menu_sheet.dart';
import 'package:fitrix/features/workouts/presentation/widgets/rest_timer.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_format.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_rpe_sheet.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_set_table.dart';

/// Done and upcoming exercises: one row. Tapping opens it.
class CollapsedExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool done;
  final bool record;
  final VoidCallback onTap;

  const CollapsedExerciseCard({
    super.key,
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
class CurrentExerciseCard extends ConsumerWidget {
  final int index;
  final Exercise exercise;
  final List<WorkoutSet>? lastSets;
  final ValueChanged<int> onToggle;

  const CurrentExerciseCard({
    super.key,
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
          const SetTableHeader(),
          for (var s = 0; s < exercise.sets.length; s++)
            SetTableRow(
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
