import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/transition/presentation/screens/chat_transition_screen.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_auto_scroll.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_entrance.dart';
import 'package:fitrix/features/chat/presentation/widgets/quick_reply_chip.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String> _quickReplies = AppConstants.fitnessGoals;
  bool _showQuickReplies = true;
  final ChatEntranceTracker _entrance = ChatEntranceTracker();

  final GlobalKey _startButtonKey = GlobalKey();
  late AnimationController _circleController;
  late Animation<double> _circleAnimation;
  bool _animating = false;
  Offset? _buttonCenter;

  @override
  void initState() {
    super.initState();
    _circleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _circleAnimation = CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeInOut,
    );
    _circleController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        context.go(AppRouter.transition);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _circleController.dispose();
    super.dispose();
  }

  void _sendMessage(String content, {bool isQuickReply = false}) {
    final notifier = ref.read(chatMessagesProvider.notifier);
    if (content.trim().isEmpty || notifier.isReplying) return;

    notifier.sendMessage(content, isQuickReply: isQuickReply);

    _messageController.clear();

    // Update quick replies based on message content
    _updateQuickReplies(content);
  }

  void _updateQuickReplies(String message) {
    setState(() {
      if (message.contains('muscle') || message.contains('strength')) {
        _quickReplies = [
          'Gym',
          'Fitness',
          'Cycling',
          'Skiing',
          'Snowboarding',
          'Football',
          'Running'
        ];
      } else if (_quickReplies.contains('Gym')) {
        _quickReplies = [
          'Once a week or less',
          'Almost every day',
          'A few times a week',
          'Just starting out'
        ];
      } else if (message.contains('week')) {
        _quickReplies = ['Beginner', 'Intermediate', 'Advanced'];
      } else if (message.contains('Intermediate') ||
          message.contains('Beginner')) {
        _quickReplies = [];
        _showQuickReplies = false;
      }
    });
  }

  void _onStartPressed() {
    final renderBox =
        _startButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      _buttonCenter = Offset(
        position.dx + renderBox.size.width / 2,
        position.dy + renderBox.size.height / 2,
      );
    }
    setState(() => _animating = true);
    _circleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);
    final isReplying =
        messagesAsync.valueOrNull?.any((m) => m.isStreaming) ?? false;

    ref.listen(chatMessagesProvider, (previous, next) {
      final messages = next.valueOrNull;
      if (messages != null) {
        followChatBottom(_scrollController, previous?.valueOrNull, messages);
      }
    });
    final size = MediaQuery.of(context).size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);
    final palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: palette.border)),
        title: Row(
          children: [
            const FelixAvatar(size: 32),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.assistantName,
                  style: AppText.headingS.copyWith(color: palette.textPrimary),
                ),
                Text(
                  AppConstants.assistantSubtitle,
                  style: AppText.caption.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    _entrance.sync(messages);
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final showTimestamp = index == 0 ||
                            _showsTimestamp(messages, index);

                        final next = index + 1 < messages.length
                            ? messages[index + 1]
                            : null;
                        final lastInGroup = next == null ||
                            next.sender != message.sender ||
                            _showsTimestamp(messages, index + 1);

                        return ChatEntrance(
                          key: ValueKey(message.id),
                          message: message,
                          delay: _entrance.take(message),
                          child: Column(
                            children: [
                              if (showTimestamp)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: AppSpacing.sm),
                                  child: Text(
                                    DateFormat('MMM dd, yyyy, h:mm a')
                                        .format(message.timestamp),
                                    style: AppText.caption
                                        .copyWith(color: palette.textSecondary),
                                  ),
                                ),
                              ChatBubble(
                                message: message,
                                lastInGroup: lastInGroup,
                                onRetry: () => ref
                                    .read(chatMessagesProvider.notifier)
                                    .retry(),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),

              // Composer area: quick replies (or the Start button once the
              // conversation is complete) directly above the input.
              Column(
                key: const ValueKey('chat-composer'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: Motion.of(context, Motion.medium),
                    curve: Motion.curve,
                    alignment: Alignment.bottomCenter,
                    child: _showQuickReplies
                        ? QuickReplyBar(
                            replies: _quickReplies,
                            hidden: isReplying,
                            onTap: (reply) =>
                                _sendMessage(reply, isQuickReply: true),
                          )
                        : _buildStartButton(),
                  ),
                  _buildMessageInput(isReplying: isReplying),
                ],
              ),
            ],
          ),

          // Black circle expanding from Start button
          if (_animating)
            AnimatedBuilder(
              animation: _circleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _CirclePainter(
                    progress: _circleAnimation.value,
                    color: ChatTransitionScreen.background,
                    center: _buttonCenter ??
                        Offset(size.width / 2, size.height - 100),
                    maxRadius: diagonal,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static bool _showsTimestamp(List<ChatMessage> messages, int index) =>
      index == 0 ||
      messages[index].timestamp
              .difference(messages[index - 1].timestamp)
              .inMinutes >
          5;

  Widget _buildStartButton() {
    return Padding(
      key: const ValueKey('start'),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AppButton(
          key: _startButtonKey,
          label: 'Start',
          size: AppButtonSize.large,
          onPressed: _animating ? null : _onStartPressed,
        ),
      ),
    );
  }

  Widget _buildMessageInput({required bool isReplying}) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.background,
        border: Border(top: BorderSide(color: palette.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Add button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: palette.border),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {},
                color: palette.textSecondary,
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Text Input
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                ),
                onSubmitted: (value) => _sendMessage(value),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            // Microphone button
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.mic, size: 20),
                onPressed: () {},
                color: palette.textSecondary,
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(width: AppSpacing.xs),

            // Send button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isReplying ? palette.border : palette.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: isReplying
                    ? null
                    : () => _sendMessage(_messageController.text),
                color: palette.onAccent,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color color;
  final Offset center;
  final double maxRadius;

  _CirclePainter({
    required this.progress,
    required this.color,
    required this.center,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, progress * maxRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
