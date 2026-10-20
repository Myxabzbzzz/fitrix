import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// One Felix chat: the general app assistant, nutrition, recovery or a
/// personal trainer for a specific sport.
class AssistantTopic {
  /// Api id sent to the backend as `topic` (see the Felix hub topic list).
  final String id;

  /// Non-null for the six sport topics.
  final Sport? sport;

  const AssistantTopic._(this.id, [this.sport]);

  static const appApiTopic = 'app';

  static const app = AssistantTopic._(appApiTopic);
  static const gym = AssistantTopic._('gym', Sport.gym);
  static const fitness = AssistantTopic._('fitness', Sport.fitness);
  static const running = AssistantTopic._('running', Sport.running);
  static const cycling = AssistantTopic._('cycling', Sport.cycling);
  static const football = AssistantTopic._('football', Sport.football);
  static const winterSports =
      AssistantTopic._('winterSports', Sport.winterSports);
  static const nutrition = AssistantTopic._('nutrition');
  static const recovery = AssistantTopic._('recovery');

  /// Hub order.
  static List<AssistantTopic> get all => const [
        gym,
        fitness,
        running,
        cycling,
        football,
        winterSports,
        nutrition,
        recovery,
        app,
      ];

  static AssistantTopic forSport(Sport sport) =>
      all.firstWhere((t) => t.sport == sport);

  static AssistantTopic? fromId(String id) {
    for (final topic in all) {
      if (topic.id == id) return topic;
    }
    return null;
  }

  bool get isApp => id == appApiTopic;

  /// Sent to the backend as `topic` to pick Felix's persona.
  String get apiTopic => id;

  /// The app chat keeps the original keys (shared with onboarding).
  String get historyKey => isApp
      ? AppConstants.keyChatHistory
      : '${AppConstants.keyChatHistory}_$id';

  String get conversationKey => isApp
      ? AppConstants.keyConversationId
      : '${AppConstants.keyConversationId}_$id';

  @override
  bool operator ==(Object other) => other is AssistantTopic && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
