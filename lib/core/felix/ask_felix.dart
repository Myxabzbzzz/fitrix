import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';

/// Text waiting to be put into Felix's input field. The chat screen takes
/// it once and clears it; it is never sent automatically.
final felixDraftProvider = StateProvider<String?>((ref) => null);

/// Opens the Felix tab on [topic] with [draft] ready in the input field.
void askFelix(
  BuildContext context,
  WidgetRef ref, {
  required AssistantTopic topic,
  required String draft,
}) {
  ref.read(selectedAssistantTopicProvider.notifier).state = topic;
  ref.read(felixDraftProvider.notifier).state = draft;
  context.go(AppRouter.felix);
}
