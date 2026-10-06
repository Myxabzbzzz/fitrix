import 'dart:convert';

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

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isQuickReply = false,
    this.isStreaming = false,
    this.isFailed = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
    bool? isFailed,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      sender: sender,
      timestamp: timestamp,
      isQuickReply: isQuickReply,
      isStreaming: isStreaming ?? this.isStreaming,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.name,
      'timestamp': timestamp.toIso8601String(),
      'isQuickReply': isQuickReply,
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
    );
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

  static List<ChatMessage> decodeMessages(String messagesJson) {
    final List<dynamic> decoded = jsonDecode(messagesJson);
    return decoded.map((m) => ChatMessage.fromJson(m)).toList();
  }
}
