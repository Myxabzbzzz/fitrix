import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WeighIn {
  final DateTime at;
  final double kg;
  const WeighIn({required this.at, required this.kg});

  Map<String, Object> toJson() => {'at': at.toIso8601String(), 'kg': kg};

  static WeighIn? fromJson(Object? json) {
    if (json is! Map) return null;
    final at = DateTime.tryParse('${json['at']}');
    final kg = json['kg'];
    if (at == null || kg is! num) return null;
    return WeighIn(at: at, kg: kg.toDouble());
  }
}

/// Weigh-ins kept on the device (SharedPreferences, [key]); the server
/// schema has no place for them. Pure storage: the provider that logs a
/// weight also updates the profile weight.
class BodyWeightStore {
  static const key = 'body_weight_v1';
  static const minKg = 20.0, maxKg = 400.0;

  final SharedPreferences _prefs;
  BodyWeightStore(this._prefs);

  /// Oldest first.
  List<WeighIn> all() {
    final raw = _prefs.getString(key);
    if (raw == null) return const [];
    try {
      final list = [
        for (final j in jsonDecode(raw) as List)
          if (WeighIn.fromJson(j) case final w?) w,
      ]..sort((a, b) => a.at.compareTo(b.at));
      return list;
    } catch (_) {
      return const [];
    }
  }

  /// Adds [w]; a weigh-in on the same calendar day is replaced.
  Future<void> add(WeighIn w) {
    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;
    final next = [
      for (final e in all())
        if (!sameDay(e.at, w.at)) e,
      w,
    ]..sort((a, b) => a.at.compareTo(b.at));
    return _prefs.setString(
        key, jsonEncode([for (final e in next) e.toJson()]));
  }
}
