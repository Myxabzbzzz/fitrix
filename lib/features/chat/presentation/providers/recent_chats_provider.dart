import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';

/// A chat the user has written in, with its last message.
class RecentChat {
  final AssistantTopic topic;
  final ChatMessage last;

  const RecentChat({required this.topic, required this.last});
}

/// Topics with at least one user message (a fresh chat only holds Felix's
/// greeting), the one with the newest last message first.
final recentChatsProvider = Provider<List<RecentChat>>((ref) {
  final chats = <RecentChat>[];
  for (final topic in AssistantTopic.all) {
    final messages = ref.watch(chatMessagesProviderFor(topic)).valueOrNull;
    if (messages == null || messages.isEmpty) continue;
    if (!messages.any((m) => m.sender == MessageSender.user)) continue;
    chats.add(RecentChat(topic: topic, last: messages.last));
  }
  chats.sort((a, b) => b.last.timestamp.compareTo(a.last.timestamp));
  return chats;
});
