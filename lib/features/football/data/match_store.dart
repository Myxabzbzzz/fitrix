import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/doc_deletions.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/features/football/data/match_log.dart';

/// Football logs by workout id, kept on the device (prefs `matches_v1`).
class MatchStore {
  MatchStore(this._prefs, {void Function(String id)? onRemoved})
      : _onRemoved = onRemoved;

  static const key = 'matches_v1';

  final SharedPreferences _prefs;
  final void Function(String id)? _onRemoved;

  Map<String, MatchLog> all() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      final out = <String, MatchLog>{};
      for (final e in (jsonDecode(raw) as Map).entries) {
        try {
          out[e.key as String] =
              MatchLog.fromJson((e.value as Map).cast<String, Object?>());
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  void _write(Map<String, MatchLog> logs) {
    _prefs.setString(key,
        jsonEncode({for (final e in logs.entries) e.key: e.value.toJson()}));
  }

  void put(String id, MatchLog d) => _write({...all(), id: d});

  /// The user deleted the log: also reports the deletion for sync.
  void remove(String id) {
    final logs = all();
    if (logs.remove(id) == null) return;
    _write(logs);
    _onRemoved?.call(id);
  }

  /// Applies pulled docs (null = deleted on the server) without reporting.
  void applySynced(Map<String, MatchLog?> updates) {
    final logs = all();
    for (final e in updates.entries) {
      final d = e.value;
      d == null ? logs.remove(e.key) : logs[e.key] = d;
    }
    _write(logs);
  }

  void clear() => _prefs.remove(key);
}

final matchStoreProvider = Provider<MatchStore>(
  (ref) => MatchStore(
    ref.watch(sharedPreferencesProvider),
    onRemoved: (id) => recordDocDeleted(ref, 'match', id),
  ),
);

class MatchesNotifier extends StateNotifier<Map<String, MatchLog>> {
  MatchesNotifier(this._store, this._onChanged) : super(_store.all());

  final MatchStore _store;
  final void Function() _onChanged;

  void put(String id, MatchLog d) {
    _store.put(id, d);
    state = _store.all();
    _onChanged();
  }

  void remove(String id) {
    _store.remove(id);
    state = _store.all();
  }

  /// Pulled docs; not reported as local changes.
  void applySynced(Map<String, MatchLog?> updates) {
    _store.applySynced(updates);
    state = _store.all();
  }

  void clear() {
    _store.clear();
    state = {};
  }
}

final matchesProvider =
    StateNotifierProvider<MatchesNotifier, Map<String, MatchLog>>(
  (ref) => MatchesNotifier(
    ref.watch(matchStoreProvider),
    ref.read(localChangesProvider).notify,
  ),
);
