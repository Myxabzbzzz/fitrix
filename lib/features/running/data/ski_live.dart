import 'package:latlong2/latlong.dart';

import 'run_track.dart';

const _distance = Distance(roundResult: false);

/// What the skier is doing right now. [descending] needs height being
/// lost; moving on the flat (or without altitude from the GPS) is [moving].
enum SkiMotion { descending, lift, moving, stopped }

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

  /// Day time without lifts, stops over 2 min and manual pauses; never
  /// goes back.
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
SkiMotion skiMotionOf(List<RunPoint> kept, DateTime now) =>
    kept.isEmpty ? SkiMotion.stopped : _motion(kept, kept.length - 1, now).$1;

/// Whether the live state at the kept fix [i] (from the fixes up to it) is
/// off the slopes: on a lift or standing (under 1 m/s, or the first fix
/// after a gap). Moving on the flat is not.
bool skiOffSlopesAt(List<RunPoint> kept, int i) {
  final (motion, standing) = _motion(kept, i, kept[i].at);
  return motion == SkiMotion.lift || standing;
}

/// The motion at [now] from the fixes up to [last], and whether it is
/// standing still.
(SkiMotion, bool) _motion(List<RunPoint> kept, int last, DateTime now) {
  if (last < 1) return (SkiMotion.stopped, true);
  final end = kept[last];
  if (now.difference(end.at) > skiMotionStale) return (SkiMotion.stopped, true);
  var i = last;
  var meters = 0.0;
  while (i > 0 && end.at.difference(kept[i - 1].at) <= skiMotionWindow) {
    meters += _distance(LatLng(kept[i - 1].lat, kept[i - 1].lng),
        LatLng(kept[i].lat, kept[i].lng));
    i--;
  }
  final first = kept[i];
  final secs = end.at.difference(first.at).inMilliseconds / 1000;
  if (i == last || secs <= 0) return (SkiMotion.stopped, true);
  final speed = meters / secs;
  if (speed < 1) return (SkiMotion.stopped, true);
  final a = first.alt, b = end.alt;
  // Without altitude nothing says the skier is going down.
  if (a == null || b == null) return (SkiMotion.moving, false);
  final rate = (b - a) / secs;
  if (rate <= _descendRate) return (SkiMotion.descending, false);
  if (rate >= _liftRate && speed <= 12) return (SkiMotion.lift, false);
  return (SkiMotion.moving, false);
}
