import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/i18n/catalog_overlay.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/features/content/data/models.dart';

import 'support/catalog_fixtures.dart';

void main() {
  test('a translated field shows only while the row still says the seed text',
      () async {
    final o = await CatalogOverlay.load(
        FixtureBundle.locale('ru', {
          'seed_content': {
            'challenges': {
              'c1': {
                'title': 'Шаги',
                'description': 'Ходите каждый день',
                'daily_target': '10 000 шагов',
              },
            },
          },
        }),
        'ru');
    final seed = {
      'challenges': [
        {
          'id': 'c1',
          'title': 'Steps',
          'description': 'Walk every day',
          'daily_target': '10,000 steps',
        },
      ],
    };
    final t = CatalogText(o, seed: seed);
    Challenge row(String target) => Challenge(
          id: 'c1',
          title: 'Steps',
          description: 'Walk every day',
          dailyTarget: target,
          days: 7,
          startsOn: DateTime(2026, 1, 1),
          endsOn: DateTime(2026, 1, 8),
        );
    final same = t.challenge(row('10,000 steps'));
    expect(same.title, 'Шаги');
    expect(same.dailyTarget, '10 000 шагов');
    // The server changed the target: its English stays, other fields keep
    // their translation.
    final edited = t.challenge(row('8,000 steps'));
    expect(edited.dailyTarget, '8,000 steps');
    expect(edited.title, 'Шаги');
    // A server-only id has no seed row: English.
    final other = t.challenge(Challenge(
      id: 'c9',
      title: 'Steps',
      description: 'Walk every day',
      dailyTarget: '1',
      days: 1,
      startsOn: DateTime(2026, 1, 1),
      endsOn: DateTime(2026, 1, 2),
    ));
    expect(other.title, 'Steps');
  });
}
