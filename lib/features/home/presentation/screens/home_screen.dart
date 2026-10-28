import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/feature_tile.dart';
import 'package:fitrix/core/widgets/fitrix_logo.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_card.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/start_workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Home dashboard: a grid of feature tiles (My progress, My nutrition, Felix,
/// My workouts, Shop, Fitrix map) and a Today card with the next workout.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const double _small = 64;
  static const double _large = 148;

  // Shape of the portrait illustrations and their transparent margin
  // (left for the map, bottom for the robot), measured from the files.
  static const double _robotAspect = 400 / 600, _robotInset = 0.18;
  static const double _mapAspect = 400 / 600, _mapInset = 0.17;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    // Inside the app shell the menu belongs to the shell's Scaffold, so it
    // slides over the tab bar; on its own (tests) Home keeps one itself.
    final inShell = context.findAncestorStateOfType<ScaffoldState>() != null;

    return Scaffold(
      backgroundColor: palette.background,
      drawer: inShell ? null : const HomeDrawer(),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const FitrixLogo(),
                  Positioned(
                    left: AppSpacing.sm,
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        color: palette.textPrimary,
                        onPressed: () => context
                            .findRootAncestorStateOfType<ScaffoldState>()
                            ?.openDrawer(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                // One label size per row of tiles, small enough that no
                // label reaches its illustration (which keeps its size).
                final cw = box.maxWidth - 2 * AppSpacing.xl;
                final half = (cw - AppSpacing.md) / 2;
                final small = Size(half, _small);
                Size area(Size tile, double f,
                        {double aspect = 1.5, double inset = 0.2}) =>
                    FeatureTile.labelArea(tile,
                        imageWidthFactor: f,
                        imageAspect: aspect,
                        artInset: inset);
                final sectionSize = FeatureTile.rowLabelSize(context, [
                  (
                    label: l10n.homeTileProgress,
                    size: AppText.displaySmall.fontSize!,
                    area: area(small, 0.5),
                  ),
                  (
                    label: l10n.homeTileNutrition,
                    size: AppText.displaySmall.fontSize!,
                    area: area(small, 0.55),
                  ),
                ]);
                final felixSize = FeatureTile.fittedLabelSize(
                    context,
                    'FELIX',
                    AppText.displayLarge.fontSize!,
                    area(Size(half, _small * 2 + AppSpacing.md), 1,
                        aspect: _robotAspect, inset: _robotInset));
                final workoutsSize = FeatureTile.fittedLabelSize(
                    context,
                    l10n.homeTileWorkouts,
                    AppText.displayLarge.fontSize!,
                    area(Size(cw, _large), 0.55));
                final bottomSize = FeatureTile.rowLabelSize(context, [
                  (
                    label: l10n.homeTileShop,
                    size: AppText.displayMedium.fontSize!,
                    area: area(small, 0.5),
                  ),
                  (
                    label: l10n.homeTileMap,
                    size: AppText.displaySmall.fontSize!,
                    area:
                        area(small, 0.45, aspect: _mapAspect, inset: _mapInset),
                  ),
                ]);
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                      AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
                  child: Column(
                    children: [
                      const CheckInCard(),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: _small * 2 + AppSpacing.md,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _SectionTile(
                                      location: AppRouter.progress,
                                      label: l10n.homeTileProgress,
                                      labelSize: sectionSize,
                                      imageAsset:
                                          'assets/images/tile_progress.png',
                                      imageWidthFactor: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Expanded(
                                    child: _SectionTile(
                                      location: AppRouter.nutrition,
                                      label: l10n.homeTileNutrition,
                                      labelSize: sectionSize,
                                      imageAsset:
                                          'assets/images/tile_nutrition.png',
                                      imageWidthFactor: 0.55,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: FeatureTile(
                                label: 'FELIX',
                                labelSize: felixSize,
                                imageAsset: 'assets/images/felix_robot.png',
                                imageWidthFactor: 1,
                                imageAspect: _robotAspect,
                                artInset: _robotInset,
                                imageAlignment: Alignment.center,
                                labelAlignment: Alignment.center,
                                onTap: () => context.go(AppRouter.felix),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: _large,
                        child: _SectionTile(
                          location: AppRouter.workouts,
                          label: l10n.homeTileWorkouts,
                          labelSize: workoutsSize,
                          imageAsset: 'assets/images/tile_workouts.png',
                          imageWidthFactor: 0.55,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: _small,
                        child: Row(
                          children: [
                            Expanded(
                              child: FeatureTile(
                                label: l10n.homeTileShop,
                                labelSize: bottomSize,
                                imageAsset: 'assets/images/tile_shop.png',
                                imageWidthFactor: 0.5,
                                onTap: () => context.go(AppRouter.shop),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _SectionTile(
                                location: AppRouter.fitrixMap,
                                label: l10n.homeTileMap,
                                labelSize: bottomSize,
                                imageAsset: 'assets/images/tile_map.png',
                                imageWidthFactor: 0.45,
                                imageAspect: _mapAspect,
                                artInset: _mapInset,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _StepsTile(),
                      const _TodayCard(),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's steps from Health: a compact tile, only while connected and
/// today's steps are known. Independent of the plan.
class _StepsTile extends ConsumerWidget {
  const _StepsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(healthTodayProvider);
    final steps = today.stepsToday;
    if (steps == null) return const SizedBox.shrink();
    final avg = today.steps7dAvg;
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        key: const Key('home-steps-tile'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration:
            BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
        child: Row(
          children: [
            Icon(Icons.directions_walk, size: 20, color: palette.accent),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                  avg == null
                      ? l10n.healthStepsToday(steps)
                      : l10n.healthStepsTodayAvg(steps, avg),
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today on the week plan: today's open session with a Start / Continue
/// button, or "Rest day" / "Done for today" with the next session. Only
/// while the plan is not in use the user's first plan stands in.
class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final templates = ref.watch(workoutTemplatesProvider);
    final plan = ref.watch(todayPlanProvider);
    final active = ref.watch(activeWorkoutProvider);

    final String title;
    final String meta;
    WorkoutTemplate? template;
    switch (plan.kind) {
      case TodayKind.unplanned:
        if (templates.isEmpty) return const SizedBox.shrink();
        template = templates.first;
        title = template.name;
        meta = l10n.homeTodayMeta(
            template.exercises.length, template.estimatedDuration.inMinutes);
      case TodayKind.session:
        final session = plan.session!;
        template =
            templates.where((t) => t.id == session.templateId).firstOrNull;
        title = session.title;
        meta = template != null
            ? l10n.homeTodayMeta(
                template.exercises.length, template.estimatedDuration.inMinutes)
            : '${planDuration(l10n, session.minutes)} · '
                '${intensityLabel(l10n, session.intensity)}';
      case TodayKind.rest:
      case TodayKind.done:
        title = plan.kind == TodayKind.rest
            ? l10n.planRestDay
            : l10n.homeDoneForToday;
        final next = plan.next;
        meta = next == null
            ? l10n.homeNothingNext
            : l10n.homeNextSession(
                upcomingDayLabel(context, ref.watch(todayProvider), next.day),
                next.title);
    }
    final start = template;

    // The card opens the week plan; its Start button starts the workout.
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const Key('home-today-card'),
        behavior: HitTestBehavior.opaque,
        onTap: () => openWithReveal(context, AppRouter.weekPlan),
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
                    Text(l10n.homeToday.toUpperCase(),
                        style: AppText.microStrong
                            .copyWith(color: palette.accent)),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                    Text(
                      meta,
                      style: AppText.caption
                          .copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              if (start != null) ...[
                const SizedBox(width: AppSpacing.sm),
                AppButton(
                  label: active?.template.id == start.id
                      ? l10n.homeContinue
                      : start.sport == Sport.football
                          ? l10n.footballLog
                          : l10n.homeStart,
                  size: AppButtonSize.small,
                  onPressed: () => startWorkout(context, ref, start),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A Home tile that opens one of Home's sections with a circle reveal
/// expanding from the tile.
class _SectionTile extends StatelessWidget {
  final String location;
  final String label;
  final double labelSize;
  final String imageAsset;
  final double imageWidthFactor;
  final double imageAspect;
  final double artInset;

  const _SectionTile({
    required this.location,
    required this.label,
    this.labelSize = 16,
    required this.imageAsset,
    required this.imageWidthFactor,
    this.imageAspect = 1.5,
    this.artInset = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureTile(
      label: label,
      labelSize: labelSize,
      imageAsset: imageAsset,
      imageWidthFactor: imageWidthFactor,
      imageAspect: imageAspect,
      artInset: artInset,
      onTap: () => openWithReveal(context, location),
    );
  }
}

/// Home's side menu.
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    Widget item(IconData icon, String label, String location) => ListTile(
          leading: Icon(icon, color: palette.textPrimary),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
          onTap: () {
            Scaffold.of(context).closeDrawer();
            // Not opened from a tile: no circle origin, plain fade instead.
            RevealOrigins.clear(location);
            context.go(location);
          },
        );

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: FitrixLogo(),
            ),
            item(Icons.show_chart, l10n.progressTitle, AppRouter.progress),
            item(Icons.restaurant_outlined, l10n.nutritionTitle,
                AppRouter.nutrition),
            item(Icons.fitness_center, l10n.gymMyWorkouts, AppRouter.workouts),
            item(Icons.smart_toy_outlined, 'Felix', AppRouter.felix),
            item(Icons.shopping_cart_outlined, l10n.shopTitle, AppRouter.shop),
            item(Icons.map_outlined, l10n.homeMenuMap, AppRouter.fitrixMap),
            item(Icons.person_outline, l10n.aboutMeTitle, AppRouter.aboutMe),
          ],
        ),
      ),
    );
  }
}
