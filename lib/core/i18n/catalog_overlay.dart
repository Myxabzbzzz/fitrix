import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';

/// Display-time translations of the built-in catalogs
/// (`assets/data/i18n/<catalog>.<locale>.json`, see the overlay format).
///
/// The catalogs, stored data, sync documents and Felix's context stay in
/// English; only what is shown on screen goes through an overlay. Every
/// lookup takes the English text and returns it when the overlay has no
/// usable value, so a missing file or key simply reads English.
class CatalogOverlay {
  const CatalogOverlay(this.locale, this._files);

  /// No translations: everything reads English.
  static const empty = CatalogOverlay('en', {});

  /// The overlay files, per locale.
  static const catalogs = [
    'exercises',
    'foods',
    'training_programs',
    'seed_content',
    'workout_catalog',
  ];

  static String assetPath(String catalog, String locale) =>
      'assets/data/i18n/$catalog.$locale.json';

  /// The language these translations are for.
  final String locale;
  final Map<String, Map<String, dynamic>> _files;

  bool get isEmpty => _files.isEmpty;

  /// Reads every overlay file for [locale] from [bundle]. English, a
  /// missing file and a malformed file give no translations for it.
  static Future<CatalogOverlay> load(AssetBundle bundle, String locale) async {
    if (locale == 'en') return empty;
    final files = <String, Map<String, dynamic>>{};
    for (final catalog in catalogs) {
      try {
        final raw = await bundle.loadString(assetPath(catalog, locale));
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) files[catalog] = json;
      } catch (_) {
        // No overlay for this catalog: it reads English.
      }
    }
    return CatalogOverlay(locale, files);
  }

  Object? _at(String catalog, List<String> path) {
    Object? node = _files[catalog];
    for (final key in path) {
      if (node is! Map) return null;
      node = node[key];
    }
    return node;
  }

  /// The translation at [path] in [catalog], or [english].
  String text(String catalog, List<String> path, String english) {
    final v = _at(catalog, path);
    return v is String && v.trim().isNotEmpty ? v : english;
  }

  /// The translated list at [path] when it has as many non-empty entries as
  /// [english] (steps and rules are numbered); otherwise [english].
  List<String> list(String catalog, List<String> path, List<String> english) {
    final v = _at(catalog, path);
    if (v is! List || v.length != english.length) return english;
    if (v.any((e) => e is! String || e.trim().isEmpty)) return english;
    return v.cast<String>();
  }

  /// Every non-empty string of the list at [path] (search words), or none.
  List<String> words(String catalog, List<String> path) {
    final v = _at(catalog, path);
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is String && e.trim().isNotEmpty) e,
    ];
  }
}

/// Where the overlay files are read from. Tests override it with fixtures.
final catalogBundleProvider = Provider<AssetBundle>((ref) => rootBundle);

/// Loaded overlays by locale, so switching back and forth reads each file
/// once.
final _overlayCacheProvider = Provider<Map<String, Future<CatalogOverlay>>>(
  (ref) {
    ref.watch(catalogBundleProvider);
    return {};
  },
);

/// The overlay for the app language, reloaded when the language changes.
final catalogOverlayLoaderProvider = FutureProvider<CatalogOverlay>((ref) {
  final locale = ref.watch(selectedLanguageProvider);
  final bundle = ref.watch(catalogBundleProvider);
  return ref.watch(_overlayCacheProvider).putIfAbsent(
        locale,
        () => CatalogOverlay.load(bundle, locale),
      );
});

/// The overlay for the app language; English (no translations) until it
/// has loaded, never the previous language's.
final catalogOverlayProvider = Provider<CatalogOverlay>((ref) {
  final locale = ref.watch(selectedLanguageProvider);
  final overlay = ref.watch(catalogOverlayLoaderProvider).valueOrNull;
  return overlay != null && overlay.locale == locale
      ? overlay
      : CatalogOverlay.empty;
});
