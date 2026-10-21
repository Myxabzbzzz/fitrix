import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';

/// Ids of finished workouts the user deleted, with the time. Kept so a
/// deleted workout is not brought back by a sync, and so the deletion can be
/// sent to the cloud and the other devices.
class DeletedWorkoutsStore {
  DeletedWorkoutsStore(this._prefs);

  static const key = 'deleted_workouts_v1';

  final SharedPreferences _prefs;

  Map<String, int> _read() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      return {
        for (final e in (jsonDecode(raw) as Map).entries)
          e.key as String: (e.value as num).toInt(),
      };
    } catch (_) {
      return {};
    }
  }

  Set<String> ids() => _read().keys.toSet();

  /// When [id] was deleted (null if it was not).
  DateTime? deletedAt(String id) {
    final ms = _read()[id];
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Records the deletion; an id already recorded keeps its first time.
  void add(String id, DateTime at) {
    final all = _read();
    if (all.containsKey(id)) return;
    all[id] = at.millisecondsSinceEpoch;
    _prefs.setString(key, jsonEncode(all));
  }

  void clear() => _prefs.remove(key);
}

final deletedWorkoutsStoreProvider = Provider<DeletedWorkoutsStore>(
  (ref) => DeletedWorkoutsStore(ref.watch(sharedPreferencesProvider)),
);
