import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/widgets/rest_timer.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Opens the "…" menu of the exercise at [exerciseIndex] of the active
/// workout: swap, warm-ups, rest timer, note, reorder, remove.
Future<void> showExerciseMenuSheet(BuildContext context, int exerciseIndex) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => ExerciseMenuSheet(exerciseIndex: exerciseIndex),
  );
}

class ExerciseMenuSheet extends ConsumerStatefulWidget {
  final int exerciseIndex;

  const ExerciseMenuSheet({super.key, required this.exerciseIndex});

  @override
  ConsumerState<ExerciseMenuSheet> createState() => _ExerciseMenuSheetState();
}

class _ExerciseMenuSheetState extends ConsumerState<ExerciseMenuSheet> {
  late int _index = widget.exerciseIndex;

  static const _stepSeconds = 30;
  static const _minRest = 30;
  static const _maxRest = 600;

  Future<void> _editNote(Exercise exercise) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: exercise.note ?? ''),
    );
    if (text == null || !mounted) return;
    ref.read(activeWorkoutProvider.notifier).setNote(_index, text);
  }

  Future<void> _remove() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutRemoveTitle),
        content: Text(l10n.workoutRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.workoutRemoveConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(activeWorkoutProvider.notifier).removeExercise(_index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);
    if (workout == null || _index >= workout.exercises.length) {
      return const SizedBox.shrink();
    }
    final exercise = workout.exercises[_index];
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(activeWorkoutProvider.notifier);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final info = catalog?.byName(exercise.name);
    final text = ref.watch(catalogTextProvider);
    final similar = info == null || catalog == null
        ? const <ExerciseInfo>[]
        : catalog.similarTo(info);

    final working = exercise.sets.where((s) => !s.warmup).toList();
    final canWarmUp = !exercise.sets.any((s) => s.warmup) &&
        working.isNotEmpty &&
        working.first.kg > 0;
    final rest = exercise.restSeconds ?? kDefaultRestSeconds;

    void setRest(int seconds) =>
        notifier.setRest(_index, seconds.clamp(_minRest, _maxRest));

    final header = [
      if (info != null) text.pattern(info.pattern),
      l10n.workoutSetCount(working.length),
    ].join(' · ');

    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MenuRow(
          icon: Icons.swap_horiz,
          title: l10n.workoutMenuSwap,
          subtitle: similar.isEmpty
              ? l10n.workoutMenuSwapSub
              : l10n.workoutMenuSimilar(
                  similar.take(3).map(text.exerciseName).join(', ')),
          trailing: const _Chevron(),
          onTap: () {
            final index = _index;
            Navigator.pop(context);
            openExercisePicker(context, ref, replaceIndex: index);
          },
        ),
        if (canWarmUp)
          _MenuRow(
            icon: Icons.local_fire_department_outlined,
            title: l10n.workoutMenuWarmup,
            subtitle: l10n.workoutMenuWarmupSub([
              for (final w in warmupPlan(working.first.kg))
                '${formatKg(w.kg)} ${l10n.unitKg} × ${w.reps}',
            ].join(', ')),
            trailing: Icon(Icons.add, color: palette.textPrimary),
            onTap: () {
              notifier.addWarmupSets(_index);
              Navigator.pop(context);
            },
          ),
        _MenuRow(
          icon: Icons.timer_outlined,
          title: l10n.workoutMenuRest,
          subtitle: l10n.workoutMenuRestSub,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoundButton(
                key: const ValueKey('restMinus'),
                icon: Icons.remove,
                onTap:
                    rest > _minRest ? () => setRest(rest - _stepSeconds) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  formatClock(Duration(seconds: rest)),
                  style: AppText.headingS.copyWith(
                    color: palette.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _RoundButton(
                key: const ValueKey('restPlus'),
                icon: Icons.add,
                onTap:
                    rest < _maxRest ? () => setRest(rest + _stepSeconds) : null,
              ),
            ],
          ),
        ),
        _MenuRow(
          icon: Icons.description_outlined,
          title: l10n.workoutMenuNote,
          subtitle: exercise.note ?? l10n.workoutMenuNoteEmpty,
          trailing: const _Chevron(),
          onTap: () => _editNote(exercise),
        ),
        _MenuRow(
          icon: Icons.swap_vert,
          title: l10n.workoutMenuReorder,
          subtitle: l10n.workoutMenuReorderSub,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoundButton(
                key: const ValueKey('moveUp'),
                icon: Icons.keyboard_arrow_up,
                onTap: _index > 0
                    ? () {
                        notifier.moveExercise(_index, _index - 1);
                        setState(() => _index--);
                      }
                    : null,
              ),
              const SizedBox(width: AppSpacing.xs),
              _RoundButton(
                key: const ValueKey('moveDown'),
                icon: Icons.keyboard_arrow_down,
                onTap: _index < workout.exercises.length - 1
                    ? () {
                        notifier.moveExercise(_index, _index + 1);
                        setState(() => _index++);
                      }
                    : null,
              ),
            ],
          ),
        ),
        _MenuRow(
          icon: Icons.delete_outline,
          title: l10n.workoutMenuRemove,
          danger: true,
          onTap: _remove,
        ),
      ],
    );

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: AppRadius.fullAll,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(text.exercise(exercise.name),
                style: AppText.headingL.copyWith(color: palette.textPrimary)),
            Text(header,
                style: AppText.body14.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.sm),
            body,
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.chevron_right, color: AppPalette.of(context).textPrimary);
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: palette.sheetTile,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? palette.textSecondary : palette.textPrimary,
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool danger;
  final VoidCallback? onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = danger ? palette.danger : palette.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: palette.sheetTile,
                borderRadius: AppRadius.smAll,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.headingS.copyWith(color: color)),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style:
                          AppText.body14.copyWith(color: palette.textSecondary),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  final String initial;

  const _NoteDialog({required this.initial});

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.workoutMenuNote),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.workoutMenuNoteHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l10n.workoutNoteSave),
        ),
      ],
    );
  }
}

/// Opens the add-exercise screen over the shell. The workout stays active;
/// the sheet folds down so the screen is visible, and the picker opens it
/// again when it closes.
void openExercisePicker(BuildContext context, WidgetRef ref,
    {int? replaceIndex}) {
  ref.read(activeWorkoutExpandedProvider.notifier).state = false;
  GoRouter.of(context).push(AppRouter.addExerciseTo(
    replace: replaceIndex != null,
    index: replaceIndex ?? 0,
  ));
}
