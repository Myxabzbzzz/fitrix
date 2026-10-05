# FITRIX Code Documentation

Complete guide to understanding the FITRIX Flutter application codebase.

## 📚 Table of Contents

1. [Project Structure](#project-structure)
2. [Core Files](#core-files)
3. [Features](#features)
4. [State Management](#state-management)
5. [Navigation](#navigation)
6. [Theming](#theming)
7. [Backend Integration](#backend-integration)
8. [Code Comments Guide](#code-comments-guide)

---

## 🏗️ Project Structure

```
lib/
├── core/                          # Shared utilities and configuration
│   ├── constants/
│   │   └── app_constants.dart     # ✅ All app-wide constants
│   ├── router/
│   │   └── app_router.dart        # ✅ Navigation configuration (go_router)
│   └── theme/
│       ├── app_colors.dart        # ✅ Color palette (light & dark themes)
│       └── app_theme.dart         # ✅ Material theme configuration
│
├── features/                      # Feature-based architecture
│   ├── intro/                     # Welcome screen
│   ├── language/                  # Language selection
│   ├── auth/                      # Authentication (mocked)
│   ├── profile/                   # User profile setup
│   └── chat/                      # AI chat with Felix
│
├── shared/                        # Shared widgets across features
│   └── widgets/
│
└── main.dart                      # ✅ App entry point

```

---

## 🔧 Core Files

### main.dart ✅
**Purpose:** Application entry point
**Key Responsibilities:**
- Initialize Flutter bindings
- Configure system UI (status bar)
- Set up Riverpod provider scope
- Configure light/dark theme switching

```dart
// Automatically switches between light and dark theme
themeMode: ThemeMode.system,
```

### app_constants.dart ✅
**Purpose:** Centralized constants
**Contains:**
- API configuration (backend URL, endpoints)
- SharedPreferences keys
- App text content
- Fitness goals list
- Supported languages

**Important:** Update `apiBaseUrl` with your backend IP address!

### app_colors.dart ✅
**Purpose:** Color palette definition
**Features:**
- Complete light theme colors (`lightXxx`)
- Complete dark theme colors (`darkXxx`)
- Shared colors (error, success, warning)
- Backwards compatibility for legacy code

**Usage Example:**
```dart
// Detect current theme
final isDark = Theme.of(context).brightness == Brightness.dark;

// Use appropriate color
color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
```

### app_theme.dart
**Purpose:** Material Design 3 theme configuration
**Provides:**
- `lightTheme`: White backgrounds, black text
- `darkTheme`: Black backgrounds, white text
- Consistent typography
- Input field styling
- Button styling

### app_router.dart
**Purpose:** Navigation setup using go_router
**Routes:**
- `/` → Intro Screen
- `/language` → Language Selection
- `/sign-in` → Email Sign-In
- `/profile` → Profile Setup
- `/chat` → AI Chat with Felix

---

## 🎯 Features

Each feature follows **Clean Architecture**:

```
feature_name/
├── data/
│   ├── models/          # Data transfer objects
│   ├── repositories/    # Data access layer
│   └── services/        # External API calls
├── domain/
│   ├── entities/        # Business objects
│   └── usecases/        # Business logic
└── presentation/
    ├── providers/       # Riverpod state management
    ├── screens/         # UI pages
    └── widgets/         # Reusable components
```

### 1. Intro Feature
**Screen:** `intro_screen.dart`
**Purpose:** Welcome screen with FITRIX branding
**Components:**
- FITRIX logo (blue "FI" + black "TRIX")
- Subtitle with highlighted letters
- "Start your journey" button

### 2. Language Feature
**Files:**
- `language_screen.dart` - UI
- `language_provider.dart` - State management
- `language_repository.dart` - Persistence

**Flow:**
1. User selects language
2. Provider updates state
3. Repository saves to SharedPreferences
4. Selection persists between app sessions

### 3. Auth Feature (Mock)
**Files:**
- `sign_in_screen.dart` - UI
- `auth_provider.dart` - State
- `auth_repository.dart` - Storage

**Note:** Authentication is MOCKED for demo purposes
- Any email address works
- No real validation
- Just stores email in SharedPreferences

### 4. Profile Feature
**Files:**
- `profile_screen.dart` - UI
- `profile_provider.dart` - State
- `profile_repository.dart` - Storage
- `user_profile.dart` - Data model

**Collected Data:**
- Name, Surname
- Age, Weight, Height
- All stored locally

### 5. Chat Feature
**Files:**
- `chat_screen.dart` - Main chat UI
- `chat_bubble.dart` - Message display widget
- `quick_reply_chip.dart` - Selection buttons
- `chat_provider.dart` - State management
- `chat_repository.dart` - Message persistence
- `chat_api_service.dart` - Backend communication
- `chat_message.dart` - Message model

**Key Features:**
- Real-time chat with Felix (AI)
- Message history persistence
- Quick reply buttons
- Backend integration with Ollama
- Mock responses when backend unavailable

---

## 🔄 State Management

Using **Riverpod** for reactive state management.

### Provider Types Used:

```dart
// 1. Provider - Read-only, immutable
final repositoryProvider = Provider<Repository>((ref) => Repository());

// 2. StateNotifierProvider - Mutable state with business logic
final stateProvider = StateNotifierProvider<Notifier, State>((ref) {
  return Notifier();
});

// 3. StateProvider - Simple mutable state
final isTypingProvider = StateProvider<bool>((ref) => false);
```

### Example: Language Selection

```dart
// Provider definition
final selectedLanguageProvider =
    StateNotifierProvider<LanguageNotifier, String?>((ref) {
  return LanguageNotifier(ref.read(languageRepositoryProvider));
});

// Usage in UI
final language = ref.watch(selectedLanguageProvider);

// Update state
ref.read(selectedLanguageProvider.notifier).setLanguage('en');
```

---

## 🧭 Navigation

Using **go_router** for type-safe navigation.

### Navigate to a route:
```dart
// Push new route
context.go('/language');

// Replace current route
context.replace('/chat');

// Go back
context.pop();
```

### Route parameters (future enhancement):
```dart
GoRoute(
  path: '/chat/:conversationId',
  builder: (context, state) {
    final id = state.pathParameters['conversationId'];
    return ChatScreen(conversationId: id);
  },
),
```

---

## 🎨 Theming

### Light Theme
- Background: `#FFFFFF` (White)
- Text: `#000000` (Black)
- Buttons: `#000000` (Black)
- Accent: `#4A9FFF` (Blue)

### Dark Theme
- Background: `#000000` (Pure Black)
- Text: `#FFFFFF` (White)
- Buttons: `#FFFFFF` (White)
- Accent: `#4A9FFF` (Blue)

### Automatic Theme Switching
```dart
// App automatically follows system theme
themeMode: ThemeMode.system,

// Detect current theme in widgets
final isDark = Theme.of(context).brightness == Brightness.dark;
```

---

## 🌐 Backend Integration

### Architecture Flow
```
Flutter App → HTTP Request → Backend API → Ollama LLM → Response
```

### API Service (`chat_api_service.dart`)

**Endpoint:** `POST /chat`

**Request:**
```json
{
  "message": "Hello Felix!",
  "conversationId": "uuid-v4-string"
}
```

**Response:**
```json
{
  "reply": "Hey there! How can I help you today?"
}
```

### Error Handling
- Network errors → Shows mock response
- Timeout → Falls back to mock
- 500 errors → Displays error message

### Mock Responses
When backend is unavailable, app provides intelligent mock responses:
- Recognizes keywords (muscle, gym, etc.)
- Provides contextual replies
- Allows full UI testing without backend

---

## 📝 Code Comments Guide

### Comment Levels

#### 1. File-Level Comments (Top of file)
```dart
/// Chat Message Model
///
/// Represents a single message in the chat conversation.
/// Used for both user messages and AI assistant responses.
///
/// Properties:
/// - id: Unique message identifier
/// - content: Message text
/// - sender: Who sent the message (user/assistant)
/// - timestamp: When message was sent
```

#### 2. Class-Level Comments
```dart
/// State notifier for managing chat messages
///
/// Responsibilities:
/// - Load messages from local storage
/// - Send messages to backend
/// - Add messages to conversation
/// - Persist chat history
class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
```

#### 3. Function-Level Comments
```dart
/// Sends a message and gets AI response
///
/// Parameters:
/// - content: The message text to send
/// - isQuickReply: Whether this was a button tap or typed message
///
/// Flow:
/// 1. Add user message to state
/// 2. Save to local storage
/// 3. Call backend API
/// 4. Add AI response to state
/// 5. Save updated history
Future<void> sendMessage(String content, {bool isQuickReply = false}) async {
```

#### 4. Inline Comments
```dart
// Check if we're in dark mode to use appropriate colors
final isDark = Theme.of(context).brightness == Brightness.dark;

// User messages go on the right, assistant on the left
alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
```

### What to Comment

✅ **DO Comment:**
- Why something is done (not just what)
- Complex business logic
- Workarounds or hacks
- External API contracts
- State management flows
- Important constants
- Public APIs

❌ **DON'T Comment:**
- Obvious code (e.g., `// Set color to blue`)
- Redundant explanations
- Commented-out code (delete it!)

---

## 🔍 Finding Code

### By Feature
```bash
# Find all language-related files
find lib/features/language -type f -name "*.dart"

# Find all providers
find lib -name "*_provider.dart"

# Find all screens
find lib -name "*_screen.dart"
```

### By Pattern
```bash
# Find all Riverpod providers
grep -r "Provider<" lib/

# Find all API calls
grep -r "http.post\|dio.post" lib/

# Find SharedPreferences usage
grep -r "SharedPreferences" lib/
```

---

## 🚀 Quick Reference

### Adding a New Screen

1. **Create screen file:**
   ```dart
   lib/features/my_feature/presentation/screens/my_screen.dart
   ```

2. **Add route:**
   ```dart
   // lib/core/router/app_router.dart
   GoRoute(
     path: '/my-screen',
     name: 'myScreen',
     pageBuilder: (context, state) => MaterialPage(
       child: const MyScreen(),
     ),
   ),
   ```

3. **Navigate to it:**
   ```dart
   context.go('/my-screen');
   ```

### Adding State Management

1. **Create repository:**
   ```dart
   class MyRepository {
     Future<void> saveData(String data) async {
       final prefs = await SharedPreferences.getInstance();
       await prefs.setString('my_key', data);
     }
   }
   ```

2. **Create provider:**
   ```dart
   final myProvider = StateNotifierProvider<MyNotifier, String>((ref) {
     return MyNotifier();
   });
   ```

3. **Use in UI:**
   ```dart
   final data = ref.watch(myProvider);
   ref.read(myProvider.notifier).updateData('new value');
   ```

---

## 📖 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Riverpod Guide](https://riverpod.dev)
- [go_router Package](https://pub.dev/packages/go_router)
- [Material Design 3](https://m3.material.io/)

---

## 🤝 Contributing

When adding new code:
1. Follow existing file structure
2. Add comprehensive comments
3. Use consistent naming
4. Update this documentation
5. Test with both light and dark themes

---

**Last Updated:** 2025-12-31
**Maintainer:** FITRIX Development Team
