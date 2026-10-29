import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/title_row.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "78.4 kg" with the locale's decimal mark.
String kgText(BuildContext context, double kg) {
  final locale = Localizations.localeOf(context).toString();
  final n = NumberFormat('0.#', locale).format(kg);
  return '$n ${AppLocalizations.of(context).unitKg}';
}

/// Colour of a sport in charts. Only palette tokens.
Color sportColor(AppPalette p, Sport sport) => switch (sport) {
      Sport.gym => p.accent,
      Sport.running => p.success,
      Sport.football => p.warning,
      Sport.cycling => p.danger,
      Sport.fitness => p.textPrimary,
      Sport.winterSports => p.chartLabel,
    };

/// A rounded tile used for every card on the progress screens.
class ProgressCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool chart;
  final EdgeInsetsGeometry padding;
  const ProgressCard({
    super.key,
    required this.child,
    this.onTap,
    this.chart = false,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: chart ? p.chartCard : p.tile,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        borderRadius: AppRadius.smAll,
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Label, big value and a note, as in the Fitness / Fatigue tiles.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final Color? valueColor;
  final Key? valueKey;
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.note,
    this.valueColor,
    this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return ProgressCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: p.textSecondary)),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                key: valueKey,
                style: AppText.headingL
                    .copyWith(color: valueColor ?? p.textPrimary)),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(note,
              style: AppText.caption.copyWith(color: p.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Row with icon, title, value and a chevron.
class LinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  const LinkRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: p.buttonMuted, borderRadius: AppRadius.smAll),
              child: Icon(icon, size: 20, color: p.textPrimary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TitleRow(
                title: Text(title,
                    style: AppText.headingS.copyWith(color: p.textPrimary)),
                trailing: Text(value,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body14.copyWith(color: p.textSecondary)),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: p.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Equal-width segmented control (4 / 12 / 16 weeks).
class Segmented<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  const Segmented({
    super.key,
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(items[i]),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: items[i] == selected ? p.pillSelected : p.tile,
                  borderRadius: AppRadius.smAll,
                ),
                child: Text(
                  labelOf(items[i]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyStrong.copyWith(
                      color: items[i] == selected
                          ? p.onPillSelected
                          : p.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A small coloured square with a label (chart legend).
class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool ring;
  const LegendDot(
      {super.key, required this.color, required this.label, this.ring = false});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: ring ? null : color,
            border: ring ? Border.all(color: color, width: 2) : null,
            borderRadius: BorderRadius.circular(ring ? 5 : 3),
          ),
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(label,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: p.textSecondary)),
        ),
      ],
    );
  }
}

/// Monday-Sunday bar chart of daily load, coloured by sport.
class LoadBarChart extends StatelessWidget {
  final DateTime weekStartDay;

  /// Load per sport for each of the 7 days, Monday first.
  final List<Map<Sport, int>> days;
  const LoadBarChart(
      {super.key, required this.weekStartDay, required this.days});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.decimalPattern(locale);
    final totals = [
      for (final d in days) d.values.fold<int>(0, (a, b) => a + b)
    ];
    final max = totals.fold<int>(0, (a, b) => a > b ? a : b);
    const barArea = 84.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: AppText.micro.fontSize! * 1.4 + AppSpacing.xxs,
                  child: totals[i] == 0
                      ? null
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(fmt.format(totals[i]),
                              style: AppText.microStrong
                                  .copyWith(color: p.textPrimary)),
                        ),
                ),
                SizedBox(
                  height: barArea,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      child: totals[i] == 0
                          ? Container(
                              height: 4,
                              decoration: BoxDecoration(
                                  color: p.border,
                                  borderRadius: BorderRadius.circular(2)))
                          : ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                              child: SizedBox(
                                height: (barArea * totals[i] / max)
                                    .clamp(4.0, barArea),
                                child: Column(
                                  children: [
                                    for (final e in days[i]
                                        .entries
                                        .where((e) => e.value > 0))
                                      Expanded(
                                        flex: e.value,
                                        child: ColoredBox(
                                            color: sportColor(p, e.key),
                                            child: const SizedBox.expand()),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  DateFormat('EEE', locale).format(DateTime(weekStartDay.year,
                      weekStartDay.month, weekStartDay.day + i)),
                  maxLines: 1,
                  style: AppText.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Seven bars of daily steps, oldest first. An unknown day is an empty
/// (placeholder) bar with no number, never a zero.
class StepsBarChart extends StatelessWidget {
  final StepsWeek week;
  const StepsBarChart({super.key, required this.week});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final locale = Localizations.localeOf(context).toString();
    final fmt = NumberFormat.decimalPattern(locale);
    final max =
        week.days.fold<int>(0, (a, d) => (d.steps ?? 0) > a ? d.steps! : a);
    const barArea = 84.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in week.days)
          Expanded(
            child: Column(
              key: ValueKey('steps-bar-${d.day.day}'),
              children: [
                SizedBox(
                  height: AppText.micro.fontSize! * 1.4 + AppSpacing.xxs,
                  child: d.steps == null
                      ? null
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(fmt.format(d.steps),
                              style: AppText.microStrong
                                  .copyWith(color: p.textPrimary)),
                        ),
                ),
                SizedBox(
                  height: barArea,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 0.7,
                      child: d.steps == null || d.steps == 0 || max == 0
                          ? Container(
                              height: 4,
                              decoration: BoxDecoration(
                                  color: p.border,
                                  borderRadius: BorderRadius.circular(2)))
                          : Container(
                              height: (barArea * d.steps! / max)
                                  .clamp(4.0, barArea),
                              decoration: BoxDecoration(
                                  color: p.accent,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)))),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  DateFormat('EEE', locale).format(d.day),
                  maxLines: 1,
                  style: AppText.caption.copyWith(color: p.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The load balance scale: low, sweet spot, high, risky, with a marker at
/// the ratio.
class BalanceBar extends StatelessWidget {
  final double acwr;
  const BalanceBar({super.key, required this.acwr});

  static const double _max = 2.0;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget seg(int flex, Color c) => Expanded(
        flex: flex,
        child: ColoredBox(
            color: c.withValues(alpha: 0.4), child: const SizedBox.expand()));
    return LayoutBuilder(builder: (context, box) {
      final x = (acwr / _max).clamp(0.0, 1.0) * box.maxWidth;
      return SizedBox(
        height: 24,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            ClipRRect(
              borderRadius: AppRadius.fullAll,
              child: SizedBox(
                height: 10,
                child: Row(children: [
                  seg(8, p.warning),
                  seg(5, p.success),
                  seg(2, p.warning),
                  seg(5, p.danger),
                ]),
              ),
            ),
            Positioned(
              left: (x - 2).clamp(0.0, box.maxWidth - 4),
              child: Container(width: 4, height: 22, color: p.textPrimary),
            ),
          ],
        ),
      );
    });
  }
}

/// Localized strength level name.
String strengthLevelLabel(AppLocalizations l10n, String level) =>
    switch (level) {
      'novice' => l10n.liftLevelNovice,
      'intermediate' => l10n.liftLevelIntermediate,
      'advanced' => l10n.liftLevelAdvanced,
      'elite' => l10n.liftLevelElite,
      _ => l10n.liftLevelBeginner,
    };

/// "Form" label for a form value (fitness minus fatigue over fitness).
({String text, Color color}) formLabel(
    AppLocalizations l10n, AppPalette p, double form) {
  if (form > 0.05) return (text: l10n.progressFormFresh, color: p.success);
  if (form < -0.1) return (text: l10n.progressFormTired, color: p.warning);
  return (text: l10n.progressFormNeutral, color: p.textPrimary);
}

String signedPercent(double ratio) {
  final pct = (ratio * 100).round();
  return '${pct >= 0 ? '+' : '−'}${pct.abs()}%';
}
