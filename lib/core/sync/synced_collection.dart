import 'dart:convert';

import 'package:crypto/crypto.dart';

/// One kind of synced document. Docs are small JSON maps keyed by id.
abstract class SyncedCollection {
  /// One of the `user_documents.kind` values.
  String get kind;

  /// Live local docs by id.
  Map<String, Map<String, Object?>> read();

  /// Applies pulled docs (null value = deleted on the server). Must update
  /// the UI state (notifiers) and must NOT ping LocalChanges. Docs the store
  /// cannot parse are skipped.
  void apply(Map<String, Map<String, Object?>?> docs);

  /// Drops all local data of this kind.
  void clear();
}

/// Identity of a doc's content: sha1 hex of its JSON.
String docHash(Map<String, Object?> doc) =>
    sha1.convert(utf8.encode(jsonEncode(doc))).toString();
