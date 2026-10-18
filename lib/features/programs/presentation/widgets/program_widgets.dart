import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/programs/domain/program_catalog.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

String programLevelLabel(AppLocalizations l10n, String level) =>
    switch (level) {
      'intermediate' => l10n.programsLevelIntermediate,
      'advanced' => l10n.programsLevelAdvanced,
      _ => l10n.programsLevelBeginner,
    };

String programGoalLabel(AppLocalizations l10n, String goal) => switch (goal) {
      'strength' => l10n.programsGoalStrength,
      'fat_loss' => l10n.programsGoalFatLoss,
      _ => l10n.programsGoalMuscle,
    };

String programGoalsText(AppLocalizations l10n, TrainingProgram p) =>
    p.goals.map((g) => programGoalLabel(l10n, g)).join(' + ');

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toString();

/// "Mon", for a weekday number (1 = Monday).
String weekdayName(BuildContext context, int weekday) =>
    // 2024-01-01 is a Monday.
    DateFormat('E', _locale(context)).format(DateTime(2024, 1, weekday));

/// "Monday", for a weekday number (1 = Monday).
String weekdayFull(BuildContext context, int weekday) =>
    DateFormat('EEEE', _locale(context)).format(DateTime(2024, 1, weekday));

/// "Mon 20 Oct".
String dayAndMonth(BuildContext context, DateTime d) =>
    DateFormat('E d MMM', _locale(context)).format(d);

/// "{sets} × {low}–{high}" (or one number when both are equal).
String setsReps(ProgramExercise e) => e.repsLow == e.repsHigh
    ? '${e.sets} × ${e.repsHigh}'
    : '${e.sets} × ${e.repsLow}–${e.repsHigh}';

/// kg without a trailing ".0".
String kgText(double kg) =>
    kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

/// A small uppercase label with a dot ("4× / WEEK").
class ProgramTag extends StatelessWidget {
  final String label;
  const ProgramTag(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
      decoration: BoxDecoration(
          color: palette.buttonMuted, borderRadius: AppRadius.fullAll),
      child: Text(label.toUpperCase(),
          style: AppText.microStrong.copyWith(color: palette.textPrimary)),
    );
  }
}

/// One square per program week: done, current, upcoming; the deload week is
/// outlined.
class WeekDots extends StatelessWidget {
  final int weeks;
  final int current;
  final int? deloadWeek;

  /// Colors for done / upcoming squares and their text.
  final Color doneColor;
  final Color doneText;
  final Color upcomingColor;
  final Color upcomingText;

  const WeekDots({
    super.key,
    required this.weeks,
    required this.current,
    required this.deloadWeek,
    required this.doneColor,
    required this.doneText,
    required this.upcomingColor,
    required this.upcomingText,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        for (var w = 1; w <= weeks; w++)
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: w == current
                  ? palette.accent
                  : w < current
                      ? doneColor
                      : upcomingColor,
              borderRadius: AppRadius.smAll,
              border: w == deloadWeek && w != current
                  ? Border.all(color: palette.textSecondary)
                  : null,
            ),
            child: Text('$w',
                style: AppText.captionStrong.copyWith(
                    color: w == current
                        ? palette.onAccent
                        : w < current
                            ? doneText
                            : upcomingText)),
          ),
      ],
    );
  }
}
