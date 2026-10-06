import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/widgets/typing_indicator.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  /// Called when a failed reply is tapped.
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isUser
        ? (isDark ? AppColors.darkTextOnDark : AppColors.lightTextOnDark)
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    final Widget content;
    if (message.isStreaming && message.content.isEmpty) {
      content = TypingIndicator(color: textColor);
    } else if (message.isFailed) {
      content = ChatFailedContent(message: message.content, color: textColor);
    } else {
      content = Text(
        message.content,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textColor,
          height: 1.4,
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
              child: Icon(
                Icons.person,
                size: 16,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: message.isFailed ? onRetry : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isUser
                      ? (isDark ? AppColors.darkChatBubbleUser : AppColors.lightChatBubbleUser)
                      : (isDark ? AppColors.darkChatBubbleAssistant : AppColors.lightChatBubbleAssistant),
                  borderRadius: BorderRadius.circular(20),
                  border: message.isFailed
                      ? Border.all(color: AppColors.error.withValues(alpha: 0.6))
                      : null,
                ),
                child: content,
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}

/// Body of a failed assistant bubble: the error plus a retry hint.
class ChatFailedContent extends StatelessWidget {
  final String message;
  final Color color;

  const ChatFailedContent({
    super.key,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: TextStyle(fontSize: 14, color: color, height: 1.3),
        ),
        const SizedBox(height: 6),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 16, color: AppColors.error),
            SizedBox(width: 4),
            Text(
              'Tap to retry',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
