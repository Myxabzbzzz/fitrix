import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:fitrix/features/running/data/location_source.dart';

/// The `<string>`s of the `<array>` under [key] in a plist.
List<String> _plistArray(String plist, String key) {
  final m = RegExp('<key>$key</key>\\s*<array>(.*?)</array>', dotAll: true)
      .firstMatch(plist);
  if (m == null) return const [];
  return RegExp('<string>(.*?)</string>')
      .allMatches(m.group(1)!)
      .map((s) => s.group(1)!)
      .toList();
}

String? _plistString(String plist, String key) =>
    RegExp('<key>$key</key>\\s*<string>(.*?)</string>', dotAll: true)
        .firstMatch(plist)
        ?.group(1);

void main() {
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  test('iOS keeps location and audio running in the background', () {
    expect(_plistArray(plist, 'UIBackgroundModes'),
        containsAll(['location', 'audio']));
  });

  test('the location usage string says it records runs', () {
    expect(_plistString(plist, 'NSLocationWhenInUseUsageDescription'),
        'FITRIX uses your location to record runs and to show gyms and '
        'parks near you.');
  });

  test('only "when in use" location is asked for on iOS', () {
    expect(plist, isNot(contains('NSLocationAlwaysUsageDescription')));
    expect(plist,
        isNot(contains('NSLocationAlwaysAndWhenInUseUsageDescription')));
  });

  test('Android declares the foreground location service permissions', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final p in [
      'FOREGROUND_SERVICE',
      'FOREGROUND_SERVICE_LOCATION',
      'POST_NOTIFICATIONS',
      'ACCESS_FINE_LOCATION',
    ]) {
      expect(manifest, contains('android.permission.$p"'), reason: p);
    }
    expect(manifest, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
  });

  test('iOS settings keep recording with the screen locked', () {
    final s = GeolocatorLocationSource.settingsForPlatform(TargetPlatform.iOS);
    expect(s, isA<AppleSettings>());
    final a = s as AppleSettings;
    expect(a.allowBackgroundLocationUpdates, isTrue);
    expect(a.pauseLocationUpdatesAutomatically, isFalse);
    expect(a.showBackgroundLocationIndicator, isTrue);
    expect(a.activityType, ActivityType.fitness);
    expect(a.accuracy,
        anyOf(LocationAccuracy.best, LocationAccuracy.bestForNavigation));
    expect(a.distanceFilter, lessThanOrEqualTo(5));
  });

  test('Android settings run as a foreground service with a notification',
      () {
    final s =
        GeolocatorLocationSource.settingsForPlatform(TargetPlatform.android);
    expect(s, isA<AndroidSettings>());
    final n = (s as AndroidSettings).foregroundNotificationConfig;
    expect(n, isNotNull);
    expect(n!.notificationTitle, 'Recording your run');
    expect(n.setOngoing, isTrue);
  });
}
