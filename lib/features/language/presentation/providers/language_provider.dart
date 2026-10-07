import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/session_providers.dart';

/// The app's language code ('en', 'ru', 'uz', 'es'): the one picked on the
/// language screen (or restored from the account), otherwise the device's
/// language when the app has it, otherwise English. Read synchronously, so
/// the first frame is already in the right language.
final selectedLanguageProvider =
    StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier(ref.watch(sharedPreferencesProvider));
});

/// [selectedLanguageProvider] as the locale for MaterialApp.
final localeProvider = Provider<Locale>(
  (ref) => Locale(ref.watch(selectedLanguageProvider)),
);

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier(this._prefs, {String? deviceLanguage})
      : super(_initial(_prefs, deviceLanguage));

  final SharedPreferences _prefs;

  static String _initial(SharedPreferences prefs, String? deviceLanguage) {
    final saved = prefs.getString(AppConstants.keyLanguage);
    if (saved != null && AppConstants.languages.containsKey(saved)) {
      return saved;
    }
    return supportedOrEnglish(
      deviceLanguage ?? PlatformDispatcher.instance.locale.languageCode,
    );
  }

  /// [code] if the app is translated into it, otherwise 'en'.
  static String supportedOrEnglish(String code) =>
      AppConstants.languages.containsKey(code) ? code : 'en';

  /// Whether the user picked a language yet (vs. the device default).
  bool get isSaved => _prefs.getString(AppConstants.keyLanguage) != null;

  Future<void> setLanguage(String languageCode) async {
    await _prefs.setString(AppConstants.keyLanguage, languageCode);
    state = languageCode;
  }
}
