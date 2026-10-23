import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/nutrition/presentation/widgets/nutrition_cards.dart';
import 'package:fitrix/features/profile/data/performance_store.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "Your targets": how the daily calories and macros are worked out, with
/// the goal and per-kg factors you can change.
class TargetsScreen extends ConsumerStatefulWidget {
  const TargetsScreen({super.key});

  @override
  ConsumerState<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends ConsumerState<TargetsScreen> {
  late NutritionSettings _draft = ref.read(nutritionSettingsProvider);

  double _step(double v, int dir, ({double min, double max}) range) =>
      ((v * 10).round() / 10 + dir * 0.1)
          .clamp(range.min, range.max)
          .toDouble();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.decimalPattern(locale);
    final one = NumberFormat('0.0', locale);
    final body = ref.watch(bodyStatsProvider);
    final hours = ref.watch(trainingHoursProvider);
    final sex = ref.watch(performanceProfileProvider).sex;
    final steps = ref.watch(healthTodayProvider).stepsToday;
    final t = targetsFor(
      sex: sex,
      age: body.age,
      weightKg: body.weightKg,
      heightCm: body.heightCm,
      trainingHoursPerWeek: hours.hours,
      goal: _draft.goal,
      proteinPerKg: _draft.proteinPerKg,
      fatPerKg: _draft.fatPerKg,
      stepsToday: steps,
    );

    Widget row(String title, String sub, String value, {bool big = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: (big ? AppText.headingM : AppText.bodyStrong)
                            .copyWith(color: palette.textPrimary)),
                    if (sub.isNotEmpty)
                      Text(sub,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value,
                      style: (big ? AppText.headingL : AppText.bodyStrong)
                          .copyWith(color: palette.textPrimary)),
                ),
              ),
            ],
          ),
        );

    Widget stepper(String key, double value, ({double min, double max}) range,
            ValueChanged<double> onChange) =>
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RoundButton(
                key: ValueKey('$key-minus'),
                icon: Icons.remove,
                onTap: () => onChange(_step(value, -1, range))),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 32),
              child: Text(one.format(value),
                  textAlign: TextAlign.center,
                  style:
                      AppText.bodyStrong.copyWith(color: palette.textPrimary)),
            ),
            _RoundButton(
                key: ValueKey('$key-plus'),
                icon: Icons.add,
                onTap: () => onChange(_step(value, 1, range))),
          ],
        );

    Widget macroRow(String title, String sub, Widget trailing) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppText.bodyStrong
                            .copyWith(color: palette.textPrimary)),
                    Text(sub,
                        style: AppText.caption
                            .copyWith(color: palette.textSecondary)),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        );

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.targetsTitle),
            Expanded(
              child: t == null
                  ? ListView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      children: [
                        InkWell(
                          key: const ValueKey('targets-complete-profile'),
                          borderRadius: AppRadius.smAll,
                          onTap: () => context.push(AppRouter.editProfile),
                          child: NutritionTile(
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l10n.nutritionCompleteTitle,
                                        style: AppText.headingS.copyWith(
                                            color: palette.textPrimary)),
                                    Text(l10n.nutritionCompleteBody,
                                        style: AppText.caption.copyWith(
                                            color: palette.textSecondary)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: palette.textSecondary),
                            ]),
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                      children: [
                        Text(l10n.targetsSubtitle,
                            style: AppText.caption
                                .copyWith(color: palette.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(l10n.targetsGoal,
                            style: AppText.headingS
                                .copyWith(color: palette.textPrimary)),
                        const SizedBox(height: AppSpacing.xs),
                        PillSelector<Goal>(
                          items: Goal.values,
                          selected: _draft.goal,
                          labelOf: (g) => switch (g) {
                            Goal.loseFat => l10n.targetsLoseFat,
                            Goal.maintain => l10n.targetsMaintain,
                            Goal.leanBulk => l10n.targetsLeanBulk,
                          },
                          onSelected: (g) =>
                              setState(() => _draft = _draft.copyWith(goal: g)),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        NutritionTile(
                          child: Column(
                            children: [
                              row(
                                l10n.targetsBmr,
                                l10n.targetsBmrFormula(
                                    one.format(body.weightKg),
                                    fmt.format(body.heightCm!.round()),
                                    '${body.age}'),
                                fmt.format(t.bmr),
                              ),
                              row(
                                l10n.targetsActivity(
                                    NumberFormat('0.0##', locale)
                                        .format(t.activity)),
                                hours.estimated
                                    ? l10n.targetsHoursEstimated(
                                        one.format(hours.hours))
                                    : l10n
                                        .targetsHours(one.format(hours.hours)),
                                fmt.format(t.tdee),
                              ),
                              row(
                                switch (_draft.goal) {
                                  Goal.loseFat => l10n.targetsAdjLose,
                                  Goal.maintain => l10n.targetsAdjMaintain,
                                  Goal.leanBulk => l10n.targetsAdjBulk,
                                },
                                '',
                                '${t.kcal - t.stepsKcal - t.tdee >= 0 ? '+' : '−'}'
                                    '${fmt.format((t.kcal - t.stepsKcal - t.tdee).abs())}',
                              ),
                              if (t.stepsKcal > 0 && steps != null)
                                row(
                                  l10n.healthStepsToday(steps),
                                  '',
                                  '+${fmt.format(t.stepsKcal)}',
                                ),
                              Divider(color: palette.border),
                              row(
                                l10n.targetsDaily,
                                '',
                                l10n.nutritionKcal(fmt.format(t.kcal)),
                                big: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(l10n.nutritionMacros,
                            style: AppText.headingS
                                .copyWith(color: palette.textPrimary)),
                        const SizedBox(height: AppSpacing.xs),
                        NutritionTile(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs),
                          child: Column(
                            children: [
                              macroRow(
                                l10n.targetsProteinG('${t.protein}'),
                                l10n.targetsPerKg(
                                    one.format(_draft.proteinPerKg)),
                                stepper(
                                    'protein',
                                    _draft.proteinPerKg,
                                    proteinPerKgRange,
                                    (v) => setState(() => _draft =
                                        _draft.copyWith(proteinPerKg: v))),
                              ),
                              macroRow(
                                l10n.targetsFatG('${t.fat}'),
                                l10n.targetsFatPerKg(
                                    one.format(_draft.fatPerKg),
                                    '${(t.fat * 9 / t.kcal * 100).round()}'),
                                stepper(
                                    'fat',
                                    _draft.fatPerKg,
                                    fatPerKgRange,
                                    (v) => setState(() =>
                                        _draft = _draft.copyWith(fatPerKg: v))),
                              ),
                              macroRow(
                                l10n.targetsCarbsG('${t.carbs}'),
                                l10n.targetsCarbsNote,
                                Text(l10n.targetsAuto,
                                    style: AppText.caption.copyWith(
                                        color: palette.textSecondary)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (t != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
                child: AppButton(
                  label: l10n.targetsSave,
                  size: AppButtonSize.large,
                  expand: true,
                  onPressed: () async {
                    await ref
                        .read(nutritionSettingsProvider.notifier)
                        .save(_draft);
                    if (context.mounted) Navigator.of(context).maybePop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: palette.buttonMuted, shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: palette.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
