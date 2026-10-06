import 'package:fitrix/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConstants.resolveApiBaseUrl', () {
    test('Android uses the emulator host alias 10.0.2.2', () {
      expect(
        AppConstants.resolveApiBaseUrl(
          define: '',
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        'http://10.0.2.2:3000',
      );
    });

    test('iOS, macOS and other native platforms use localhost', () {
      for (final platform in [
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.linux,
        TargetPlatform.windows,
        TargetPlatform.fuchsia,
      ]) {
        expect(
          AppConstants.resolveApiBaseUrl(
            define: '',
            platform: platform,
            isWeb: false,
          ),
          'http://localhost:3000',
          reason: platform.name,
        );
      }
    });

    test('web uses localhost even in a browser on Android', () {
      expect(
        AppConstants.resolveApiBaseUrl(
          define: '',
          platform: TargetPlatform.android,
          isWeb: true,
        ),
        'http://localhost:3000',
      );
    });

    test('--dart-define API_BASE_URL wins on every platform', () {
      const lan = 'http://192.168.0.103:3000';
      for (final platform in TargetPlatform.values) {
        for (final isWeb in [false, true]) {
          expect(
            AppConstants.resolveApiBaseUrl(
              define: lan,
              platform: platform,
              isWeb: isWeb,
            ),
            lan,
          );
        }
      }
    });
  });
}
