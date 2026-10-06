/// FITRIX - AI-Powered Fitness Application
/// Main entry point for the Flutter application
///
/// This file initializes the app with:
/// - Riverpod for state management
/// - Material Design 3 theming (light & dark modes)
/// - Go Router for navigation
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/supabase/supabase_config.dart';
import 'package:fitrix/core/supabase/supabase_providers.dart';
import 'package:fitrix/features/auth/data/account_service.dart';
import 'package:fitrix/features/auth/data/auth_gateway.dart';
import 'package:fitrix/features/auth/presentation/providers/auth_provider.dart';
import 'package:fitrix/features/profile/data/repositories/profile_remote.dart';

/// Application entry point
/// Initializes Flutter bindings and loads local storage before launching the app
void main() async {
  // Ensure Flutter bindings are initialized before any async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Configure status bar appearance
  // Make status bar transparent for immersive full-screen experience
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Storage is loaded up front so the router knows whether onboarding is
  // done and saved workouts are available on the first frame.
  final prefs = await SharedPreferences.getInstance();
  final session = AppSession(prefs);
  final supabase = await _initSupabase();

  // Sign-in and the account's profile; without Supabase the app runs
  // local-only, exactly as before accounts existed.
  final auth = supabase == null ? null : SupabaseAuthGateway(supabase);
  final account = auth == null
      ? null
      : (AccountService(
          prefs: prefs,
          session: session,
          auth: auth,
          remote: SupabaseProfileRemote(supabase!),
        )..start());

  runApp(
    FitrixRoot(
      prefs: prefs,
      session: session,
      router: AppRouter.create(session, auth: auth),
      supabase: supabase,
      auth: auth,
      account: account,
    ),
  );
}

/// Connects to Supabase (auth + sync). Initialization only reads config and
/// any saved session, so it works offline; if it still fails the app runs
/// local-only rather than not starting.
Future<SupabaseClient?> _initSupabase() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    return Supabase.instance.client;
  } catch (e) {
    debugPrint('Supabase unavailable, running local-only: $e');
    return null;
  }
}

/// Owns the Riverpod scope. Signing out bumps [AppSession.generation], which
/// recreates the scope so no in-memory state (chats, workouts, profile)
/// survives into the next account.
class FitrixRoot extends StatelessWidget {
  final SharedPreferences prefs;
  final AppSession session;
  final GoRouter router;

  /// Null when Supabase isn't available (e.g. in tests): local-only mode.
  final SupabaseClient? supabase;

  /// Email-code sign-in; null in local-only mode. Must be the same instance
  /// the [router] was created with.
  final AuthGateway? auth;

  /// Account ↔ local data glue; null in local-only mode.
  final AccountService? account;

  const FitrixRoot({
    super.key,
    required this.prefs,
    required this.session,
    required this.router,
    this.supabase,
    this.auth,
    this.account,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => ProviderScope(
        key: ValueKey(session.generation),
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appSessionProvider.overrideWithValue(session),
          supabaseClientProvider.overrideWithValue(supabase),
          authGatewayProvider.overrideWithValue(auth),
          accountServiceProvider.overrideWithValue(account),
        ],
        child: FitrixApp(router: router),
      ),
    );
  }
}

/// Root widget of the FITRIX application
/// Configures Material App with theming and routing
class FitrixApp extends StatelessWidget {
  final GoRouter router;

  const FitrixApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Application title shown in task switcher
      title: 'FITRIX',

      // Hide debug banner in top right corner
      debugShowCheckedModeBanner: false,

      // Light theme configuration (used when system is in light mode)
      theme: AppTheme.lightTheme,

      // Dark theme configuration (used when system is in dark mode)
      // Provides true black backgrounds and light text for OLED displays
      darkTheme: AppTheme.darkTheme,

      // Theme mode strategy:
      // - ThemeMode.system: Follows device system settings (default)
      // - ThemeMode.light: Always use light theme
      // - ThemeMode.dark: Always use dark theme
      themeMode: ThemeMode.system,

      // Router configuration using go_router
      // Handles all navigation and deep linking
      routerConfig: router,
    );
  }
}
