import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/text/normalize.dart';
import 'package:fitrix/core/time/day_key.dart';

void main() {
  group('dayOf', () {
    test('drops the time of day to local midnight', () {
      expect(dayOf(DateTime(2026, 10, 12, 14, 30, 5)), DateTime(2026, 10, 12));
      expect(dayOf(DateTime(2026, 10, 12)), DateTime(2026, 10, 12));
    });
    test('23:59:59 stays on the same day', () {
      expect(dayOf(DateTime(2026, 12, 31, 23, 59, 59)), DateTime(2026, 12, 31));
    });
    test('result is a local date', () {
      expect(dayOf(DateTime(2026, 3, 1, 8)).isUtc, isFalse);
    });
  });

  group('dayKey', () {
    test('formats yyyy-MM-dd with zero padding', () {
      expect(dayKey(DateTime(2026, 1, 5)), '2026-01-05');
      expect(dayKey(DateTime(2026, 10, 12, 23, 59)), '2026-10-12');
      expect(dayKey(DateTime(2026, 12, 31, 0, 0)), '2026-12-31');
    });
    test('pads the year to four digits', () {
      expect(dayKey(DateTime(987, 2, 3)), '0987-02-03');
    });
  });

  group('normalizeName', () {
    test('trims and lower-cases', () {
      expect(normalizeName('  Bench Press '), 'bench press');
      expect(normalizeName('ЖИМ'), 'жим');
      expect(normalizeName(''), '');
    });
  });
}
