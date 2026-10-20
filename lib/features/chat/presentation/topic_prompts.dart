import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Three questions worth asking in the topic's chat (quick replies).
List<String> topicPrompts(AppLocalizations l10n, AssistantTopic t) =>
    switch (t.id) {
      'gym' => [
          l10n.felixPromptGym1,
          l10n.felixPromptGym2,
          l10n.felixPromptGym3
        ],
      'fitness' => [
          l10n.felixPromptFitness1,
          l10n.felixPromptFitness2,
          l10n.felixPromptFitness3
        ],
      'running' => [
          l10n.felixPromptRunning1,
          l10n.felixPromptRunning2,
          l10n.felixPromptRunning3
        ],
      'cycling' => [
          l10n.felixPromptCycling1,
          l10n.felixPromptCycling2,
          l10n.felixPromptCycling3
        ],
      'football' => [
          l10n.felixPromptFootball1,
          l10n.felixPromptFootball2,
          l10n.felixPromptFootball3
        ],
      'winterSports' => [
          l10n.felixPromptWinter1,
          l10n.felixPromptWinter2,
          l10n.felixPromptWinter3
        ],
      'nutrition' => [
          l10n.felixPromptNutrition1,
          l10n.felixPromptNutrition2,
          l10n.felixPromptNutrition3
        ],
      'recovery' => [
          l10n.felixPromptRecovery1,
          l10n.felixPromptRecovery2,
          l10n.felixPromptRecovery3
        ],
      _ => [l10n.felixPromptApp1, l10n.felixPromptApp2, l10n.chatQuickPlanWeek],
    };

/// What the chat header says Felix can see for this topic.
String topicSees(AppLocalizations l10n, AssistantTopic t) => switch (t.id) {
      'nutrition' => l10n.felixSeesNutrition,
      'recovery' => l10n.felixSeesRecovery,
      _ => l10n.felixSeesPlan,
    };
