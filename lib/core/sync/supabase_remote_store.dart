import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitrix/core/sync/remote_store.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';

/// [RemoteStore] on the Supabase tables from
/// `supabase/migrations/*_initial_schema.sql`. Row level security limits
/// every query to the signed-in user's rows; `user_id` is still set on
/// writes because the insert policies check it.
class SupabaseRemoteStore implements RemoteStore {
  SupabaseRemoteStore(this._client);

  final SupabaseClient _client;

  /// Rows per request (the API returns at most `max_rows` = 1000).
  static const pageSize = 1000;

  /// Rows per write request.
  static const batchSize = 500;

  @override
  Future<List<RemotePlan>> fetchPlans(String userId, {DateTime? since}) async {
    final rows = await _fetch('workout_templates', userId, 'updated_at', since);
    return [for (final row in rows) _planFromRow(row)];
  }

  @override
  Future<Map<String, DateTime>> upsertPlans(
    String userId,
    List<RemotePlan> plans,
  ) async {
    final result = <String, DateTime>{};
    for (final rows in _chunks([for (final p in plans) _planRow(userId, p)])) {
      final stored = await _client
          .from('workout_templates')
          .upsert(rows, onConflict: 'user_id,id')
          .select('id, updated_at');
      for (final row in stored) {
        result[row['id'] as String] =
            DateTime.parse(row['updated_at'] as String);
      }
    }
    return result;
  }

  @override
  Future<List<RemoteRow<CompletedWorkout>>> fetchHistory(
    String userId, {
    DateTime? since,
  }) async {
    final rows =
        await _fetch('completed_workouts', userId, 'created_at', since);
    return [
      for (final row in rows)
        RemoteRow(
          CompletedWorkout(
            id: row['id'] as String,
            templateId: row['template_id'] as String,
            name: row['name'] as String,
            sport: Sport.fromName(row['sport'] as String),
            startedAt: DateTime.parse(row['started_at'] as String).toLocal(),
            finishedAt: DateTime.parse(row['finished_at'] as String).toLocal(),
            exercises: _exercises(row['exercises']),
          ),
          DateTime.parse(row['created_at'] as String),
        ),
    ];
  }

  @override
  Future<Set<String>> insertHistory(
    String userId,
    List<CompletedWorkout> workouts,
  ) =>
      _insert('completed_workouts', [
        for (final w in workouts)
          {
            'id': w.id,
            'user_id': userId,
            'template_id': _clip(w.templateId, 100),
            'name': _name(w.name),
            'sport': w.sport.name,
            'started_at': w.startedAt.toUtc().toIso8601String(),
            'finished_at': (w.finishedAt.isBefore(w.startedAt)
                    ? w.startedAt
                    : w.finishedAt)
                .toUtc()
                .toIso8601String(),
            'exercises': [for (final e in w.exercises) e.toJson()],
          },
      ]);

  @override
  Future<List<RemoteRow<ChatRecord>>> fetchChat(
    String userId, {
    DateTime? since,
  }) async {
    final rows = await _fetch('chat_messages', userId, 'created_at', since);
    return [
      for (final row in rows)
        RemoteRow(
          ChatRecord(
            row['topic'] as String,
            ChatMessage(
              id: row['id'] as String,
              content: row['content'] as String,
              sender: row['role'] == 'user'
                  ? MessageSender.user
                  : MessageSender.assistant,
              timestamp: DateTime.parse(row['sent_at'] as String).toLocal(),
              isQuickReply: row['is_quick_reply'] as bool? ?? false,
            ),
          ),
          DateTime.parse(row['created_at'] as String),
        ),
    ];
  }

  @override
  Future<Set<String>> insertChat(String userId, List<ChatRecord> messages) =>
      _insert('chat_messages', [
        for (final r in messages)
          {
            'id': r.message.id,
            'user_id': userId,
            'topic': r.topic,
            'role':
                r.message.sender == MessageSender.user ? 'user' : 'assistant',
            'content': _clip(r.message.content, 8000),
            'is_quick_reply': r.message.isQuickReply,
            'sent_at': r.message.timestamp.toUtc().toIso8601String(),
          },
      ]);

  /// All of the user's rows in [table] with [timeColumn] after [since],
  /// oldest first, page by page.
  Future<List<Map<String, dynamic>>> _fetch(
    String table,
    String userId,
    String timeColumn,
    DateTime? since,
  ) async {
    final all = <Map<String, dynamic>>[];
    for (var from = 0;; from += pageSize) {
      var query = _client.from(table).select().eq('user_id', userId);
      if (since != null) {
        query = query.gt(timeColumn, since.toUtc().toIso8601String());
      }
      final page = await query
          .order(timeColumn, ascending: true)
          .order('id', ascending: true)
          .range(from, from + pageSize - 1);
      all.addAll(page);
      if (page.length < pageSize) return all;
    }
  }

  /// Inserts [rows], skipping ids already stored. If a batch is rejected
  /// (e.g. one bad row) its rows are retried one by one so a single row
  /// can't hold up the rest; rows that still fail stay unsynced.
  Future<Set<String>> _insert(
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    final stored = <String>{};
    for (final batch in _chunks(rows)) {
      try {
        await _client
            .from(table)
            .upsert(batch, onConflict: 'id', ignoreDuplicates: true);
        stored.addAll(batch.map((r) => r['id'] as String));
      } on PostgrestException catch (e) {
        // Only bad data (Postgres classes 22 / 23) is worth splitting up;
        // auth, permission or server errors fail the whole sync for a retry.
        final code = e.code ?? '';
        if (!code.startsWith('22') && !code.startsWith('23')) rethrow;
        if (batch.length == 1) {
          debugPrint('Sync: $table row ${batch.single['id']} rejected: $e');
          continue;
        }
        for (final row in batch) {
          stored.addAll(await _insert(table, [row]));
        }
      }
    }
    return stored;
  }

  static Iterable<List<T>> _chunks<T>(List<T> items) sync* {
    for (var i = 0; i < items.length; i += batchSize) {
      yield items.sublist(i, min(i + batchSize, items.length));
    }
  }

  static Map<String, dynamic> _planRow(String userId, RemotePlan plan) {
    final t = plan.template;
    return {
      'user_id': userId,
      'id': t.id,
      'sport': t.sport.name,
      'name': _name(t.name),
      'focus': _clip(t.focus, 100),
      'estimated_minutes': t.estimatedDuration.inMinutes.clamp(0, 1440),
      'exercises': [for (final e in t.exercises) e.toJson()],
      'position': plan.position,
      'deleted_at': t.deletedAt?.toUtc().toIso8601String(),
    };
  }

  static RemotePlan _planFromRow(Map<String, dynamic> row) {
    final deletedAt = row['deleted_at'] as String?;
    return RemotePlan(
      WorkoutTemplate(
        id: row['id'] as String,
        sport: Sport.fromName(row['sport'] as String),
        name: row['name'] as String,
        focus: row['focus'] as String,
        estimatedDuration: Duration(minutes: row['estimated_minutes'] as int),
        exercises: _exercises(row['exercises']),
        updatedAt: DateTime.parse(row['updated_at'] as String),
        deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt),
      ),
      position: row['position'] as int? ?? 0,
    );
  }

  static List<Exercise> _exercises(Object? json) => [
        for (final e in json as List)
          Exercise.fromJson(e as Map<String, dynamic>),
      ];

  static String _clip(String text, int max) =>
      text.length <= max ? text : text.substring(0, max);

  /// Names must be 1-100 characters.
  static String _name(String name) =>
      name.trim().isEmpty ? 'Workout' : _clip(name, 100);
}
