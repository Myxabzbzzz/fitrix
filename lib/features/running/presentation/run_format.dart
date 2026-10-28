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
/// kilometre. Since the start or the last gap in fixes (a pause, or the
/// signal lost for [maxGap]) there may be less: then it is the pace over
/// what there is once that is [minMeters], or [minTime] covering at least
/// [minTimeMeters] (so the start of a run shows a pace within seconds);
/// null before.
int? currentPaceSecPerKm(
  RunTrack track, {
  double window = 200,
  Duration maxGap = const Duration(seconds: 20),
  double minMeters = 100,
  Duration minTime = const Duration(seconds: 20),
  double minTimeMeters = 30,
}) {
  final pts = track.kept;
  if (pts.length < 2) return null;
  var meters = 0.0;
  var i = pts.length - 1;
  while (i > 0 && meters < window) {
    final a = pts[i - 1], b = pts[i];
    if (b.at.difference(a.at) > maxGap) break;
    meters += _distance(LatLng(a.lat, a.lng), LatLng(b.lat, b.lng));
    i--;
  }
  final time = pts.last.at.difference(pts[i].at);
  final enough = meters >= window ||
      meters >= minMeters ||
      (time >= minTime && meters >= minTimeMeters);
  if (!enough) return null;
  return paceSecPerKm(meters, time);
}

/// Speed in km/h with one decimal from m/s, or [noValue].
String formatSpeed(double? metersPerSecond, String locale) {
  if (metersPerSecond == null || !metersPerSecond.isFinite) return noValue;
  return NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1)
      .format(metersPerSecond * 3.6);
}

/// Distance over time in m/s, or null without both.
double? averageSpeed(double meters, Duration time) {
  final secs = time.inMilliseconds / 1000;
  return meters > 0 && secs > 0 ? meters / secs : null;
}

/// Speed over the last [window] of the track in m/s; 0 when the last kept
/// fix is older than [stale] (standing: a stop keeps no fixes), null before
/// there are two fixes to compare.
double? currentSpeed(
  RunTrack track,
  DateTime now, {
  Duration window = const Duration(seconds: 8),
  Duration stale = const Duration(seconds: 10),
}) {
  final pts = track.kept;
  if (pts.length < 2) return null;
  if (now.difference(pts.last.at) > stale) return 0;
  var i = pts.length - 1;
  var meters = 0.0;
  while (i > 0 && pts.last.at.difference(pts[i].at) < window) {
    final a = pts[i - 1], b = pts[i];
    if (b.at.difference(a.at) > stale) break;
    meters += _distance(LatLng(a.lat, a.lng), LatLng(b.lat, b.lng));
    i--;
  }
  final secs = pts.last.at.difference(pts[i].at).inMilliseconds / 1000;
  return secs > 0 ? meters / secs : null;
}
