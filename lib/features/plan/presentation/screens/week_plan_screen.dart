import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/plan/presentation/widgets/add_session_sheet.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_day_section.dart';

/// "This week": the Mon-Sun plan, its training load, Felix's advice and a
/// way to add sessions.
class WeekPlanScreen extends ConsumerWidget {
  const WeekPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final plan = ref.watch(weekPlanProvider);
    final history = ref.watch(workoutHistoryProvider);
    final templates = ref.watch(workoutTemplatesProvider);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final dismissed = ref.watch(dismissedSuggestionsProvider);
    final readiness = ref.watch(todayReadinessProvider);

    final start = weekStartOf(today);
    final days = [for (var i = 0; i < 7; i++) addDays(start, i)];
    final week = [
      for (final s in plan)
        if (!s.day.isBefore(start) && !s.day.isAfter(days.last)) s,
    ];
    SessionStatus status(PlannedSession s) =>
        statusOf(s, history, today, plan: plan);
    final doneCount = week.where((s) => status(s) == SessionStatus.done).length;

    var suggestion = catalog == null
        ? null
        : suggestPlanChange(plan, today, catalog,
            templates: templates,
            isDone: (s) => status(s) == SessionStatus.done);
    if (suggestion != null &&
        dismissed.contains(
            DismissedSuggestionsNotifier.keyFor(suggestion.sessionId, today))) {
      suggestion = null;
    }

    final locale = Localizations.localeOf(context).toString();
    final range = start.month == days.last.month
        ? '${start.day}–${days.last.day} '
            '${DateFormat.MMM(locale).format(days.last)}'
        : '${DateFormat('d MMM', locale).format(start)} – '
            '${DateFormat('d MMM', locale).format(days.last)}';

    // Sessions after this Sunday that the add sheet can reach (today + 6).
    final nextStart = addDays(start, 7);
    final nextLast = addDays(today, 6);
    final nextDays = [
      for (var d = nextStart; !d.isAfter(nextLast); d = addDays(d, 1))
        if (plan.any((s) => s.day == d)) d,
    ];
    final nextWeekHasPlan = plan.any((s) => !s.day.isBefore(nextStart));
    final (seeds, seedsNextWeek) =
        _seedSessions(templates, start, today, nextWeekHasPlan);
    final showSeedOffer = week.isEmpty && (seeds.isNotEmpty || plan.isEmpty);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(
              l10n.planTitle,
              trailing: IconButton(
                key: const Key('plan-add'),
                tooltip: l10n.planAddSession,
                icon: Icon(Icons.add, color: palette.textPrimary),
                onPressed: () => showAddSessionSheet(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                children: [
                  Text(
                    '$range · ${l10n.planSummary(week.length, doneCount)}',
                    style: AppText.bodyRegular
                        .copyWith(color: palette.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _DayStrip(
                    days: days,
                    today: today,
                    sessions: week,
                    status: status,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LoadCard(
                    hard: hardInNext3Days(plan, today),
                    recovery: readiness?.score,
                  ),
                  if (suggestion != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _FelixCard(
                      suggestion: suggestion,
                      plan: plan,
                      today: today,
                    ),
                  ],
                  if (showSeedOffer) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SeedOffer(seeds: seeds, nextWeek: seedsNextWeek),
                  ],
                  for (final d in days) ...[
                    const SizedBox(height: AppSpacing.md),
                    PlanDaySection(
                      day: d,
                      today: today,
                      sessions: [
                        for (final s in week)
                          if (s.day == d) s,
                      ],
                      history: history,
                      templates: templates,
                    ),
                  ],
                  if (nextDays.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.planNextWeek,
                        style: AppText.headingM
                            .copyWith(color: palette.textPrimary)),
                    for (final d in nextDays) ...[
                      const SizedBox(height: AppSpacing.md),
                      PlanDaySection(
                        day: d,
                        today: today,
                        sessions: [
                          for (final s in plan)
                            if (s.day == d) s,
                        ],
                        history: history,
                        templates: templates,
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l10n.planAddSession,
                    icon: Icons.add,
                    style: AppButtonStyle.secondary,
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: () => showAddSessionSheet(context),
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

/// One session per gym plan on Mon, Wed and Fri. This week's days from
/// today on; when none is left, next week's (unless it already has
/// sessions). The flag says it is next week.
(List<PlannedSession>, bool) _seedSessions(List<WorkoutTemplate> templates,
    DateTime weekStart, DateTime today, bool nextWeekHasPlan) {
  final gym = [
    for (final t in templates)
      if (t.sport == Sport.gym) t,
  ];
  List<PlannedSession> seed(DateTime monday) {
    final out = <PlannedSession>[];
    for (var i = 0; i < gym.length && i < 3; i++) {
      final day = addDays(monday, i * 2);
      if (day.isBefore(today)) continue;
      out.add(PlannedSession(
        id: const Uuid().v4(),
        day: day,
        sport: Sport.gym,
        title: gym[i].name,
        templateId: gym[i].id,
        minutes: gym[i].estimatedDuration.inMinutes,
        intensity: intensityOfTemplate(gym[i]),
      ));
    }
    return out;
  }

  final thisWeek = seed(weekStart);
  if (thisWeek.isNotEmpty) return (thisWeek, false);
  if (nextWeekHasPlan) return (const [], false);
  return (seed(addDays(weekStart, 7)), true);
}

class _DayStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime today;
  final List<PlannedSession> sessions;
  final SessionStatus Function(PlannedSession) status;

  const _DayStrip({
    required this.days,
    required this.today,
    required this.sessions,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Builder(builder: (context) {
              final d = days[i];
              final isToday = d == today;
              final fg = isToday ? palette.onPillSelected : palette.textPrimary;
              final mine = [
                for (final s in sessions)
                  if (s.day == d) s,
              ];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: isToday ? palette.pillSelected : palette.tile,
                  borderRadius: AppRadius.smAll,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "пн", not "П": one letter is ambiguous in Russian
                    // (Mon/Fri, Tue/Sun, Wed/Sat).
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        weekdayShort(context, d),
                        maxLines: 1,
                        style: AppText.micro.copyWith(
                            color: isToday ? fg : palette.textSecondary),
                      ),
                    ),
                    Text('${d.day}',
                        style: AppText.bodyStrong.copyWith(color: fg)),
                    const SizedBox(height: AppSpacing.xxs),
                    SizedBox(
                      height: 4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final s in mine.take(3))
                            Container(
                              width: 4,
                              height: 4,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: status(s) == SessionStatus.done
                                    ? palette.textSecondary
                                    : palette.accent,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _LoadCard extends StatelessWidget {
  final int hard;
  final int? recovery;

  const _LoadCard({required this.hard, required this.recovery});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final level = hard >= 3 ? 2 : (hard == 2 ? 1 : 0);
    final label =
        [l10n.planLoadEasy, l10n.planLoadNormal, l10n.planLoadHigh][level];
    final color = level == 2 ? palette.danger : palette.accent;
    final caption = [
      l10n.planLoadCaption(hard),
      if (recovery != null) l10n.planRecoveryToday(recovery!),
    ].join(' ');

    Widget segment(Color c) => Expanded(
          child: Container(
            height: 4,
            decoration:
                BoxDecoration(color: c, borderRadius: AppRadius.fullAll),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.planLoadTitle,
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(label,
                  key: const Key('plan-load-label'),
                  style: AppText.bodyStrong.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 16,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    segment(palette.accent),
                    const SizedBox(width: AppSpacing.xxs),
                    segment(palette.accent),
                    const SizedBox(width: AppSpacing.xxs),
                    segment(palette.danger),
                  ],
                ),
                Align(
                  alignment: Alignment(level - 1.0, 0),
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: palette.tile,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final t in [
                l10n.planLoadEasy,
                l10n.planLoadNormal,
                l10n.planLoadHigh
              ])
                Text(t,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(caption,
              style: AppText.body14.copyWith(color: palette.textPrimary)),
        ],
      ),
    );
  }
}

class _FelixCard extends ConsumerWidget {
  final PlanSuggestion suggestion;
  final List<PlannedSession> plan;
  final DateTime today;

  const _FelixCard({
    required this.suggestion,
    required this.plan,
    required this.today,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final moved = plan.firstWhere((s) => s.id == suggestion.sessionId);
    final other = plan.firstWhere((s) => s.id == suggestion.otherSessionId);
    final text = l10n.planFelixText(
      other.title,
      weekdayLong(context, other.day),
      moved.title,
      weekdayLong(context, moved.day),
      weekdayLong(context, suggestion.to),
    );
    return KeyedSubtree(
      key: const Key('plan-felix-card'),
      child: CoachCard(
        eyebrow: l10n.planFelixLabel,
        title: '',
        message: text,
        imageAsset: 'assets/images/felix_robot.png',
        imageWidth: 56,
        imageHeight: 80,
        primaryLabel: l10n.planOptimize,
        onPrimary: () => ref
            .read(weekPlanProvider.notifier)
            .move(suggestion.sessionId, suggestion.to),
        secondaryLabel: l10n.planKeep,
        onSecondary: () => ref
            .read(dismissedSuggestionsProvider.notifier)
            .dismiss(suggestion.sessionId, today),
        onAsk: () => askFelix(
          context,
          ref,
          topic: AssistantTopic.forSport(Sport.gym),
          draft: l10n.planAskDraft(
            other.title,
            weekdayLong(context, other.day),
            moved.title,
            weekdayLong(context, moved.day),
          ),
        ),
      ),
    );
  }
}

class _SeedOffer extends ConsumerWidget {
  final List<PlannedSession> seeds;
  final bool nextWeek;
  const _SeedOffer({required this.seeds, required this.nextWeek});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.planEmptyTitle,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(nextWeek ? l10n.planEmptyBodyNextWeek : l10n.planEmptyBody,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          if (seeds.isNotEmpty)
            AppButton(
              label: nextWeek ? l10n.planPlanNextWeek : l10n.planPlanWeek,
              onPressed: () =>
                  ref.read(weekPlanProvider.notifier).addAll(seeds),
            )
          else
            AppButton(
              label: l10n.planAddSession,
              onPressed: () => showAddSessionSheet(context),
            ),
        ],
      ),
    );
  }
}
