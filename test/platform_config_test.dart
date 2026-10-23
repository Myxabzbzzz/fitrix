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

  test('iOS declares the Health usage strings', () {
    expect(_plistString(plist, 'NSHealthShareUsageDescription'),
        'FITRIX reads sleep, heart rate, HRV, steps, weight and workouts to '
        'fill your check-in, recovery and training load.');
    expect(_plistString(plist, 'NSHealthUpdateUsageDescription'),
        'FITRIX saves the workouts you record so they count in Apple Health '
        'and Fitness.');
  });

  test('iOS has the HealthKit entitlement wired into the project', () {
    final ent = File('ios/Runner/Runner.entitlements').readAsStringSync();
    expect(
        RegExp(r'<key>com\.apple\.developer\.healthkit</key>\s*<true/>')
            .hasMatch(ent),
        isTrue);
    expect(ent, contains('com.apple.developer.healthkit.access'));
    final pbx =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx, contains('IPHONEOS_DEPLOYMENT_TARGET = 15.0'));
    expect(pbx, isNot(contains('IPHONEOS_DEPLOYMENT_TARGET = 13.0')));
    expect('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'
            .allMatches(pbx)
            .length,
        3);
  });

  test('Android declares Health Connect permissions, rationale and query', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    for (final p in [
      'READ_STEPS',
      'READ_HEART_RATE',
      'READ_RESTING_HEART_RATE',
      'READ_HEART_RATE_VARIABILITY',
      'READ_SLEEP',
      'READ_WEIGHT',
      'READ_EXERCISE',
      'READ_DISTANCE',
      'READ_TOTAL_CALORIES_BURNED',
      'READ_HEALTH_DATA_HISTORY',
      'WRITE_EXERCISE',
      'WRITE_DISTANCE',
    ]) {
      expect(manifest, contains('android.permission.health.$p"'), reason: p);
    }
    expect(manifest,
        contains('androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE'));
    expect(manifest, contains('android.intent.action.VIEW_PERMISSION_USAGE'));
    expect(manifest, contains('android.intent.category.HEALTH_PERMISSIONS'));
    expect(manifest, contains('<activity-alias'));
    expect(manifest,
        contains('<package android:name="com.google.android.apps.healthdata" />'));
  });

  test('Android uses a fragment activity and minSdk 26', () {
    expect(
        File('android/app/src/main/kotlin/com/elibayev/fitrix/MainActivity.kt')
            .readAsStringSync(),
        contains('class MainActivity : FlutterFragmentActivity()'));
    expect(File('android/app/build.gradle.kts').readAsStringSync(),
        contains('minSdk = 26'));
  });
}
