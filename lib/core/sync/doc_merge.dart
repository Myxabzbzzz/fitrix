import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/core/sync/synced_collection.dart';

/// Outcome of merging pulled docs of one kind.
class DocMergeResult {
  /// Docs to apply locally (null value = delete).
  final Map<String, Map<String, Object?>?> apply;

  /// The agreed hashes (doc id -> hash) after the merge.
  final Map<String, String> agreed;

  const DocMergeResult(this.apply, this.agreed);
}

/// A doc has changes the server doesn't: its content differs from the
/// version both sides last agreed on (or there is none).
bool isDocDirty(Map<String, Object?> doc, String? agreedHash) =>
    docHash(doc) != agreedHash;

/// Merges pulled [remote] docs of one kind into [local].
///
/// A doc is dirty if its hash differs from [agreed] or it has a tombstone.
/// Remote changes apply only to non-dirty docs; a dirty doc keeps the local
/// version, whose push then overwrites the server (last writer wins).
DocMergeResult mergeDocs({
  required Map<String, Map<String, Object?>> local,
  required Map<String, String> agreed,
  required Set<String> tombstones,
  required List<RemoteDoc> remote,
}) {
  final apply = <String, Map<String, Object?>?>{};
  final result = {...agreed};
  for (final doc in remote) {
    final id = doc.docId;
    final mine = local[id];
    final dirty = tombstones.contains(id) ||
        (mine != null && isDocDirty(mine, agreed[id]));
    if (dirty) continue;
    final data = doc.data;
    if (data == null) {
      if (mine != null) apply[id] = null;
      result.remove(id);
    } else {
      final hash = docHash(data);
      if (mine == null || docHash(mine) != hash) apply[id] = data;
      result[id] = hash;
    }
  }
  return DocMergeResult(apply, result);
}
