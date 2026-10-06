import 'package:flutter/widgets.dart';
import 'package:fitrix/core/animation/motion.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';

/// Decides which chat messages get an entrance animation: only messages
/// inserted after the history was first shown — never the loaded history,
/// and never again on later rebuilds (e.g. each streamed token).
class ChatEntranceTracker {
  final Set<String> _seen = {};
  final Map<String, Duration> _pending = {};
  Object? _scope;
  bool _seeded = false;

  /// Stagger between messages inserted together (user message + reply).
  static const Duration stagger = Duration(milliseconds: 90);

  /// Call with the current list on every build. The first list seen for a
  /// [scope] (e.g. a chat topic) is treated as history.
  void sync(List<ChatMessage> messages, {Object? scope}) {
    if (!_seeded || scope != _scope) {
      _seeded = true;
      _scope = scope;
      _pending.clear();
      _seen
        ..clear()
        ..addAll(messages.map((m) => m.id));
      return;
    }
    // Anything still pending from an earlier build was never laid out
    // (scrolled away), so it shouldn't animate later out of context.
    _pending.clear();
    var batch = 0;
    for (final m in messages) {
      if (_seen.add(m.id)) _pending[m.id] = stagger * batch++;
    }
  }

  /// The entrance delay for [message] if it should animate in, else null.
  /// Consumed on first call so the entrance never replays.
  Duration? take(ChatMessage message) => _pending.remove(message.id);
}

/// Slides/fades a chat item in when it is first inserted. Key it by message
/// id so a different message at the same index gets its own entrance.
class ChatEntrance extends StatelessWidget {
  final ChatMessage message;

  /// Null: no animation (history, or already shown).
  final Duration? delay;
  final Widget child;

  const ChatEntrance({
    super.key,
    required this.message,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    return FadeSlideIn(
      animate: delay != null,
      delay: delay ?? Duration.zero,
      duration: Motion.medium,
      offset: Offset(isUser ? 12 : -12, 14),
      scale: 0.94,
      scaleAlignment: isUser ? Alignment.bottomRight : Alignment.bottomLeft,
      child: child,
    );
  }
}
