import 'package:flutter/material.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Felix's avatar, shown beside the last bubble of a Felix group (24) and in
/// the chat header (32).
class FelixAvatar extends StatelessWidget {
  final double size;

  const FelixAvatar({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        'assets/images/felix_avatar.png',
        key: const ValueKey('felix-avatar'),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  static const double maxWidth = 247;

  /// Width of the avatar column beside a Felix bubble.
  static const double avatarSize = 24;

  final ChatMessage message;

  /// Called when a failed reply is tapped.
  final VoidCallback? onRetry;

  /// True for the last message of one author's run: it gets the Felix avatar
  /// and the larger gap below. Earlier ones sit 2 px apart.
  final bool lastInGroup;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.lastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isUser = message.sender == MessageSender.user;
    final textColor = isUser ? palette.onBubbleUser : palette.textPrimary;

    final Widget content;
    if (message.isStreaming && message.content.isEmpty) {
      content = TypingIndicator(color: textColor);
    } else if (message.isFailed) {
      content = ChatFailedContent(message: message.content, color: textColor);
    } else {
      content = Text(
        message.content,
        style: AppText.body14.copyWith(color: textColor),
      );
    }

    final bubble = GestureDetector(
      onTap: message.isFailed ? onRetry : null,
      child: Container(
        key: const ValueKey('chat-bubble'),
        constraints: const BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: isUser ? palette.bubbleUser : palette.bubble,
          borderRadius: AppRadius.mdAll,
          border: message.isFailed ? Border.all(color: palette.danger) : null,
        ),
        child: content,
      ),
    );

    return Padding(
      padding: EdgeInsets.only(bottom: lastInGroup ? AppSpacing.md : 2),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            SizedBox(
              width: avatarSize,
              child: lastInGroup ? const FelixAvatar(size: avatarSize) : null,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(child: bubble),
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
    final danger = AppPalette.of(context).danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: AppText.bodyRegular.copyWith(color: color)),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 16, color: danger),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              AppLocalizations.of(context).chatTapToRetry,
              style: AppText.captionStrong.copyWith(color: danger),
            ),
          ],
        ),
      ],
    );
  }
}
