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

class AppConstants {
  // Private constructor prevents instantiation
  AppConstants._();

  // ==========================================================================
  // API CONFIGURATION
  // ==========================================================================

  /// Base URL for the backend API server
  ///
  /// Defaults to localhost, which works for the iOS simulator, macOS and web.
  /// For a physical phone pass your Mac's LAN IP at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.0.103:3000
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Chat endpoint path (appended to apiBaseUrl), replies in one response
  static const String chatEndpoint = '/chat';

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

  /// Application name displayed in UI
  static const String appName = 'FITRIX';

  /// First subtitle line on intro screen
  /// "The Fitness Matrix"
  static const String appSubtitle1 = 'The Fitness Matrix';

  /// Second subtitle line on intro screen
  /// "Based on Artificial intelligence"
  static const String appSubtitle2 = 'Based on Artificial intelligence';

  // ==========================================================================
  // FELIX AI ASSISTANT CONFIGURATION
  // ==========================================================================

  /// Name of the AI fitness coach
  static const String assistantName = 'Felix';

  /// Subtitle shown below Felix's name in chat header
  static const String assistantSubtitle = 'Your personal assistant';

  /// Initial greeting message from Felix (line 1)
  /// Displays when chat screen first opens
  static const String assistantGreeting =
      'Hey there!\nI\'m Felix, your personal AI coach here in Fitrix.';

  /// Introduction message from Felix (line 2)
  /// Explains Felix's purpose and capabilities
  static const String assistantIntro =
      'I\'ll help you train smarter, track your progress and stay motivated.';

  /// First question from Felix (line 3)
  /// Prompts user to select their main fitness goal
  static const String assistantQuestion =
      'So, tell me — what\'s your main goal right now?';

  // ==========================================================================
  // FITNESS GOALS (Quick Reply Options)
  // ==========================================================================

  /// Predefined fitness goals shown as quick reply chips
  /// Users can select one to start their fitness journey
  /// These are the first options Felix presents
  static const List<String> fitnessGoals = [
    'Build muscle and strength',       // Hypertrophy and strength training
    'Improve endurance and stamina',    // Cardio and aerobic fitness
    'Lose weight and get toned',        // Fat loss and body composition
    'Feel healthier and balanced',      // General wellness and lifestyle
    'Just track my progress',           // Monitoring without specific goal
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
  /// 2. Implement i18n translations (future feature)
  /// 3. Update language selection UI if needed
  static const Map<String, String> languages = {
    'ru': 'Русский',      // Russian
    'en': 'English',      // English
    'uz': 'O\'zbekcha',   // Uzbek
    'es': 'Espanol',      // Spanish (note: should be "Español" with tilde)
  };
}
