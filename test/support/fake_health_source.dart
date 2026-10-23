import 'package:fitrix/features/health/data/health_source.dart';

class WrittenWorkout {
  const WrittenWorkout({
    required this.activity,
    required this.from,
    required this.to,
    this.meters,
    this.title,
  });

  final String activity;
  final DateTime from, to;
  final double? meters;
  final String? title;
}

/// In-memory [HealthSource]: set the lists, read back [written].
/// [throwOnRead] simulates the locked phone: every read throws.
class FakeHealthSource implements HealthSource {
  FakeHealthSource({
    this.platform = HealthPlatform.appleHealth,
    this.hrvKind = HrvKind.sdnn,
    this.availabilityValue = HealthAvailability.available,
    this.grantAccess = true,
    this.sleepSegments = const [],
    this.restingHrSamples = const [],
    this.hrvSamples = const [],
    this.stepsValue,
    this.heartRateSamples = const [],
    this.weightSamples = const [],
    this.workoutRecords = const [],
    this.throwOnRead = false,
    this.writeResult = true,
    this.throwOnWrite = false,
  });

  @override
  HealthPlatform platform;
  @override
  HrvKind hrvKind;
  HealthAvailability availabilityValue;
  bool grantAccess;
  List<SleepSegment> sleepSegments;
  List<HealthSample> restingHrSamples;
  List<HealthSample> hrvSamples;
  int? stepsValue;
  List<HealthSample> heartRateSamples;
  List<HealthSample> weightSamples;
  List<HealthWorkoutRecord> workoutRecords;
  bool throwOnRead;
  bool writeResult;
  bool throwOnWrite;

  int requestAccessCalls = 0;
  int openInstallCalls = 0;

  /// Every read method (sleep, restingHr, hrv, steps, heartRate, weightKg,
  /// workouts) counts here.
  int readCalls = 0;
  final List<WrittenWorkout> written = [];

  T _read<T>(T v) {
    readCalls++;
    if (throwOnRead) {
      throw StateError('Protected health data is inaccessible');
    }
    return v;
  }

  @override
  Future<HealthAvailability> availability() async => availabilityValue;

  @override
  Future<void> openInstall() async => openInstallCalls++;

  @override
  Future<bool> requestAccess() async {
    requestAccessCalls++;
    return grantAccess;
  }

  @override
  Future<List<SleepSegment>> sleep(DateTime from, DateTime to) async =>
      _read(sleepSegments);

  @override
  Future<List<HealthSample>> restingHr(DateTime from, DateTime to) async =>
      _read(restingHrSamples);

  @override
  Future<List<HealthSample>> hrv(DateTime from, DateTime to) async =>
      _read(hrvSamples);

  @override
  Future<int?> steps(DateTime from, DateTime to) async => _read(stepsValue);

  @override
  Future<List<HealthSample>> heartRate(DateTime from, DateTime to) async =>
      _read(heartRateSamples);

  @override
  Future<List<HealthSample>> weightKg(DateTime from, DateTime to) async =>
      _read(weightSamples);

  @override
  Future<List<HealthWorkoutRecord>> workouts(
          DateTime from, DateTime to) async =>
      _read(workoutRecords);

  @override
  Future<bool> writeWorkout({
    required String activity,
    required DateTime from,
    required DateTime to,
    double? meters,
    String? title,
  }) async {
    written.add(WrittenWorkout(
        activity: activity, from: from, to: to, meters: meters, title: title));
    if (throwOnWrite) throw StateError('write denied');
    return writeResult;
  }
}
