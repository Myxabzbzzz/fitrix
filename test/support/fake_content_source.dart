import 'package:fitrix/features/content/data/content_repository.dart';

class FakeContentSource implements ContentSource {
  Object? error;
  List<Product> productTable = const [];
  List<Program> programTable = const [];
  List<Article> articleTable = const [];
  List<Challenge> challengeTable = const [];
  List<Place> placeTable = const [];
  final joined = <String, Set<String>>{};
  Map<String, int>? lastOrder;

  T _ok<T>(T v) {
    if (error != null) throw error!;
    return v;
  }

  @override
  Future<List<Product>> products() async => _ok(productTable);
  @override
  Future<List<Program>> programs() async => _ok(programTable);
  @override
  Future<List<Article>> articles() async => _ok(articleTable);
  @override
  Future<List<Challenge>> challenges() async => _ok(challengeTable);
  @override
  Future<List<Place>> places() async => _ok(placeTable);
  @override
  Future<Set<String>> joinedChallenges(String userId) async =>
      _ok({...?joined[userId]});
  @override
  Future<void> joinChallenge(String challengeId, String userId) async {
    _ok(null);
    (joined[userId] ??= {}).add(challengeId);
  }

  @override
  Future<void> leaveChallenge(String challengeId, String userId) async {
    _ok(null);
    joined[userId]?.remove(challengeId);
  }

  @override
  Future<String> placeOrder(Map<String, int> quantities) async {
    _ok(null);
    lastOrder = Map.of(quantities);
    return 'order-1';
  }
}
