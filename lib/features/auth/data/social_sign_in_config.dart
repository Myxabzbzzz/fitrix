import 'package:flutter/foundation.dart';

/// Which of "Continue with Google" / "Continue with Apple" work in this
/// build. Both are off unless the build passes the right `--dart-define`s;
/// switched-off buttons say "coming soon", as before.
///
///   flutter run \
///     --dart-define=GOOGLE_WEB_CLIENT_ID=<web client id> \
///     --dart-define=GOOGLE_IOS_CLIENT_ID=<iOS client id> \
///     --dart-define=APPLE_SIGN_IN=true
///
/// Google on iOS also needs the reversed iOS client id as a URL scheme
/// (`ios/Flutter/GoogleSignIn.xcconfig`); Apple needs a paid Apple
/// developer account. See README.md, "Google and Apple sign-in".
class SocialSignInConfig {
  const SocialSignInConfig({
    this.googleWebClientId = '',
    this.googleIosClientId = '',
    this.appleSignIn = false,
    required this.platform,
    this.isWeb = false,
  });

  /// From the build's `--dart-define`s, for the platform the app runs on.
  factory SocialSignInConfig.fromEnvironment() => SocialSignInConfig(
        googleWebClientId:
            const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID').trim(),
        googleIosClientId:
            const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID').trim(),
        appleSignIn: const bool.fromEnvironment('APPLE_SIGN_IN'),
        platform: defaultTargetPlatform,
        isWeb: kIsWeb,
      );

  /// The OAuth "Web application" client id. Google issues the ID token for
  /// it (its audience), and Supabase must list it under the Google
  /// provider's client ids. Required on Android and iOS.
  final String googleWebClientId;

  /// The OAuth "iOS" client id (bundle id com.elibayev.fitrix). iOS only.
  final String googleIosClientId;

  /// `--dart-define=APPLE_SIGN_IN=true`: the build is signed with the
  /// "Sign in with Apple" capability (paid developer account only).
  final bool appleSignIn;

  final TargetPlatform platform;
  final bool isWeb;

  bool get _isApplePlatform =>
      !isWeb &&
      (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS);

  /// Native Google sign-in is set up for this platform. Only Android and
  /// iOS are wired up (web needs Google's own button, macOS a keychain
  /// entitlement).
  bool get googleEnabled {
    if (isWeb || googleWebClientId.isEmpty) return false;
    return switch (platform) {
      TargetPlatform.android => true,
      TargetPlatform.iOS => googleIosClientId.isNotEmpty,
      _ => false,
    };
  }

  /// Sign in with Apple is offered on Apple platforms only.
  bool get showAppleButton => _isApplePlatform;

  /// The Apple button signs in (rather than saying "coming soon").
  bool get appleEnabled => appleSignIn && _isApplePlatform;
}
