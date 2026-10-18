import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final data =
      jsonDecode(File('assets/data/seed_content.json').readAsStringSync())
          as Map<String, dynamic>;
  List<Map<String, dynamic>> rows(String key) =>
      (data[key] as List).cast<Map<String, dynamic>>();

  test('seed content has the expected row counts', () {
    expect(rows('products'), hasLength(8));
    expect(rows('programs'), hasLength(3));
    expect(rows('articles'), hasLength(3));
    expect(rows('challenges'), hasLength(1));
    expect(rows('places'), hasLength(22));
  });

  test('every place is inside central Tashkent', () {
    for (final p in rows('places')) {
      expect(p['lat'] as double, inInclusiveRange(41.29, 41.34),
          reason: '${p['id']}');
      expect(p['lon'] as double, inInclusiveRange(69.24, 69.31),
          reason: '${p['id']}');
    }
  });

  test('ids are unique per table', () {
    for (final key in data.keys) {
      final ids = rows(key).map((r) => r['id']).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: key);
    }
  });
}
