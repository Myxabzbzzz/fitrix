import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_colors.dart';

/// Design tokens for the post-onboarding screens (Home, Workouts, Progress,
/// Nutrition, Felix chats), taken from the "FITRIX App UI" Figma file.
///
/// Resolves to the light or dark variant based on the current theme:
/// `final palette = AppPalette.of(context);`
class AppPalette {
  final Color background;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;

  /// Home / workout tiles and cards (#EEEEEE in the design)
  final Color tile;

  /// Chart cards (#EDEDED in the design)
  final Color chartCard;

  /// Active workout sheet and mini player (#F1F1F1 in the design)
  final Color sheet;

  /// Cells inside the active workout table (white @ 51%)
  final Color tableCell;

  /// Secondary buttons like "Edit" (#D8D8D8)
  final Color buttonMuted;

  /// Outline of unselected pills, chart grid lines (#E6E6E6)
  final Color border;

  /// Assistant chat bubbles and chat list items (#E9E9EB)
  final Color bubble;

  /// Selected pill background (black @ 90%)
  final Color pillSelected;
  final Color onPillSelected;

  /// Chart axis labels (#828282)
  final Color chartLabel;

  /// Tab bar background
  final Color tabBar;
  final Color tabInactive;

  const AppPalette._({
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.tile,
    required this.chartCard,
    required this.sheet,
    required this.tableCell,
    required this.buttonMuted,
    required this.border,
    required this.bubble,
    required this.pillSelected,
    required this.onPillSelected,
    required this.chartLabel,
    required this.tabBar,
    required this.tabInactive,
  });

  static const light = AppPalette._(
    background: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0x6E000000),
    accent: AppColors.lightSecondary,
    tile: Color(0xFFEEEEEE),
    chartCard: Color(0xFFEDEDED),
    sheet: Color(0xFFF1F1F1),
    tableCell: Color(0x82FFFFFF),
    buttonMuted: Color(0xFFD8D8D8),
    border: Color(0xFFE6E6E6),
    bubble: Color(0xFFE9E9EB),
    pillSelected: Color(0xE6000000),
    onPillSelected: Color(0xFFFFFFFF),
    chartLabel: Color(0xFF828282),
    tabBar: Color(0xFFFFFFFF),
    tabInactive: Color(0xFF000000),
  );

  static const dark = AppPalette._(
    background: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0x8CFFFFFF),
    accent: AppColors.darkSecondary,
    tile: Color(0xFF1C1C1E),
    chartCard: Color(0xFF1C1C1E),
    sheet: Color(0xFF1C1C1E),
    tableCell: Color(0x1FFFFFFF),
    buttonMuted: Color(0xFF3A3A3C),
    border: Color(0xFF38383A),
    bubble: Color(0xFF2C2C2E),
    pillSelected: Color(0xFFFFFFFF),
    onPillSelected: Color(0xFF000000),
    chartLabel: Color(0xFF8E8E93),
    tabBar: Color(0xFF0D0D0D),
    tabInactive: Color(0xFFFFFFFF),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
