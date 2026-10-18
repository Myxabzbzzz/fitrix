import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.light.background,
      fontFamily: AppText.body,
      colorScheme: ColorScheme.light(
        primary: AppPalette.light.textPrimary,
        secondary: AppPalette.light.accent,
        surface: AppPalette.light.background,
        error: AppPalette.light.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.light.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppPalette.light.textPrimary),
        titleTextStyle: TextStyle(
          color: AppPalette.light.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.light.textPrimary,
          foregroundColor: AppPalette.light.onBubbleUser,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.light.inputFill,
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
          borderSide: BorderSide(color: AppPalette.light.accent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: AppPalette.light.textHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppText.headingXL.copyWith(color: AppPalette.light.textPrimary),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppPalette.light.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppPalette.light.textPrimary,
        ),
        headlineMedium: AppText.headingM.copyWith(color: AppPalette.light.textPrimary),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppPalette.light.textPrimary,
        ),
        titleMedium: AppText.headingS.copyWith(color: AppPalette.light.textPrimary),
        bodyLarge: AppText.bodyRegular
            .copyWith(fontSize: 16, color: AppPalette.light.textPrimary),
        bodyMedium: AppText.bodyRegular.copyWith(color: AppPalette.light.textPrimary),
        bodySmall: AppText.caption.copyWith(color: AppPalette.light.textMuted),
        labelSmall: AppText.micro.copyWith(color: AppPalette.light.textMuted),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppPalette.dark.background,
      fontFamily: AppText.body,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppPalette.dark.textPrimary,
        secondary: AppPalette.dark.accent,
        surface: AppPalette.dark.background,
        error: AppPalette.dark.error,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.dark.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppPalette.dark.textPrimary),
        titleTextStyle: TextStyle(
          color: AppPalette.dark.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.dark.textPrimary,
          foregroundColor: AppPalette.dark.onBubbleUser,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.dark.inputFill,
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
          borderSide:
              BorderSide(color: AppPalette.dark.accent, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: AppPalette.dark.textHint,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
      ),
      textTheme: TextTheme(
        displayLarge:
            AppText.headingXL.copyWith(color: AppPalette.dark.textPrimary),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppPalette.dark.textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppPalette.dark.textPrimary,
        ),
        headlineMedium:
            AppText.headingM.copyWith(color: AppPalette.dark.textPrimary),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppPalette.dark.textPrimary,
        ),
        titleMedium:
            AppText.headingS.copyWith(color: AppPalette.dark.textPrimary),
        bodyLarge: AppText.bodyRegular
            .copyWith(fontSize: 16, color: AppPalette.dark.textPrimary),
        bodyMedium:
            AppText.bodyRegular.copyWith(color: AppPalette.dark.textPrimary),
        bodySmall: AppText.caption.copyWith(color: AppPalette.dark.textMuted),
        labelSmall: AppText.micro.copyWith(color: AppPalette.dark.textMuted),
      ),
    );
  }
}
