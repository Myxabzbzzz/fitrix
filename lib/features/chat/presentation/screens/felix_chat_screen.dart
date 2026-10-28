import 'dart:io';

import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_composer.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/topic_labels.dart';
import 'package:fitrix/features/chat/presentation/topic_prompts.dart';
import 'package:fitrix/features/chat/presentation/providers/felix_snapshot_provider.dart';
import 'package:fitrix/features/chat/presentation/widgets/felix_context_chips.dart';
import 'package:fitrix/features/chat/data/services/photo_service.dart';
import 'package:fitrix/features/chat/data/services/speech_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/providers/dictation_controller.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_auto_scroll.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_action_card.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_entrance.dart';
import 'package:fitrix/features/chat/presentation/widgets/quick_reply_chip.dart';

/// One Felix chat: the app assistant, a sport trainer, nutrition or
/// recovery. Opened from the Felix hub, which it returns to.
class FelixChatScreen extends ConsumerStatefulWidget {
  final AssistantTopic topic;

  const FelixChatScreen({super.key, required this.topic});

  @override
  ConsumerState<FelixChatScreen> createState() => _FelixChatScreenState();
}

class _FelixChatScreenState extends ConsumerState<FelixChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatEntranceTracker _entrance = ChatEntranceTracker();
  late final DictationController _dictation = DictationController(
    ref.read(speechServiceProvider),
    _controller,
    language: () => ref.read(selectedLanguageProvider),
  );

  /// Photo picked for the next message (stored path, see photo_service).
  String? _pendingPhoto;

  /// The chat opened at its newest message already.
  bool _openedAtBottom = false;
  bool _wasListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dictation.addListener(_announceDictation);
    // A draft set before this screen was built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeDraft());
  }

  /// Moves a pending "Ask Felix" draft into the field once. Never sends.
  void _takeDraft() {
    if (!mounted) return;
    // A chat on a hidden tab or under another page leaves the draft for the
    // screen about to open; the router may replace this one a frame later.
    if (!TickerMode.of(context) ||
        !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return;
    }
    final draft = ref.read(felixDraftProvider);
    if (draft == null) return;
    final target = ref.read(felixDraftTopicProvider);
    if (target != null && target != widget.topic) return;
    ref.read(felixDraftTopicProvider.notifier).state = null;
    ref.read(felixDraftProvider.notifier).state = null;
    _controller.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tabs keep their state: an offstage tab has its tickers off.
    if (!TickerMode.of(context)) _dictation.stop();
    // Becoming visible or current again (tab switched back, page uncovered)
    // is when a draft left for this chat can be taken.
    ModalRoute.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _takeDraft());
  }

  @override
  void didUpdateWidget(FelixChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.topic != widget.topic) _openedAtBottom = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) _dictation.stop();
  }

  void _announceDictation() {
    if (_dictation.listening == _wasListening || !mounted) return;
    _wasListening = _dictation.listening;
    final l10n = AppLocalizations.of(context);
    SemanticsService.sendAnnouncement(
      View.of(context),
      _wasListening ? l10n.chatMicListening : l10n.chatMicStopped,
      Directionality.of(context),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dictation.removeListener(_announceDictation);
    _dictation.dispose();
    // A picked photo that was never sent is not kept.
    final unsent = _pendingPhoto;
    if (unsent != null) deleteChatPhoto(unsent);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(AssistantTopic topic) {
    final notifier = ref.read(chatMessagesProviderFor(topic).notifier);
    // Stop first so a late dictation result can't refill the cleared field.
    _dictation.stop();
    final photo = _pendingPhoto;
    var text = _controller.text.trim();
    if (text.isEmpty && photo != null) {
      text = AppLocalizations.of(context).chatPhotoPrompt;
    }
    if (text.isEmpty || !notifier.canSend) return;
    if (!notifier.startSend(text, imagePath: photo)) return;
    _controller.clear();
    setState(() => _pendingPhoto = null);
  }

  Future<void> _toggleDictation() async {
    final ok = await _dictation.toggle();
    if (!ok && mounted) {
      showAppSnack(context, AppLocalizations.of(context).chatMicDenied);
    }
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<PhotoSource>(
      useRootNavigator: true,
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const ValueKey('photo-source-camera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.chatTakePhoto),
              onTap: () => Navigator.of(context).pop(PhotoSource.camera),
            ),
            ListTile(
              key: const ValueKey('photo-source-library'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chatChooseFromLibrary),
              onTap: () => Navigator.of(context).pop(PhotoSource.library),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final String? path;
    try {
      path = await ref.read(photoServiceProvider).pick(source);
    } on PhotoTooLargeException {
      if (mounted) showAppSnack(context, l10n.chatPhotoTooLarge);
      return;
    } catch (_) {
      if (mounted) showAppSnack(context, l10n.chatPhotoFailed);
      return;
    }
    if (path == null || !mounted) return;
    final docs = await chatDocsDir();
    if (File(resolveChatPhoto(docs, path)).lengthSync() > maxChatPhotoBytes) {
      await deleteChatPhoto(path);
      if (mounted) showAppSnack(context, l10n.chatPhotoTooLarge);
      return;
    }
    if (!mounted) return;
    final previous = _pendingPhoto;
    setState(() => _pendingPhoto = path);
    if (previous != null) await deleteChatPhoto(previous);
  }

  Future<void> _removePhoto() async {
    final path = _pendingPhoto;
    setState(() => _pendingPhoto = null);
    if (path != null) await deleteChatPhoto(path);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final topic = widget.topic;
    final messages = ref.watch(chatMessagesProviderFor(topic));

    final isReplying = messages.valueOrNull?.any((m) => m.isStreaming) ?? false;

    ref.listen(felixDraftProvider, (_, next) {
      if (next != null) _takeDraft();
    });

    ref.listen(chatMessagesProviderFor(topic), (previous, next) {
      final list = next.valueOrNull;
      if (list != null) {
        followChatBottom(_scrollController, previous?.valueOrNull, list);
      }
    });

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(topic: topic),
            FelixContextChips(
                snapshot: ref.watch(felixSnapshotProvider(topic)),
                topic: topic),
            Expanded(
              child: messages.when(
                data: (list) {
                  // Each topic's loaded history shows without animation.
                  _entrance.sync(list, scope: topic);
                  if (!_openedAtBottom) {
                    _openedAtBottom = true;
                    jumpChatToBottom(_scrollController);
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final message = list[index];
                      final next =
                          index + 1 < list.length ? list[index + 1] : null;
                      final lastInGroup =
                          next == null || next.sender != message.sender;
                      return ChatEntrance(
                        key: ValueKey(message.id),
                        message: message,
                        delay: _entrance.take(message),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ChatBubble(
                              message: message,
                              lastInGroup: lastInGroup,
                              onRetry: () => ref
                                  .read(chatMessagesProviderFor(topic).notifier)
                                  .retry(),
                            ),
                            if (message.action != null && !message.isStreaming)
                              ChatActionCard(
                                message: message,
                                onApplied: (result) => ref
                                    .read(
                                        chatMessagesProviderFor(topic).notifier)
                                    .markActionApplied(message.id,
                                        result: result),
                                onUndone: () => ref
                                    .read(
                                        chatMessagesProviderFor(topic).notifier)
                                    .markActionUndone(message.id),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                    child:
                        Text(AppLocalizations.of(context).chatError('$error'))),
              ),
            ),
            Column(
              key: const ValueKey('chat-composer'),
              mainAxisSize: MainAxisSize.min,
              children: [
                QuickReplyBar(
                  replies: topicPrompts(l10n, topic),
                  hidden: isReplying,
                  onTap: (reply) => ref
                      .read(chatMessagesProviderFor(topic).notifier)
                      .sendMessage(reply, isQuickReply: true),
                ),
                ChatComposer(
                  controller: _controller,
                  enabled: !isReplying,
                  onSend: () => _send(topic),
                  dictation: _dictation,
                  onMic: _toggleDictation,
                  onAdd: _addPhoto,
                  pendingPhoto: _pendingPhoto,
                  onRemovePhoto: _removePhoto,
                  hintText: topic.isApp
                      ? l10n.felixAskAboutApp
                      : l10n
                          .felixAskAbout(topicTitle(l10n, topic).toLowerCase()),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AssistantTopic topic;

  const _Header({required this.topic});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: palette.textPrimary,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(AppRouter.felix),
          ),
          const FelixAvatar(size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.felixChatTitle(topicTitle(l10n, topic)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.headingS.copyWith(color: palette.textPrimary),
                ),
                Text(
                  topicSees(l10n, topic),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
