import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitrix/features/auth/data/social_sign_in.dart';

/// Email + one-time-code sign-in (and Google / Apple ID tokens), behind an
/// interface so screens and
/// session logic can be tested without a Supabase server.
///
/// Notifies listeners whenever the signed-in user changes (sign-in,
/// sign-out, session revoked).
abstract class AuthGateway implements Listenable {
  /// The signed-in user's id, or null without a session.
  String? get userId;

  /// The signed-in user's email, or null without a session.
  String? get email;

  /// Emails a 6-digit sign-in code, creating the account if it's new.
  Future<void> sendCode(String email);

  /// Checks [code] for [email] and starts a session. Returns the user id.
  Future<String> verifyCode({required String email, required String code});

  /// Starts a session from a Google or Apple ID token, creating the account
  /// if it's new. Returns the user id.
  Future<String> signInWithIdToken(SocialCredential credential);

  /// Ends the session on this device right away; the server call that
  /// revokes the refresh token may finish (or fail offline) later.
  Future<void> signOut();

  /// Whether the signed-in account can sign in with Apple. Its Apple tokens
  /// have to be revoked when the account is deleted.
  bool get hasAppleSignIn;

  /// Deletes the signed-in account and all its data on the server for good,
  /// then ends the session on this device. With [appleAuthorizationCode]
  /// (a fresh one from Apple) the server also revokes the Apple tokens.
  /// Throws if the server can't be reached or refuses; nothing changes then.
  Future<void> deleteAccount({String? appleAuthorizationCode});
}

class SupabaseAuthGateway extends ChangeNotifier implements AuthGateway {
  SupabaseAuthGateway(this._client) {
    _lastUserId = userId;
    _subscription = _client.auth.onAuthStateChange.listen(
      (_) => _onAuthChange(),
      // Refresh failures surface here too; the session state is still read
      // from currentUser, so there's nothing to do but keep listening.
      onError: (Object e) => debugPrint('Auth state error: $e'),
    );
  }

  final SupabaseClient _client;
  late final StreamSubscription<AuthState> _subscription;
  String? _lastUserId;

  void _onAuthChange() {
    final id = userId;
    if (id == _lastUserId) return;
    _lastUserId = id;
    notifyListeners();
  }

  @override
  String? get userId => _client.auth.currentUser?.id;

  @override
  String? get email => _client.auth.currentUser?.email;

  @override
  Future<void> sendCode(String email) =>
      _client.auth.signInWithOtp(email: email, shouldCreateUser: true);

  @override
  Future<String> verifyCode({
    required String email,
    required String code,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    final user = response.user ?? response.session?.user;
    if (user == null) {
      throw const AuthException('No session after verification');
    }
    _onAuthChange();
    return user.id;
  }

  @override
  Future<String> signInWithIdToken(SocialCredential credential) async {
    final response = await _client.auth.signInWithIdToken(
      provider: switch (credential.provider) {
        SocialProvider.google => OAuthProvider.google,
        SocialProvider.apple => OAuthProvider.apple,
      },
      idToken: credential.idToken,
      accessToken: credential.accessToken,
      nonce: credential.nonce,
    );
    final user = response.user ?? response.session?.user;
    if (user == null) {
      throw const AuthException('No session after sign-in');
    }
    _onAuthChange();
    _saveName(user, credential);
    return user.id;
  }

  /// Apple shares the user's name only once, and not in the ID token: keep
  /// it in the account's metadata. Best effort.
  void _saveName(User user, SocialCredential credential) {
    final name = [credential.givenName, credential.familyName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');
    if (name.isEmpty || user.userMetadata?['full_name'] != null) return;
    unawaited(_client.auth
        .updateUser(UserAttributes(data: {
          'full_name': name,
          if (credential.givenName != null) 'given_name': credential.givenName,
          if (credential.familyName != null)
            'family_name': credential.familyName,
        }))
        .then((_) {}, onError: (Object e) => debugPrint('Saving name: $e')));
  }

  @override
  Future<void> signOut() =>
      // Drops the local session synchronously (listeners hear about it from
      // the auth stream a moment later), then revokes it on the server.
      _client.auth.signOut();

  @override
  bool get hasAppleSignIn {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    final providers = user.appMetadata['providers'];
    return (providers is List && providers.contains('apple')) ||
        (user.identities?.any((i) => i.provider == 'apple') ?? false);
  }

  @override
  Future<void> deleteAccount({String? appleAuthorizationCode}) async {
    var session = _client.auth.currentSession;
    if (session == null) throw const AuthException('Not signed in');
    // The function checks the token itself: make sure it's still valid.
    if (session.isExpired) {
      session = (await _client.auth.refreshSession()).session ?? session;
    }
    // supabase/functions/delete-account; throws FunctionException on errors.
    await _client.functions.invoke(
      'delete-account',
      headers: {'Authorization': 'Bearer ${session.accessToken}'},
      body: {
        if (appleAuthorizationCode != null)
          'appleAuthorizationCode': appleAuthorizationCode,
      },
    );
    // The account is gone: drop the session on this device. Telling the
    // server fails (no such user), which signOut ignores.
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      debugPrint('Sign-out after deleting the account: $e');
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
