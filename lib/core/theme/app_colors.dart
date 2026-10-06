/// Application Color Palette
///
/// Defines all colors used throughout the FITRIX app for both light and dark themes.
/// Colors are organized by component type (background, text, buttons, etc.)
///
/// Usage:
/// - Light theme: Use `lightXxx` colors
/// - Dark theme: Use `darkXxx` colors
/// - Legacy code: Defaults to light colors for backwards compatibility
library;

import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ============================================================================
  // LIGHT THEME COLORS
  // ============================================================================

  /// Primary color for light theme (Black)
  /// Used for main UI elements like primary buttons and text
  static const Color lightPrimary = Color(0xFF000000);

  /// Secondary color for light theme (Blue, brand accent from the Figma design)
  /// Used for FITRIX logo highlighting and selected states
  static const Color lightSecondary = Color(0xFF009ED8);

  /// Main background color for light theme (White)
  /// Used for screen backgrounds
  static const Color lightBackground = Color(0xFFFFFFFF);

  /// Card background color for light theme (Light Gray)
  /// Used for elevated cards and containers
  static const Color lightCardBackground = Color(0xFFF5F5F5);

  /// Primary text color for light theme (Black)
  /// Used for headings and body text
  static const Color lightTextPrimary = Color(0xFF000000);

  /// Secondary text color for light theme (Gray)
  /// Used for less important text and labels
  static const Color lightTextSecondary = Color(0xFF666666);

  /// Hint text color for light theme (Light Gray)
  /// Used for placeholder text in input fields
  static const Color lightTextHint = Color(0xFF999999);

  /// Text color on dark backgrounds for light theme (White)
  /// Used for text on black buttons
  static const Color lightTextOnDark = Color(0xFFFFFFFF);

  /// Primary button color for light theme (Black)
  /// Used for main action buttons
  static const Color lightButtonPrimary = Color(0xFF000000);

  /// Selected button color for light theme (Blue)
  /// Used for active/selected buttons
  static const Color lightButtonSelected = Color(0xFF009ED8);

  /// Unselected button color for light theme (Light Gray)
  /// Used for inactive buttons
  static const Color lightButtonUnselected = Color(0xFFE8E8E8);

  /// User message bubble color for light theme (Black)
  /// Used for outgoing chat messages
  static const Color lightChatBubbleUser = Color(0xFF000000);

  /// Assistant message bubble color for light theme (Light Gray)
  /// Used for incoming messages from Felix
  static const Color lightChatBubbleAssistant = Color(0xFFF0F0F0);

  /// Chat text color for light theme (Black)
  /// Used for text inside chat bubbles
  static const Color lightChatBubbleText = Color(0xFF000000);

  /// Input field background for light theme (Light Gray)
  /// Used for text field backgrounds
  static const Color lightInputBackground = Color(0xFFF5F5F5);

  /// Input field border for light theme (Border Gray)
  /// Used for text field borders
  static const Color lightInputBorder = Color(0xFFE0E0E0);

  /// Divider color for light theme
  /// Used for separating UI elements
  static const Color lightDivider = Color(0xFFE0E0E0);

  // ============================================================================
  // DARK THEME COLORS
  // ============================================================================

  /// Primary color for dark theme (White)
  /// Used for main UI elements in dark mode
  static const Color darkPrimary = Color(0xFFFFFFFF);

  /// Secondary color for dark theme (Blue)
  /// Same as light theme for consistency
  static const Color darkSecondary = Color(0xFF009ED8);

  /// Main background color for dark theme (Pure Black)
  /// True black for OLED power savings
  static const Color darkBackground = Color(0xFF000000);

  /// Card background color for dark theme (Dark Gray)
  /// Used for elevated cards in dark mode
  static const Color darkCardBackground = Color(0xFF1C1C1E);

  /// Primary text color for dark theme (White)
  /// Used for headings and body text
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// Secondary text color for dark theme (Light Gray)
  /// Used for less important text
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  /// Hint text color for dark theme (Medium Gray)
  /// Used for placeholder text
  static const Color darkTextHint = Color(0xFF6C6C6C);

  /// Text color on dark backgrounds for dark theme (Black)
  /// Used for text on white buttons in dark mode
  static const Color darkTextOnDark = Color(0xFF000000);

  /// Primary button color for dark theme (White)
  /// Used for main action buttons
  static const Color darkButtonPrimary = Color(0xFFFFFFFF);

  /// Selected button color for dark theme (Blue)
  /// Same as light theme for consistency
  static const Color darkButtonSelected = Color(0xFF009ED8);

  /// Unselected button color for dark theme (Dark Gray)
  /// Used for inactive buttons
  static const Color darkButtonUnselected = Color(0xFF2C2C2E);

  /// User message bubble color for dark theme (White)
  /// Used for outgoing chat messages
  static const Color darkChatBubbleUser = Color(0xFFFFFFFF);

  /// Assistant message bubble color for dark theme (Dark Gray)
  /// Used for incoming messages from Felix
  static const Color darkChatBubbleAssistant = Color(0xFF1C1C1E);

  /// Chat text color for dark theme (White)
  /// Used for text inside chat bubbles
  static const Color darkChatBubbleText = Color(0xFFFFFFFF);

  /// Input field background for dark theme (Dark Gray)
  /// Used for text field backgrounds
  static const Color darkInputBackground = Color(0xFF1C1C1E);

  /// Input field border for dark theme (Border Gray)
  /// Used for text field borders
  static const Color darkInputBorder = Color(0xFF38383A);

  /// Divider color for dark theme
  /// Used for separating UI elements
  static const Color darkDivider = Color(0xFF38383A);

  // ============================================================================
  // SHARED COLORS (used in both themes)
  // ============================================================================

  /// Error color (Bright Red)
  /// Used for error messages and validation
  static const Color error = Color(0xFFFF453A);

  /// Success color (Green)
  /// Used for success messages and confirmations
  static const Color success = Color(0xFF32D74B);

  /// Warning color (Yellow)
  /// Used for warning messages
  static const Color warning = Color(0xFFFFD60A);

  // ============================================================================
  // BACKWARDS COMPATIBILITY
  // These defaults allow legacy code to work without changes
  // ============================================================================

  /// @deprecated Use lightPrimary or darkPrimary with theme detection
  static const Color primary = lightPrimary;

  /// @deprecated Use lightSecondary or darkSecondary with theme detection
  static const Color secondary = lightSecondary;

  /// @deprecated Use lightBackground or darkBackground with theme detection
  static const Color background = lightBackground;

  /// @deprecated Use lightCardBackground or darkCardBackground with theme detection
  static const Color cardBackground = lightCardBackground;

  /// @deprecated Use lightTextPrimary or darkTextPrimary with theme detection
  static const Color textPrimary = lightTextPrimary;

  /// @deprecated Use lightTextSecondary or darkTextSecondary with theme detection
  static const Color textSecondary = lightTextSecondary;

  /// @deprecated Use lightTextHint or darkTextHint with theme detection
  static const Color textHint = lightTextHint;

  /// @deprecated Use lightTextOnDark or darkTextOnDark with theme detection
  static const Color textOnDark = lightTextOnDark;

  /// @deprecated Use lightButtonPrimary or darkButtonPrimary with theme detection
  static const Color buttonPrimary = lightButtonPrimary;

  /// @deprecated Use lightButtonSelected or darkButtonSelected with theme detection
  static const Color buttonSelected = lightButtonSelected;

  /// @deprecated Use lightButtonUnselected or darkButtonUnselected with theme detection
  static const Color buttonUnselected = lightButtonUnselected;

  /// @deprecated Use lightChatBubbleUser or darkChatBubbleUser with theme detection
  static const Color chatBubbleUser = lightChatBubbleUser;

  /// @deprecated Use lightChatBubbleAssistant or darkChatBubbleAssistant with theme detection
  static const Color chatBubbleAssistant = lightChatBubbleAssistant;

  /// @deprecated Use lightChatBubbleText or darkChatBubbleText with theme detection
  static const Color chatBubbleText = lightChatBubbleText;

  /// @deprecated Use lightInputBackground or darkInputBackground with theme detection
  static const Color inputBackground = lightInputBackground;

  /// @deprecated Use lightInputBorder or darkInputBorder with theme detection
  static const Color inputBorder = lightInputBorder;

  /// @deprecated Use lightDivider or darkDivider with theme detection
  static const Color divider = lightDivider;
}
