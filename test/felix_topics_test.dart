import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/topic_labels.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

Future<ProviderContainer> _container(
  Map<String, Object> stored, {
  String language = 'en',
}) async {
  SharedPreferences.setMockInitialValues(
      {...stored, AppConstants.keyLanguage: language});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<List<ChatMessage>> _messages(
  ProviderContainer c,
  AssistantTopic topic,
) async {
  final provider = chatMessagesProviderFor(topic);
  c.listen(provider, (_, __) {});
  while (c.read(provider).valueOrNull == null) {
    await Future<void>.delayed(Duration.zero);
  }
  return c.read(provider).requireValue;
}

void main() {
  test('nine topics in hub order', () {
    expect(AssistantTopic.all.map((t) => t.id), [
      'gym',
      'fitness',
      'running',
      'cycling',
      'football',
      'winterSports',
      'nutrition',
      'recovery',
      'app',
    ]);
    expect(AssistantTopic.all.map((t) => t.apiTopic),
        AssistantTopic.all.map((t) => t.id));
  });

  test('storage keys', () {
    expect(AssistantTopic.app.historyKey, 'chat_history');
    expect(AssistantTopic.app.conversationKey, 'conversation_id');
    expect(AssistantTopic.forSport(Sport.gym).historyKey, 'chat_history_gym');
    expect(AssistantTopic.forSport(Sport.winterSports).conversationKey,
        'conversation_id_winterSports');
    expect(AssistantTopic.nutrition.historyKey, 'chat_history_nutrition');
    expect(AssistantTopic.recovery.conversationKey, 'conversation_id_recovery');
  });

  test('fromId and forSport', () {
    expect(AssistantTopic.fromId('recovery'), AssistantTopic.recovery);
    expect(AssistantTopic.fromId('chess'), isNull);
    for (final sport in Sport.values) {
      expect(AssistantTopic.forSport(sport).sport, sport);
      expect(AssistantTopic.forSport(sport).id, sport.name);
    }
    expect(AssistantTopic.app.isApp, isTrue);
    expect(AssistantTopic.nutrition.isApp, isFalse);
  });

  test('a stored gym history loads unchanged', () async {
    final stored = ChatMessage.encodeMessages([
      ChatMessage(
        id: 'g1',
        content: 'old gym chat',
        sender: MessageSender.user,
        timestamp: DateTime.utc(2026, 10, 1),
      ),
    ]);
    final c = await _container({'chat_history_gym': stored});
    final messages = await _messages(c, AssistantTopic.forSport(Sport.gym));
    expect(messages.map((m) => m.content), ['old gym chat']);
  });

  test('a fresh nutrition chat greets in the app language', () async {
    final c = await _container({}, language: 'ru');
    final messages = await _messages(c, AssistantTopic.nutrition);
    final l10n = await AppLocalizations.delegate.load(const Locale('ru'));
    expect(messages.map((m) => m.content), [
      l10n.felixTopicGreeting(l10n.felixTopicNutrition),
      l10n.felixTopicGreetingHint,
    ]);
    expect(messages.first.content, startsWith('Привет'));
  });

  test('titles and subtitles exist in every locale', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final topic in AssistantTopic.all) {
        expect(topicTitle(l10n, topic), isNotEmpty, reason: '$locale $topic');
        expect(topicSubtitle(l10n, topic), isNotEmpty,
            reason: '$locale $topic');
      }
    }
  });
}
