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
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/app_session.dart';
import 'package:fitrix/core/session/session_providers.dart';

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

  runApp(
    FitrixRoot(
      prefs: prefs,
      session: session,
      router: AppRouter.create(session),
    ),
  );
}

/// Owns the Riverpod scope. Signing out bumps [AppSession.generation], which
/// recreates the scope so no in-memory state (chats, workouts, profile)
/// survives into the next account.
class FitrixRoot extends StatelessWidget {
  final SharedPreferences prefs;
  final AppSession session;
  final GoRouter router;

  const FitrixRoot({
    super.key,
    required this.prefs,
    required this.session,
    required this.router,
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
