import '../../workouts/data/models/workout.dart';

/// What is being recorded on the GPS track.
enum ActivityKind { run, ride, ski }

/// The per-activity knobs of the track math and the recorder.
class ActivityProfile {
  const ActivityProfile({
    required this.kind,
    required this.maxSpeed,
    required this.autoStop,
    required this.splitMeters,
    required this.sport,
    required this.voiceDefault,
    required this.freeTemplateId,
  });

  final ActivityKind kind;

  /// A fix implying a faster move than this (m/s) is dropped.
  final double maxSpeed;

  /// Moving time stops while the speed is under 1 m/s (stops of 10 s or more).
  final bool autoStop;

  /// Length of one split, metres.
  final int splitMeters;
  final Sport sport;
  final bool voiceDefault;
  final String freeTemplateId;
}

const runProfile = ActivityProfile(
  kind: ActivityKind.run,
  maxSpeed: 12,
  autoStop: false,
  splitMeters: 1000,
  sport: Sport.running,
  voiceDefault: true,
  freeTemplateId: 'free_run',
);

const rideProfile = ActivityProfile(
  kind: ActivityKind.ride,
  maxSpeed: 30,
  autoStop: true,
  splitMeters: 5000,
  sport: Sport.cycling,
  voiceDefault: false,
  freeTemplateId: 'free_ride',
);

const skiProfile = ActivityProfile(
  kind: ActivityKind.ski,
  maxSpeed: 40,
  autoStop: true,
  splitMeters: 1000,
  sport: Sport.winterSports,
  voiceDefault: false,
  freeTemplateId: 'free_ski',
);

ActivityProfile profileFor(ActivityKind k) => switch (k) {
      ActivityKind.run => runProfile,
      ActivityKind.ride => rideProfile,
      ActivityKind.ski => skiProfile,
    };
