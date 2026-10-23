import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

import 'package:fitrix/features/health/data/health_source.dart';
import 'package:fitrix/features/health/data/plugin_health_source.dart';

HealthDataPoint _point(HealthValue value, HealthDataType type) =>
    HealthDataPoint(
      uuid: 'u1',
      value: value,
      type: type,
      unit: HealthDataUnit.NO_UNIT,
      dateFrom: DateTime(2026, 10, 1, 8),
      dateTo: DateTime(2026, 10, 1, 9),
      sourcePlatform: HealthPlatformType.googleHealthConnect,
      sourceDeviceId: 'd',
      sourceId: '',
      sourceName: fitrixHealthSourceId,
    );

void main() {
  test('Android points with empty sourceId take the package name', () {
    final src = PluginHealthSource(isAndroid: true);
    final w = src.workoutsFrom([
      _point(
          WorkoutHealthValue(
              workoutActivityType: HealthWorkoutActivityType.RUNNING,
              totalDistance: 5000,
              totalDistanceUnit: HealthDataUnit.METER),
          HealthDataType.WORKOUT),
    ]);
    expect(w.single.sourceId, fitrixHealthSourceId);
    expect(w.single.meters, 5000);
    final s = src.samplesFrom([
      _point(NumericHealthValue(numericValue: 60),
          HealthDataType.RESTING_HEART_RATE),
    ]);
    expect(s.single.sourceId, fitrixHealthSourceId);
  });
}
