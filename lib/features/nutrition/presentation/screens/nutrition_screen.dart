import 'package:flutter/material.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/widgets/screen_title.dart';

/// "My Nutrition": today's calories ring and macro progress. The ring and
/// bars fill from zero when the screen opens.
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  static const int _consumed = 1700;
  static const int _goal = 2400;

  static const _macros = [
    (label: 'Protein', grams: 120, goal: 160),
    (label: 'Carbs', grams: 180, goal: 260),
    (label: 'Fat', grams: 55, goal: 80),
  ];

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  static const _consumed = NutritionScreen._consumed;
  static const _goal = NutritionScreen._goal;
  static const _macros = NutritionScreen._macros;

  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );
  VoidCallback? _cancelPending;

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
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: palette.textPrimary,
    );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenTitle('My Nutrition'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: palette.chartCard,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 126,
                          height: 126,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: _consumed / _goal * _progress(0),
                                strokeWidth: 10,
                                strokeCap: StrokeCap.round,
                                color: palette.accent,
                                backgroundColor: palette.border,
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$_consumed',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'of $_goal kcal',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: palette.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 54),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _consumed / _goal * _progress(0),
                              minHeight: 8,
                              color: palette.accent,
                              backgroundColor: palette.border,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_goal - _consumed} kcal left today',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final (i, macro) in _macros.indexed) ...[
                    Row(
                      children: [
                        Expanded(child: Text(macro.label, style: labelStyle)),
                        Text(
                          '${macro.grams} / ${macro.goal} g',
                          style: labelStyle.copyWith(
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: macro.grams / macro.goal * _progress(i + 1),
                        minHeight: 8,
                        color: palette.accent,
                        backgroundColor: palette.tile,
                      ),
                    ),
                    const SizedBox(height: 16),
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
