import 'package:flutter/foundation.dart';

/// Where the app finds Supabase (auth + database).
///
/// Defaults point at the local stack started with `supabase start` (see
/// `supabase/config.toml`, API on port 55321). For the cloud project pass:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
///     --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable key>
class SupabaseConfig {
  SupabaseConfig._();

  static const String _urlDefine = String.fromEnvironment('SUPABASE_URL');

  /// The public client key (safe to ship in the app; row level security
  /// protects the data). The default is the key every local Supabase stack
  /// ships with — not a secret, and it only works locally.
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );

  static String get url => resolveUrl(
        define: _urlDefine,
        platform: defaultTargetPlatform,
        isWeb: kIsWeb,
      );

  /// A non-empty [define] wins; otherwise the local stack, which the Android
  /// emulator reaches through 10.0.2.2.
  static String resolveUrl({
    required String define,
    required TargetPlatform platform,
    required bool isWeb,
  }) {
    if (define.isNotEmpty) return define;
    if (!isWeb && platform == TargetPlatform.android) {
      return 'http://10.0.2.2:55321';
    }
    return 'http://127.0.0.1:55321';
  }
}
