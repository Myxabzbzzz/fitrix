import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/constants/app_constants.dart';

/// App-wide session state that the router needs synchronously:
/// whether onboarding is done, which account the local data belongs to, and
/// a generation counter that bumps whenever local data is replaced wholesale
/// (sign-out, another account signing in) so the app rebuilds all in-memory
/// state from scratch.
class AppSession extends ChangeNotifier {
  AppSession(this._prefs);

  final SharedPreferences _prefs;

  /// Supabase user id of the account whose data is on this device. A
  /// different account signing in clears the local data first.
  static const String keyAccountUserId = 'account_user_id';

  bool get onboardingComplete =>
      _prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

  /// Supabase user id of the account whose data is on this device, or null
  /// (local-only mode, or nobody signed in yet).
  String? get accountUserId => _prefs.getString(keyAccountUserId);

  int _generation = 0;

  /// Changes every time local data is replaced (sign-out, account switch).
  int get generation => _generation;

  Future<void> completeOnboarding({bool notify = true}) async {
    await _prefs.setBool(AppConstants.keyOnboardingComplete, true);
    if (notify) notifyListeners();
  }

  Future<void> setAccountUserId(String userId, {bool notify = true}) async {
    await _prefs.setString(keyAccountUserId, userId);
    if (notify) notifyListeners();
  }

  /// Keys the Supabase client keeps in SharedPreferences (session, PKCE
  /// verifier). They belong to the auth session, not to the local data.
  static bool isAuthStorageKey(String key) =>
      key.startsWith('sb-') || key.startsWith('supabase.');

  /// Deletes the previous account's data but keeps the current auth session
  /// (and, with [keepLanguage], the language picked on this device).
  /// Call [reload] afterwards so in-memory state is rebuilt.
  Future<void> clearLocalData({bool keepLanguage = false}) async {
    for (final key in _prefs.getKeys().toList()) {
      if (isAuthStorageKey(key)) continue;
      if (keepLanguage && key == AppConstants.keyLanguage) continue;
      await _prefs.remove(key);
    }
  }

  /// Rebuilds all in-memory state from storage.
  void reload() {
    _generation++;
    notifyListeners();
  }

  /// Clears everything stored on this device and starts over.
  Future<void> signOut() async {
    await _prefs.clear();
    reload();
  }
}
