import 'dart:io';

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
      final text = Text(
        message.content,
        style: AppText.body14.copyWith(color: textColor),
      );
      final imagePath = message.imagePath;
      content = imagePath == null
          ? text
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ChatPhotoThumb(path: imagePath),
                const SizedBox(height: AppSpacing.xs),
                text,
              ],
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
              width: 24,
              child: lastInGroup ? const FelixAvatar(size: 24) : null,
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

/// A photo sent with a message; tap to view it full screen.
class ChatPhotoThumb extends StatelessWidget {
  final String path;

  const ChatPhotoThumb({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChatPhotoViewer(path: path)),
      ),
      child: ClipRRect(
        key: const ValueKey('chat-bubble-image'),
        borderRadius: AppRadius.smAll,
        child: Image.file(
          File(path),
          width: 160,
          height: 160,
          fit: BoxFit.cover,
          cacheWidth: 480,
          errorBuilder: (_, __, ___) => Container(
            width: 160,
            height: 160,
            color: palette.tile,
            child: Icon(Icons.image_not_supported_outlined,
                color: palette.textSecondary),
          ),
        ),
      ),
    );
  }
}

class ChatPhotoViewer extends StatelessWidget {
  final String path;

  const ChatPhotoViewer({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Scaffold(
      key: const ValueKey('chat-photo-viewer'),
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        elevation: 0,
        title: Text(AppLocalizations.of(context).chatPhotoViewer),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                color: palette.textSecondary),
          ),
        ),
      ),
    );
  }
}
