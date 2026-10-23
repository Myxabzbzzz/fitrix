import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import 'package:fitrix/features/health/data/health_source.dart';

/// [HealthSource] over the `health` package.
class PluginHealthSource implements HealthSource {
  PluginHealthSource({Health? health, bool? isAndroid})
      : _health = health ?? Health(),
        _android = isAndroid ?? Platform.isAndroid;

  final Health _health;
  final bool _android;
  Future<void>? _configured;

  Future<void> _ready() => _configured ??= _health.configure();

  @override
  HealthPlatform get platform =>
      _android ? HealthPlatform.healthConnect : HealthPlatform.appleHealth;

  @override
  HrvKind get hrvKind => _android ? HrvKind.rmssd : HrvKind.sdnn;

  HealthDataType get _hrvType => _android
      ? HealthDataType.HEART_RATE_VARIABILITY_RMSSD
      : HealthDataType.HEART_RATE_VARIABILITY_SDNN;

  static const _asleepTypes = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  ];
  static const _awakeTypes = [
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.SLEEP_IN_BED,
  ];

  @override
  Future<HealthAvailability> availability() async {
    try {
      if (!_android) {
        return Platform.isIOS
            ? HealthAvailability.available
            : HealthAvailability.unsupported;
      }
      await _ready();
      final status = await _health.getHealthConnectSdkStatus();
      return switch (status) {
        HealthConnectSdkStatus.sdkAvailable => HealthAvailability.available,
        HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired =>
          HealthAvailability.needsUpdate,
        _ => HealthAvailability.notInstalled,
      };
    } catch (e) {
      debugPrint('PluginHealthSource.availability: $e');
      return HealthAvailability.unsupported;
    }
  }

  @override
  Future<void> openInstall() async {
    if (!_android) return;
    try {
      await _health.installHealthConnect();
    } catch (e) {
      debugPrint('PluginHealthSource.openInstall: $e');
    }
  }

  @override
  Future<bool> requestAccess() async {
    try {
      await _ready();
      final read = <HealthDataType>[
        ..._asleepTypes,
        ..._awakeTypes,
        HealthDataType.RESTING_HEART_RATE,
        _hrvType,
        HealthDataType.HEART_RATE,
        HealthDataType.WEIGHT,
        HealthDataType.STEPS,
        // Health Connect reads a session's calories with the workout; without
        // this grant every workout read fails.
        if (_android) HealthDataType.TOTAL_CALORIES_BURNED,
      ];
      final types = <HealthDataType>[];
      final access = <HealthDataAccess>[];
      for (final t in read) {
        if (!_health.isDataTypeAvailable(t)) continue;
        types.add(t);
        access.add(HealthDataAccess.READ);
      }
      // Workouts are read and written. Health Connect also needs distance
      // for the distance of a written workout; on iOS it rides on the workout.
      final readWrite = <HealthDataType>[
        HealthDataType.WORKOUT,
        if (_android) HealthDataType.DISTANCE_DELTA,
      ];
      for (final t in readWrite) {
        if (!_health.isDataTypeAvailable(t)) continue;
        types.add(t);
        access.add(HealthDataAccess.READ_WRITE);
      }
      final ok = await _health.requestAuthorization(types, permissions: access);
      if (_android) {
        try {
          await _health.requestHealthDataHistoryAuthorization();
        } catch (_) {}
      }
      return ok;
    } catch (e) {
      debugPrint('PluginHealthSource.requestAccess: $e');
      return false;
    }
  }

  Future<List<HealthDataPoint>> _read(
    List<HealthDataType> types,
    DateTime from,
    DateTime to,
  ) async {
    try {
      await _ready();
      final usable = types.where(_health.isDataTypeAvailable).toList();
      if (usable.isEmpty) return const [];
      return await _health.getHealthDataFromTypes(
          types: usable, startTime: from, endTime: to);
    } catch (e) {
      debugPrint('PluginHealthSource read $types: $e');
      return const [];
    }
  }

  /// Health Connect gives an empty source id and the package name as the
  /// source name; use it so FITRIX's own records can be recognised.
  @visibleForTesting
  static String normalisedSourceId(HealthDataPoint p) =>
      p.sourceId.isEmpty ? p.sourceName : p.sourceId;

  @visibleForTesting
  List<HealthSample> samplesFrom(List<HealthDataPoint> points) =>
      _samples(points);

  @visibleForTesting
  List<HealthWorkoutRecord> workoutsFrom(List<HealthDataPoint> points) =>
      _workouts(points);

  List<HealthSample> _samples(List<HealthDataPoint> points) => [
        for (final p in points)
          if (p.value is NumericHealthValue)
            HealthSample(
              uuid: p.uuid,
              from: p.dateFrom,
              to: p.dateTo,
              value: (p.value as NumericHealthValue).numericValue.toDouble(),
              sourceId: normalisedSourceId(p),
              sourceName: p.sourceName,
            ),
      ];

  @override
  Future<List<SleepSegment>> sleep(DateTime from, DateTime to) async {
    final points = await _read([..._asleepTypes, ..._awakeTypes], from, to);
    return [
      for (final p in points)
        if (_asleepTypes.contains(p.type) || _awakeTypes.contains(p.type))
          SleepSegment(
            from: p.dateFrom,
            to: p.dateTo,
            asleep: _asleepTypes.contains(p.type),
            inBed: p.type == HealthDataType.SLEEP_IN_BED,
            sourceName: p.sourceName,
          ),
    ];
  }

  @override
  Future<List<HealthSample>> restingHr(DateTime from, DateTime to) async =>
      _samples(await _read([HealthDataType.RESTING_HEART_RATE], from, to));

  @override
  Future<List<HealthSample>> hrv(DateTime from, DateTime to) async =>
      _samples(await _read([_hrvType], from, to));

  @override
  Future<int?> steps(DateTime from, DateTime to) async {
    try {
      await _ready();
      return await _health.getTotalStepsInInterval(from, to);
    } catch (e) {
      debugPrint('PluginHealthSource.steps: $e');
      return null;
    }
  }

  @override
  Future<List<HealthSample>> heartRate(DateTime from, DateTime to) async =>
      _samples(await _read([HealthDataType.HEART_RATE], from, to));

  @override
  Future<List<HealthSample>> weightKg(DateTime from, DateTime to) async =>
      _samples(await _read([HealthDataType.WEIGHT], from, to));

  double? _meters(WorkoutHealthValue w) {
    final d = w.totalDistance;
    if (d == null) return null;
    return switch (w.totalDistanceUnit) {
      HealthDataUnit.CENTIMETER => d / 100.0,
      HealthDataUnit.MILE => d * 1609.344,
      HealthDataUnit.FOOT => d * 0.3048,
      HealthDataUnit.YARD => d * 0.9144,
      HealthDataUnit.INCH => d * 0.0254,
      _ => d.toDouble(),
    };
  }

  double? _kcal(WorkoutHealthValue w) {
    final e = w.totalEnergyBurned;
    if (e == null) return null;
    return switch (w.totalEnergyBurnedUnit) {
      HealthDataUnit.JOULE => e / 4184.0,
      HealthDataUnit.LARGE_CALORIE => e.toDouble(),
      HealthDataUnit.SMALL_CALORIE => e / 1000.0,
      _ => e.toDouble(),
    };
  }

  @override
  Future<List<HealthWorkoutRecord>> workouts(DateTime from, DateTime to) async {
    return _workouts(await _read([HealthDataType.WORKOUT], from, to));
  }

  List<HealthWorkoutRecord> _workouts(List<HealthDataPoint> points) {
    return [
      for (final p in points)
        if (p.value is WorkoutHealthValue)
          HealthWorkoutRecord(
            uuid: p.uuid,
            activity: (p.value as WorkoutHealthValue).workoutActivityType.name,
            from: p.dateFrom,
            to: p.dateTo,
            meters: _meters(p.value as WorkoutHealthValue),
            kcal: _kcal(p.value as WorkoutHealthValue),
            sourceId: normalisedSourceId(p),
            sourceName: p.sourceName,
          ),
    ];
  }

  @override
  Future<bool> writeWorkout({
    required String activity,
    required DateTime from,
    required DateTime to,
    double? meters,
    String? title,
  }) async {
    try {
      await _ready();
      final type = HealthWorkoutActivityType.values.firstWhere(
        (t) => t.name == activity,
        orElse: () => HealthWorkoutActivityType.OTHER,
      );
      return await _health.writeWorkoutData(
        activityType: type,
        start: from,
        end: to,
        totalDistance: meters?.round(),
        title: title,
      );
    } catch (e) {
      debugPrint('PluginHealthSource.writeWorkout: $e');
      return false;
    }
  }
}
