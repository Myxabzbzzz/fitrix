import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitrix/features/content/data/models.dart';
import 'package:fitrix/features/shop/data/models.dart';

export 'package:fitrix/features/content/data/models.dart';
export 'package:fitrix/features/shop/data/models.dart';

/// The action needs a signed-in account; the UI should prompt to sign in.
class SignInRequired implements Exception {
  const SignInRequired();
  @override
  String toString() => 'SignInRequired';
}

/// The server rejected an order (unknown product, invalid items, ...).
class OrderException implements Exception {
  OrderException(this.message);
  final String message;
  @override
  String toString() => 'OrderException: $message';
}

abstract class ContentSource {
  Future<List<Product>> products();
  Future<List<Program>> programs();
  Future<List<Article>> articles();
  Future<List<Challenge>> challenges();
  Future<List<Place>> places();
  Future<Set<String>> joinedChallenges(String userId);
  Future<void> joinChallenge(String challengeId, String userId);
  Future<void> leaveChallenge(String challengeId, String userId);

  /// Returns the new order id. Throws [OrderException] when the server
  /// rejects the order and [SignInRequired] when there is no valid session.
  /// Network failures surface as SocketException / ClientException (retryable).
  Future<String> placeOrder(Map<String, int> quantities);
}

/// Used when Supabase isn't configured: catalog reads fail like a lost
/// connection (so the repository serves the seed) and account actions ask
/// for sign-in.
class OfflineContentSource implements ContentSource {
  const OfflineContentSource();

  Never _offline() => throw const SocketException('Supabase not configured');

  @override
  Future<List<Product>> products() async => _offline();
  @override
  Future<List<Program>> programs() async => _offline();
  @override
  Future<List<Article>> articles() async => _offline();
  @override
  Future<List<Challenge>> challenges() async => _offline();
  @override
  Future<List<Place>> places() async => _offline();
  @override
  Future<Set<String>> joinedChallenges(String userId) async => <String>{};
  @override
  Future<void> joinChallenge(String challengeId, String userId) async =>
      throw const SignInRequired();
  @override
  Future<void> leaveChallenge(String challengeId, String userId) async =>
      throw const SignInRequired();
  @override
  Future<String> placeOrder(Map<String, int> quantities) async =>
      throw const SignInRequired();
}

bool _isAuthError(PostgrestException e, {required String extra}) =>
    e.code == extra ||
    e.code == '28000' ||
    (e.code?.startsWith('PGRST3') ?? false) ||
    e.code == '401';

class SupabaseContentSource implements ContentSource {
  SupabaseContentSource(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> _rows(String table,
      {bool ordered = true}) async {
    final query = _client.from(table).select();
    final rows = ordered ? await query.order('position') : await query;
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Future<List<Product>> products() async =>
      (await _rows('products')).map(Product.fromJson).toList();
  @override
  Future<List<Program>> programs() async =>
      (await _rows('programs')).map(Program.fromJson).toList();
  @override
  Future<List<Article>> articles() async =>
      (await _rows('articles')).map(Article.fromJson).toList();
  @override
  Future<List<Challenge>> challenges() async {
    final rows = List<Map<String, dynamic>>.from(
        await _client.from('challenges').select().order('starts_on'));
    return rows.map(Challenge.fromJson).toList();
  }

  @override
  Future<List<Place>> places() async =>
      (await _rows('places', ordered: false)).map(Place.fromJson).toList();

  @override
  Future<Set<String>> joinedChallenges(String userId) async {
    final rows = await _client
        .from('challenge_participants')
        .select('challenge_id')
        .eq('user_id', userId);
    return {for (final r in rows) r['challenge_id'] as String};
  }

  @override
  Future<void> joinChallenge(String challengeId, String userId) async {
    try {
      await _client
          .from('challenge_participants')
          .insert({'challenge_id': challengeId, 'user_id': userId});
    } on PostgrestException catch (e) {
      if (e.code == '23505') return; // already joined
      if (_isAuthError(e, extra: '42501')) throw const SignInRequired();
      rethrow;
    }
  }

  @override
  Future<void> leaveChallenge(String challengeId, String userId) async {
    try {
      await _client
          .from('challenge_participants')
          .delete()
          .eq('challenge_id', challengeId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      if (_isAuthError(e, extra: '42501')) throw const SignInRequired();
      rethrow;
    }
  }

  @override
  Future<String> placeOrder(Map<String, int> quantities) async {
    if (_client.auth.currentUser == null) throw const SignInRequired();
    try {
      final id = await _client.rpc('place_order', params: {
        'p_items': [
          for (final e in quantities.entries)
            {'product_id': e.key, 'quantity': e.value},
        ],
      });
      return id as String;
    } on PostgrestException catch (e) {
      if (_isAuthError(e, extra: '28000')) throw const SignInRequired();
      throw OrderException(e.message);
    }
  }
}

/// Remote first; on any error the bundled seed answers, so every screen
/// works offline and signed out.
class ContentRepository {
  ContentRepository(
    this._remote,
    this._loadSeed, {
    this.timeout = const Duration(seconds: 8),
  });

  final Duration timeout;

  final ContentSource _remote;
  final Future<Map<String, dynamic>> Function() _loadSeed;

  Future<List<T>> _list<T>(
    Future<List<T>> Function() remote,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      return await remote().timeout(timeout);
    } catch (e) {
      debugPrint('Content "$key": remote failed ($e), using the seed');
      final seed = await _loadSeed();
      final rows = (seed[key] as List?) ?? const [];
      return [
        for (final r in rows) fromJson(Map<String, dynamic>.from(r as Map)),
      ];
    }
  }

  Future<List<Product>> products() =>
      _list(_remote.products, 'products', Product.fromJson);
  Future<List<Program>> programs() =>
      _list(_remote.programs, 'programs', Program.fromJson);
  Future<List<Article>> articles() =>
      _list(_remote.articles, 'articles', Article.fromJson);
  Future<List<Challenge>> challenges() =>
      _list(_remote.challenges, 'challenges', Challenge.fromJson);
  Future<List<Place>> places() =>
      _list(_remote.places, 'places', Place.fromJson);

  Future<Set<String>> joinedChallenges(String? userId) async {
    if (userId == null) return <String>{};
    try {
      return await _remote.joinedChallenges(userId).timeout(timeout);
    } catch (e) {
      debugPrint('joinedChallenges failed ($e), assuming none');
      return <String>{};
    }
  }

  Future<void> joinChallenge(String challengeId, String? userId) async {
    if (userId == null) throw const SignInRequired();
    await _remote.joinChallenge(challengeId, userId);
  }

  Future<void> leaveChallenge(String challengeId, String? userId) async {
    if (userId == null) throw const SignInRequired();
    await _remote.leaveChallenge(challengeId, userId);
  }

  Future<String> placeOrder(Map<String, int> quantities) =>
      _remote.placeOrder(quantities);
}
