import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  return ChatApiService();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.read(chatApiServiceProvider),
    profileRepository: ref.read(profileRepositoryProvider),
    topic: AssistantTopic.app.apiTopic,
    prefs: ref.read(sharedPreferencesProvider),
    onSaved: ref.read(localChangesProvider).notify,
  );
});

final chatMessagesProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>((ref) {
  return ChatNotifier(ref.read(chatRepositoryProvider));
});

/// Per-sport Felix trainer chats. Each has its own stored history and
/// backend conversation id.
final topicChatMessagesProvider = StateNotifierProvider.family<ChatNotifier,
    AsyncValue<List<ChatMessage>>, AssistantTopic>((ref, topic) {
  return ChatNotifier(
    ChatRepository(
      ref.read(chatApiServiceProvider),
      profileRepository: ref.read(profileRepositoryProvider),
      topic: topic.apiTopic,
      historyKey: topic.historyKey,
      conversationKey: topic.conversationKey,
      greeting: topic.greeting,
      prefs: ref.read(sharedPreferencesProvider),
      onSaved: ref.read(localChangesProvider).notify,
    ),
  );
});

/// The general app assistant shares its history with the onboarding chat.
StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>
    chatMessagesProviderFor(AssistantTopic topic) =>
        topic.isApp ? chatMessagesProvider : topicChatMessagesProvider(topic);

class ChatNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ChatRepository _repository;
  final Uuid _uuid = const Uuid();

  ChatNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  /// Sync has just stored [stored] (all completed messages, oldest first)
  /// as this chat's history. Shows it, keeping a reply that is still
  /// streaming or has failed at the end; an empty history reloads the
  /// greeting.
  void applySynced(List<ChatMessage> stored) {
    if (!mounted) return;
    if (stored.isEmpty) {
      _loadMessages();
      return;
    }
    final inFlight = (state.valueOrNull ?? const <ChatMessage>[])
        .where((m) => m.isStreaming || m.isFailed);
    state = AsyncValue.data([...stored, ...inFlight]);
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

  bool _isReplying = false;

  /// True while Felix's reply is streaming in; new sends are ignored.
  bool get isReplying => _isReplying;

  Future<void> sendMessage(String content, {bool isQuickReply = false}) async {
    final messages = state.valueOrNull;
    if (messages == null || _isReplying || content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      isQuickReply: isQuickReply,
    );

    final history = [...messages.where((m) => !m.isFailed), userMessage];
    await _reply(history, history.length - 1);
  }

  /// Re-asks Felix for the last user message after a failed reply.
  Future<void> retry() async {
    final messages = state.valueOrNull;
    if (messages == null || _isReplying) return;

    final history = messages.where((m) => !m.isFailed).toList();
    final lastUser = history.lastIndexWhere(
      (m) => m.sender == MessageSender.user,
    );
    if (lastUser == -1) return;

    await _reply(history, lastUser);
  }

  /// Shows [history] plus a streaming reply to the user message at
  /// [promptIndex]. Everything before that message is sent as context.
  Future<void> _reply(List<ChatMessage> history, int promptIndex) async {
    final prompt = history[promptIndex].content;
    final context = history.sublist(0, promptIndex);
    _isReplying = true;
    final reply = ChatMessage(
      id: _uuid.v4(),
      content: '',
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    state = AsyncValue.data([...history, reply]);
    await _repository.saveMessages(history);

    final text = StringBuffer();
    try {
      await for (final delta
          in _repository.streamMessage(prompt, context: context)) {
        if (!mounted) return;
        text.write(delta);
        _updateReply(reply.id, (m) => m.copyWith(content: text.toString()));
      }
      if (!mounted) return;
      _updateReply(
        reply.id,
        (m) => m.copyWith(content: text.toString().trim(), isStreaming: false),
      );
      await _repository.saveMessages(state.requireValue);
    } catch (e) {
      if (!mounted) return;
      _updateReply(
        reply.id,
        (m) => m.copyWith(
          content: e is ChatException ? e.message : 'Something went wrong.',
          isStreaming: false,
          isFailed: true,
        ),
      );
    } finally {
      _isReplying = false;
    }
  }

  void _updateReply(String id, ChatMessage Function(ChatMessage) update) {
    final messages = state.valueOrNull;
    if (messages == null) return;
    state = AsyncValue.data([
      for (final m in messages) m.id == id ? update(m) : m,
    ]);
  }

  Future<void> clearMessages() async {
    await _repository.saveMessages([]);
    await _loadMessages();
  }
}
