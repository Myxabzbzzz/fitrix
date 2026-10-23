import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/day_key.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/health/data/health_daily_store.dart';
import 'package:fitrix/features/health/data/health_importers.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/domain/health_math.dart';

/// Reads that an importer (workouts, weight, ...) does with the same window
/// as the daily values.
abstract class HealthImporter {
  /// [mayWrite] turns false once nothing may be written anymore (signed
  /// out, another account, disconnected): check it before every write.
  Future<void> run(
      HealthSource s, DateTime from, DateTime to, bool Function() mayWrite);
}

final healthImportersProvider = Provider<List<HealthImporter>>(
    (ref) => [WorkoutImporter(ref), WeightImporter(ref)]);

final healthDailyStoreProvider = Provider<HealthDailyStore>((ref) =>
    HealthDailyStore(ref.watch(sharedPreferencesProvider),
        now: ref.watch(clockProvider)));

class HealthConnection {
  const HealthConnection({
    this.connected = false,
    this.writeWorkouts = false,
    this.lastReadAt,
  });

  final bool connected;
  final bool writeWorkouts;
  final DateTime? lastReadAt;

  HealthConnection copyWith({
    bool? connected,
    bool? writeWorkouts,
    DateTime? lastReadAt,
    bool clearLastReadAt = false,
  }) =>
      HealthConnection(
        connected: connected ?? this.connected,
        writeWorkouts: writeWorkouts ?? this.writeWorkouts,
        lastReadAt: clearLastReadAt ? null : lastReadAt ?? this.lastReadAt,
      );

  Map<String, dynamic> toJson() => {
        'connected': connected,
        'writeWorkouts': writeWorkouts,
        if (lastReadAt != null) 'lastReadAt': lastReadAt!.toIso8601String(),
      };

  factory HealthConnection.fromJson(Map<String, dynamic> j) => HealthConnection(
        connected: j['connected'] == true,
        writeWorkouts: j['writeWorkouts'] == true,
        lastReadAt: j['lastReadAt'] == null
            ? null
            : DateTime.tryParse(j['lastReadAt'] as String),
      );
}

class HealthConnectionNotifier extends Notifier<HealthConnection> {
  static const key = 'health_connection_v1';

  @override
  HealthConnection build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(key);
    if (raw == null) return const HealthConnection();
    try {
      return HealthConnection.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const HealthConnection();
    }
  }

  Future<void> _set(HealthConnection c) async {
    state = c;
    await ref
        .read(sharedPreferencesProvider)
        .setString(key, jsonEncode(c.toJson()));
  }

  /// Asks for access (the one system sheet) and, if granted, marks the app
  /// connected (workout writing on) and starts the first 30-day read in the
  /// background: it returns as soon as access is granted, the last read time
  /// appears when the read lands. Returns whether it is connected.
  Future<bool> connect() async {
    var granted = false;
    try {
      granted = await ref.read(healthSourceProvider).requestAccess();
    } catch (_) {}
    if (!granted) return false;
    await _set(state.copyWith(
        connected: true, writeWorkouts: true, clearLastReadAt: true));
    unawaited(ref
        .read(healthSyncProvider)
        .refresh(force: true)
        .catchError((Object _) {}));
    return true;
  }

  Future<void> disconnect() =>
      _set(state.copyWith(connected: false, clearLastReadAt: true));

  Future<void> setWriteWorkouts(bool v) =>
      _set(state.copyWith(writeWorkouts: v));

  Future<void> markRead(DateTime at) => _set(state.copyWith(lastReadAt: at));
}

/// Whether the platform's health store can be connected (Health Connect may
/// be missing or outdated). Only asked on Android; Apple Health is always
/// available.
final healthAvailabilityProvider =
    FutureProvider.autoDispose<HealthAvailability>((ref) async {
  try {
    return await ref.read(healthSourceProvider).availability();
  } catch (_) {
    return HealthAvailability.unsupported;
  }
});

final healthConnectionProvider =
    NotifierProvider<HealthConnectionNotifier, HealthConnection>(
        HealthConnectionNotifier.new);

/// Bumped when the daily cache changes so [healthTodayProvider] recomputes.
final _healthCacheVersionProvider = StateProvider<int>((_) => 0);

class HealthSync {
  HealthSync(this._ref);

  final Ref _ref;
  Future<void>? _inFlight;

  /// False once the provider is disposed (sign-out, account switch): a read
  /// still running then must not write into the next account's data.
  bool _alive = true;

  void dispose() => _alive = false;

  /// Whether a running read may still write: not disposed and connected,
  /// in memory and in storage (cleared local data reads as disconnected).
  bool _mayWrite() {
    if (!_alive) return false;
    try {
      if (!_ref.read(healthConnectionProvider).connected) return false;
      final raw = _ref
          .read(sharedPreferencesProvider)
          .getString(HealthConnectionNotifier.key);
      if (raw == null) return false;
      return HealthConnection.fromJson(jsonDecode(raw) as Map<String, dynamic>)
          .connected;
    } catch (_) {
      return false;
    }
  }

  static const throttle = Duration(minutes: 15);
  static const firstReadDays = 30;

  /// Reads the day values (and runs the importers). No-op when not
  /// connected, or when read less than 15 minutes ago unless [force]. A
  /// call while a read runs returns that read. Never throws.
  Future<void> refresh({bool force = false}) {
    if (!_alive) return Future.value();
    final running = _inFlight;
    if (running != null) return running;
    final conn = _ref.read(healthConnectionProvider);
    if (!conn.connected) return Future.value();
    final now = _ref.read(clockProvider)();
    final last = conn.lastReadAt;
    if (!force && last != null && now.difference(last) < throttle) {
      return Future.value();
    }
    final f = _run(conn, now).whenComplete(() => _inFlight = null);
    _inFlight = f;
    return f;
  }

  Future<void> _run(HealthConnection conn, DateTime now) async {
    final today = dayOf(now);
    final last = conn.lastReadAt;
    final firstDay = last == null
        ? DateTime(today.year, today.month, today.day - firstReadDays)
        : _earlier(
            dayOf(last), DateTime(today.year, today.month, today.day - 2));
    try {
      final source = _ref.read(healthSourceProvider);
      final days = await _readDays(source, firstDay, now);
      // Disconnected or signed out while reading: drop the results.
      if (!_mayWrite()) return;
      await _ref.read(healthDailyStoreProvider).putAll(days);
      if (!_mayWrite()) return;
      await _ref.read(healthConnectionProvider.notifier).markRead(now);
      if (!_mayWrite()) return;
      _ref.read(_healthCacheVersionProvider.notifier).state++;
    } catch (_) {
      // Locked phone etc.: keep the cache, try again next time.
    }
    try {
      for (final i in _ref.read(healthImportersProvider)) {
        if (!_mayWrite()) return;
        try {
          await i.run(
              _ref.read(healthSourceProvider), firstDay, now, _mayWrite);
        } catch (_) {}
      }
    } catch (_) {
      // Disposed meanwhile: nothing more to do.
    }
  }

  static DateTime _earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;

  Future<Map<String, HealthDay>> _readDays(
      HealthSource s, DateTime firstDay, DateTime now) async {
    final readFrom =
        DateTime(firstDay.year, firstDay.month, firstDay.day - 1, 18);
    final sleep = await s.sleep(readFrom, now);
    final rhr = await s.restingHr(readFrom, now);
    final hrv = await s.hrv(readFrom, now);
    final today = dayOf(now);
    final out = <String, HealthDay>{};
    for (var d = firstDay;
        !d.isAfter(today);
        d = DateTime(d.year, d.month, d.day + 1)) {
      final next = DateTime(d.year, d.month, d.day + 1);
      final end = d == today ? now : next;
      final night = lastNightSleep(sleep, d);
      final nightFrom = DateTime(d.year, d.month, d.day - 1, 18);
      final nightTo = DateTime(d.year, d.month, d.day, 12);
      final source = night == null
          ? null
          : nightSegments(sleep, d).segments.first.sourceName;

      var rhrDay = _latest(rhr, d, end);
      if (rhrDay == null && d == today) {
        rhrDay = _latest(rhr, now.subtract(const Duration(hours: 24)), now);
      }
      final hrvDay = _latest(hrv, nightFrom, nightTo);
      final steps = await s.steps(d, end);
      out[dayKey(d)] = HealthDay(
        sleep: night?.sleep,
        sleepSource: source,
        sleepInBed: night?.inBed ?? false,
        restingHr: rhrDay?.value,
        hrv: hrvDay?.value,
        hrvKind: hrvDay == null ? null : s.hrvKind,
        steps: steps,
      );
    }
    return out;
  }

  /// The sample ending last in (from, to].
  static HealthSample? _latest(
      List<HealthSample> l, DateTime from, DateTime to) {
    HealthSample? best;
    for (final x in l) {
      if (!x.to.isAfter(from) || x.to.isAfter(to)) continue;
      if (best == null || x.to.isAfter(best.to)) best = x;
    }
    return best;
  }
}

final healthSyncProvider = Provider<HealthSync>((ref) {
  final sync = HealthSync(ref);
  ref.onDispose(sync.dispose);
  return sync;
});

/// Today's cached values and their baselines. Only today's entry counts: no
/// entry for today means all values are null.
final healthTodayProvider = Provider<HealthSignals>((ref) {
  final today = ref.watch(todayProvider);
  ref.watch(_healthCacheVersionProvider);
  if (!ref.watch(healthConnectionProvider).connected) {
    return const HealthSignals();
  }
  final days = ref.watch(healthDailyStoreProvider).lastDays(29, today);
  final t = days[dayKey(today)];

  final hrvKind = t?.hrv == null ? null : t!.hrvKind;
  final rhrBase = baseline({
    for (final e in days.entries)
      if (e.value.restingHr != null) e.key: e.value.restingHr!,
  }, today);
  final hrvBase = hrvKind == null
      ? null
      : baseline({
          for (final e in days.entries)
            if (e.value.hrv != null && e.value.hrvKind == hrvKind)
              e.key: e.value.hrv!,
        }, today);

  final steps = <int>[];
  for (var i = 1; i <= 7; i++) {
    final s =
        days[dayKey(DateTime(today.year, today.month, today.day - i))]?.steps;
    if (s != null) steps.add(s);
  }
  return HealthSignals(
    restingHr: t?.restingHr,
    restingHrBaseline: rhrBase,
    hrv: t?.hrv,
    hrvBaseline: hrvBase,
    hrvKind: hrvKind,
    stepsToday: t?.steps,
    steps7dAvg: steps.isEmpty
        ? null
        : (steps.reduce((a, b) => a + b) / steps.length).round(),
  );
});

/// Today's cached entry (sleep with its source, ...), null when not
/// connected or nothing is cached for today.
final healthTodayDayProvider = Provider<HealthDay?>((ref) {
  final today = ref.watch(todayProvider);
  ref.watch(_healthCacheVersionProvider);
  if (!ref.watch(healthConnectionProvider).connected) return null;
  return ref.watch(healthDailyStoreProvider).day(dayKey(today));
});
