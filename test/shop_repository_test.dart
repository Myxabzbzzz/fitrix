import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/features/content/data/content_repository.dart';
import 'package:fitrix/features/shop/data/shop_repository.dart';

import 'support/fake_content_source.dart';

void main() {
  test('placeOrder passes only ids and quantities', () async {
    final remote = FakeContentSource();
    final shop = ShopRepository(ContentRepository(remote, () async => {}));
    final id = await shop.placeOrder({'a': 2, 'b': 1});
    expect(id, 'order-1');
    expect(remote.lastOrder, {'a': 2, 'b': 1});
  });

  test('OrderException propagates', () async {
    final remote = FakeContentSource()..error = OrderException('unknown product');
    final shop = ShopRepository(ContentRepository(remote, () async => {}));
    expect(() => shop.placeOrder({'a': 1}), throwsA(isA<OrderException>()));
  });

  test('products fall back to the seed offline', () async {
    final remote = FakeContentSource()..error = const SocketException('x');
    final shop = ShopRepository(ContentRepository(remote, () async => {
          'products': [
            {
              'id': 'p',
              'name': 'P',
              'category': 'apparel',
              'price_cents': 5,
              'currency': 'USD',
            }
          ]
        }));
    expect((await shop.products()).single.id, 'p');
  });
}
