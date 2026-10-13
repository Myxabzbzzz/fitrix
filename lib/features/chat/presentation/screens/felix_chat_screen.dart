import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_auto_scroll.dart';
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

class _FelixChatScreenState extends ConsumerState<FelixChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatEntranceTracker _entrance = ChatEntranceTracker();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(AssistantTopic topic) {
    final notifier = ref.read(chatMessagesProviderFor(topic).notifier);
    final text = _controller.text.trim();
    if (text.isEmpty || notifier.isReplying) return;
    notifier.sendMessage(text);
    _controller.clear();
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
                        child: ChatBubble(
                          message: message,
                          lastInGroup: lastInGroup,
                          onRetry: () => ref
                              .read(chatMessagesProviderFor(topic).notifier)
                              .retry(),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(AppLocalizations.of(context).chatError('$error'))),
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

  const _Composer({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xxs, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            color: palette.textPrimary,
            onPressed: () {},
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
                        hintText: AppLocalizations.of(context).chatMessageHint,
                        filled: false,
                        hintStyle:
                            AppText.bodyRegular.copyWith(color: palette.chartLabel),
                      ),
                    ),
                  ),
                  Icon(Icons.mic_none, size: 22, color: palette.textPrimary),
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
                      style: AppText.headingS.copyWith(color: palette.textPrimary),
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
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
