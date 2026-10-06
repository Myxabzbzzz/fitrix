import 'package:flutter/widgets.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';

/// Keeps a chat list pinned to the newest message.
///
/// New messages scroll smoothly; streamed text growing inside the last
/// bubble jumps instantly (animating on every token stutters). If the user
/// has scrolled up to read history, streaming doesn't yank them back down.
void followChatBottom(
  ScrollController controller,
  List<ChatMessage>? previous,
  List<ChatMessage> next,
) {
  final isNewMessage = previous == null || previous.length != next.length;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.hasClients) return;
    final position = controller.position;
    final target = position.maxScrollExtent;

    if (isNewMessage) {
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else if (target - position.pixels < 120) {
      controller.jumpTo(target);
    }
  });
}
