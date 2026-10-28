/// Application-Wide Constants
///
/// Centralized location for all constant values used throughout the FITRIX app.
/// Organized into logical groups:
/// - API Configuration: Backend connection settings
/// - Local Storage Keys: SharedPreferences keys for data persistence
/// - App Text Content: Static text and branding
/// - Fitness Goals: Predefined user goal options
/// - Languages: Supported application languages
///
/// Best Practice: Update these constants instead of hardcoding values
/// throughout the codebase for easier maintenance and consistency.
library;

import 'package:flutter/foundation.dart';

class AppConstants {
  // Private constructor prevents instantiation
  AppConstants._();

  // ==========================================================================
  // API CONFIGURATION
  // ==========================================================================

  /// `--dart-define=API_BASE_URL=...` value, or '' when none was given.
  static const String _apiBaseUrlDefine =
      String.fromEnvironment('API_BASE_URL');

  /// Base URL for the backend API server (see [resolveApiBaseUrl]).
  ///
  /// For a physical phone pass your Mac's LAN IP at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.0.103:3000
  static String get apiBaseUrl => resolveApiBaseUrl(
        define: _apiBaseUrlDefine,
        platform: defaultTargetPlatform,
        isWeb: kIsWeb,
      );

  /// Picks the backend URL: a non-empty [define] (from `--dart-define`) always
  /// wins. Otherwise the Android emulator reaches the host Mac at 10.0.2.2,
  /// while the iOS simulator, macOS, desktop and web use localhost.
  /// ([platform] on web is the browser's OS, so [isWeb] is checked first.)
  static String resolveApiBaseUrl({
    required String define,
    required TargetPlatform platform,
    required bool isWeb,
  }) {
    if (define.isNotEmpty) return define;
    if (!isWeb && platform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Streaming chat endpoint: NDJSON lines of {"delta"} / {"done"} / {"error"}
  static const String chatStreamEndpoint = '/chat/stream';

  /// How long to wait for the backend to accept the connection.
  /// Kept short so an unreachable backend fails fast instead of hanging.
  static const Duration apiConnectTimeout = Duration(seconds: 3);

  /// Max silence between streamed chunks before giving up.
  static const Duration apiReceiveTimeout = Duration(seconds: 60);

  // ==========================================================================
  // LOCAL STORAGE KEYS (SharedPreferences)
  // ==========================================================================

  /// Key for storing selected language preference
  /// Values: 'en', 'ru', 'uz', 'es'
  static const String keyLanguage = 'language';

  /// Key for storing authentication status
  /// Values: true (authenticated) or false (not authenticated)
  static const String keyIsAuthenticated = 'is_authenticated';

  /// Key for storing user's email address
  /// Used for mock authentication in this version
  static const String keyUserEmail = 'user_email';

  /// Key for storing user's first name
  static const String keyUserName = 'user_name';

  /// Key for storing user's surname/last name
  static const String keyUserSurname = 'user_surname';

  /// Key for storing user's age
  static const String keyUserAge = 'user_age';

  /// Key for storing user's weight
  static const String keyUserWeight = 'user_weight';

  /// Key for storing user's height
  static const String keyUserHeight = 'user_height';

  /// Onboarding answers (goal, experience level, sports) Felix uses.
  static const String keyUserGoal = 'user_goal';
  static const String keyUserExperience = 'user_experience';
  static const String keyUserSports = 'user_sports';

  /// Key for storing chat conversation history
  /// Stored as JSON string for persistence between app sessions
  static const String keyChatHistory = 'chat_history';

  /// Set once the user finishes onboarding; later launches open Home.
  static const String keyOnboardingComplete = 'onboarding_complete';

  /// Saved workout plans (JSON list).
  static const String keyWorkoutTemplates = 'workout_templates';

  /// Workout in progress, so it survives an app restart (JSON).
  static const String keyActiveWorkout = 'active_workout';

  /// Finished workouts, newest first (JSON list).
  static const String keyWorkoutHistory = 'workout_history';

  /// Key for storing unique conversation identifier
  /// Used to maintain context across backend API requests
  static const String keyConversationId = 'conversation_id';

  // ==========================================================================
  // APP TEXT CONTENT & BRANDING
  // ==========================================================================

  // ==========================================================================
  // FELIX AI ASSISTANT CONFIGURATION
  // ==========================================================================

  /// Name of the AI fitness coach
  static const String assistantName = 'Felix';

  // Felix's greeting and subtitle are in the ARB files (assistant*).

  // ==========================================================================
  // FITNESS GOALS (Quick Reply Options)
  // ==========================================================================

  /// Predefined fitness goals shown as quick reply chips
  /// Users can select one to start their fitness journey
  /// These are the first options Felix presents
  static const List<String> fitnessGoals = [
    'Build muscle and strength', // Hypertrophy and strength training
    'Improve endurance and stamina', // Cardio and aerobic fitness
    'Lose weight and get toned', // Fat loss and body composition
    'Feel healthier and balanced', // General wellness and lifestyle
    'Just track my progress', // Monitoring without specific goal
  ];

  // ==========================================================================
  // SUPPORTED LANGUAGES
  // ==========================================================================

  /// Map of language codes to display names
  ///
  /// Key: ISO 639-1 language code
  /// Value: Native language name (how speakers write their language)
  ///
  /// To add a new language:
  /// 1. Add entry here (e.g., 'fr': 'Français')
  /// 2. Add lib/l10n/app_<code>.arb with every key of app_en.arb
  /// 3. Add the code to CFBundleLocalizations in ios/Runner/Info.plist
  static const Map<String, String> languages = {
    'ru': 'Русский', // Russian
    'en': 'English', // English
    'uz': 'O‘zbekcha', // Uzbek
    'es': 'Español', // Spanish
  };
}
