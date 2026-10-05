import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  return ChatApiService();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(chatApiServiceProvider));
});

final chatMessagesProvider = StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  return ChatNotifier(ref.read(chatRepositoryProvider));
});

/// Per-sport Felix trainer chats. Each has its own stored history and
/// backend conversation id.
final topicChatMessagesProvider = StateNotifierProvider.family<ChatNotifier,
    AsyncValue<List<ChatMessage>>, AssistantTopic>((ref, topic) {
  return ChatNotifier(
    ChatRepository(
      ref.read(chatApiServiceProvider),
      historyKey: topic.historyKey,
      conversationKey: topic.conversationKey,
      greeting: topic.greeting,
    ),
  );
});

/// The general app assistant shares its history with the onboarding chat.
StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>
    chatMessagesProviderFor(AssistantTopic topic) =>
        topic.isApp ? chatMessagesProvider : topicChatMessagesProvider(topic);

final isTypingProvider = StateProvider<bool>((ref) => false);

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _repository;
  final Uuid _uuid = const Uuid();

  ChatNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getMessages();
      state = AsyncValue.data(messages);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendMessage(String content, {bool isQuickReply = false}) async {
    state.whenData((messages) async {
      // Add user message
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: content,
        sender: MessageSender.user,
        timestamp: DateTime.now(),
        isQuickReply: isQuickReply,
      );

      final updatedMessages = [...messages, userMessage];
      state = AsyncValue.data(updatedMessages);
      await _repository.saveMessages(updatedMessages);

      try {
        // Get AI response
        final response = await _repository.sendMessage(content);

        // Add assistant message
        final assistantMessage = ChatMessage(
          id: _uuid.v4(),
          content: response,
          sender: MessageSender.assistant,
          timestamp: DateTime.now(),
        );

        final finalMessages = [...updatedMessages, assistantMessage];
        state = AsyncValue.data(finalMessages);
        await _repository.saveMessages(finalMessages);
      } catch (e) {
        // Handle error but keep user message
        state = AsyncValue.error(e, StackTrace.current);
      }
    });
  }

  Future<void> clearMessages() async {
    await _repository.saveMessages([]);
    await _loadMessages();
  }
}
