import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(AssistantTopic topic) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatMessagesProviderFor(topic).notifier).sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final topic = ref.watch(selectedAssistantTopicProvider);
    final messages = ref.watch(chatMessagesProviderFor(topic));

    ref.listen(chatMessagesProviderFor(topic), (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: palette.background,
      drawer: _AllChatsDrawer(
        selected: topic,
        onSelected: (t) {
          ref.read(selectedAssistantTopicProvider.notifier).state = t;
          Navigator.of(context).pop();
          _scrollToBottom();
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(topic: topic),
            Expanded(
              child: messages.when(
                data: (list) => ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final message = list[index];
                    final next = index + 1 < list.length ? list[index + 1] : null;
                    final lastInGroup = next == null || next.sender != message.sender;
                    return _MessageBubble(
                      message: message,
                      showAvatar: lastInGroup,
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
            _Composer(controller: _controller, onSend: () => _send(topic)),
            const SizedBox(height: 8),
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
              tooltip: 'All chats',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage('assets/images/felix_avatar.png'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  topic.subtitle,
                  style: TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const _MessageBubble({required this.message, required this.showAvatar});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isUser = message.sender == MessageSender.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userBubble = isDark ? Colors.white : Colors.black;
    final userText = isDark ? Colors.black : Colors.white;

    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 247),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: isUser ? userBubble : palette.bubble,
        borderRadius: BorderRadius.circular(isUser ? 18 : 24),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
          height: 1.3,
          color: isUser ? userText : palette.textPrimary,
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: showAvatar ? 14 : 2),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            SizedBox(
              width: 24,
              child: showAvatar
                  ? const CircleAvatar(
                      radius: 12,
                      backgroundImage:
                          AssetImage('assets/images/felix_avatar.png'),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _Composer({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 16, 0),
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
              padding: const EdgeInsets.only(left: 14, right: 4),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      style: TextStyle(fontSize: 14, color: palette.textPrimary),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Message...',
                        filled: false,
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: palette.chartLabel,
                        ),
                      ),
                    ),
                  ),
                  Icon(Icons.mic_none, size: 22, color: palette.textPrimary),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32),
                    icon: const Icon(Icons.arrow_circle_up, size: 28),
                    color: palette.textPrimary,
                    onPressed: onSend,
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
                      'All chats',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
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
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final topic = AssistantTopic.all[index];
                  final isSelected = topic == selected;
                  return Material(
                    color: isSelected ? palette.pillSelected : palette.bubble,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => onSelected(topic),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          topic.menuLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
