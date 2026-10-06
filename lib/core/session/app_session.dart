import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/constants/app_constants.dart';

/// App-wide session state that the router needs synchronously:
/// whether onboarding is done, and a generation counter that bumps on
/// sign-out so the app can rebuild all in-memory state from scratch.
class AppSession extends ChangeNotifier {
  AppSession(this._prefs);

  final SharedPreferences _prefs;

  bool get onboardingComplete =>
      _prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;

  int _generation = 0;

  /// Changes every time the user signs out.
  int get generation => _generation;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(AppConstants.keyOnboardingComplete, true);
    notifyListeners();
  }

  /// Clears everything stored on this device and starts over.
  Future<void> signOut() async {
    await _prefs.clear();
    _generation++;
    notifyListeners();
  }
}
