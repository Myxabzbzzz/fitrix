import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// A plan as stored on the server. On a pulled plan `template.updatedAt` is
/// the server's last-change time and `template.deletedAt` marks a deletion.
class RemotePlan {
  final WorkoutTemplate template;

  /// Index in the user's plan list (keeps the order across devices).
  final int position;

  const RemotePlan(this.template, {this.position = 0});

  String get id => template.id;
  bool get isDeleted => template.deletedAt != null;

  /// Server time of the last change (only meaningful on pulled plans).
  DateTime get updatedAt => template.updatedAt!;
}

/// A pulled append-only row and the server time it was stored at.
class RemoteRow<T> {
  final T value;
  final DateTime serverTime;

  const RemoteRow(this.value, this.serverTime);
}

/// A chat message and the Felix chat it belongs to
/// (`AssistantTopic.apiTopic`: 'app' or a sport name).
class ChatRecord {
  final String topic;
  final ChatMessage message;

  const ChatRecord(this.topic, this.message);
}

/// The server side of sync, for one signed-in user. Implemented with
/// Supabase in the app and in memory in tests.
///
/// Fetches return rows changed after [since] (all rows when null), oldest
/// first. Writes are idempotent so a retried push is harmless.
abstract class RemoteStore {
  Future<List<RemotePlan>> fetchPlans(String userId, {DateTime? since});

  /// Inserts or overwrites [plans] (tombstones included). Returns the
  /// server's new `updatedAt` of every plan that was stored.
  Future<Map<String, DateTime>> upsertPlans(
    String userId,
    List<RemotePlan> plans,
  );

  Future<List<RemoteRow<CompletedWorkout>>> fetchHistory(
    String userId, {
    DateTime? since,
  });

  /// Stores [workouts] that aren't on the server yet (existing ids are left
  /// alone). Returns the ids now known to be on the server.
  Future<Set<String>> insertHistory(
    String userId,
    List<CompletedWorkout> workouts,
  );

  Future<List<RemoteRow<ChatRecord>>> fetchChat(
    String userId, {
    DateTime? since,
  });

  /// Like [insertHistory], for chat messages.
  Future<Set<String>> insertChat(String userId, List<ChatRecord> messages);
}
