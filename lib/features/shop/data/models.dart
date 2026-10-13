class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.priceCents,
    this.currency = 'USD',
    this.image,
    this.word,
  });

  final String id, name, category, currency;
  final int priceCents;
  final String? image, word;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        priceCents: (j['price_cents'] as num).toInt(),
        currency: (j['currency'] as String?) ?? 'USD',
        image: j['image'] as String?,
        word: j['word'] as String?,
      );
}
