/// FITRIX - AI-Powered Fitness Application
/// Main entry point for the Flutter application
///
/// This file initializes the app with:
/// - Riverpod for state management
/// - Material Design 3 theming (light & dark modes)
/// - Go Router for navigation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/router/app_router.dart';

/// Application entry point
/// Initializes Flutter bindings and system UI settings before launching the app
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

  // Launch app wrapped in ProviderScope for Riverpod state management
  runApp(
    const ProviderScope(
      child: FitrixApp(),
    ),
  );
}

/// Root widget of the FITRIX application
/// Configures Material App with theming and routing
class FitrixApp extends StatelessWidget {
  const FitrixApp({super.key});

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
      routerConfig: AppRouter.router,
    );
  }
}
