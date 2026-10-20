import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/providers/recent_chats_provider.dart';
import 'package:fitrix/features/chat/presentation/widgets/topic_row.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Every chat that has messages, newest first, then all nine topics.
class FelixAllChatsScreen extends ConsumerWidget {
  const FelixAllChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final chats = ref.watch(recentChatsProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: palette.textPrimary,
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(l10n.chatAllChats,
                        style: AppText.headingS
                            .copyWith(color: palette.textPrimary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  for (final chat in chats) ...[
                    RecentChatRow(
                      key: ValueKey('recent-chat-${chat.topic.id}'),
                      chat: chat,
                      now: now,
                      onTap: () =>
                          context.push(AppRouter.felixChat(chat.topic)),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                  if (chats.isNotEmpty) const SizedBox(height: AppSpacing.md),
                  Text(l10n.felixAllTopics,
                      style: AppText.headingS
                          .copyWith(color: palette.textPrimary)),
                  for (final topic in AssistantTopic.all) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TopicRow(
                      key: ValueKey('topic-row-${topic.id}'),
                      topic: topic,
                      onTap: () => context.push(AppRouter.felixChat(topic)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
