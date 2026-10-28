import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/core/widgets/equal_height_row.dart';
import 'package:fitrix/core/widgets/shrink_to_fit_text.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/features/programs/presentation/providers/programs_provider.dart';
import 'package:fitrix/features/programs/presentation/widgets/program_widgets.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Shows the start sheet. Completes with true once the program started.
Future<bool?> showStartProgramSheet(
    BuildContext context, TrainingProgram program, List<int> weekdays) {
  return showModalBottomSheet<bool>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
    builder: (_) => _StartSheet(program: program, weekdays: weekdays),
  );
}

enum _DateChoice { today, nextMonday, custom }

class _StartSheet extends ConsumerStatefulWidget {
  final TrainingProgram program;
  final List<int> weekdays;
  const _StartSheet({required this.program, required this.weekdays});

  @override
  ConsumerState<_StartSheet> createState() => _StartSheetState();
}

class _StartSheetState extends ConsumerState<_StartSheet> {
  _DateChoice _choice = _DateChoice.nextMonday;
  DateTime? _custom;
  late final Set<int> _days = {...widget.weekdays};
  bool _replace = true;
  bool _busy = false;

  DateTime _dateFor(DateTime today) => switch (_choice) {
        _DateChoice.today => today,
        _DateChoice.nextMonday => addDays(today, 8 - today.weekday),
        _DateChoice.custom => _custom ?? today,
      };

  Future<void> _pickDate(DateTime today) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _custom ?? today,
      firstDate: today,
      lastDate: addDays(today, 365),
    );
    if (d != null) {
      setState(() {
        _custom = dayOf(d);
        _choice = _DateChoice.custom;
      });
    }
  }

  Future<void> _start(DateTime start) async {
    setState(() => _busy = true);
    await ref.read(programStarterProvider).start(
          program: widget.program,
          start: start,
          weekdays: _days.toList()..sort(),
          replacePlan: _replace,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final p = widget.program;
    final today = ref.watch(todayProvider);
    final start = _dateFor(today);
    final nonGym = ref.watch(upcomingNonGymProvider);
    final hardDays = hardNonGymWeekdays(nonGym).toList()..sort();
    final history = ref.watch(workoutHistoryProvider);
    final exercises = ref.watch(exerciseCatalogProvider).valueOrNull;
    final weights = [
      for (final e in mainLifts(p, exercises, max: 6))
        if (startKg(e.exercise, history, e.repsHigh, catalog: exercises)
            case final kg?)
          (name: e.exercise, kg: kg, reps: e.repsHigh),
    ];
    final active = ref.watch(activeProgramProvider);
    final ok = _days.length == p.perWeek;
    final dateText = dayAndMonth(context, start);

    Widget choice(_DateChoice c, String label, {VoidCallback? onTap}) => _Chip(
          label: label,
          selected: _choice == c,
          onTap: onTap ?? () => setState(() => _choice = c),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.programStartTitle(p.name),
                      style: AppText.headingL
                          .copyWith(color: palette.textPrimary)),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: palette.accent),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Text(
                l10n.programStartSub(p.weeks,
                    dayAndMonth(context, addDays(start, p.weeks * 7 - 1))),
                style: AppText.body14.copyWith(color: palette.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.programStartDate,
                style: AppText.headingS.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            EqualHeightRow(
              spacing: AppSpacing.xs,
              children: [
                choice(_DateChoice.today, l10n.programToday),
                choice(_DateChoice.nextMonday,
                    dayAndMonth(context, addDays(today, 8 - today.weekday))),
                choice(
                    _DateChoice.custom,
                    _custom == null
                        ? l10n.programPickDate
                        : dayAndMonth(context, _custom!),
                    onTap: () => _pickDate(today)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.programTrainingDays,
                      style: AppText.headingS
                          .copyWith(color: palette.textPrimary)),
                ),
                Text(l10n.programDaysPicked(_days.length, p.perWeek),
                    style:
                        AppText.body14.copyWith(color: palette.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                for (var d = 1; d <= 7; d++) ...[
                  if (d > 1) const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: _Chip(
                      key: Key('start-day-$d'),
                      label: weekdayName(context, d),
                      selected: _days.contains(d),
                      danger: hardDays.contains(d),
                      compact: true,
                      onTap: () => setState(() {
                        if (!_days.add(d)) _days.remove(d);
                      }),
                    ),
                  ),
                ],
              ],
            ),
            for (final d in hardDays) ...[
              const SizedBox(height: AppSpacing.xs),
              _ClashCard(
                title: l10n.programClashTitle(weekdayFull(context, d),
                    nonGym.firstWhere((s) => s.day.weekday == d).title),
                body: _days.contains(d)
                    ? l10n.programClashHit
                    : _days.contains(d == 1 ? 7 : d - 1) ||
                            _days.contains(d == 7 ? 1 : d + 1)
                        ? l10n.programClashNear
                        : l10n.programClashAvoid,
              ),
            ],
            if (weights.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.programStartWeights,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                  ),
                  Text(l10n.programFromRecords,
                      style: AppText.body14
                          .copyWith(color: palette.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                key: const Key('start-weights'),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                    color: palette.sheetTile, borderRadius: AppRadius.mdAll),
                child: Column(
                  children: [
                    for (var i = 0; i < weights.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: palette.border),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(weights[i].name,
                                  style: AppText.body14
                                      .copyWith(color: palette.textPrimary)),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                                l10n.programKgReps(
                                    formatKg(weights[i].kg), weights[i].reps),
                                style: AppText.bodyStrong
                                    .copyWith(color: palette.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.programReplacePlan,
                          style: AppText.headingS
                              .copyWith(color: palette.textPrimary)),
                      Text(l10n.programReplaceSub,
                          style: AppText.body14
                              .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  key: const Key('start-replace'),
                  value: _replace,
                  activeTrackColor: palette.accent,
                  activeThumbColor: palette.onAccent,
                  onChanged: (v) => setState(() => _replace = v),
                ),
              ],
            ),
            if (active != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.programReplacesActive,
                  style:
                      AppText.caption.copyWith(color: palette.textSecondary)),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const Key('start-confirm'),
              label: l10n.programStartOn(dateText),
              size: AppButtonSize.large,
              expand: true,
              onPressed: ok && !_busy ? () => _start(start) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool danger;
  final bool compact;
  final VoidCallback onTap;
  const _Chip(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.danger = false,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final bg = selected
        ? palette.pillSelected
        : danger
            ? palette.danger.withValues(alpha: 0.12)
            : palette.sheetTile;
    final fg = selected
        ? palette.onPillSelected
        : danger
            ? palette.danger
            : palette.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          curve: Motion.curve,
          constraints: const BoxConstraints(minHeight: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadius.smAll),
          child: ShrinkToFitText(label,
              textAlign: TextAlign.center,
              style: (compact ? AppText.bodyStrong : AppText.headingS)
                  .copyWith(color: fg)),
        ),
      ),
    );
  }
}

class _ClashCard extends StatelessWidget {
  final String title;
  final String body;
  const _ClashCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
          color: palette.danger.withValues(alpha: 0.12),
          borderRadius: AppRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt, color: palette.danger, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                Text(body,
                    style:
                        AppText.body14.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
