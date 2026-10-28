import 'dart:convert';

import 'package:fitrix/features/chat/data/models/chat_action.dart';

enum MessageSender { user, assistant }

/// Why Felix couldn't answer a message. The chat shows it localized next to
/// the question, with a retry.
enum ChatFailure {
  /// The backend can't be reached or can't answer right now.
  unavailable,

  /// The reply stopped before it was complete (connection lost, app closed).
  interrupted,

  /// The backend sent something that isn't a reply.
  unreadable,

  /// The access token was rejected.
  signInAgain,

  /// Too many messages in a short time.
  tooFast,

  /// The attached photo is missing or too large.
  photoUnavailable,
}

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isQuickReply;

  /// Assistant reply that is still being streamed in. Not persisted.
  final bool isStreaming;

  /// Why Felix didn't answer this user message; the chat shows it with a
  /// retry. Not persisted: a stored question with no reply after it is
  /// marked [ChatFailure.interrupted] when the chat loads.
  final ChatFailure? failure;

  bool get isFailed => failure != null;

  /// Photo the user attached (file in the app's documents dir). Kept on this
  /// device only: not synced and never part of the history sent to Felix.
  final String? imagePath;

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
    this.failure,
    this.imagePath,
    this.action,
    this.actionApplied = false,
    this.appliedResult,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    ChatFailure? failure,
    bool clearFailure = false,
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
      failure: clearFailure ? null : failure ?? this.failure,
      imagePath: imagePath,
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
      if (imagePath != null) 'imagePath': imagePath,
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
      imagePath: json['imagePath'] as String?,
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

  /// Only completed messages are stored; a reply still streaming is
  /// transient UI state. A question Felix failed to answer is stored as
  /// asked (the failure itself is not).
  static String encodeMessages(List<ChatMessage> messages) {
    return jsonEncode(
      messages.where((m) => !m.isStreaming).map((m) => m.toJson()).toList(),
    );
  }

  /// The conversation context sent to the backend as `history`: the last
  /// [limit] completed messages of [messages] (oldest first) as
  /// `{role, content}`. Still-streaming and empty messages are left out,
  /// since Felix never really said them.
  static List<Map<String, String>> toApiHistory(
    Iterable<ChatMessage> messages, {
    int limit = maxApiHistory,
  }) {
    final turns = [
      for (final m in messages)
        if (!m.isStreaming && m.content.trim().isNotEmpty)
          {
            'role': m.sender == MessageSender.user ? 'user' : 'assistant',
            'content': m.content.trim(),
          },
    ];
    return turns.length > limit ? turns.sublist(turns.length - limit) : turns;
  }

  /// [messages] with a last question that has no reply marked
  /// [ChatFailure.interrupted] (the app was closed or the account switched
  /// while Felix replied), so the chat offers a retry. Unchanged when the
  /// chat ends with Felix, a reply in flight or an already failed question.
  static List<ChatMessage> markUnanswered(List<ChatMessage> messages) {
    if (messages.isEmpty) return messages;
    final last = messages.last;
    if (last.sender != MessageSender.user || last.isFailed) return messages;
    return [
      ...messages.take(messages.length - 1),
      last.copyWith(failure: ChatFailure.interrupted),
    ];
  }

  /// Matches the backend's cap on history turns.
  static const maxApiHistory = 20;

  static List<ChatMessage> decodeMessages(String messagesJson) {
    final List<dynamic> decoded = jsonDecode(messagesJson);
    return decoded.map((m) => ChatMessage.fromJson(m)).toList();
  }
}
