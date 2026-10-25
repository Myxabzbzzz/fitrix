import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/health/data/health_import_store.dart';
import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/presentation/providers/health_providers.dart';
import 'package:fitrix/features/running/data/run_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// The `health` package's `HealthWorkoutActivityType` name FITRIX writes for
/// [s]. Checked against the package's write support per platform:
/// - iOS has TRADITIONAL_STRENGTH_TRAINING; Android only STRENGTH_TRAINING
///   (the Dart check rejects the traditional one there).
/// - SOCCER passes the Dart check on Android but has no Health Connect
///   mapping in the plugin (the write fails), so football is OTHER there.
String activityForSport(Sport s,
    {HealthPlatform platform = HealthPlatform.appleHealth}) {
  final ios = platform == HealthPlatform.appleHealth;
  switch (s) {
    case Sport.gym:
      return ios ? 'TRADITIONAL_STRENGTH_TRAINING' : 'STRENGTH_TRAINING';
    case Sport.fitness:
      return 'OTHER';
    case Sport.cycling:
      return 'BIKING';
    case Sport.running:
      return 'RUNNING';
    case Sport.football:
      return ios ? 'SOCCER' : 'OTHER';
    case Sport.winterSports:
      return 'DOWNHILL_SKIING';
  }
}

/// Writes workouts created in FITRIX to Apple Health / Health Connect, each
/// id at most once (persisted, so edits, re-adds and restarts never write
/// twice). A failed write is not retried.
class HealthWriter {
  HealthWriter(this._ref);

  final Ref _ref;
  final Set<String> _inFlight = {};

  static const key = 'health_written_v1';
  static const maxIds = 200;

  /// When each id was written (`{id: ISO time}`), kept beside the id list;
  /// ids from before this existed have no time and are not counted.
  static const timesKey = 'health_written_at_v1';

  /// Ids written at or after [since], per the time ledger.
  static int writtenSince(SharedPreferences prefs, DateTime since) {
    try {
      final raw = prefs.getString(timesKey);
      if (raw == null) return 0;
      var n = 0;
      for (final v in (jsonDecode(raw) as Map).values) {
        final t = DateTime.tryParse('$v');
        if (t != null && !t.isBefore(since)) n++;
      }
      return n;
    } catch (_) {
      return 0;
    }
  }

  List<String> _load() {
    try {
      final raw = _ref.read(sharedPreferencesProvider).getString(key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _remember(String id) async {
    final ids = _load()..add(id);
    final kept = ids.length > maxIds ? ids.sublist(ids.length - maxIds) : ids;
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(key, jsonEncode(kept));
    Map<String, dynamic> times = {};
    try {
      final raw = prefs.getString(timesKey);
      if (raw != null) times = (jsonDecode(raw) as Map).cast<String, dynamic>();
    } catch (_) {}
    times[id] = _ref.read(clockProvider)().toIso8601String();
    final keep = kept.toSet();
    times.removeWhere((k, _) => !keep.contains(k));
    await prefs.setString(timesKey, jsonEncode(times));
    _ref.read(healthLedgerVersionProvider.notifier).state++;
  }

  /// A workout was created locally. Never throws.
  Future<void> onAdded(CompletedWorkout w) async {
    try {
      if (w.templateId == healthImportTemplateId) return;
      final conn = _ref.read(healthConnectionProvider);
      if (!conn.connected || !conn.writeWorkouts) return;
      if (!w.finishedAt.isAfter(w.startedAt)) return;
      if (_inFlight.contains(w.id) || _load().contains(w.id)) return;
      _inFlight.add(w.id);
      try {
        // A run's, ride's or ski day's details (distance) are saved right after the workout.
        await Future<void>.delayed(Duration.zero);
        final c = _ref.read(healthConnectionProvider);
        if (!c.connected || !c.writeWorkouts) return;
        double? meters;
        if (w.sport == Sport.running ||
            w.sport == Sport.cycling ||
            w.sport == Sport.winterSports) {
          final m = _ref.read(runsProvider)[w.id]?.meters;
          if (m != null && m > 0) meters = m;
        }
        final source = _ref.read(healthSourceProvider);
        final ok = await source.writeWorkout(
          activity: activityForSport(w.sport, platform: source.platform),
          from: w.startedAt,
          to: w.finishedAt,
          meters: meters,
          title: w.name,
        );
        // Signed out / disconnected while writing: leave the ledger alone.
        if (ok && _ref.read(healthSyncProvider).mayWrite()) {
          await _remember(w.id);
        }
      } finally {
        _inFlight.remove(w.id);
      }
    } catch (e) {
      debugPrint('HealthWriter: $e');
    }
  }
}

final healthWriterProvider = Provider<HealthWriter>((ref) => HealthWriter(ref));
