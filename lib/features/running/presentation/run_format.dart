import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:fitrix/features/running/data/run_track.dart';

const _distance = Distance(roundResult: false);

/// Shown where a value is not known yet.
const noValue = '--';

/// "1:05:09" from an hour on, otherwise "5:09".
String formatClock(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// "5:42" for seconds per kilometre, or [noValue].
String formatPace(int? secPerKm) {
  if (secPerKm == null || secPerKm <= 0) return noValue;
  // Anything slower than a walk is not a pace worth showing.
  if (secPerKm >= 60 * 60) return noValue;
  return formatClock(Duration(seconds: secPerKm));
}

/// Kilometres with two decimals in the language's number format.
String formatKm(double meters, String locale) =>
    NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2)
        .format(meters / 1000);

/// Metres without decimals.
String formatMeters(double meters, String locale) =>
    NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 0)
        .format(meters);

/// Pace over the last [window] metres of the track, in seconds per
/// kilometre, or null while there is less than that since the start or the
/// last gap in fixes (a pause, or the signal lost for [maxGap]).
int? currentPaceSecPerKm(
  RunTrack track, {
  double window = 200,
  Duration maxGap = const Duration(seconds: 20),
}) {
  final pts = track.kept;
  if (pts.length < 2) return null;
  var meters = 0.0;
  var i = pts.length - 1;
  while (i > 0 && meters < window) {
    final a = pts[i - 1], b = pts[i];
    if (b.at.difference(a.at) > maxGap) return null;
    meters += _distance(LatLng(a.lat, a.lng), LatLng(b.lat, b.lng));
    i--;
  }
  if (meters < window) return null;
  return paceSecPerKm(meters, pts.last.at.difference(pts[i].at));
}
