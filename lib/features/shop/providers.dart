import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/content/data/content_repository.dart';
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/features/shop/data/cart.dart';
import 'package:fitrix/features/shop/data/shop_repository.dart';

export 'package:fitrix/features/shop/data/cart.dart';

final cartProvider =
    NotifierProvider<CartNotifier, Map<String, int>>(CartNotifier.new);

final shopRepositoryProvider = Provider<ShopRepository>(
    (ref) => ShopRepository(ref.watch(contentRepositoryProvider)));

final productsProvider = FutureProvider<List<Product>>(
    (ref) => ref.watch(shopRepositoryProvider).products());
