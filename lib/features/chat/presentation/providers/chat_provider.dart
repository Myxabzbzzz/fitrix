import 'dart:async';
import 'dart:ui' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/supabase/supabase_providers.dart';
import 'package:fitrix/core/sync/local_changes.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/providers/felix_snapshot_provider.dart';
import 'package:fitrix/features/chat/presentation/topic_labels.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';

final chatApiServiceProvider = Provider<ChatApiService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ChatApiService(
    accessToken: supabase == null
        ? null
        : () async {
            // supabase_flutter refreshes the session in the background; if
            // it has lapsed anyway (app was asleep), refresh before sending.
            final session = supabase.auth.currentSession;
            if (session == null) return null;
            if (!session.isExpired) return session.accessToken;
            final refreshed = await supabase.auth.refreshSession();
            return refreshed.session?.accessToken;
          },
  );
});

List<String> _topicGreeting(Ref ref, AssistantTopic topic) {
  final l10n = lookupAppLocalizations(
    Locale(ref.read(selectedLanguageProvider)),
  );
  if (topic.isApp) {
    return [
      l10n.assistantGreeting,
      l10n.assistantIntro,
      l10n.assistantQuestion,
    ];
  }
  return [
    l10n.felixTopicGreeting(topicTitle(l10n, topic)),
    l10n.felixTopicGreetingHint,
  ];
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.read(chatApiServiceProvider),
    profileRepository: ref.read(profileRepositoryProvider),
    topic: AssistantTopic.app.apiTopic,
    // In the app's language, like the topic chats.
    greeting: () => _topicGreeting(ref, AssistantTopic.app),
    prefs: ref.read(sharedPreferencesProvider),
    onSaved: ref.read(localChangesProvider).notify,
    language: () => ref.read(selectedLanguageProvider),
    context: () => ref.read(felixSnapshotProvider(AssistantTopic.app)).toJson(),
    now: ref.read(clockProvider),
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
      greeting: () => _topicGreeting(ref, topic),
      prefs: ref.read(sharedPreferencesProvider),
      onSaved: ref.read(localChangesProvider).notify,
      language: () => ref.read(selectedLanguageProvider),
      context: () => ref.read(felixSnapshotProvider(topic)).toJson(),
      now: ref.read(clockProvider),
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
  /// streaming at the end and the failed mark of a question; an empty
  /// history reloads the greeting.
  void applySynced(List<ChatMessage> stored) {
    if (!mounted) return;
    if (stored.isEmpty) {
      _loadMessages();
      return;
    }
    final current = state.valueOrNull ?? const <ChatMessage>[];
    final failures = {
      for (final m in current)
        if (m.failure != null) m.id: m.failure!,
    };
    final streaming = current.where((m) => m.isStreaming).toList();
    final merged = [
      for (final m in stored)
        failures.containsKey(m.id) ? m.copyWith(failure: failures[m.id]) : m,
    ];
    state = AsyncValue.data(
      streaming.isEmpty
          ? ChatMessage.markUnanswered(merged)
          : [...merged, ...streaming],
    );
  }

  Future<void> _loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _repository.getMessages();
      state = AsyncValue.data(
        _isReplying ? messages : ChatMessage.markUnanswered(messages),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  bool _isReplying = false;

  /// True while Felix's reply is streaming in; new sends are ignored.
  bool get isReplying => _isReplying;

  /// Whether a message sent now would be accepted.
  bool get canSend => state.valueOrNull != null && !_isReplying;

  Future<void> sendMessage(String content,
          {bool isQuickReply = false, String? imagePath}) =>
      _begin(content, isQuickReply: isQuickReply, imagePath: imagePath) ??
      Future.value();

  /// Starts sending without waiting for the reply. Returns whether the
  /// message was accepted (false while loading or while Felix replies).
  bool startSend(String content,
      {bool isQuickReply = false, String? imagePath}) {
    final future =
        _begin(content, isQuickReply: isQuickReply, imagePath: imagePath);
    if (future == null) return false;
    unawaited(future);
    return true;
  }

  /// Null when the message is rejected; otherwise the reply, already started.
  Future<void>? _begin(String content,
      {bool isQuickReply = false, String? imagePath}) {
    final messages = state.valueOrNull;
    if (messages == null || _isReplying || content.trim().isEmpty) return null;

    final userMessage = ChatMessage(
      id: _uuid.v4(),
      content: content,
      sender: MessageSender.user,
      timestamp: _repository.now(),
      isQuickReply: isQuickReply,
      imagePath: imagePath,
    );

    // An earlier question left unanswered stays in the chat as asked.
    final history = [
      for (final m in messages) m.copyWith(clearFailure: true),
      userMessage,
    ];
    return _reply(history, history.length - 1);
  }

  /// Re-asks Felix the question whose reply failed (the last one).
  Future<void> retry() async {
    final messages = state.valueOrNull;
    if (messages == null || _isReplying) return;

    final failed = messages.lastIndexWhere((m) => m.isFailed);
    if (failed == -1) return;
    final history = [
      for (final m in messages.take(failed + 1)) m.copyWith(clearFailure: true),
    ];
    await _reply(history, failed);
  }

  /// Shows [history] plus a streaming reply to the user message at
  /// [promptIndex] (its last message). Everything before that message is
  /// sent as context. If Felix can't answer, nothing is added: the question
  /// is marked failed with the reason, and [retry] asks again.
  Future<void> _reply(List<ChatMessage> history, int promptIndex) async {
    final promptMessage = history[promptIndex];
    final prompt = promptMessage.content;
    final imagePath = promptMessage.imagePath;
    final context = history.sublist(0, promptIndex);
    _isReplying = true;
    var reply = ChatMessage(
      id: _uuid.v4(),
      content: '',
      sender: MessageSender.assistant,
      timestamp: _repository.now(),
      isStreaming: true,
    );
    state = AsyncValue.data([...history, reply]);
    await _repository.saveMessages(history);

    final text = StringBuffer();
    ChatAction? action;
    try {
      await for (final delta in _repository.streamMessage(
        prompt,
        context: context,
        imagePath: imagePath,
        onAction: (a) => action = a,
      )) {
        if (!mounted) return;
        text.write(delta);
        reply = reply.copyWith(content: text.toString());
        _showReply(promptMessage.id, reply);
      }
      if (!mounted) return;
      reply = ChatMessage(
        id: reply.id,
        content: text.toString().trim(),
        sender: MessageSender.assistant,
        timestamp: reply.timestamp,
        action: action,
      );
      if (_showReply(promptMessage.id, reply)) {
        await _repository.saveMessages(state.requireValue);
      }
    } catch (e) {
      if (!mounted) return;
      final failure = e is ChatException ? e.failure : ChatFailure.unavailable;
      _fail(promptMessage.id, reply.id, failure);
    } finally {
      _isReplying = false;
    }
  }

  /// Puts [reply] in the chat right after the question [promptId]: in place
  /// when it is already shown, else inserted (the chat was reloaded while
  /// Felix replied, e.g. by a sync). False when the question is gone too.
  bool _showReply(String promptId, ChatMessage reply) {
    final messages = state.valueOrNull;
    if (messages == null) return false;
    if (messages.any((m) => m.id == reply.id)) {
      _updateReply(reply.id, (_) => reply);
      return true;
    }
    final prompt = messages.indexWhere((m) => m.id == promptId);
    if (prompt == -1) return false;
    state = AsyncValue.data([
      ...messages.take(prompt),
      messages[prompt].copyWith(clearFailure: true),
      reply,
      ...messages.skip(prompt + 1),
    ]);
    return true;
  }

  /// Drops the reply bubble and marks the question [promptId] failed.
  void _fail(String promptId, String replyId, ChatFailure failure) {
    final messages = state.valueOrNull;
    if (messages == null) return;
    state = AsyncValue.data([
      for (final m in messages)
        if (m.id == promptId)
          m.copyWith(failure: failure)
        else if (m.id != replyId)
          m,
    ]);
  }

  void _updateReply(String id, ChatMessage Function(ChatMessage) update) {
    final messages = state.valueOrNull;
    if (messages == null) return;
    state = AsyncValue.data([
      for (final m in messages) m.id == id ? update(m) : m,
    ]);
  }

  /// Marks the action of message [id] as applied (kept across restarts, so
  /// it can't be applied twice).
  Future<void> markActionApplied(
    String id, {
    Map<String, num>? result,
  }) async {
    final messages = state.valueOrNull;
    if (messages == null) return;
    _updateReply(
      id,
      (m) => m.copyWith(actionApplied: true, appliedResult: result),
    );
    await _repository.saveMessages(state.requireValue);
  }

  /// Takes the applied mark off message [id] after the user undid the
  /// action, so its card offers the button again.
  Future<void> markActionUndone(String id) async {
    if (state.valueOrNull == null) return;
    _updateReply(id, (m) => m.copyWith(actionApplied: false));
    await _repository.saveMessages(state.requireValue);
  }
}
