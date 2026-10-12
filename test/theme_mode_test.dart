import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/settings/theme_mode_provider.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('defaults to ThemeMode.system when nothing is stored', () async {
    final container = await _container({});
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  test('restores the stored dark mode', () async {
    final container = await _container({'theme_mode': 'dark'});
    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  test('set persists the mode under theme_mode and updates state', () async {
    final container = await _container({});
    final prefs = container.read(sharedPreferencesProvider);

    await container.read(themeModeProvider.notifier).set(ThemeMode.light);

    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(prefs.getString('theme_mode'), 'light');
  });

  test('an unknown stored value falls back to system', () async {
    final container = await _container({'theme_mode': 'neon'});
    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
