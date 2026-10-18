import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';

/// The week plan and the Felix suggestions the user chose to keep, in one
/// JSON blob. Bad entries are skipped one by one, never wiping the rest.
class WeekPlanStore {
  static const key = 'week_plan_v1';

  final SharedPreferences _prefs;
  WeekPlanStore(this._prefs);

  Map<String, dynamic> _read() {
    final raw = _prefs.getString(key);
    if (raw == null) return const {};
    try {
      final v = jsonDecode(raw);
      if (v is Map<String, dynamic>) return v;
    } catch (_) {}
    return const {};
  }

  List<PlannedSession> all() {
    final out = <PlannedSession>[];
    final list = _read()['sessions'];
    if (list is! List) return out;
    for (final e in list) {
      try {
        out.add(PlannedSession.fromJson(e as Map<String, dynamic>));
      } catch (_) {}
    }
    return out;
  }

  /// "sessionId@monday" keys of dismissed suggestions.
  Set<String> dismissed() {
    final list = _read()['dismissed'];
    if (list is! List) return {};
    return {
      for (final e in list)
        if (e is String) e,
    };
  }

  /// Whether the user ever saved a plan or dismissed a suggestion.
  bool get isSaved => _prefs.containsKey(key);

  /// Replaces everything with a pulled plan (not a user change).
  void applySynced(List<PlannedSession> sessions, Set<String> dismissed) {
    _write(sessions, dismissed);
  }

  void clearAll() => _prefs.remove(key);

  Future<void> save(List<PlannedSession> sessions) =>
      _write(sessions, dismissed());

  Future<void> saveDismissed(Set<String> keys) => _write(all(), keys);

  Future<void> _write(List<PlannedSession> s, Set<String> d) =>
      _prefs.setString(
        key,
        jsonEncode({
          'sessions': [for (final x in s) x.toJson()],
          'dismissed': d.toList(),
        }),
      );
}
