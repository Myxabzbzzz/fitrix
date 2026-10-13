import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/app_session.dart';

Future<(AppSession, SharedPreferences)> _session() async {
  SharedPreferences.setMockInitialValues({
    'theme_mode': 'dark',
    'language': 'ru',
    'onboarding_complete': true,
    'sb-session': 'token',
    'profile': 'x',
  });
  final prefs = await SharedPreferences.getInstance();
  return (AppSession(prefs), prefs);
}

void main() {
  test('sign-out clears the account data but keeps the theme choice',
      () async {
    final (session, prefs) = await _session();
    await session.signOut();
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getBool('onboarding_complete'), isNull);
    expect(prefs.getString('profile'), isNull);
    expect(prefs.getString('language'), isNull);
  });

  test('an account switch keeps the theme and, asked to, the language',
      () async {
    final (session, prefs) = await _session();
    await session.clearLocalData(keepLanguage: true);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('language'), 'ru');
    expect(prefs.getString('sb-session'), 'token');
    expect(prefs.getString('profile'), isNull);

    await session.clearLocalData();
    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('language'), isNull);
  });
}
