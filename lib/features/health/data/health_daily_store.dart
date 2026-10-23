import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/features/health/data/health_source.dart';

/// One day of values read from Apple Health / Health Connect. Null = unknown
/// (never 0 for "not read").
class HealthDay {
  const HealthDay({
    this.sleep,
    this.sleepSource,
    this.sleepInBed = false,
    this.restingHr,
    this.hrv,
    this.hrvKind,
    this.steps,
  });

  final Duration? sleep;
  final String? sleepSource;

  /// The sleep is in-bed time, not time asleep.
  final bool sleepInBed;
  final double? restingHr;
  final double? hrv;
  final HrvKind? hrvKind;
  final int? steps;

  /// This day with [o]'s non-null values on top. HRV and its kind travel
  /// together.
  HealthDay merge(HealthDay o) => HealthDay(
        sleep: o.sleep ?? sleep,
        sleepSource: o.sleep != null ? o.sleepSource : sleepSource,
        sleepInBed: o.sleep != null ? o.sleepInBed : sleepInBed,
        restingHr: o.restingHr ?? restingHr,
        hrv: o.hrv ?? hrv,
        hrvKind: o.hrv != null ? o.hrvKind : hrvKind,
        steps: o.steps ?? steps,
      );

  Map<String, dynamic> toJson() => {
        if (sleep != null) 'sleep': sleep!.inSeconds,
        if (sleepSource != null) 'sleepSource': sleepSource,
        if (sleepInBed) 'sleepInBed': true,
        if (restingHr != null) 'restingHr': restingHr,
        if (hrv != null) 'hrv': hrv,
        if (hrvKind != null) 'hrvKind': hrvKind!.name,
        if (steps != null) 'steps': steps,
      };

  factory HealthDay.fromJson(Map<String, dynamic> j) => HealthDay(
        sleep: j['sleep'] == null
            ? null
            : Duration(seconds: (j['sleep'] as num).toInt()),
        sleepSource: j['sleepSource'] as String?,
        sleepInBed: j['sleepInBed'] == true,
        restingHr: (j['restingHr'] as num?)?.toDouble(),
        hrv: (j['hrv'] as num?)?.toDouble(),
        hrvKind: HrvKind.values
            .where((k) => k.name == j['hrvKind'])
            .cast<HrvKind?>()
            .firstOrNull,
        steps: (j['steps'] as num?)?.toInt(),
      );
}

/// Daily health values in SharedPreferences ('health_days_v1', 60 days).
/// Local only; never synced.
class HealthDailyStore {
  static const key = 'health_days_v1';
  static const keepDays = 60;

  HealthDailyStore(this._prefs, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  Map<String, HealthDay> _all() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      return {
        for (final e in (jsonDecode(raw) as Map<String, dynamic>).entries)
          e.key: HealthDay.fromJson(e.value as Map<String, dynamic>),
      };
    } catch (_) {
      return {};
    }
  }

  HealthDay? day(String dayKey) => _all()[dayKey];

  /// The cached days among the [n] days ending [today] (inclusive).
  Map<String, HealthDay> lastDays(int n, DateTime today) {
    final all = _all();
    final out = <String, HealthDay>{};
    for (var i = 0; i < n; i++) {
      final k = dayKey(DateTime(today.year, today.month, today.day - i));
      final d = all[k];
      if (d != null) out[k] = d;
    }
    return out;
  }

  /// Stores [d] for [key], keeping the old non-null values where [d] has
  /// none, and drops days older than 60.
  Future<void> put(String key0, HealthDay d) => putAll({key0: d});

  Future<void> putAll(Map<String, HealthDay> days) async {
    final all = _all();
    for (final e in days.entries) {
      final old = all[e.key];
      all[e.key] = old == null ? e.value : old.merge(e.value);
    }
    final n = _now();
    final cutoff = dayKey(DateTime(n.year, n.month, n.day - keepDays));
    all.removeWhere((k, _) => k.compareTo(cutoff) < 0);
    await _prefs.setString(
      key,
      jsonEncode({for (final e in all.entries) e.key: e.value.toJson()}),
    );
  }

  Future<void> clearAll() => _prefs.remove(key);
}
