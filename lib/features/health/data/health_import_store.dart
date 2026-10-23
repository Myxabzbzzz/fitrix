import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/doc_deletions.dart';
import 'package:fitrix/core/sync/local_changes.dart';

/// `templateId` of every imported workout (it belongs to no plan).
const healthImportTemplateId = 'health_import';

/// What came with a workout imported from Apple Health / Health Connect
/// (the `health_import` document; id = the workout id).
class HealthImport {
  const HealthImport({
    required this.source,
    required this.healthUuid,
    this.meters,
    this.avgHr,
    this.kcal,
    this.rpe,
  });

  /// The app or device that recorded it ("Apple Watch").
  final String source;
  final String healthUuid;
  final double? meters;
  final int? avgHr;
  final double? kcal;

  /// Session RPE 1-10 the user gave the workout; synced here because the
  /// workout itself keeps its RPE local.
  final int? rpe;

  HealthImport withRpe(int rpe) => HealthImport(
      source: source,
      healthUuid: healthUuid,
      meters: meters,
      avgHr: avgHr,
      kcal: kcal,
      rpe: rpe);

  Map<String, Object?> toJson() => {
        'source': source,
        'healthUuid': healthUuid,
        if (meters != null) 'meters': meters,
        if (avgHr != null) 'avgHr': avgHr,
        if (kcal != null) 'kcal': kcal,
        if (rpe != null) 'rpe': rpe,
      };

  factory HealthImport.fromJson(Map<String, Object?> j) => HealthImport(
        source: j['source']! as String,
        healthUuid: j['healthUuid']! as String,
        meters: (j['meters'] as num?)?.toDouble(),
        avgHr: (j['avgHr'] as num?)?.toInt(),
        kcal: (j['kcal'] as num?)?.toDouble(),
        rpe: _rpeOf(j['rpe']),
      );

  static int? _rpeOf(Object? v) {
    final n = (v as num?)?.toInt();
    return n != null && n >= 1 && n <= 10 ? n : null;
  }
}

/// Import details by workout id, kept on the device (prefs
/// `health_imports_v1`).
class HealthImportStore {
  HealthImportStore(this._prefs);

  static const key = 'health_imports_v1';

  final SharedPreferences _prefs;

  Map<String, HealthImport> all() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      final out = <String, HealthImport>{};
      for (final e in (jsonDecode(raw) as Map).entries) {
        try {
          out[e.key as String] =
              HealthImport.fromJson((e.value as Map).cast<String, Object?>());
        } catch (_) {}
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  void _write(Map<String, HealthImport> m) => _prefs.setString(
      key, jsonEncode({for (final e in m.entries) e.key: e.value.toJson()}));

  void put(String id, HealthImport d) => _write({...all(), id: d});

  /// Returns whether [id] was there.
  bool remove(String id) {
    final m = all();
    if (m.remove(id) == null) return false;
    _write(m);
    return true;
  }

  void applySynced(Map<String, HealthImport?> updates) {
    final m = all();
    for (final e in updates.entries) {
      final d = e.value;
      d == null ? m.remove(e.key) : m[e.key] = d;
    }
    _write(m);
  }

  void clear() => _prefs.remove(key);
}

final healthImportStoreProvider = Provider<HealthImportStore>(
    (ref) => HealthImportStore(ref.watch(sharedPreferencesProvider)));

class HealthImportsNotifier extends StateNotifier<Map<String, HealthImport>> {
  HealthImportsNotifier(this._ref)
      : super(_ref.read(healthImportStoreProvider).all());

  final Ref _ref;

  HealthImportStore get _store => _ref.read(healthImportStoreProvider);

  void put(String id, HealthImport d) {
    _store.put(id, d);
    state = _store.all();
    _ref.read(localChangesProvider).notify();
  }

  void setRpe(String id, int rpe) {
    final d = state[id];
    if (d == null || d.rpe == rpe) return;
    put(id, d.withRpe(rpe));
  }

  /// The user deleted the workout: the doc goes too (reported for sync).
  void remove(String id) {
    if (!_store.remove(id)) return;
    state = _store.all();
    recordDocDeleted(_ref, 'health_import', id);
  }

  /// Pulled docs; not reported as local changes.
  void applySynced(Map<String, HealthImport?> updates) {
    _store.applySynced(updates);
    state = _store.all();
  }

  void clear() {
    _store.clear();
    state = {};
  }
}

/// Workout id → import details; a workout in here came from Health.
final healthImportsProvider =
    StateNotifierProvider<HealthImportsNotifier, Map<String, HealthImport>>(
        (ref) => HealthImportsNotifier(ref));
