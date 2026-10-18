import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/theme/app_tokens.dart';

void main() {
  test('spacing scale', () {
    expect(
      [
        AppSpacing.xxs,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ],
      [4, 8, 12, 16, 24, 32],
    );
  });

  test('radius scale', () {
    expect([AppRadius.sm, AppRadius.md, AppRadius.lg, AppRadius.full],
        [8, 18, 32, 999]);
    expect(AppRadius.mdAll, BorderRadius.circular(18));
  });

  test('themes use Inter for body text', () {
    expect(AppTheme.lightTheme.textTheme.bodyMedium!.fontFamily, 'Inter');
    expect(AppTheme.darkTheme.textTheme.bodyMedium!.fontFamily, 'Inter');
    expect(AppText.displayLarge.fontFamily, 'Exo 2');
  });

  test('palette bubbleUser', () {
    expect(AppPalette.light.bubbleUser, const Color(0xFF000000));
    expect(AppPalette.dark.bubbleUser, const Color(0xFFFFFFFF));
    expect(AppPalette.light.danger, const Color(0xFFD93A3F));
    expect(AppPalette.dark.danger, const Color(0xFFFF6B6F));
  });

  test('palette keeps the values of the removed AppColors constants', () {
    // light, dark (hex copied from the deleted app_colors.dart)
    final pins = <String, List<Color>>{
      'background': [const Color(0xFFFFFFFF), const Color(0xFF000000)],
      'textPrimary': [const Color(0xFF000000), const Color(0xFFFFFFFF)],
      'accent': [const Color(0xFF009ED8), const Color(0xFF009ED8)],
      'onBubbleUser': [const Color(0xFFFFFFFF), const Color(0xFF000000)],
      'textMuted': [const Color(0xFF666666), const Color(0xFFB0B0B0)],
      'textHint': [const Color(0xFF999999), const Color(0xFF6C6C6C)],
      'inputFill': [const Color(0xFFF5F5F5), const Color(0xFF1C1C1E)],
      'error': [const Color(0xFFFF453A), const Color(0xFFFF453A)],
    };
    Color pick(AppPalette p, String k) => switch (k) {
          'background' => p.background,
          'textPrimary' => p.textPrimary,
          'accent' => p.accent,
          'onBubbleUser' => p.onBubbleUser,
          'textMuted' => p.textMuted,
          'textHint' => p.textHint,
          'inputFill' => p.inputFill,
          _ => p.error,
        };
    pins.forEach((k, v) {
      expect(pick(AppPalette.light, k), v[0], reason: '$k light');
      expect(pick(AppPalette.dark, k), v[1], reason: '$k dark');
    });
  });

  test('themes are built from the palette', () {
    for (final (t, p) in [
      (AppTheme.lightTheme, AppPalette.light),
      (AppTheme.darkTheme, AppPalette.dark),
    ]) {
      expect(t.scaffoldBackgroundColor, p.background);
      expect(t.colorScheme.primary, p.textPrimary);
      expect(t.colorScheme.secondary, p.accent);
      expect(t.colorScheme.error, p.error);
      expect(t.inputDecorationTheme.fillColor, p.inputFill);
      expect(t.textTheme.bodySmall!.color, p.textMuted);
      expect(t.inputDecorationTheme.hintStyle!.color, p.textHint);
    }
  });

  test('no SF Pro reference in lib/', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.contains('lib/l10n/generated/'))
        .where((f) => f.readAsStringSync().contains('SF Pro'))
        .map((f) => f.path)
        .toList();
    expect(offenders, isEmpty);
  });
}
