import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/data/social_sign_in.dart';
import 'package:fitrix/features/auth/data/social_sign_in_config.dart';

void main() {
  group('SocialSignInConfig', () {
    SocialSignInConfig config(
      TargetPlatform platform, {
      String web = '',
      String ios = '',
      bool apple = false,
      bool isWeb = false,
    }) =>
        SocialSignInConfig(
          googleWebClientId: web,
          googleIosClientId: ios,
          appleSignIn: apple,
          platform: platform,
          isWeb: isWeb,
        );

    test('nothing is enabled without dart-defines', () {
      final c = SocialSignInConfig.fromEnvironment();
      expect(c.googleEnabled, isFalse);
      expect(c.appleEnabled, isFalse);
    });

    test('Google needs the web client id, and on iOS the iOS one too', () {
      const web = 'web.apps.googleusercontent.com';
      const ios = 'ios.apps.googleusercontent.com';
      expect(config(TargetPlatform.android).googleEnabled, isFalse);
      expect(config(TargetPlatform.android, web: web).googleEnabled, isTrue);
      expect(config(TargetPlatform.android, ios: ios).googleEnabled, isFalse);
      expect(config(TargetPlatform.iOS, web: web).googleEnabled, isFalse);
      expect(config(TargetPlatform.iOS, ios: ios).googleEnabled, isFalse);
      expect(
          config(TargetPlatform.iOS, web: web, ios: ios).googleEnabled, isTrue);
      // Not wired up on web / desktop.
      expect(
          config(TargetPlatform.android, web: web, isWeb: true).googleEnabled,
          isFalse);
      expect(config(TargetPlatform.macOS, web: web, ios: ios).googleEnabled,
          isFalse);
    });

    test('Apple: shown on Apple platforms, enabled only with the flag', () {
      expect(config(TargetPlatform.iOS).showAppleButton, isTrue);
      expect(config(TargetPlatform.macOS).showAppleButton, isTrue);
      expect(config(TargetPlatform.android).showAppleButton, isFalse);
      expect(config(TargetPlatform.iOS, isWeb: true).showAppleButton, isFalse);

      expect(config(TargetPlatform.iOS).appleEnabled, isFalse);
      expect(config(TargetPlatform.iOS, apple: true).appleEnabled, isTrue);
      expect(config(TargetPlatform.macOS, apple: true).appleEnabled, isTrue);
      expect(config(TargetPlatform.android, apple: true).appleEnabled, isFalse);
    });
  });

  group('nonce', () {
    test('SHA-256 hex of the raw nonce goes to the provider', () {
      expect(hashNonce('abc'),
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
    });

    test('raw nonces are random', () {
      final a = generateRawNonce();
      expect(a, hasLength(32));
      expect(a, isNot(generateRawNonce()));
    });
  });

  group('NativeSocialSignIn', () {
    test('refuses providers the build has not enabled, without the SDKs',
        () async {
      final native = NativeSocialSignIn(
        const SocialSignInConfig(platform: TargetPlatform.iOS),
      );
      await expectLater(
        native.google(),
        throwsA(isA<AuthFailure>().having(
            (f) => f.kind, 'kind', AuthFailureKind.providerUnavailable)),
      );
      await expectLater(
        native.apple(),
        throwsA(isA<AuthFailure>().having(
            (f) => f.kind, 'kind', AuthFailureKind.providerUnavailable)),
      );
    });

    test('Google SDK errors', () {
      AuthFailureKind kind(GoogleSignInExceptionCode code, [String? text]) =>
          NativeSocialSignIn.googleFailure(
                  GoogleSignInException(code: code, description: text))
              .kind;
      expect(kind(GoogleSignInExceptionCode.clientConfigurationError),
          AuthFailureKind.providerUnavailable);
      expect(kind(GoogleSignInExceptionCode.providerConfigurationError),
          AuthFailureKind.providerUnavailable);
      expect(kind(GoogleSignInExceptionCode.interrupted),
          AuthFailureKind.socialFailed);
      expect(
          kind(GoogleSignInExceptionCode.unknownError,
              'A network error occurred'),
          AuthFailureKind.network);
      expect(NativeSocialSignIn.googleFailure(const GoogleSignInException(
              code: GoogleSignInExceptionCode.unknownError))
          .message, contains('Google'));
    });

    test('Apple and plugin errors', () {
      final failed = NativeSocialSignIn.appleFailure(
        const SignInWithAppleAuthorizationException(
          code: AuthorizationErrorCode.unknown,
          message: 'The operation couldn’t be completed. (1000)',
        ),
      );
      expect(failed.kind, AuthFailureKind.socialFailed);
      expect(failed.message, contains('Apple'));

      expect(
          NativeSocialSignIn.platformFailure(
                  const SignInWithAppleNotSupportedException(message: 'iOS 12'),
                  SocialProvider.apple)
              .kind,
          AuthFailureKind.providerUnavailable);
      expect(
          NativeSocialSignIn.platformFailure(
                  MissingPluginException(), SocialProvider.google)
              .kind,
          AuthFailureKind.providerUnavailable);
      expect(
          NativeSocialSignIn.platformFailure(
                  PlatformException(code: 'x'), SocialProvider.google)
              .kind,
          AuthFailureKind.socialFailed);
    });
  });

  group('AuthFailure.fromSocial', () {
    AuthFailure map(Object e) => AuthFailure.fromSocial(e, provider: 'Google');

    test('provider switched off on the server', () {
      final f = map(const AuthApiException(
        'Provider (issuer "https://accounts.google.com") is not enabled',
        statusCode: '400',
        code: 'provider_disabled',
      ));
      expect(f.kind, AuthFailureKind.providerDisabled);
      expect(f.message, "Sign in with Google isn't set up on the server yet. "
          'Please use your email for now.');
    });

    test('client id missing on the server (audience)', () {
      expect(
          map(const AuthApiException(
            'Unacceptable audience in id_token: [ios.apps.googleusercontent.com]',
            statusCode: '400',
          )).kind,
          AuthFailureKind.providerDisabled);
    });

    test('network and rate limits keep their messages', () {
      expect(map(AuthRetryableFetchException()).kind,
          AuthFailureKind.network);
      expect(
          map(const AuthApiException('slow down',
                  statusCode: '429', code: 'over_request_rate_limit'))
              .kind,
          AuthFailureKind.rateLimited);
    });

    test('a rejected token is a generic provider failure', () {
      // validation_failed means "invalid email" for codes; not here.
      final f = map(const AuthApiException('Nonces mismatch',
          statusCode: '400', code: 'validation_failed'));
      expect(f.kind, AuthFailureKind.socialFailed);
      expect(f.message, contains('Google'));
      expect(map(StateError('?')).kind, AuthFailureKind.socialFailed);
    });

    test('failures from the SDK wrapper pass through', () {
      final f = AuthFailure.providerUnavailable('Apple');
      expect(AuthFailure.fromSocial(f, provider: 'Apple'), same(f));
    });
  });
}
