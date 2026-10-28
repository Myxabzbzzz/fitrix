import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

void main() {
  test('a finished session under a minute is "<1 min", never 0', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(doneDuration(ru, const Duration(seconds: 40)), '<1 мин');
    expect(doneDuration(ru, Duration.zero), '<1 мин');
    expect(doneDuration(ru, const Duration(minutes: 2, seconds: 40)), '2 мин');
    expect(doneDuration(ru, const Duration(minutes: 75)),
        isNot(contains('0 мин')));
    final en = lookupAppLocalizations(const Locale('en'));
    expect(en.durationSeconds(40), '40 s');
  });

  for (final lang in ['en', 'ru', 'uz', 'es']) {
    test('the code step keeps the email with its lead-in in $lang', () {
      final l10n = lookupAppLocalizations(Locale(lang));
      final text = l10n.signInCodePrompt('6', 'eli.e2e@fitrix.test');
      expect(text, isNot(contains('\n')));
      expect(text, endsWith('\u00a0eli.e2e@fitrix.test'));
    });
  }
}
