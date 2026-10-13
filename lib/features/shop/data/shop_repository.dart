import 'package:fitrix/features/content/data/content_repository.dart';

/// Shop view of the content repository: the catalog and placing an order.
/// Only product ids and quantities leave the device; prices come from the
/// server catalog.
class ShopRepository {
  ShopRepository(this._content);
  final ContentRepository _content;

  Future<List<Product>> products() => _content.products();
  Future<String> placeOrder(Map<String, int> quantities) =>
      _content.placeOrder(quantities);
}
