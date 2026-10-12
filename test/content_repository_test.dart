import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/features/content/data/content_repository.dart';

import 'support/fake_content_source.dart';

Future<Map<String, dynamic>> _seed() async => {
      'products': [
        {
          'id': 'p1',
          'name': 'Seed product',
          'category': 'apparel',
          'price_cents': 100,
          'currency': 'USD',
          'image': null,
          'word': 'TEE',
        }
      ],
      'programs': [
        {
          'id': 'seed-prog',
          'title': 'Seed program',
          'meta': '1 week',
          'level': 'beginner',
          'sport': 'gym',
          'image': null,
        }
      ],
      'articles': [
        {'id': 'a', 'tag': 'T', 'title': 'Seed', 'minutes': 3, 'body': 'b'}
      ],
      'challenges': [
        {
          'id': 'c',
          'title': 'C',
          'description': 'd',
          'days': 7,
          'daily_target': '10k',
          'starts_on': '2026-10-12',
          'ends_on': '2026-10-18',
        }
      ],
      'places': [
        {
          'id': 'pl',
          'name': 'Gym',
          'kind': 'gyms',
          'type': 'Gym',
          'lat': 41.3,
          'lon': 69.2,
          'hours': null,
          'note': null,
          'osm_ref': null,
        }
      ],
    };

void main() {
  test('falls back to the seed when the remote throws SocketException',
      () async {
    final remote = FakeContentSource()..error = const SocketException('offline');
    final repo = ContentRepository(remote, _seed);
    final programs = await repo.programs();
    expect(programs.single.id, 'seed-prog');
    expect((await repo.products()).single.priceCents, 100);
    expect((await repo.articles()).single.minutes, 3);
    final ch = (await repo.challenges()).single;
    expect(ch.dailyTarget, '10k');
    expect(ch.startsOn, DateTime(2026, 10, 12));
    expect((await repo.places()).single.lat, 41.3);
  });

  test('returns remote data when it works', () async {
    final remote = FakeContentSource()
      ..programTable = const [
        Program(
            id: 'remote',
            title: 'R',
            meta: 'm',
            level: 'medium',
            sport: 'gym')
      ];
    final repo = ContentRepository(remote, _seed);
    expect((await repo.programs()).single.id, 'remote');
  });

  test('Product.fromJson maps snake_case', () {
    final p = Product.fromJson({
      'id': 'x',
      'name': 'N',
      'category': 'equipment',
      'price_cents': 1234,
      'currency': 'UZS',
      'image': 'tile_shop',
      'word': null,
    });
    expect(p.priceCents, 1234);
    expect(p.image, 'tile_shop');
    expect(p.word, isNull);
  });

  test('join without a user throws SignInRequired', () {
    final repo = ContentRepository(FakeContentSource(), _seed);
    expect(() => repo.joinChallenge('c', null), throwsA(isA<SignInRequired>()));
  });

  test('join and leave reach the source', () async {
    final remote = FakeContentSource();
    final repo = ContentRepository(remote, _seed);
    await repo.joinChallenge('c', 'u1');
    expect(await repo.joinedChallenges('u1'), {'c'});
    await repo.leaveChallenge('c', 'u1');
    expect(await repo.joinedChallenges('u1'), isEmpty);
  });
}
