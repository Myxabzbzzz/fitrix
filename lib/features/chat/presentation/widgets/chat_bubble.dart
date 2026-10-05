import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_colors.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? (isDark ? AppColors.darkChatBubbleUser : AppColors.lightChatBubbleUser)
                    : (isDark ? AppColors.darkChatBubbleAssistant : AppColors.lightChatBubbleAssistant),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isUser
                      ? (isDark ? AppColors.darkTextOnDark : AppColors.lightTextOnDark)
                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 40),
        ],
      ),
    );
  }
}
