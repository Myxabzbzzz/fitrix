import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/core/time/greeting.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_text.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 20, h, m);

  test('greeting and check-in title follow the clock', () {
    expect(timeOfDayGreeting(en, at(0, 3), ''), 'Good evening');
    expect(timeOfDayGreeting(en, at(4, 59), ''), 'Good evening');
    expect(timeOfDayGreeting(en, at(5), ''), 'Good morning');
    expect(timeOfDayGreeting(en, at(11, 59), 'Eli'), 'Good morning, Eli');
    expect(timeOfDayGreeting(en, at(12), ''), 'Good afternoon');
    expect(timeOfDayGreeting(en, at(18), ''), 'Good evening');

    expect(checkinTitleAt(en, at(7)), 'Morning check-in');
    expect(checkinTitleAt(en, at(14)), 'Afternoon check-in');
    expect(checkinTitleAt(en, at(22, 15)), 'Evening check-in');
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(checkinTitleAt(ru, at(22, 15)), 'Вечерний чек-ин');
  });

  test('sentences start in upper case', () {
    expect(
        capitalizeSentences('Тяжёлая тренировка подойдёт. ноги: сегодня '
            'полегче.'),
        'Тяжёлая тренировка подойдёт. Ноги: сегодня полегче.');
    expect(capitalizeSentences('ok. fine! sure? yes'), 'Ok. Fine! Sure? Yes');
  });

  for (final lang in ['en', 'ru', 'uz', 'es']) {
    test(
        'recovery advice with sore legs starts its sentences in upper case '
        'in $lang', () {
      final l10n = lookupAppLocalizations(Locale(lang));
      final text = l10n.recoveryHint(
        const Readiness(85, [], ReadinessLabel.ready),
        CheckIn(
          at: at(8),
          sleep: const Duration(hours: 8),
          quality: SleepQuality.good,
          soreness: Soreness.light,
          sore: const {BodyArea.legs},
          energy: Level3.high,
          stress: Level3.low,
        ),
      );
      for (final sentence in text.split(RegExp(r'(?<=[.!?])\s+'))) {
        expect(sentence[0], sentence[0].toUpperCase(), reason: text);
      }
    });
  }
}
