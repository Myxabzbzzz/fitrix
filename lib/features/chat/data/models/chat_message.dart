import 'dart:convert';

import 'package:fitrix/features/chat/data/models/chat_action.dart';

enum MessageSender { user, assistant }

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isQuickReply;

  /// Assistant reply that is still being streamed in. Not persisted.
  final bool isStreaming;

  /// Assistant reply that failed; tapping it retries. Not persisted.
  final bool isFailed;

  /// Change Felix proposes with this reply. Kept with the message on this
  /// device only: never sent as history and not part of the synced row.
  final ChatAction? action;

  /// The user confirmed [action] and it was applied.
  final bool actionApplied;

  /// What applying [action] changed, frozen at apply time so the card keeps
  /// saying the same thing later (weight: `{from, to}`).
  final Map<String, num>? appliedResult;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isQuickReply = false,
    this.isStreaming = false,
    this.isFailed = false,
    this.action,
    this.actionApplied = false,
    this.appliedResult,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    bool? isFailed,
    ChatAction? action,
    bool? actionApplied,
    Map<String, num>? appliedResult,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      sender: sender,
      timestamp: timestamp,
      isQuickReply: isQuickReply,
      isStreaming: isStreaming ?? this.isStreaming,
      isFailed: isFailed ?? this.isFailed,
      action: action ?? this.action,
      actionApplied: actionApplied ?? this.actionApplied,
      appliedResult: appliedResult ?? this.appliedResult,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'isQuickReply': isQuickReply,
      if (action != null) 'action': action!.toJson(),
      if (action != null && actionApplied) 'actionApplied': true,
      if (action != null && actionApplied && appliedResult != null)
        'appliedResult': appliedResult,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      content: json['content'],
      sender: MessageSender.values.firstWhere(
        (e) => e.name == json['sender'],
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isQuickReply: json['isQuickReply'] ?? false,
      action: ChatAction.tryParse(json['action']),
      actionApplied: json['actionApplied'] == true,
      appliedResult: _result(json['appliedResult']),
    );
  }

  static Map<String, num>? _result(Object? raw) {
    if (raw is! Map) return null;
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is num) e.key as String: e.value as num,
    };
  }

  /// Only completed messages are stored; in-flight and failed replies are
  /// transient UI state.
  static String encodeMessages(List<ChatMessage> messages) {
    return jsonEncode(
      messages
          .where((m) => !m.isStreaming && !m.isFailed)
          .map((m) => m.toJson())
          .toList(),
    );
  }

  /// The conversation context sent to the backend as `history`: the last
  /// [limit] completed messages of [messages] (oldest first) as
  /// `{role, content}`. Failed, still-streaming and empty messages are left
  /// out, since Felix never really said them.
  static List<Map<String, String>> toApiHistory(
    Iterable<ChatMessage> messages, {
    int limit = maxApiHistory,
  }) {
    final turns = [
      for (final m in messages)
        if (!m.isFailed && !m.isStreaming && m.content.trim().isNotEmpty)
          {
            'role': m.sender == MessageSender.user ? 'user' : 'assistant',
            'content': m.content.trim(),
          },
    ];
    return turns.length > limit ? turns.sublist(turns.length - limit) : turns;
  }

  /// Matches the backend's cap on history turns.
  static const maxApiHistory = 20;

  static List<ChatMessage> decodeMessages(String messagesJson) {
    final List<dynamic> decoded = jsonDecode(messagesJson);
    return decoded.map((m) => ChatMessage.fromJson(m)).toList();
  }
}
