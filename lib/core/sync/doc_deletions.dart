import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/core/sync/sync_state.dart';

/// A store calls this when the user deletes a synced document, so the
/// deletion reaches the server. Pruning old data must not call it.
void recordDocDeleted(Ref ref, String kind, String docId) {
  final prefs = ref.read(sharedPreferencesProvider);
  final state = SyncState.load(prefs);
  state.docTombstones['$kind/$docId'] = DateTime.now().millisecondsSinceEpoch;
  state.save(prefs);
  ref.read(localChangesProvider).notify();
}
