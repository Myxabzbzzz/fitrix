import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:fitrix/features/auth/data/auth_failure.dart';
import 'package:fitrix/features/auth/data/social_sign_in_config.dart';

enum SocialProvider {
  google('Google'),
  apple('Apple');

  const SocialProvider(this.label);

  /// Name shown to the user ("Continue with Google").
  final String label;
}

/// What a provider's native sign-in hands over for Supabase
/// `signInWithIdToken`.
class SocialCredential {
  const SocialCredential({
    required this.provider,
    required this.idToken,
    this.accessToken,
    this.nonce,
    this.givenName,
    this.familyName,
  });

  final SocialProvider provider;
  final String idToken;

  /// Google on iOS: its ID tokens carry a hash of the access token, which
  /// Supabase checks.
  final String? accessToken;

  /// The raw nonce; the ID token carries its SHA-256 (hex).
  final String? nonce;

  /// Apple shares the name only on the very first sign-in.
  final String? givenName;
  final String? familyName;
}

/// Gets an ID token from Google or Apple, kept behind an interface so the
/// sign-in screen can be tested without the platform SDKs.
abstract class SocialSignIn {
  /// Shows Google's account picker. Null when the user cancels; throws an
  /// [AuthFailure] otherwise.
  Future<SocialCredential?> google();

  /// Shows the Sign in with Apple sheet. Null when the user cancels; throws
  /// an [AuthFailure] otherwise.
  Future<SocialCredential?> apple();

  /// Asks Apple again (Face ID / password sheet) for a fresh authorization
  /// code, which the server needs to revoke Apple's tokens when the account
  /// is deleted. Null when the user cancels; throws an [AuthFailure] when
  /// Apple can't be asked on this build or device.
  Future<String?> appleAuthorizationCode();
}

/// A random nonce for an ID token request.
String generateRawNonce([int length = 32]) {
  const chars =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)])
      .join();
}

/// What goes into the provider request: SHA-256 of [rawNonce], hex. Supabase
/// gets the raw nonce and compares hashes.
String hashNonce(String rawNonce) =>
    sha256.convert(utf8.encode(rawNonce)).toString();

/// The real thing: google_sign_in and sign_in_with_apple.
class NativeSocialSignIn implements SocialSignIn {
  NativeSocialSignIn(this.config);

  final SocialSignInConfig config;

  static const _googleScopes = ['email', 'profile'];

  // google_sign_in may be initialized only once per process, and the nonce
  // is part of that, so one nonce serves every Google sign-in of this run.
  static Future<void>? _googleReady;
  static String? _googleNonce;

  Future<void> _initGoogle() {
    final nonce = generateRawNonce();
    return GoogleSignIn.instance
        .initialize(
          clientId: config.platform == TargetPlatform.iOS
              ? config.googleIosClientId
              : null,
          serverClientId: config.googleWebClientId,
          nonce: hashNonce(nonce),
        )
        .then((_) => _googleNonce = nonce);
  }

  @override
  Future<SocialCredential?> google() async {
    const provider = SocialProvider.google;
    if (!config.googleEnabled) {
      throw AuthFailure.providerUnavailable(provider.label);
    }
    final signIn = GoogleSignIn.instance;
    try {
      try {
        await (_googleReady ??= _initGoogle());
      } catch (_) {
        _googleReady = null; // Try again next time.
        rethrow;
      }
      if (!signIn.supportsAuthenticate()) {
        throw AuthFailure.providerUnavailable(provider.label);
      }

      final account = await signIn.authenticate(scopeHint: _googleScopes);
      final idToken = account.authentication.idToken;
      if (idToken == null) throw AuthFailure.socialFailed(provider.label);

      // iOS ID tokens include the access token's hash, so Supabase needs
      // the access token too. Android's don't (and asking could show a
      // second consent screen).
      String? accessToken;
      if (config.platform != TargetPlatform.android) {
        final client = account.authorizationClient;
        final authorization =
            await client.authorizationForScopes(_googleScopes) ??
                await client.authorizeScopes(_googleScopes);
        accessToken = authorization.accessToken;
      }

      // Supabase holds the session from here; don't keep Google's around.
      unawaited(signIn.signOut().catchError((Object _) {}));
      return SocialCredential(
        provider: provider,
        idToken: idToken,
        accessToken: accessToken,
        nonce: _googleNonce,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('Google sign-in failed: $e');
      throw googleFailure(e);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      throw platformFailure(e, provider);
    }
  }

  @override
  Future<SocialCredential?> apple() async {
    const provider = SocialProvider.apple;
    if (!config.appleEnabled) {
      throw AuthFailure.providerUnavailable(provider.label);
    }
    final nonce = generateRawNonce();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashNonce(nonce),
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw AuthFailure.socialFailed(provider.label);
      return SocialCredential(
        provider: provider,
        idToken: idToken,
        nonce: nonce,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      debugPrint('Sign in with Apple failed: $e');
      throw appleFailure(e);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      debugPrint('Sign in with Apple failed: $e');
      throw platformFailure(e, provider);
    }
  }

  @override
  Future<String?> appleAuthorizationCode() async {
    const provider = SocialProvider.apple;
    if (!config.appleEnabled) {
      throw AuthFailure.providerUnavailable(provider.label);
    }
    try {
      final credential =
          await SignInWithApple.getAppleIDCredential(scopes: const []);
      return credential.authorizationCode;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      debugPrint('Apple authorization failed: $e');
      throw appleFailure(e);
    } catch (e) {
      debugPrint('Apple authorization failed: $e');
      throw platformFailure(e, provider);
    }
  }

  /// Google SDK errors other than cancelling.
  @visibleForTesting
  static AuthFailure googleFailure(GoogleSignInException e) {
    const label = 'Google';
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
      case GoogleSignInExceptionCode.uiUnavailable:
        return AuthFailure.providerUnavailable(label);
      default:
        final details = '${e.description ?? ''} ${e.details ?? ''}'
            .toLowerCase();
        if (details.contains('network') || details.contains('offline')) {
          return AuthFailure.network;
        }
        return AuthFailure.socialFailed(label);
    }
  }

  /// Sign in with Apple errors other than cancelling. A build without the
  /// "Sign in with Apple" capability fails with `unknown` (code 1000).
  @visibleForTesting
  static AuthFailure appleFailure(SignInWithAppleAuthorizationException e) =>
      AuthFailure.socialFailed('Apple');

  /// Anything else from the plugins: missing plugin, unsupported OS, ...
  @visibleForTesting
  static AuthFailure platformFailure(Object e, SocialProvider provider) {
    if (e is SignInWithAppleNotSupportedException ||
        e is MissingPluginException ||
        e is UnsupportedError) {
      return AuthFailure.providerUnavailable(provider.label);
    }
    return AuthFailure.socialFailed(provider.label);
  }
}
