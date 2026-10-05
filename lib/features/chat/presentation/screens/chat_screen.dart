import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(String content, {bool isQuickReply = false}) {
    if (content.trim().isEmpty) return;

    ref.read(chatMessagesProvider.notifier).sendMessage(
          content,
          isQuickReply: isQuickReply,
        );

    _messageController.clear();
    _scrollToBottom();

    // Update quick replies based on message content
    _updateQuickReplies(content);
  }

  void _updateQuickReplies(String message) {
    setState(() {
      if (message.contains('muscle') || message.contains('strength')) {
        _quickReplies = ['Gym', 'Fitness', 'Cycling', 'Skiing', 'Snowboarding', 'Football', 'Running'];
      } else if (_quickReplies.contains('Gym')) {
        _quickReplies = ['Once a week or less', 'Almost every day', 'A few times a week', 'Just starting out'];
      } else if (message.contains('week')) {
        _quickReplies = ['Beginner', 'Intermediate', 'Advanced'];
      } else if (message.contains('Intermediate') || message.contains('Beginner')) {
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
    final size = MediaQuery.of(context).size;
    final diagonal = sqrt(size.width * size.width + size.height * size.height);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.cardBackground,
              child: const Icon(
                Icons.person,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.assistantName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  AppConstants.assistantSubtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
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
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final showTimestamp = index == 0 ||
                            message.timestamp.difference(messages[index - 1].timestamp).inMinutes > 5;

                        return Column(
                          children: [
                            if (showTimestamp)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  DateFormat('MMM dd, yyyy, h:mm a').format(message.timestamp),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ChatBubble(message: message),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              ),

              // Quick Replies
              if (_showQuickReplies && _quickReplies.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickReplies.map((reply) {
                      return QuickReplyChip(
                        label: reply,
                        onTap: () => _sendMessage(reply, isQuickReply: true),
                      );
                    }).toList(),
                  ),
                ),

              // Start button (shown when chat conversation is complete)
              if (!_showQuickReplies)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: SizedBox(
                    width: 160,
                    height: 44,
                    child: ElevatedButton(
                      key: _startButtonKey,
                      onPressed: _animating ? null : _onStartPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: AppColors.textOnDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

              // Message Input
              _buildMessageInput(),
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
                    color: Colors.black,
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.divider.withOpacity(0.3),
            width: 1,
          ),
        ),
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
                border: Border.all(color: AppColors.divider),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {},
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(width: 12),

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

            const SizedBox(width: 12),

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
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: () => _sendMessage(_messageController.text),
                color: AppColors.textOnDark,
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
