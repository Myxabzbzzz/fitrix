import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';

typedef Swap = ({String from, String to});

/// Check-ins in SharedPreferences ('checkins_v1', 60 days, one per day) and
/// the exercise swaps applied to today's session ('checkin_swaps_v1',
/// scoped to the day they were applied).
class CheckInStore {
  static const key = 'checkins_v1';
  static const swapsKey = 'checkin_swaps_v1';
  static const keepDays = 60;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  CheckInStore(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  List<CheckIn> _all() {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          CheckIn.fromJson(j as Map<String, dynamic>),
      ];
    } catch (_) {
      return [];
    }
  }

  /// Today's check-in (calendar day of the clock), or null.
  CheckIn? today() {
    final t = dayOf(_now());
    CheckIn? found;
    for (final c in _all()) {
      if (dayOf(c.at) == t && (found == null || c.at.isAfter(found.at))) {
        found = c;
      }
    }
    return found;
  }

  /// Check-ins from the last [n] calendar days including today, oldest first.
  List<CheckIn> lastDays(int n) {
    final from = dayOf(_now()).subtract(Duration(days: n - 1));
    final list = [
      for (final c in _all())
        if (!dayOf(c.at).isBefore(from)) c,
    ]..sort((a, b) => a.at.compareTo(b.at));
    return list;
  }

  /// Saves [c]; it replaces any earlier check-in of the same day. Swaps of
  /// an older check-in are dropped when the day changes.
  Future<void> save(CheckIn c) async {
    final cutoff = dayOf(_now()).subtract(const Duration(days: keepDays));
    final kept = [
      for (final o in _all())
        if (dayOf(o.at) != dayOf(c.at) && !dayOf(o.at).isBefore(cutoff)) o,
      c,
    ]..sort((a, b) => a.at.compareTo(b.at));
    await _prefs.setString(key, jsonEncode([for (final o in kept) o.toJson()]));
  }

  /// Swaps applied to today's session; empty when none or from another day.
  List<Swap> swaps() {
    final raw = _prefs.getString(swapsKey);
    if (raw == null) return [];
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['day'] != dayKey(_now())) return [];
      return [
        for (final s in j['swaps'] as List)
          (from: s['from'] as String, to: s['to'] as String),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSwaps(List<Swap> swaps) async {
    if (swaps.isEmpty) {
      await _prefs.remove(swapsKey);
      return;
    }
    await _prefs.setString(
      swapsKey,
      jsonEncode({
        'day': dayKey(_now()),
        'swaps': [
          for (final s in swaps) {'from': s.from, 'to': s.to},
        ],
      }),
    );
  }
}
