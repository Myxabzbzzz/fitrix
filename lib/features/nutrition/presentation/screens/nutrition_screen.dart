import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "My Nutrition": today's calories ring and macro progress. The ring and
/// bars fill from zero when the screen opens.
enum _Macro { protein, carbs, fat }

enum _Meal { breakfast, lunch, snack }

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  static const int _consumed = 1700;
  static const int _goal = 2400;

  static const _macros = [
    (id: _Macro.protein, grams: 120, goal: 160),
    (id: _Macro.carbs, grams: 180, goal: 260),
    (id: _Macro.fat, grams: 55, goal: 80),
  ];

  static const _meals = [
    (id: _Meal.breakfast, kcal: 520),
    (id: _Meal.lunch, kcal: 780),
    (id: _Meal.snack, kcal: 400),
  ];

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _goal = NutritionScreen._goal;
  static const _macros = NutritionScreen._macros;

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );
  VoidCallback? _cancelPending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The date may have changed since the meals were loaded.
    Future.microtask(() {
      if (mounted) ref.read(todayMealsProvider.notifier).refresh();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.read(todayMealsProvider.notifier).refresh();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _cancelPending?.call();
      _fill.value = 1;
    } else if (_cancelPending == null && _fill.isDismissed) {
      // Fill once the page transition has revealed the screen.
      _cancelPending = afterRouteEntrance(context, () {
        if (mounted) _fill.forward();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cancelPending?.call();
    _fill.dispose();
    super.dispose();
  }

  /// Fill progress for item [index], slightly staggered.
  double _progress(int index) => Curves.easeOutCubic.transform(
        Interval(0.1 * index, 0.7 + 0.1 * index).transform(_fill.value),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fill,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final fmt =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    // Meals confirmed from Felix replace the sample day.
    final logged = ref.watch(todayMealsProvider);
    final hasLogged = logged.isNotEmpty;
    final consumed = hasLogged
        ? logged.fold<int>(0, (sum, m) => sum + m.kcal)
        : NutritionScreen._consumed;
    final left = _goal - consumed;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.nutritionTitle),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.lg),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: palette.tile,
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          key: const ValueKey('calorie-ring'),
                          width: 132,
                          height: 132,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                painter: _RingPainter(
                                  fraction: consumed / _goal * _progress(0),
                                  track: palette.buttonMuted,
                                  arc: palette.accent,
                                ),
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      fmt.format(consumed),
                                      style: AppText.displayMedium
                                          .copyWith(color: palette.textPrimary),
                                    ),
                                    Text(
                                      l10n.nutritionOfGoal(fmt.format(_goal)),
                                      style: AppText.micro.copyWith(
                                          color: palette.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasLogged)
                          const Spacer()
                        else ...[
                          const SizedBox(width: AppSpacing.lg),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final (i, macro) in _macros.indexed) ...[
                                  if (i > 0)
                                    const SizedBox(height: AppSpacing.sm),
                                  _MacroRow(
                                    label: switch (macro.id) {
                                      _Macro.protein => l10n.nutritionProtein,
                                      _Macro.carbs => l10n.nutritionCarbs,
                                      _Macro.fat => l10n.nutritionFat,
                                    },
                                    grams: macro.grams,
                                    goal: macro.goal,
                                    progress: _progress(i + 1),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    left > 0
                        ? l10n.nutritionLeft(fmt.format(left))
                        : l10n.nutritionGoalReached,
                    style:
                        AppText.bodyStrong.copyWith(color: palette.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (hasLogged)
                    for (final meal in logged) ...[
                      _MealRow(
                        name: meal.name,
                        items: meal.items,
                        trailing: l10n.nutritionKcal('${meal.kcal}'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ]
                  else ...[
                    for (final meal in NutritionScreen._meals) ...[
                      _MealRow(
                        name: switch (meal.id) {
                          _Meal.breakfast => l10n.nutritionBreakfast,
                          _Meal.lunch => l10n.nutritionLunch,
                          _Meal.snack => l10n.nutritionSnack,
                        },
                        items: switch (meal.id) {
                          _Meal.breakfast => l10n.nutritionBreakfastItems,
                          _Meal.lunch => l10n.nutritionLunchItems,
                          _Meal.snack => l10n.nutritionSnackItems,
                        },
                        trailing: l10n.nutritionKcal('${meal.kcal}'),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    _MealRow(
                      name: l10n.nutritionDinner,
                      items: l10n.nutritionNotLogged,
                      trailing: '—',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  CoachCard(
                    eyebrow: l10n.nutritionTipEyebrow,
                    title: l10n.nutritionTipTitle,
                    message: l10n.nutritionTipMessage,
                    imageAsset: 'assets/images/felix_avatar.png',
                    imageWidth: 44,
                    imageHeight: 44,
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

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color track;
  final Color arc;

  _RingPainter({
    required this.fraction,
    required this.track,
    required this.arc,
  });

  static const double _stroke = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    final f = fraction.clamp(0.0, 1.0);
    if (f > 0) {
      canvas.drawArc(
          rect, -math.pi / 2, math.pi * 2 * f, false, paint..color = arc);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.fraction != fraction || old.track != track || old.arc != arc;
}

class _MacroRow extends StatelessWidget {
  final String label;
  final int grams;
  final int goal;
  final double progress;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.goal,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppText.captionStrong
                      .copyWith(color: palette.textPrimary)),
            ),
            Text('$grams / $goal g',
                style: AppText.caption.copyWith(color: palette.textSecondary)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        ClipRRect(
          borderRadius: AppRadius.fullAll,
          child: LinearProgressIndicator(
            value: (grams / goal).clamp(0.0, 1.0) * progress,
            minHeight: 6,
            color: palette.accent,
            backgroundColor: palette.buttonMuted,
          ),
        ),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  final String name;
  final String items;
  final String trailing;

  const _MealRow({
    required this.name,
    required this.items,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppText.bodyStrong
                        .copyWith(color: palette.textPrimary)),
                Text(items,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(trailing,
              style:
                  AppText.captionStrong.copyWith(color: palette.textPrimary)),
        ],
      ),
    );
  }
}
