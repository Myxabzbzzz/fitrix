import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/shop/providers.dart';

Future<ProviderContainer> _make(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('add, remove, clear and count', () async {
    final c = await _make();
    final cart = c.read(cartProvider.notifier);
    cart.add('a');
    cart.add('a');
    cart.add('b');
    expect(c.read(cartProvider), {'a': 2, 'b': 1});
    expect(cart.count, 3);
    cart.remove('a');
    expect(c.read(cartProvider), {'a': 1, 'b': 1});
    cart.remove('a');
    expect(c.read(cartProvider).containsKey('a'), isFalse);
    cart.clear();
    expect(c.read(cartProvider), isEmpty);
  });

  test('caps at 20 per item', () async {
    final c = await _make();
    final cart = c.read(cartProvider.notifier);
    for (var i = 0; i < 25; i++) {
      cart.add('a');
    }
    expect(c.read(cartProvider)['a'], 20);
  });

  test('persists and restores', () async {
    final c = await _make();
    c.read(cartProvider.notifier).add('a');
    c.read(cartProvider.notifier).add('a');
    final prefs = c.read(sharedPreferencesProvider);
    expect(jsonDecode(prefs.getString('cart')!), {'a': 2});
    final c2 = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    addTearDown(c2.dispose);
    expect(c2.read(cartProvider), {'a': 2});
  });

  test('ignores corrupt stored data', () async {
    final c = await _make({'cart': 'not json'});
    expect(c.read(cartProvider), isEmpty);
  });

  test('sanitises odd stored values', () async {
    final c = await _make({'cart': '{"a":-1,"b":99,"c":"x","d":2,"e":0}'});
    expect(c.read(cartProvider), {'b': 20, 'd': 2});
  });

  test('ignores a JSON array', () async {
    final c = await _make({'cart': '[1,2]'});
    expect(c.read(cartProvider), isEmpty);
  });
}
