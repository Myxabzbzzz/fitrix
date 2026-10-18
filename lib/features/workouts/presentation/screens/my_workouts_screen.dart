import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/exercises/data/exercise_catalog.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';

/// "My workouts": a large tile per sport, each opening its list of workouts.
class MyWorkoutsScreen extends ConsumerWidget {
  const MyWorkoutsScreen({super.key});

  static const _sports = [Sport.gym, Sport.fitness, Sport.cycling];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(workoutTemplatesProvider);
    final history = ref.watch(workoutHistoryProvider);
    final catalog = ref.watch(exerciseCatalogProvider).valueOrNull;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    String caption(Sport sport) => l10n.gymTileCaption(
          templates.where((t) => t.sport == sport).length,
          history
              .where((w) => w.sport == sport && w.finishedAt.isAfter(weekAgo))
              .length,
        );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.gymMyWorkouts),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                children: [
                  Builder(
                    builder: (cardContext) => _WeekPlanCard(
                      onTap: () =>
                          openWithReveal(cardContext, AppRouter.weekPlan),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Builder(
                    builder: (cardContext) => _EntryCard(
                      key: const ValueKey('exercises-entry'),
                      title: l10n.gymExercises,
                      subtitle: catalog == null
                          ? null
                          : l10n.gymExercisesSub(catalog.all.length),
                      onTap: () => openWithReveal(
                          cardContext, AppRouter.exerciseLibrary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Builder(
                    builder: (cardContext) => _EntryCard(
                      key: const ValueKey('programs-entry'),
                      title: l10n.programsTitle,
                      subtitle: l10n.programsEntrySub,
                      onTap: () =>
                          openWithReveal(cardContext, AppRouter.programs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final sport in _sports) ...[
                    SizedBox(
                      height: 120,
                      child: Builder(
                        // The tile's own context, so the reveal starts there.
                        builder: (tileContext) => FeatureTile(
                          label: sport.localizedTileLabel(l10n),
                          labelSize: 24,
                          imageAsset: sport.imageAsset,
                          imageWidthFactor: 0.45,
                          labelAlignment: Alignment.topLeft,
                          imageAlignment: Alignment.centerRight,
                          onTap: () => openWithReveal(
                            tileContext,
                            AppRouter.sportWorkouts(sport),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs, horizontal: AppSpacing.xxs),
                      child: Text(
                        caption(sport),
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "This week" entry above the sport tiles.
class _WeekPlanCard extends ConsumerWidget {
  final VoidCallback onTap;
  const _WeekPlanCard({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final history = ref.watch(workoutHistoryProvider);
    final start = weekStartOf(today);
    final end = addDays(start, 6);
    final week = [
      for (final s in ref.watch(weekPlanProvider))
        if (!s.day.isBefore(start) && !s.day.isAfter(end)) s,
    ];
    final done = week
        .where((s) => statusOf(s, history, today) == SessionStatus.done)
        .length;

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration:
              BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.planTitle,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                    Text(
                      week.isEmpty
                          ? l10n.planEntryEmpty
                          : l10n.planSummary(week.length, done),
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tile-coloured row with a title, an optional caption and a chevron.
class _EntryCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  const _EntryCard(
      {super.key, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration:
              BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
