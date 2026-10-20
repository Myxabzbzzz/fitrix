import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';

/// Text waiting to be put into Felix's input field. The chat screen takes
/// it once and clears it; it is never sent automatically.
final felixDraftProvider = StateProvider<String?>((ref) => null);

/// The chat the draft is for, so another open chat leaves it alone. Null
/// means any chat.
final felixDraftTopicProvider = StateProvider<AssistantTopic?>((ref) => null);

/// Opens the Felix chat for [topic] with [draft] ready in the input field.
void askFelix(
  BuildContext context,
  WidgetRef ref, {
  required AssistantTopic topic,
  required String draft,
}) {
  ref.read(felixDraftTopicProvider.notifier).state = topic;
  ref.read(felixDraftProvider.notifier).state = draft;
  context.go(AppRouter.felixChat(topic));
}
