import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/widgets/shrink_to_fit_text.dart';
import 'package:fitrix/core/widgets/equal_height_row.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/domain/training_math.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_format.dart';
import 'package:fitrix/features/workouts/presentation/widgets/live_log_rpe_sheet.dart';

/// Shown after "Finish workout": the summary of the finished (not yet saved)
/// workout in [pendingCompletedWorkoutProvider], an overall RPE question,
/// and Save / Discard. Without a pending workout it goes home.
class WorkoutCompleteScreen extends ConsumerStatefulWidget {
  const WorkoutCompleteScreen({super.key});

  @override
  ConsumerState<WorkoutCompleteScreen> createState() =>
      _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends ConsumerState<WorkoutCompleteScreen> {
  int? _rpe;

  /// Set before this screen clears the pending workout itself, so the "no
  /// pending workout, go home" check doesn't fight the navigation.
  bool _leaving = false;

  /// Save ran already (a second tap must not store the workout twice).
  bool _saved = false;

  void _go(String location) {
    _leaving = true;
    GoRouter.of(context).go(location);
  }

  void _close() {
    _leaving = true;
    ref.read(pendingCompletedWorkoutProvider.notifier).state = null;
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRouter.home);
    }
  }

  /// Stores the summary the user confirmed (with the chosen RPE) once, then
  /// ends the workout.
  void _save(CompletedWorkout pending) {
    if (_saved) return;
    _saved = true;
    final messenger = ScaffoldMessenger.of(context);
    final savedText = AppLocalizations.of(context).workoutSaved;
    _leaving = true;
    ref
        .read(workoutHistoryProvider.notifier)
        .add(pending.copyWith(sessionRpe: _rpe));
    ref.read(activeWorkoutProvider.notifier).discard();
    ref.read(pendingCompletedWorkoutProvider.notifier).state = null;
    messenger.showSnackBar(SnackBar(content: Text(savedText)));
    GoRouter.of(context).go(AppRouter.progress);
  }

  Future<void> _discard() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.workoutDiscardTitle),
        content: Text(l10n.workoutDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.workoutKeepGoing),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.workoutDiscard),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(activeWorkoutProvider.notifier).discard();
    ref.read(pendingCompletedWorkoutProvider.notifier).state = null;
    _go(AppRouter.home);
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingCompletedWorkoutProvider);
    final palette = AppPalette.of(context);
    if (pending == null) {
      if (!_leaving) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_leaving) _go(AppRouter.home);
        });
      }
      return Scaffold(backgroundColor: palette.background);
    }

    final l10n = AppLocalizations.of(context);
    final history = ref.watch(workoutHistoryProvider);
    final active = ref.watch(activeWorkoutProvider);
    final workout = pending.copyWith(sessionRpe: _rpe);
    final records = recordsIn(workout, history);
    final text = ref.watch(catalogTextProvider);
    final recordNames = {for (final r in records) r.exercise.toLowerCase()};

    // First exercise whose suggested weight beats today's best: judged on
    // the planned sets, so a skipped set means "stay where you are".
    ({String name, double kg})? nextTime;
    for (final e in workout.exercises) {
      final plan = active?.exercises
              .where((a) => a.name.toLowerCase() == e.name.toLowerCase())
              .map((a) => a.sets)
              .firstOrNull ??
          e.sets;
      final suggested = suggestNextKg(plan);
      final best = bestSet(e.sets);
      if (suggested != null && best != null && suggested > best.kg) {
        nextTime = (name: e.name, kg: suggested);
        break;
      }
    }

    final minutes = workout.duration.inMinutes;
    // Under a minute in seconds rather than "0:00".
    final duration = minutes == 0
        ? l10n.durationSeconds(workout.duration.inSeconds)
        : '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _close,
                    icon: Icon(Icons.close, color: palette.textPrimary),
                  ),
                  Expanded(
                    child: Text(
                      DateFormat('EEE d MMM · HH:mm')
                          .format(workout.finishedAt),
                      textAlign: TextAlign.center,
                      style: AppText.bodyStrong
                          .copyWith(color: palette.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                children: [
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: palette.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.emoji_events_outlined,
                          color: palette.onAccent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.workoutCompleteTitle,
                    textAlign: TextAlign.center,
                    style:
                        AppText.headingXL.copyWith(color: palette.textPrimary),
                  ),
                  Text(
                    l10n.workoutCompleteSubtitle(
                        text.completedTitle(workout), records.length),
                    textAlign: TextAlign.center,
                    style: AppText.bodyStrong
                        .copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _StatRows([
                    _StatTile(l10n.workoutTileDuration, duration),
                    _StatTile(
                      l10n.workoutTileVolume,
                      '${formatTonnes(context, volumeKg(workout.exercises))} '
                      '${l10n.unitTonnes}',
                    ),
                    _StatTile(l10n.workoutTileSets, '${workout.setCount}'),
                    // "No new records" is already in the subtitle.
                    if (records.isNotEmpty)
                      _StatTile(
                        l10n.workoutTileRecords,
                        '${records.length}',
                        accent: true,
                      ),
                    if (_rpe != null)
                      _StatTile(
                        l10n.workoutTileLoad,
                        NumberFormat.decimalPattern(
                                Localizations.localeOf(context).toString())
                            .format(workout.load),
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  _RpeCard(
                    rpe: _rpe,
                    onPick: (n) => setState(() => _rpe = n),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.workoutExercisesTitle,
                          style: AppText.headingM
                              .copyWith(color: palette.textPrimary),
                        ),
                      ),
                      Text(
                        l10n.workoutBestSetE1rm,
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.tile,
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < workout.exercises.length; i++)
                          _ExerciseRow(
                            exercise: workout.exercises[i],
                            name: text.exercise(workout.exercises[i].name),
                            record: recordNames.contains(
                                workout.exercises[i].name.toLowerCase()),
                            divider: i > 0,
                          ),
                      ],
                    ),
                  ),
                  if (nextTime != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _NextTimeCard(
                      text: l10n.workoutNextTimeBody(
                          text.exercise(nextTime.name), formatKg(nextTime.kg)),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
              child: EqualHeightRow(
                spacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: l10n.workoutDiscard,
                    style: AppButtonStyle.secondary,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: _discard,
                  ),
                  AppButton(
                    label: l10n.workoutSave,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: () => _save(pending),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat tiles in balanced rows: 3, 2 + 2 or 3 + 2, never a lone tile.
class _StatRows extends StatelessWidget {
  final List<_StatTile> tiles;

  const _StatRows(this.tiles);

  @override
  Widget build(BuildContext context) {
    final perRow = tiles.length == 4 ? 2 : 3;
    return Column(
      children: [
        for (var i = 0; i < tiles.length; i += perRow) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          EqualHeightRow(
            spacing: AppSpacing.xs,
            children: [
              for (var j = i; j < i + perRow && j < tiles.length; j++) tiles[j],
            ],
          ),
        ],
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _StatTile(this.label, this.value, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        // Values sit on the tile's bottom edge, so they line up across a
        // row even when one label wraps.
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShrinkToFitText(
            label,
            style: AppText.body14.copyWith(color: palette.textSecondary),
          ),
          ShrinkToFitText(
            value,
            style: AppText.headingL.copyWith(
              color: accent ? palette.accent : palette.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RpeCard extends StatelessWidget {
  final int? rpe;
  final ValueChanged<int> onPick;

  const _RpeCard({required this.rpe, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final n = rpe;
    final label = n == null
        ? ''
        : switch (n) {
            <= 2 => l10n.workoutRpeVeryEasy,
            <= 4 => l10n.workoutRpeEasy,
            <= 6 => l10n.workoutRpeModerate,
            7 => l10n.workoutRpeHard,
            <= 9 => l10n.workoutRpeVeryHard,
            _ => l10n.workoutRpeMax,
          };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: AppRadius.mdAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.workoutOverallTitle,
            style: AppText.headingS.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          RpeScale(
            keyPrefix: 'completeRpe',
            selected: rpe,
            onPick: onPick,
            cellColor: palette.background,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            n == null
                ? l10n.workoutOverallHint
                : l10n.workoutOverallCaption(n, label),
            style: AppText.body14.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final Exercise exercise;

  /// [exercise]'s name in the app language.
  final String name;
  final bool record;
  final bool divider;

  const _ExerciseRow({
    required this.exercise,
    required this.name,
    required this.record,
    required this.divider,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final best = bestSet(exercise.sets);
    final estimate =
        best == null || best.kg == 0 ? null : e1rm(best.kg, best.reps);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: divider ? Border(top: BorderSide(color: palette.border)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppText.headingS.copyWith(color: palette.textPrimary),
                ),
                if (best != null)
                  Text(
                    l10n.workoutBestSet(formatSetLoad(context, best)),
                    style:
                        AppText.body14.copyWith(color: palette.textSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                estimate == null ? '—' : formatOneDecimal(estimate),
                style: AppText.headingS.copyWith(
                  color: palette.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                record ? l10n.workoutPr : l10n.workoutE1rm,
                style: AppText.caption.copyWith(
                  color: record ? palette.accent : palette.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextTimeCard extends StatelessWidget {
  final String text;

  const _NextTimeCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Image.asset(
              'assets/images/felix_robot.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.workoutNextTimeTitle.toUpperCase(),
                  style: AppText.captionStrong.copyWith(color: palette.accent),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  text,
                  style: AppText.body14.copyWith(color: palette.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
