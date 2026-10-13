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
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }
}

final locationSourceProvider =
    Provider<LocationSource>((ref) => const GeolocatorLocationSource());

/// The user's position, or null when it is unknown (see [LocationSource]).
final myLocationProvider = FutureProvider<LatLng?>(
    (ref) => ref.watch(locationSourceProvider).current());
