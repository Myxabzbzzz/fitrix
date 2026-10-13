import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/animation/motion.dart';
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

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleDictation() async {
    final ok = await _dictation.toggle();
    if (!ok && mounted) _snack(AppLocalizations.of(context).chatMicDenied);
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
      if (mounted) _snack(l10n.chatPhotoTooLarge);
      return;
    } catch (_) {
      if (mounted) _snack(l10n.chatPhotoFailed);
      return;
    }
    if (path == null || !mounted) return;
    final docs = await chatDocsDir();
    if (File(resolveChatPhoto(docs, path)).lengthSync() > maxChatPhotoBytes) {
      await deleteChatPhoto(path);
      if (mounted) _snack(l10n.chatPhotoTooLarge);
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
                _Composer(
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

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final DictationController dictation;
  final VoidCallback onMic;
  final VoidCallback onAdd;
  final String? pendingPhoto;
  final VoidCallback onRemovePhoto;

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.dictation,
    required this.onMic,
    required this.onAdd,
    required this.pendingPhoto,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xxs, AppSpacing.md, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingPhoto != null)
            Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.xs, bottom: AppSpacing.xs),
              child: _PendingPhoto(
                path: pendingPhoto!,
                removeLabel: l10n.chatRemovePhoto,
                onRemove: onRemovePhoto,
              ),
            ),
          Row(
            children: [
              IconButton(
                key: const ValueKey('chat-add'),
                icon: const Icon(Icons.add_circle_outline, size: 28),
                color: palette.textPrimary,
                tooltip: l10n.chatAddPhoto,
                onPressed: onAdd,
              ),
              Expanded(
                child: Container(
                  height: 37,
                  padding: const EdgeInsets.only(
                      left: AppSpacing.sm, right: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: palette.background,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: palette.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) {
                            if (enabled) onSend();
                          },
                          style: AppText.bodyRegular
                              .copyWith(color: palette.textPrimary),
                          decoration: InputDecoration.collapsed(
                            hintText:
                                AppLocalizations.of(context).chatMessageHint,
                            filled: false,
                            hintStyle: AppText.bodyRegular
                                .copyWith(color: palette.chartLabel),
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: dictation,
                        builder: (context, _) => _MicButton(
                          listening: dictation.listening,
                          tooltip: dictation.listening
                              ? l10n.chatMicStop
                              : l10n.chatMicStart,
                          onTap: onMic,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32),
                        icon: const Icon(Icons.arrow_circle_up, size: 28),
                        color: palette.textPrimary,
                        disabledColor: palette.border,
                        onPressed: enabled ? onSend : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thumbnail of the photo about to be sent, with a remove button. The
/// button's 44x44 hit area lies inside the widget's bounds.
class _PendingPhoto extends StatelessWidget {
  final String path;
  final String removeLabel;
  final VoidCallback onRemove;

  const _PendingPhoto({
    required this.path,
    required this.removeLabel,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SizedBox(
      key: const ValueKey('chat-pending-photo'),
      width: 84,
      height: 84,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            width: 72,
            height: 72,
            child: ClipRRect(
              borderRadius: AppRadius.smAll,
              child: ChatPhotoImage(path: path, fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            width: 44,
            height: 44,
            child: IconButton(
              key: const ValueKey('chat-remove-photo'),
              padding: EdgeInsets.zero,
              tooltip: removeLabel,
              onPressed: onRemove,
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: palette.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: palette.background),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mic button; pulses while listening (a static highlight with reduced
/// motion).
class _MicButton extends StatefulWidget {
  final bool listening;
  final String tooltip;
  final VoidCallback onTap;

  const _MicButton({
    required this.listening,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_MicButton old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.listening && !Motion.reduced(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return IconButton(
      key: const ValueKey('chat-mic'),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: widget.tooltip,
      onPressed: widget.onTap,
      icon: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.listening
                ? palette.accent.withValues(alpha: 0.2 + 0.3 * _pulse.value)
                : Colors.transparent,
          ),
          child: Icon(
            widget.listening ? Icons.mic : Icons.mic_none,
            size: 22,
            color: widget.listening ? palette.accent : palette.textPrimary,
          ),
        ),
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
