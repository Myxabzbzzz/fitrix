import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One kind of synced document. Docs are small JSON maps keyed by id.
abstract class SyncedCollection {
  /// One of the `user_documents.kind` values.
  String get kind;

  /// Live local docs by id. Must only return what the user has actually
  /// created or changed: never unset defaults (e.g. empty settings), or a
  /// first sync would overwrite the same doc on the server.
  Map<String, Map<String, Object?>> read();

  /// Applies pulled docs (null value = deleted on the server). Must update
  /// the UI state (notifiers) and must NOT ping LocalChanges. Docs the store
  /// cannot parse are skipped.
  void apply(Map<String, Map<String, Object?>?> docs);

  /// Drops all local data of this kind.
  void clear();
}

/// Identity of a doc's content: sha1 hex of its JSON with keys sorted
/// (recursively), because the server's jsonb returns keys in another order.
String docHash(Map<String, Object?> doc) =>
    sha1.convert(utf8.encode(jsonEncode(_canonical(doc)))).toString();

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((k) => k.toString()).toList()..sort();
    return {for (final k in keys) k: _canonical(value[k])};
  }
  if (value is List) return [for (final v in value) _canonical(v)];
  return value;
}
