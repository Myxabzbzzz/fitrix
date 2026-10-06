import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The version of a plan both this device and the server last agreed on.
/// Times are microseconds since epoch.
class PlanVersion {
  /// The plan's local `updatedAt` at that point (null for built-in or
  /// pre-sync plans that had none).
  final int? local;

  /// The server's `updated_at` for that version.
  final int server;

  const PlanVersion({required this.local, required this.server});

  List<int?> toJson() => [local, server];

  factory PlanVersion.fromJson(List<dynamic> json) =>
      PlanVersion(local: json[0] as int?, server: json[1] as int);
}

/// What this device knows about the server, stored next to the data it
/// describes (so signing out, which clears storage, also resets it).
///
/// Together with the local data this *is* the retry queue: anything local
/// that isn't recorded here as synced gets pushed on the next sync.
class SyncState {
  /// The account the local data was last synced with.
  String? owner;

  /// Plan id -> last synced version. A plan whose `updatedAt` differs from
  /// its entry (or has none) has unsynced changes.
  Map<String, PlanVersion> plans;

  /// Ids of finished workouts / chat messages known to be on the server.
  Set<String> history;
  Set<String> chat;

  /// Latest server time seen per table; the next pull starts from there.
  /// Null until the first (full) pull.
  DateTime? plansCursor;
  DateTime? historyCursor;
  DateTime? chatCursor;

  SyncState({
    this.owner,
    Map<String, PlanVersion>? plans,
    Set<String>? history,
    Set<String>? chat,
    this.plansCursor,
    this.historyCursor,
    this.chatCursor,
  })  : plans = plans ?? {},
        history = history ?? {},
        chat = chat ?? {};

  static const storageKey = 'sync_state';

  static SyncState load(SharedPreferences prefs) {
    final raw = prefs.getString(storageKey);
    if (raw == null) return SyncState();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return SyncState(
        owner: json['owner'] as String?,
        plans: {
          for (final e in (json['plans'] as Map<String, dynamic>).entries)
            e.key: PlanVersion.fromJson(e.value as List<dynamic>),
        },
        history: {...(json['history'] as List).cast<String>()},
        chat: {...(json['chat'] as List).cast<String>()},
        plansCursor: _date(json['plansCursor']),
        historyCursor: _date(json['historyCursor']),
        chatCursor: _date(json['chatCursor']),
      );
    } catch (e) {
      // Losing this only means a full pull and re-push (both idempotent).
      debugPrint('Discarding unreadable sync state: $e');
      return SyncState();
    }
  }

  void save(SharedPreferences prefs) {
    prefs.setString(
      storageKey,
      jsonEncode({
        'owner': owner,
        'plans': {for (final e in plans.entries) e.key: e.value.toJson()},
        'history': history.toList(),
        'chat': chat.toList(),
        'plansCursor': plansCursor?.toUtc().toIso8601String(),
        'historyCursor': historyCursor?.toUtc().toIso8601String(),
        'chatCursor': chatCursor?.toUtc().toIso8601String(),
      }),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
