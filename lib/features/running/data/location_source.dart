import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

enum LocationAccess { granted, denied, deniedForever, serviceOff }

/// GPS fixes for a run.
abstract class LocationSource {
  /// Asks for "when in use" location if it was never asked; never "always".
  Future<LocationAccess> ensureAccess();

  /// Starts the fixes. Call while the app is in the foreground; they keep
  /// coming with the screen locked until [stop].
  Stream<RunPoint> start();

  Future<void> stop();

  /// Whether the user gave only approximate location (iOS "Precise
  /// Location" off): fixes then come about 1 km wide and none are kept.
  Future<bool> reducedAccuracy();
}

class GeolocatorLocationSource implements LocationSource {
  GeolocatorLocationSource({AppLocalizations Function()? l10n}) : _l10n = l10n;

  final AppLocalizations Function()? _l10n;
  StreamController<RunPoint>? _out;
  StreamSubscription<Position>? _sub;

  /// How the platform records a run with the screen locked. iOS: a fitness
  /// session that never pauses itself and keeps running in the background
  /// (needs `UIBackgroundModes` `location`; "when in use" is enough because
  /// it starts in the foreground). Android: a foreground service with a
  /// notification.
  static LocationSettings settingsForPlatform(
    TargetPlatform platform, {
    AppLocalizations? l10n,
  }) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          activityType: ActivityType.fitness,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      case TargetPlatform.android:
        final t = l10n ?? lookupAppLocalizations(const Locale('en'));
        return AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 1),
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: t.runNotificationTitle,
            notificationText: t.runNotificationText,
            notificationChannelName: t.runNotificationChannel,
            setOngoing: true,
          ),
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        );
    }
  }

  @override
  Future<LocationAccess> ensureAccess() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceOff;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return switch (permission) {
        LocationPermission.whileInUse ||
        LocationPermission.always =>
          LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.denied,
      };
    } catch (_) {
      return LocationAccess.denied;
    }
  }

  @override
  Stream<RunPoint> start() {
    _sub?.cancel();
    _out?.close();
    final out = _out = StreamController<RunPoint>();
    _sub = Geolocator.getPositionStream(
      locationSettings:
          settingsForPlatform(defaultTargetPlatform, l10n: _l10n?.call()),
    ).listen(
      (p) => out.add(RunPoint(
        lat: p.latitude,
        lng: p.longitude,
        // A negative (iOS) or zero (Android) accuracy means no altitude.
        alt: p.altitudeAccuracy > 0 ? p.altitude : null,
        accuracy: p.accuracy,
        at: p.timestamp,
      )),
      onError: out.addError,
    );
    return out.stream;
  }

  @override
  Future<bool> reducedAccuracy() async {
    try {
      return await Geolocator.getLocationAccuracy() ==
          LocationAccuracyStatus.reduced;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    final sub = _sub, out = _out;
    _sub = null;
    _out = null;
    await sub?.cancel();
    await out?.close();
  }
}

final locationSourceProvider = Provider<LocationSource>(
  (ref) => GeolocatorLocationSource(
    l10n: () =>
        lookupAppLocalizations(Locale(ref.read(selectedLanguageProvider))),
  ),
);
