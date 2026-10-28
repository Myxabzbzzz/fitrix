import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Amir Timur Square: where the map centres when location is unavailable.
const LatLng amirTimurSquare = LatLng(41.31111, 69.27972);

/// Where the user is right now, or null when permission is denied, the
/// service is off or no fix arrives in time. Never throws.
abstract class LocationSource {
  Future<LatLng?> current();
}

class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Future<LatLng?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await quickFix(
        lastKnown: () async {
          final p = await Geolocator.getLastKnownPosition();
          return p == null
              ? null
              : (at: LatLng(p.latitude, p.longitude), time: p.timestamp);
        },
        fresh: (limit) async {
          final p = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: limit,
            ),
          );
          return LatLng(p.latitude, p.longitude);
        },
      );
    } catch (_) {
      return null;
    }
  }
}

/// A position fix and when it was taken.
typedef Fix = ({LatLng at, DateTime time});

/// Where the user is, without keeping the map waiting on the GPS: a last
/// known fix younger than [maxAge] at once, otherwise a fresh one within
/// [timeLimit], otherwise any last known one (null without).
Future<LatLng?> quickFix({
  required Future<Fix?> Function() lastKnown,
  required Future<LatLng> Function(Duration timeLimit) fresh,
  DateTime Function() now = DateTime.now,
  Duration maxAge = const Duration(minutes: 10),
  Duration timeLimit = const Duration(seconds: 5),
}) async {
  Fix? last;
  try {
    last = await lastKnown();
  } catch (_) {}
  if (last != null && now().difference(last.time) <= maxAge) return last.at;
  try {
    return await fresh(timeLimit);
  } catch (_) {
    return last?.at;
  }
}

final locationSourceProvider =
    Provider<LocationSource>((ref) => const GeolocatorLocationSource());

/// The user's position, or null when it is unknown (see [LocationSource]).
final myLocationProvider = FutureProvider.autoDispose<LatLng?>(
    (ref) => ref.watch(locationSourceProvider).current());
