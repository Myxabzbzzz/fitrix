import 'package:fitrix/core/time/day_key.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "1h 35m", "1h" or "45 min".
String planDuration(AppLocalizations l10n, int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return l10n.planDurationM(m);
  if (m == 0) return l10n.planDurationH(h);
  return l10n.planDurationHM(h, m);
}

String intensityLabel(AppLocalizations l10n, Intensity i) => switch (i) {
      Intensity.easy => l10n.planIntensityEasy,
      Intensity.normal => l10n.planIntensityNormal,
      Intensity.hard => l10n.planIntensityHard,
    };

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toString();

/// "Mon".
String weekdayShort(BuildContext context, DateTime d) =>
    DateFormat('E', _locale(context)).format(d);

/// "Monday".
String weekdayLong(BuildContext context, DateTime d) =>
    DateFormat('EEEE', _locale(context)).format(d);

/// "Mon 13".
String weekdayAndDate(BuildContext context, DateTime d) =>
    DateFormat('E d', _locale(context)).format(d);

/// A small rounded label such as "Hard", "Easy" or "Missed".
class PlanChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const PlanChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });

  /// The chip for an intensity, on a light surface or a selected (dark) row.
  factory PlanChip.intensity(
    BuildContext context,
    Intensity i, {
    bool onDark = false,
  }) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final hard = i == Intensity.hard;
    return PlanChip(
      label: intensityLabel(l10n, i),
      background: hard
          ? palette.accentSoft
          : onDark
              ? palette.onPillSelected.withValues(alpha: 0.12)
              : palette.buttonMuted,
      foreground: hard ? palette.accent : palette.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        decoration:
            BoxDecoration(color: background, borderRadius: AppRadius.fullAll),
        child: Text(label,
            maxLines: 1,
            style: AppText.captionStrong.copyWith(color: foreground)),
      );
}

/// The day of an upcoming session: "Friday" within the coming week,
/// "Wed 21" further out.
String upcomingDayLabel(BuildContext context, DateTime today, DateTime day) =>
    addDays(dayOf(today), 6).isBefore(day)
        ? weekdayAndDate(context, day)
        : weekdayLong(context, day);
