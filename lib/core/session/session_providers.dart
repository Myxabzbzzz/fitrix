import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/session/app_session.dart';

/// Loaded once in `main()` before the app starts, so storage reads are
/// synchronous everywhere else. Overridden in the root ProviderScope.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

final appSessionProvider = Provider<AppSession>(
  (ref) => throw UnimplementedError('Override appSessionProvider'),
);
