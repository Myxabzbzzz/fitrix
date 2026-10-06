import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/features/auth/data/auth_gateway.dart';
import 'package:fitrix/features/profile/data/models/profile_row.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';
import 'package:fitrix/features/profile/data/repositories/profile_remote.dart';
import 'package:fitrix/features/profile/data/repositories/profile_repository.dart';

/// Where to go once a sign-in code has been accepted.
enum SignInDestination {
  /// The account finished onboarding before (or this device already has its
  /// data): straight to Home.
  home,

  /// New account (or onboarding never finished): continue onboarding.
  profile,
}

/// Ties the Supabase account to the data on this device: what happens after
/// sign-in, uploading the profile, and signing out.
///
/// Only exists when Supabase is available; in local-only mode the app works
/// exactly as before without it.
class AccountService {
  AccountService({
    required SharedPreferences prefs,
    required AppSession session,
    required AuthGateway auth,
    required ProfileRemote remote,
    ProfileRepository? profiles,
    Duration Function(int failures)? retryDelay,
  })  : _prefs = prefs,
        _session = session,
        _auth = auth,
        _remote = remote,
        _profiles = profiles ?? ProfileRepository(),
        _retryDelay = retryDelay ?? defaultRetryDelay;

  /// True while local profile changes (or finishing onboarding) still have
  /// to be uploaded to the `profiles` table.
  static const String keyProfileSyncPending = 'profile_sync_pending';

  final SharedPreferences _prefs;
  final AppSession _session;
  final AuthGateway _auth;
  final ProfileRemote _remote;
  final ProfileRepository _profiles;
  final Duration Function(int failures) _retryDelay;

  /// Backs off from 5 seconds to 5 minutes between upload attempts.
  static Duration defaultRetryDelay(int failures) {
    const steps = [5, 15, 30, 60, 120, 300];
    return Duration(seconds: steps[(failures - 1).clamp(0, steps.length - 1)]);
  }

  Future<void> _queue = Future.value();
  int _revision = 0;
  int _failures = 0;
  Timer? _retryTimer;
  bool _started = false;

  AuthGateway get auth => _auth;

  /// Email of the signed-in account.
  String? get email => _auth.email;

  /// Signed in, and the data on this device belongs to that account.
  bool get isSignedIn =>
      _auth.userId != null && _auth.userId == _session.accountUserId;

  /// Whether local profile changes still have to be uploaded.
  bool get hasPendingUpload =>
      _prefs.getBool(keyProfileSyncPending) ?? false;

  /// Uploads anything left over from the last run, and again whenever the
  /// account signs in.
  void start() {
    if (_started) return;
    _started = true;
    _auth.addListener(_onAuthChanged);
    if (hasPendingUpload) unawaited(flush());
  }

  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _retryTimer?.cancel();
  }

  void _onAuthChanged() {
    if (isSignedIn && hasPendingUpload) unawaited(flush());
  }

  /// Called once a sign-in code was accepted for [userId]. Decides where the
  /// user goes next and prepares the local data:
  ///
  /// * Same account signing back in on a device that's already set up (or
  ///   data from before accounts existed): keep everything, go Home.
  /// * Otherwise load the account's profile row. If onboarding was finished
  ///   (returning user, new device) it's restored locally and the user goes
  ///   Home; if not, onboarding continues with the profile step.
  /// * A different account than the one whose data is on this device: that
  ///   data is deleted first (the session and the chosen language are kept).
  ///
  /// Throws if the profile can't be loaded; nothing local changes then, so
  /// it's safe to call again.
  Future<SignInDestination> completeSignIn(String userId) async {
    final previous = _session.accountUserId;
    final switching = previous != null && previous != userId;

    if (!switching && _session.onboardingComplete) {
      if (previous == null) {
        // Onboarded before accounts existed: this data becomes the account's.
        await _prefs.setBool(keyProfileSyncPending, true);
        _revision++;
      }
      await _session.setAccountUserId(userId);
      unawaited(flush());
      return SignInDestination.home;
    }

    final row = await _remote.fetch(userId);
    final keepLocalProfile = !switching && hasPendingUpload;

    if (switching) await _session.clearLocalData(keepLanguage: true);

    final restored = row != null && row.onboardingComplete;
    if (row != null && !keepLocalProfile && (restored || row.name.isNotEmpty)) {
      // Restores the profile, or pre-fills the form if it was started.
      await _profiles.saveProfile(row.toUserProfile());
    }
    if (restored) {
      await _prefs.setString(AppConstants.keyLanguage, row.language);
      await _session.completeOnboarding(notify: false);
    }
    await _session.setAccountUserId(userId, notify: false);

    // Rebuild in-memory state (profile, workouts, chats) from storage.
    _session.reload();
    if (hasPendingUpload) unawaited(flush());
    return restored ? SignInDestination.home : SignInDestination.profile;
  }

  /// Call after the local profile, language or onboarding state changed.
  /// Saves the change for upload and tries to upload it right away; if that
  /// fails it's retried with back-off, on the next sign-in and on the next
  /// launch until it lands. Completes with whether the upload succeeded.
  Future<bool> profileChanged() async {
    await _prefs.setBool(keyProfileSyncPending, true);
    _revision++;
    return flush();
  }

  /// Uploads pending profile changes. Uploads run one at a time and always
  /// send the latest local state.
  Future<bool> flush() {
    final result = _queue.then((_) => _upload());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<bool> _upload() async {
    if (!hasPendingUpload) return true;
    final userId = _auth.userId;
    // Wait for the right account to be signed in.
    if (userId == null || userId != _session.accountUserId) return false;

    final revision = _revision;
    final UserProfile? profile = await _profiles.getProfile();
    final row = ProfileRow.fromLocal(
      id: userId,
      profile: profile ??
          UserProfile(name: '', surname: '', age: '', weight: '', height: ''),
      language: _prefs.getString(AppConstants.keyLanguage),
      onboardingComplete: _session.onboardingComplete,
    );

    try {
      await _remote.upsert(row, includeProfile: profile != null);
    } catch (e) {
      debugPrint('Profile upload failed, will retry: $e');
      _scheduleRetry();
      return false;
    }

    _failures = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
    // Something changed during the upload: keep it pending, the next
    // flush (already queued by profileChanged) sends it.
    if (revision == _revision && _session.accountUserId == userId) {
      await _prefs.remove(keyProfileSyncPending);
    }
    return true;
  }

  void _scheduleRetry() {
    _failures++;
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay(_failures), () {
      _retryTimer = null;
      unawaited(flush());
    });
  }

  /// Signs out and deletes all local data. Pending profile changes get a
  /// short chance to upload first. Works offline: the session is dropped on
  /// this device immediately, the server is told when it can be reached.
  Future<void> signOut() async {
    if (hasPendingUpload) {
      try {
        await flush().timeout(const Duration(seconds: 2));
      } catch (_) {
        // Offline: the changes stay on the device only.
      }
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    _failures = 0;

    final remote = _auth.signOut();
    await _session.signOut();
    unawaited(remote.timeout(const Duration(seconds: 10)).then(
          (_) {},
          onError: (Object e) => debugPrint('Remote sign-out failed: $e'),
        ));
  }
}
