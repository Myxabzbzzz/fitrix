import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/felix_plan_badge.dart';
import 'package:fitrix/features/workouts/data/felix_templates_store.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

const _sports = [
  Sport.gym,
  Sport.fitness,
  Sport.running,
  Sport.cycling,
  Sport.football,
  Sport.winterSports,
];

Future<void> showAddSessionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => const _AddSessionSheet(),
  );
}

/// One thing the user can plan: a saved workout or a generic sport entry.
class _Choice {
  final String key;
  final Sport sport;
  final String title;
  final String subtitle;
  final String? templateId;
  final int minutes;
  final Intensity intensity;
  final bool felix;

  const _Choice({
    required this.key,
    required this.sport,
    required this.title,
    required this.subtitle,
    this.templateId,
    required this.minutes,
    required this.intensity,
    this.felix = false,
  });
}

class _AddSessionSheet extends ConsumerStatefulWidget {
  const _AddSessionSheet();

  @override
  ConsumerState<_AddSessionSheet> createState() => _AddSessionSheetState();
}

class _AddSessionSheetState extends ConsumerState<_AddSessionSheet> {
  Sport _sport = Sport.gym;
  String? _choiceKey;
  DateTime? _day;

  /// The day Felix moved the selection away from; null once the user picks.
  DateTime? _autoFrom;

  List<_Choice> _choices(AppLocalizations l10n) {
    final out = <_Choice>[];
    final felixIds = ref.watch(felixTemplateIdsProvider);
    for (final t in ref.watch(workoutTemplatesProvider)) {
      if (t.sport != _sport) continue;
      final minutes = t.estimatedDuration.inMinutes;
      out.add(_Choice(
        key: 't:${t.id}',
        sport: t.sport,
        title: t.name,
        subtitle: l10n.planExercisesMeta(
            t.exercises.length, planDuration(l10n, minutes)),
        templateId: t.id,
        minutes: minutes,
        intensity: intensityOfTemplate(t),
        felix: felixIds.contains(t.id),
      ));
    }
    if (_sport != Sport.gym) {
      final (String title, int minutes, Intensity i) = switch (_sport) {
        Sport.football => (l10n.planGenericFootball, 90, Intensity.hard),
        Sport.winterSports => (l10n.planSkiing, 120, Intensity.hard),
        Sport.running => (l10n.sportRunning, 40, Intensity.normal),
        Sport.cycling => (l10n.sportCycling, 60, Intensity.normal),
        _ => (l10n.sportFitness, 45, Intensity.normal),
      };
      out.add(_Choice(
        key: 'g:${_sport.name}',
        sport: _sport,
        title: title,
        subtitle: planDuration(l10n, minutes),
        minutes: minutes,
        intensity: i,
      ));
    }
    return out;
  }

  List<DateTime> _days(DateTime today) =>
      [for (var i = 0; i < 6; i++) addDays(today, i)];

  /// Today, or when that would be a 3rd hard day in a row, the first day
  /// that isn't and has no hard session yet.
  DateTime _defaultDay(
      List<PlannedSession> plan, DateTime today, Intensity intensity) {
    if (!wouldBeThirdHardDayInARow(plan, today, intensity)) return today;
    for (final d in _days(today)) {
      if (!wouldBeThirdHardDayInARow(plan, d, intensity) &&
          !plan
              .any((s) => s.intensity == Intensity.hard && sameDay(s.day, d))) {
        return d;
      }
    }
    return today;
  }

  void _apply(_Choice c, List<PlannedSession> plan, DateTime today) {
    final day = _defaultDay(plan, today, c.intensity);
    _choiceKey = c.key;
    _day = day;
    _autoFrom = day == today ? null : today;
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider);
    final choices = _choices(l10n);
    var choice = choices.where((c) => c.key == _choiceKey).firstOrNull;
    if (choice == null && choices.isNotEmpty) {
      // First build or a new sport: same default as tapping the first row.
      choice = choices.first;
      _apply(choice, plan, today);
    }
    final day = _day ?? today;
    final thirdHard = choice != null &&
        wouldBeThirdHardDayInARow(plan, day, choice.intensity);
    final warnDay = thirdHard ? day : _autoFrom;
    final showWarning =
        choice != null && choice.intensity == Intensity.hard && warnDay != null;

    String dayName(DateTime d) =>
        d == today ? l10n.homeToday : weekdayLong(context, d);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                          color: palette.border,
                          borderRadius: AppRadius.fullAll),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.planAddTitle,
                            style: AppText.headingM
                                .copyWith(color: palette.textPrimary)),
                      ),
                      IconButton(
                        tooltip: l10n.cancel,
                        icon: Icon(Icons.close, color: palette.accent),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final s in _sports)
                        _Pill(
                          label: s == Sport.winterSports
                              ? l10n.planSkiing
                              : s.localizedLabel(l10n),
                          selected: s == _sport,
                          onTap: () => setState(() {
                            _sport = s;
                            _choiceKey = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _Label(l10n.planWorkoutLabel),
                  const SizedBox(height: AppSpacing.xs),
                  for (final c in choices) ...[
                    _ChoiceRow(
                      choice: c,
                      selected: c.key == choice?.key,
                      onTap: () => setState(() => _apply(c, plan, today)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  _Label(l10n.planDayLabel),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final d in _days(today))
                        _Pill(
                          label: d == today
                              ? l10n.homeToday
                              : weekdayShort(context, d),
                          selected: d == day,
                          onTap: () => setState(() {
                            _day = d;
                            _autoFrom = null;
                          }),
                        ),
                    ],
                  ),
                  if (showWarning) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      key: const Key('plan-add-warning'),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: palette.danger.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.bolt, size: 20, color: palette.danger),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.planWarnThird(dayName(warnDay)),
                                    style: AppText.bodyStrong
                                        .copyWith(color: palette.textPrimary)),
                                Text(
                                  thirdHard
                                      ? l10n.planWarnPick
                                      : l10n.planWarnAuto(dayName(day)),
                                  style: AppText.caption
                                      .copyWith(color: palette.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AppButton(
              label: choice == null
                  ? l10n.planAddSession
                  : l10n.planAddButton(choice.title, dayName(day)),
              size: AppButtonSize.large,
              expand: true,
              onPressed: choice == null
                  ? null
                  : () async {
                      final c = choice!;
                      await ref.read(weekPlanProvider.notifier).add(
                            PlannedSession(
                              id: const Uuid().v4(),
                              day: day,
                              sport: c.sport,
                              title: c.title,
                              templateId: c.templateId,
                              minutes: c.minutes,
                              intensity: c.intensity,
                            ),
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: AppText.microStrong
          .copyWith(color: AppPalette.of(context).textSecondary));
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Pill(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? palette.pillSelected : palette.background,
            borderRadius: AppRadius.fullAll,
            border: selected ? null : Border.all(color: palette.border),
          ),
          child: Text(
            label,
            style: AppText.body14.copyWith(
                color: selected ? palette.onPillSelected : palette.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final _Choice choice;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceRow(
      {required this.choice, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final fg = selected ? palette.onPillSelected : palette.textPrimary;
    final fg2 = selected
        ? palette.onPillSelected.withValues(alpha: 0.6)
        : palette.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? palette.pillSelected : palette.tile,
            borderRadius: AppRadius.mdAll,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? palette.accent : Colors.transparent,
                  border: selected ? null : Border.all(color: palette.border),
                ),
                child: selected
                    ? Icon(Icons.circle, size: 8, color: palette.onAccent)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(choice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headingS.copyWith(color: fg)),
                    Text(choice.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(color: fg2)),
                    if (choice.felix) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      FelixPlanBadge(onDark: selected),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              PlanChip.intensity(context, choice.intensity, onDark: selected),
            ],
          ),
        ),
      ),
    );
  }
}
