import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fitrix/core/widgets/felix_avatar.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/services/photo_service.dart';
import 'package:fitrix/features/chat/presentation/widgets/typing_indicator.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

class ChatBubble extends StatelessWidget {
  static const double maxWidth = 247;

  /// Width of the avatar column beside a Felix bubble.
  static const double avatarSize = 24;

  final ChatMessage message;

  /// Called when Retry under a failed question is tapped.
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

    final bubble = Container(
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
    );

    final failure = message.failure;
    if (failure != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Flexible(child: bubble)],
            ),
            ChatFailedRow(failure: failure, onRetry: onRetry),
          ],
        ),
      );
    }

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

/// Localized reason Felix didn't answer.
String chatFailureText(AppLocalizations l10n, ChatFailure failure) =>
    switch (failure) {
      ChatFailure.unavailable => l10n.chatFailedUnavailable,
      ChatFailure.interrupted => l10n.chatFailedInterrupted,
      ChatFailure.unreadable => l10n.chatFailedUnreadable,
      ChatFailure.signInAgain => l10n.chatFailedSignIn,
      ChatFailure.tooFast => l10n.chatFailedTooFast,
      ChatFailure.photoUnavailable => l10n.chatPhotoUnavailable,
    };

/// Under a question Felix failed to answer: why, and a Retry button.
class ChatFailedRow extends StatelessWidget {
  final ChatFailure failure;
  final VoidCallback? onRetry;

  const ChatFailedRow({super.key, required this.failure, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const ValueKey('chat-failed'),
      padding: const EdgeInsets.only(top: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.error_outline, size: 16, color: palette.danger),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              chatFailureText(l10n, failure),
              textAlign: TextAlign.end,
              style: AppText.caption.copyWith(color: palette.textSecondary),
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              key: const ValueKey('chat-retry'),
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: palette.danger,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                minimumSize: const Size(0, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l10n.chatRetry, style: AppText.captionStrong),
            ),
        ],
      ),
    );
  }
}

/// A stored chat photo (see photo_service), resolved against the current
/// documents directory. Decoded at <= 480 px so landscape photos stay sharp.
class ChatPhotoImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool full;

  const ChatPhotoImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.full = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final placeholder = Container(
      width: width,
      height: height,
      color: palette.tile,
      child: Icon(Icons.image_not_supported_outlined,
          color: palette.textSecondary),
    );
    return FutureBuilder<String>(
      future: chatDocsDir(),
      builder: (context, snapshot) {
        final docs = snapshot.data;
        if (docs == null) return placeholder;
        final ImageProvider file =
            FileImage(File(resolveChatPhoto(docs, path)));
        return Image(
          image: full
              ? file
              : ResizeImage(file,
                  width: 480, height: 480, policy: ResizeImagePolicy.fit),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => placeholder,
        );
      },
    );
  }
}

/// A photo sent with a message; tap to view it full screen.
class ChatPhotoThumb extends StatelessWidget {
  final String path;

  const ChatPhotoThumb({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      image: true,
      label: AppLocalizations.of(context).chatPhotoViewer,
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => ChatPhotoViewer(path: path)),
        ),
        child: ClipRRect(
          key: const ValueKey('chat-bubble-image'),
          borderRadius: AppRadius.smAll,
          child: ChatPhotoImage(path: path, width: 160, height: 160),
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
          child: ChatPhotoImage(path: path, fit: BoxFit.contain, full: true),
        ),
      ),
    );
  }
}
