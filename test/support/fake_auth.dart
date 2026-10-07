import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitrix/features/auth/data/auth_gateway.dart';
import 'package:fitrix/features/auth/data/social_sign_in.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/data/repositories/profile_remote.dart';

/// In-memory stand-in for Supabase email-code sign-in.
class FakeAuthGateway extends ChangeNotifier implements AuthGateway {
  FakeAuthGateway({Map<String, String>? users}) : users = users ?? {};

  /// email → user id. Unknown emails get a new id on first sign-in.
  final Map<String, String> users;
  String validCode = '123456';

  /// Thrown by the next [sendCode] / [verifyCode] / [signInWithIdToken]
  /// calls while set.
  Object? sendError;
  Object? verifyError;
  Object? idTokenError;

  /// ID tokens handed to [signInWithIdToken]. A token is the account's
  /// email in these tests.
  final List<SocialCredential> idTokens = [];

  final List<String> codesSentTo = [];
  int signOutCalls = 0;

  /// Thrown by [deleteAccount] while set.
  Object? deleteError;

  /// Apple authorization codes handed to [deleteAccount], one per call
  /// (null: none sent).
  final List<String?> deleteCalls = [];

  /// Emails of accounts that were created with Sign in with Apple.
  final Set<String> appleAccounts = {};

  String? _userId;
  String? _email;

  @override
  String? get userId => _userId;

  @override
  String? get email => _email;

  /// Starts with a session already in place (e.g. a persisted one).
  void signInAs(String email) {
    _email = email;
    _userId = users.putIfAbsent(email, () => 'user-${users.length + 1}');
    notifyListeners();
  }

  /// The session ends without the app asking (revoked, signed out elsewhere).
  void revoke() {
    _userId = null;
    _email = null;
    notifyListeners();
  }

  @override
  Future<void> sendCode(String email) async {
    if (sendError != null) throw sendError!;
    codesSentTo.add(email);
  }

  @override
  Future<String> verifyCode({
    required String email,
    required String code,
  }) async {
    if (verifyError != null) throw verifyError!;
    if (code != validCode) {
      throw const AuthApiException(
        'Token has expired or is invalid',
        statusCode: '403',
        code: 'otp_expired',
      );
    }
    signInAs(email);
    return _userId!;
  }

  @override
  Future<String> signInWithIdToken(SocialCredential credential) async {
    idTokens.add(credential);
    if (idTokenError != null) throw idTokenError!;
    if (credential.provider == SocialProvider.apple) {
      appleAccounts.add(credential.idToken);
    }
    signInAs(credential.idToken);
    return _userId!;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    revoke();
  }

  @override
  bool get hasAppleSignIn => appleAccounts.contains(_email);

  @override
  Future<void> deleteAccount({String? appleAuthorizationCode}) async {
    deleteCalls.add(appleAuthorizationCode);
    if (deleteError != null) throw deleteError!;
    // Gone for good: signing in with the same email creates a new account.
    users.remove(_email);
    appleAccounts.remove(_email);
    revoke();
  }
}

/// Google / Apple sheets that answer as told: an account (by email), a
/// cancel (null) or an error.
class FakeSocialSignIn implements SocialSignIn {
  /// Email of the account picked in the sheet; null = the user cancels.
  String? googleAccount;
  String? appleAccount;
  Object? googleError;
  Object? appleError;
  int googleCalls = 0;
  int appleCalls = 0;

  /// What Apple's re-authorization sheet answers: a code, a cancel (null)
  /// or [appleCodeError].
  String? appleCode = 'apple-auth-code';
  Object? appleCodeError;
  int appleCodeCalls = 0;

  @override
  Future<SocialCredential?> google() async {
    googleCalls++;
    if (googleError != null) throw googleError!;
    final email = googleAccount;
    return email == null
        ? null
        : SocialCredential(
            provider: SocialProvider.google,
            idToken: email,
            accessToken: 'access-token',
            nonce: 'nonce',
          );
  }

  @override
  Future<SocialCredential?> apple() async {
    appleCalls++;
    if (appleError != null) throw appleError!;
    final email = appleAccount;
    return email == null
        ? null
        : SocialCredential(
            provider: SocialProvider.apple,
            idToken: email,
            nonce: 'nonce',
            givenName: 'Alex',
          );
  }

  @override
  Future<String?> appleAuthorizationCode() async {
    appleCodeCalls++;
    if (appleCodeError != null) throw appleCodeError!;
    return appleCode;
  }
}

/// In-memory `profiles` table with upsert semantics like PostgREST.
class FakeProfileRemote implements ProfileRemote {
  final Map<String, Map<String, dynamic>> rows = {};
  Object? fetchError;
  Object? upsertError;
  int upserts = 0;

  @override
  Future<ProfileRow?> fetch(String userId) async {
    if (fetchError != null) throw fetchError!;
    final row = rows[userId];
    return row == null ? null : ProfileRow.fromJson(row);
  }

  @override
  Future<void> upsert(ProfileRow row, {bool includeProfile = true}) async {
    if (upsertError != null) throw upsertError!;
    upserts++;
    rows[row.id] = {
      'name': '',
      'surname': '',
      'language': 'en',
      'onboarding_complete': false,
      ...?rows[row.id],
      ...row.toUpsert(includeProfile: includeProfile),
    };
  }
}
