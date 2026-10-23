import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitrix/features/health/data/plugin_health_source.dart';

enum HealthPlatform { appleHealth, healthConnect }

enum HealthAvailability { available, notInstalled, needsUpdate, unsupported }

/// Which HRV statistic the platform gives. The two are never mixed.
enum HrvKind { sdnn, rmssd }

class HealthSample {
  const HealthSample({
    required this.uuid,
    required this.from,
    required this.to,
    required this.value,
    required this.sourceId,
    required this.sourceName,
  });

  final String uuid;
  final DateTime from, to;
  final double value;
  final String sourceId, sourceName;
}

/// One sleep stage. [asleep] is false for awake / in bed.
class SleepSegment {
  const SleepSegment({
    required this.from,
    required this.to,
    required this.asleep,
    required this.sourceName,
  });

  final DateTime from, to;
  final bool asleep;
  final String sourceName;
}

class HealthWorkoutRecord {
  const HealthWorkoutRecord({
    required this.uuid,
    required this.activity,
    required this.from,
    required this.to,
    this.meters,
    this.kcal,
    required this.sourceId,
    required this.sourceName,
  });

  final String uuid;

  /// The `health` package's `HealthWorkoutActivityType` name.
  final String activity;
  final DateTime from, to;
  final double? meters;
  final double? kcal;
  final String sourceId, sourceName;
}

/// Apple Health / Health Connect. Every call swallows platform errors
/// (locked phone, missing Health Connect, denied type): no data, no crash.
abstract class HealthSource {
  HealthPlatform get platform;
  Future<HealthAvailability> availability();

  /// Android store page for Health Connect; no-op on iOS.
  Future<void> openInstall();

  /// One system sheet: all read + write types, plus history on Android.
  Future<bool> requestAccess();
  Future<List<SleepSegment>> sleep(DateTime from, DateTime to);
  Future<List<HealthSample>> restingHr(DateTime from, DateTime to);
  Future<List<HealthSample>> hrv(DateTime from, DateTime to);
  HrvKind get hrvKind;

  /// Null = unknown / denied.
  Future<int?> steps(DateTime from, DateTime to);
  Future<List<HealthSample>> heartRate(DateTime from, DateTime to);
  Future<List<HealthSample>> weightKg(DateTime from, DateTime to);
  Future<List<HealthWorkoutRecord>> workouts(DateTime from, DateTime to);
  Future<bool> writeWorkout({
    required String activity,
    required DateTime from,
    required DateTime to,
    double? meters,
    String? title,
  });
}

final healthSourceProvider =
    Provider<HealthSource>((ref) => PluginHealthSource());

/// Our own bundle / package id: records with this source are ours.
const fitrixHealthSourceId = 'com.elibayev.fitrix';
