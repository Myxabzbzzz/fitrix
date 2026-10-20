import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Localized topic name: "Gym", "Nutrition", "App assistant".
String topicTitle(AppLocalizations l10n, AssistantTopic t) {
  final sport = t.sport;
  if (sport != null) return sport.localizedLabel(l10n);
  return switch (t.id) {
    'nutrition' => l10n.felixTopicNutrition,
    'recovery' => l10n.felixTopicRecovery,
    _ => l10n.felixTopicApp,
  };
}

/// One-line description of what the topic covers (hub tile).
String topicSubtitle(AppLocalizations l10n, AssistantTopic t) => switch (t.id) {
      'gym' => l10n.felixTopicSubGym,
      'fitness' => l10n.felixTopicSubFitness,
      'running' => l10n.felixTopicSubRunning,
      'cycling' => l10n.felixTopicSubCycling,
      'football' => l10n.felixTopicSubFootball,
      'winterSports' => l10n.felixTopicSubWinterSports,
      'nutrition' => l10n.felixTopicSubNutrition,
      'recovery' => l10n.felixTopicSubRecovery,
      _ => l10n.felixTopicSubApp,
    };
