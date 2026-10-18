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

  /// Synced documents: 'kind/docId' -> hash of the version both sides
  /// agreed on. A local doc with another hash (or none) is unsynced.
  Map<String, String> docs;

  /// Per kind: server time of the newest document of that kind merged. A
  /// kind without an entry is pulled in full.
  Map<String, DateTime> docsCursors;

  /// Documents deleted by the user: 'kind/docId' -> ms when deleted. Kept
  /// until the deletion is on the server.
  Map<String, int> docTombstones;

  SyncState({
    this.owner,
    Map<String, PlanVersion>? plans,
    Set<String>? history,
    Set<String>? chat,
    this.plansCursor,
    this.historyCursor,
    this.chatCursor,
    Map<String, String>? docs,
    Map<String, DateTime>? docsCursors,
    Map<String, int>? docTombstones,
  })  : docs = docs ?? {},
        docsCursors = docsCursors ?? {},
        docTombstones = docTombstones ?? {},
        plans = plans ?? {},
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
        docs: {
          for (final e in ((json['docs'] as Map?) ?? const {}).entries)
            e.key as String: e.value as String,
        },
        docsCursors: {
          for (final e in ((json['docsCursors'] as Map?) ?? const {}).entries)
            if (_date(e.value) != null) e.key as String: _date(e.value)!,
        },
        docTombstones: {
          for (final e in ((json['docTombstones'] as Map?) ?? const {}).entries)
            e.key as String: e.value as int,
        },
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
        'docs': docs,
        'docsCursors': {
          for (final e in docsCursors.entries)
            e.key: e.value.toUtc().toIso8601String(),
        },
        'docTombstones': docTombstones,
      }),
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
