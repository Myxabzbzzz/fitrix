import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// One entry of Felix's "All chats" list: the general app assistant or a
/// personal trainer for a specific sport.
class AssistantTopic {
  /// null for the general "Felix - App assistant" chat.
  final Sport? sport;

  const AssistantTopic._(this.sport);

  static const app = AssistantTopic._(null);

  static List<AssistantTopic> get all => [
        app,
        for (final sport in Sport.values) AssistantTopic._(sport),
      ];

  bool get isApp => sport == null;

  /// Label in the "All chats" drawer.
  String get menuLabel => isApp ? 'Felix - App assistant' : sport!.label;

  /// Title in the chat header.
  String get title => isApp
      ? AppConstants.assistantName
      : '${AppConstants.assistantName} - ${sport!.label}';

  String get subtitle =>
      isApp ? AppConstants.assistantSubtitle : 'Your personal trainer';

  /// Sent to the backend as `topic` to pick Felix's persona: "app" for the
  /// general assistant, otherwise the sport's name (e.g. "gym", "running").
  String get apiTopic => isApp ? appApiTopic : sport!.name;

  static const appApiTopic = 'app';

  String get historyKey => isApp
      ? AppConstants.keyChatHistory
      : '${AppConstants.keyChatHistory}_${sport!.name}';

  String get conversationKey => isApp
      ? AppConstants.keyConversationId
      : '${AppConstants.keyConversationId}_${sport!.name}';

  List<String> get greeting => isApp
      ? const [
          AppConstants.assistantGreeting,
          AppConstants.assistantIntro,
          AppConstants.assistantQuestion,
        ]
      : [
          'Hey! I\'m Felix, your ${sport!.label.toLowerCase()} trainer.',
          'Ask me to build a plan, adjust today\'s workout or explain '
              'an exercise.',
        ];

  @override
  bool operator ==(Object other) =>
      other is AssistantTopic && other.sport == sport;

  @override
  int get hashCode => sport.hashCode;
}
