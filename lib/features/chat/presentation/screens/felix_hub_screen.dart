import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/time/greeting.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/providers/recent_chats_provider.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:fitrix/features/chat/presentation/widgets/topic_row.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/plan/presentation/widgets/plan_format.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/workouts/presentation/sport_l10n.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Felix tab: the nine topics, today at a glance and the latest chats.
class FelixHubScreen extends ConsumerWidget {
  const FelixHubScreen({super.key});

  static const _recentLimit = 3;

  /// "Back and Triceps today · Football on Saturday", or null when there is
  /// nothing to say.
  String? _todayLine(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plan = ref.watch(todayPlanProvider);
    final today = ref.watch(todayProvider);
    final horizon = addDays(today, 7);
    PlannedSession? next;
    for (final s in ref.watch(upcomingNonGymProvider)) {
      if (!s.day.isAfter(today) || s.day.isAfter(horizon)) continue;
      if (next == null || s.day.isBefore(next.day)) next = s;
    }
    final parts = [
      switch (plan.kind) {
        TodayKind.session => l10n.felixHubToday(plan.session!.title),
        TodayKind.rest => l10n.felixHubRest,
        TodayKind.done => l10n.felixHubDone,
        TodayKind.unplanned => null,
      },
      if (next != null)
        l10n.felixHubNext(
            next.sport.localizedLabel(l10n), weekdayLong(context, next.day)),
    ].whereType<String>();
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final now = ref.watch(clockProvider)();
    final name = ref.watch(profileProvider).valueOrNull?.name.trim() ?? '';
    final todayLine = _todayLine(context, ref);
    final recent = ref.watch(recentChatsProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Row(
              children: [
                const FelixAvatar(size: 48),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Felix',
                          style: AppText.headingM
                              .copyWith(color: palette.textPrimary)),
                      Text(l10n.felixHubAiCoach,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(timeOfDayGreeting(l10n, now, name),
                style: AppText.headingM.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.felixHubIntro,
                style:
                    AppText.bodyRegular.copyWith(color: palette.textSecondary)),
            if (todayLine != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(todayLine,
                  key: const ValueKey('felix-today-line'),
                  style: AppText.body14.copyWith(color: palette.textPrimary)),
            ],
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: l10n.felixHubTopicsHeader,
              trailing: l10n.felixHubTopicsCount(AssistantTopic.all.length),
            ),
            for (final topic in AssistantTopic.all) ...[
              const SizedBox(height: AppSpacing.xs),
              TopicRow(
                key: ValueKey('topic-row-${topic.id}'),
                topic: topic,
                onTap: () => context.push(AppRouter.felixChat(topic)),
              ),
            ],
            if (recent.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              _SectionHeader(
                title: l10n.felixHubRecent,
                action: l10n.felixHubSeeAll,
                onAction: () => context.push(AppRouter.felixAll),
              ),
              for (final chat in recent.take(_recentLimit)) ...[
                const SizedBox(height: AppSpacing.xs),
                RecentChatRow(
                  key: ValueKey('recent-chat-${chat.topic.id}'),
                  chat: chat,
                  now: now,
                  onTap: () => context.push(AppRouter.felixChat(chat.topic)),
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.trailing,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(title,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
        ),
        if (trailing != null)
          Text(trailing!,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!,
                style: AppText.body14.copyWith(color: palette.textPrimary)),
          ),
      ],
    );
  }
}
