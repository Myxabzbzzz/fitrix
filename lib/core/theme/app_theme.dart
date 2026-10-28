import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    const p = AppPalette.light;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: p.background,
      fontFamily: AppText.body,
      colorScheme: ColorScheme.light(
        primary: p.textPrimary,
        secondary: p.accent,
        surface: p.background,
        error: p.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.textPrimary,
          foregroundColor: p.onBubbleUser,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppText.headingS,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: p.textHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppText.headingXL.copyWith(color: p.textPrimary),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        headlineMedium: AppText.headingM.copyWith(color: p.textPrimary),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        titleMedium: AppText.headingS.copyWith(color: p.textPrimary),
        bodyLarge:
            AppText.bodyRegular.copyWith(fontSize: 16, color: p.textPrimary),
        bodyMedium: AppText.bodyRegular.copyWith(color: p.textPrimary),
        bodySmall: AppText.caption.copyWith(color: p.textMuted),
        labelSmall: AppText.micro.copyWith(color: p.textMuted),
      ),
    );
  }

  static ThemeData get darkTheme {
    const p = AppPalette.dark;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: p.background,
      fontFamily: AppText.body,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: p.textPrimary,
        secondary: p.accent,
        surface: p.background,
        error: p.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        elevation: 0,
        iconTheme: IconThemeData(color: p.textPrimary),
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.textPrimary,
          foregroundColor: p.onBubbleUser,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppText.headingS,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.accent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: p.textHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppText.headingXL.copyWith(color: p.textPrimary),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        headlineMedium: AppText.headingM.copyWith(color: p.textPrimary),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        titleMedium: AppText.headingS.copyWith(color: p.textPrimary),
        bodyLarge:
            AppText.bodyRegular.copyWith(fontSize: 16, color: p.textPrimary),
        bodyMedium: AppText.bodyRegular.copyWith(color: p.textPrimary),
        bodySmall: AppText.caption.copyWith(color: p.textMuted),
        labelSmall: AppText.micro.copyWith(color: p.textMuted),
      ),
    );
  }
}
