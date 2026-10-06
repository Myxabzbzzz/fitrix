import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/data/workout_catalog.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';

/// The device side of sync: reads the synced data from local storage and
/// applies merge results through the same notifiers the UI watches, so
/// screens update right away.
class SyncLocal {
  SyncLocal(this._ref);

  final Ref _ref;

  SharedPreferences get prefs => _ref.read(sharedPreferencesProvider);

  /// User changes to synced data.
  Stream<void> get changes => _ref.read(localChangesProvider).stream;

  List<WorkoutTemplate> get plans => _ref.read(workoutTemplatesProvider);

  List<WorkoutTemplate> get tombstones =>
      _ref.read(workoutStorageProvider).loadDeletedTemplates();

  void applyPlans(
    List<WorkoutTemplate> plans,
    List<WorkoutTemplate> tombstones,
  ) =>
      _ref
          .read(workoutTemplatesProvider.notifier)
          .applySynced(plans, tombstones);

  List<CompletedWorkout> get history => _ref.read(workoutHistoryProvider);

  void applyHistory(List<CompletedWorkout> history) =>
      _ref.read(workoutHistoryProvider.notifier).applySynced(history);

  /// Stored (completed) messages of [topic]'s chat, oldest first.
  List<ChatMessage> chat(AssistantTopic topic) {
    final raw = prefs.getString(topic.historyKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      return ChatMessage.decodeMessages(raw);
    } catch (_) {
      return const [];
    }
  }

  void applyChat(AssistantTopic topic, List<ChatMessage> messages) {
    if (messages.isEmpty) {
      prefs.remove(topic.historyKey);
    } else {
      prefs.setString(topic.historyKey, ChatMessage.encodeMessages(messages));
    }
    // A chat that is open (or was opened) shows the new history at once;
    // others read it from storage when they open.
    final provider = chatMessagesProviderFor(topic);
    if (_ref.exists(provider)) {
      _ref.read(provider.notifier).applySynced(messages);
    }
  }

  /// Drops all synced data (it belongs to another account).
  void clear() {
    applyPlans(WorkoutCatalog.defaults, const []);
    applyHistory(const []);
    for (final topic in AssistantTopic.all) {
      prefs.remove(topic.conversationKey);
      applyChat(topic, const []);
    }
  }
}
