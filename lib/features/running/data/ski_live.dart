import 'package:latlong2/latlong.dart';

import 'run_track.dart';

const _distance = Distance(roundResult: false);

/// What the skier is doing right now.
enum SkiMotion { descending, lift, stopped }

/// The numbers of a ski day in progress, for the live screen.
class SkiLive {
  const SkiLive({
    required this.descents,
    required this.verticalDown,
    required this.maxSpeed,
    required this.motion,
    required this.onSlopes,
  });

  /// Descents so far (the one under way counts once it is long enough).
  final int descents;

  /// Metres lost on them.
  final double verticalDown;

  /// Top speed on a descent, m/s; null before the first.
  final double? maxSpeed;
  final SkiMotion motion;

  /// Day time without lifts and manual pauses.
  final Duration onSlopes;
}

/// The latest fixes within this are looked at to tell what is going on.
const Duration skiMotionWindow = Duration(seconds: 40);

/// No kept fix for this long means standing still (the recorder drops the
/// jitter of a stop).
const Duration skiMotionStale = Duration(seconds: 15);

/// Altitude change per second that counts as going down / up.
const double _descendRate = -0.25, _liftRate = 0.3;

/// Cheap: only the last few fixes are read.
SkiMotion skiMotionOf(List<RunPoint> kept, DateTime now) {
  if (kept.length < 2) return SkiMotion.stopped;
  final last = kept.last;
  if (now.difference(last.at) > skiMotionStale) return SkiMotion.stopped;
  var i = kept.length - 1;
  var meters = 0.0;
  while (i > 0 && last.at.difference(kept[i - 1].at) <= skiMotionWindow) {
    meters += _distance(LatLng(kept[i - 1].lat, kept[i - 1].lng),
        LatLng(kept[i].lat, kept[i].lng));
    i--;
  }
  final first = kept[i];
  final secs = last.at.difference(first.at).inMilliseconds / 1000;
  if (i == kept.length - 1 || secs <= 0) return SkiMotion.stopped;
  final speed = meters / secs;
  if (speed < 1) return SkiMotion.stopped;
  final a = first.alt, b = last.alt;
  if (a == null || b == null) {
    return speed >= 3 ? SkiMotion.descending : SkiMotion.stopped;
  }
  final rate = (b - a) / secs;
  if (rate <= _descendRate) return SkiMotion.descending;
  if (rate >= _liftRate && speed <= 12) return SkiMotion.lift;
  return SkiMotion.stopped;
}
