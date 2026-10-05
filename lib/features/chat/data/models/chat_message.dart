import 'dart:convert';

enum MessageSender { user, assistant }

class ChatMessage {
  final String id;
  final String content;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isQuickReply;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isQuickReply = false,
  });

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

  static String encodeMessages(List<ChatMessage> messages) {
    return jsonEncode(messages.map((m) => m.toJson()).toList());
  }

  static List<ChatMessage> decodeMessages(String messagesJson) {
    final List<dynamic> decoded = jsonDecode(messagesJson);
    return decoded.map((m) => ChatMessage.fromJson(m)).toList();
  }
}
