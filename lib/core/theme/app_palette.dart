import 'package:flutter/material.dart';

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

  /// Text and icons on top of [accent] fills
  final Color onAccent;

  /// Home / workout tiles and cards (#EEEEEE in the design)
  final Color tile;

  /// Chart cards (#EDEDED in the design)
  final Color chartCard;

  /// Active workout sheet and mini player (#F1F1F1 in the design)
  final Color sheet;

  /// Modal sheets and the side menu. White in light; a raised grey in dark
  /// so they stand off the black page (a scrim does nothing on black).
  final Color sheetSurface;

  /// Chips, rows and cards on a sheet ([tile] would vanish into the dark
  /// sheet surface).
  final Color sheetTile;

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

  /// User chat bubbles
  final Color bubbleUser;
  final Color onBubbleUser;

  /// Small badges / chips (grey @ 32% light, white @ 12% dark)
  final Color badge;

  /// Soft accent wash (accent @ 14% light, @ 22% dark)
  final Color accentSoft;

  /// Destructive actions and errors
  final Color danger;

  /// Caution (low intake, over a limit that is not an error).
  final Color warning;

  /// Good / on target.
  final Color success;

  /// Opaque secondary text (ThemeData bodySmall/labelSmall).
  final Color textMuted;

  /// Hint / placeholder text in inputs.
  final Color textHint;

  /// Text field fill
  final Color inputFill;

  /// Form validation errors (sign-in message, code boxes)
  final Color error;

  const AppPalette._({
    required this.background,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.tile,
    required this.chartCard,
    required this.sheet,
    required this.sheetSurface,
    required this.sheetTile,
    required this.tableCell,
    required this.buttonMuted,
    required this.border,
    required this.bubble,
    required this.pillSelected,
    required this.onPillSelected,
    required this.chartLabel,
    required this.tabBar,
    required this.tabInactive,
    required this.bubbleUser,
    required this.onBubbleUser,
    required this.badge,
    required this.accentSoft,
    required this.danger,
    required this.warning,
    required this.success,
    required this.textMuted,
    required this.textHint,
    required this.inputFill,
    required this.error,
  });

  static const light = AppPalette._(
    background: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0x6E000000),
    accent: Color(0xFF009ED8),
    onAccent: Color(0xFFFFFFFF),
    tile: Color(0xFFEEEEEE),
    chartCard: Color(0xFFEDEDED),
    sheet: Color(0xFFF1F1F1),
    sheetSurface: Color(0xFFFFFFFF),
    sheetTile: Color(0xFFEEEEEE),
    tableCell: Color(0x82FFFFFF),
    buttonMuted: Color(0xFFD8D8D8),
    border: Color(0xFFE6E6E6),
    bubble: Color(0xFFE9E9EB),
    pillSelected: Color(0xE6000000),
    onPillSelected: Color(0xFFFFFFFF),
    chartLabel: Color(0xFF828282),
    tabBar: Color(0xFFFFFFFF),
    tabInactive: Color(0xFF000000),
    bubbleUser: Color(0xFF000000),
    onBubbleUser: Color(0xFFFFFFFF),
    badge: Color(0x52C5C5C5),
    accentSoft: Color(0x24009ED8),
    danger: Color(0xFFD93A3F),
    warning: Color(0xFFB87A00),
    success: Color(0xFF1E8E3E),
    textMuted: Color(0xFF666666),
    textHint: Color(0xFF999999),
    inputFill: Color(0xFFF5F5F5),
    error: Color(0xFFFF453A),
  );

  static const dark = AppPalette._(
    background: Color(0xFF000000),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0x8CFFFFFF),
    accent: Color(0xFF009ED8),
    onAccent: Color(0xFFFFFFFF),
    tile: Color(0xFF1C1C1E),
    chartCard: Color(0xFF1C1C1E),
    sheet: Color(0xFF1C1C1E),
    sheetSurface: Color(0xFF2C2C2E),
    sheetTile: Color(0xFF3A3A3C),
    tableCell: Color(0x1FFFFFFF),
    buttonMuted: Color(0xFF3A3A3C),
    border: Color(0xFF38383A),
    bubble: Color(0xFF2C2C2E),
    pillSelected: Color(0xFFFFFFFF),
    onPillSelected: Color(0xFF000000),
    chartLabel: Color(0xFF8E8E93),
    tabBar: Color(0xFF0D0D0D),
    tabInactive: Color(0xFFFFFFFF),
    bubbleUser: Color(0xFFFFFFFF),
    onBubbleUser: Color(0xFF000000),
    badge: Color(0x1FFFFFFF),
    accentSoft: Color(0x38009ED8),
    danger: Color(0xFFFF6B6F),
    warning: Color(0xFFFFB84D),
    success: Color(0xFF5FD38D),
    textMuted: Color(0xFFB0B0B0),
    textHint: Color(0xFF6C6C6C),
    inputFill: Color(0xFF1C1C1E),
    error: Color(0xFFFF453A),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
