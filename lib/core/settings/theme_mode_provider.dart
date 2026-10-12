import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/session/session_providers.dart';

/// The app's theme mode: follow the system (default), or force light or dark.
/// Read synchronously from the preloaded SharedPreferences, so the first
/// frame already uses the saved mode.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _fromName(prefs.getString(_key));
  }

  /// Persists [mode] and applies it immediately.
  Future<void> set(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
    state = mode;
  }

  static ThemeMode _fromName(String? name) {
    for (final mode in ThemeMode.values) {
      if (mode.name == name) return mode;
    }
    return ThemeMode.system;
  }
}
