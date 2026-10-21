import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/doc_deletions.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/features/running/data/run_track.dart';

/// Run details by workout id, kept on the device (prefs `runs_v1`).
class RunStore {
  RunStore(this._prefs, {void Function(String id)? onRemoved})
      : _onRemoved = onRemoved;

  static const key = 'runs_v1';

  final SharedPreferences _prefs;
  final void Function(String id)? _onRemoved;

  Map<String, RunDetails> all() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      final out = <String, RunDetails>{};
      for (final e in (jsonDecode(raw) as Map).entries) {
        try {
          out[e.key as String] =
              RunDetails.fromJson((e.value as Map).cast<String, Object?>());
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  void _write(Map<String, RunDetails> runs) {
    _prefs.setString(key,
        jsonEncode({for (final e in runs.entries) e.key: e.value.toJson()}));
  }

  void put(String id, RunDetails d) => _write({...all(), id: d});

  /// The user deleted the run: also reports the deletion for sync.
  void remove(String id) {
    final runs = all();
    if (runs.remove(id) == null) return;
    _write(runs);
    _onRemoved?.call(id);
  }

  /// Applies pulled docs (null = deleted on the server) without reporting.
  void applySynced(Map<String, RunDetails?> updates) {
    final runs = all();
    for (final e in updates.entries) {
      final d = e.value;
      d == null ? runs.remove(e.key) : runs[e.key] = d;
    }
    _write(runs);
  }

  void clear() => _prefs.remove(key);
}

final runStoreProvider = Provider<RunStore>(
  (ref) => RunStore(
    ref.watch(sharedPreferencesProvider),
    onRemoved: (id) => recordDocDeleted(ref, 'run', id),
  ),
);

class RunsNotifier extends StateNotifier<Map<String, RunDetails>> {
  RunsNotifier(this._store, this._onChanged) : super(_store.all());

  final RunStore _store;
  final void Function() _onChanged;

  void put(String id, RunDetails d) {
    _store.put(id, d);
    state = _store.all();
    _onChanged();
  }

  void remove(String id) {
    _store.remove(id);
    state = _store.all();
  }

  /// Pulled docs; not reported as local changes.
  void applySynced(Map<String, RunDetails?> updates) {
    _store.applySynced(updates);
    state = _store.all();
  }

  void clear() {
    _store.clear();
    state = {};
  }
}

final runsProvider =
    StateNotifierProvider<RunsNotifier, Map<String, RunDetails>>(
  (ref) => RunsNotifier(
    ref.watch(runStoreProvider),
    ref.read(localChangesProvider).notify,
  ),
);
