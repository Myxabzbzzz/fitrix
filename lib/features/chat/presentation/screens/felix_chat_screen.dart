import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/widgets/app_snack.dart';
import 'package:fitrix/core/felix/ask_felix.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/services/photo_service.dart';
import 'package:fitrix/features/chat/data/services/speech_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/providers/dictation_controller.dart';
import 'package:fitrix/features/language/presentation/providers/language_provider.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_auto_scroll.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_action_card.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_entrance.dart';
import 'package:fitrix/features/chat/presentation/widgets/quick_reply_chip.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_composer.dart';

/// Chat currently open on the Felix tab.
final selectedAssistantTopicProvider =
    StateProvider<AssistantTopic>((ref) => AssistantTopic.app);

/// Felix tab: chat with the app assistant or a sport trainer, with the
/// "All chats" side menu from the design.
class FelixChatScreen extends ConsumerStatefulWidget {
  const FelixChatScreen({super.key});

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
    final draft = ref.read(felixDraftProvider);
    if (draft == null) return;
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
      context: context,
      backgroundColor: AppPalette.of(context).sheet,
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
    final topic = ref.watch(selectedAssistantTopicProvider);
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
      drawer: _AllChatsDrawer(
        selected: topic,
        onSelected: (t) {
          ref.read(selectedAssistantTopicProvider.notifier).state = t;
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(topic: topic),
            Expanded(
              child: messages.when(
                data: (list) {
                  // Each topic's loaded history shows without animation.
                  _entrance.sync(list, scope: topic);
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
                  replies: [
                    l10n.chatQuickPlanWeek,
                    l10n.chatQuickEatToday,
                    l10n.chatQuickTired,
                  ],
                  hidden: isReplying,
                  onTap: (reply) => ref
                      .read(chatMessagesProviderFor(topic).notifier)
                      .sendMessage(reply, isQuickReply: true),
                ),
                Composer(
                  controller: _controller,
                  enabled: !isReplying,
                  onSend: () => _send(topic),
                  dictation: _dictation,
                  onMic: _toggleDictation,
                  onAdd: _addPhoto,
                  pendingPhoto: _pendingPhoto,
                  onRemovePhoto: _removePhoto,
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

    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.sort),
              color: palette.textPrimary,
              tooltip: AppLocalizations.of(context).chatAllChats,
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const FelixAvatar(size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: AppText.headingS.copyWith(color: palette.textPrimary),
                ),
                Text(
                  topic.subtitle,
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

class _AllChatsDrawer extends StatelessWidget {
  final AssistantTopic selected;
  final ValueChanged<AssistantTopic> onSelected;

  const _AllChatsDrawer({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Drawer(
      width: 280,
      backgroundColor: palette.background,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 8, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).chatAllChats,
                      style:
                          AppText.headingS.copyWith(color: palette.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort),
                    color: palette.textPrimary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                itemCount: AssistantTopic.all.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final topic = AssistantTopic.all[index];
                  final isSelected = topic == selected;
                  return Material(
                    color: isSelected ? palette.pillSelected : palette.bubble,
                    borderRadius: AppRadius.mdAll,
                    child: InkWell(
                      borderRadius: AppRadius.mdAll,
                      onTap: () => onSelected(topic),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          topic.menuLabel,
                          style: AppText.body14.copyWith(
                            color: isSelected
                                ? palette.onPillSelected
                                : palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
