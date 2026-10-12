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
