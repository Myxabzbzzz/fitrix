import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/supabase/supabase_providers.dart';
import 'package:fitrix/features/content/data/content_repository.dart';

Future<Map<String, dynamic>> loadBundledSeed() async =>
    Map<String, dynamic>.from(
        jsonDecode(await rootBundle.loadString('assets/data/seed_content.json'))
            as Map);

/// Override in tests to avoid the asset bundle.
final seedLoaderProvider =
    Provider<Future<Map<String, dynamic>> Function()>((ref) => loadBundledSeed);

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final source = client == null
      ? const OfflineContentSource()
      : SupabaseContentSource(client);
  return ContentRepository(source, ref.watch(seedLoaderProvider));
});

final programsProvider = FutureProvider<List<Program>>(
    (ref) => ref.watch(contentRepositoryProvider).programs());
final articlesProvider = FutureProvider<List<Article>>(
    (ref) => ref.watch(contentRepositoryProvider).articles());
final challengesProvider = FutureProvider<List<Challenge>>(
    (ref) => ref.watch(contentRepositoryProvider).challenges());
final placesProvider = FutureProvider<List<Place>>(
    (ref) => ref.watch(contentRepositoryProvider).places());

/// Ids of the challenges the signed-in user joined; empty when signed out.
final joinedChallengesProvider = FutureProvider<Set<String>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return <String>{};
  return ref.watch(contentRepositoryProvider).joinedChallenges(user.id);
});
