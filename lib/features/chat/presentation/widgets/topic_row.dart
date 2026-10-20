import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/presentation/providers/recent_chats_provider.dart';
import 'package:fitrix/features/chat/presentation/topic_labels.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Material icon of a topic.
IconData topicIcon(AssistantTopic t) => switch (t.id) {
      'gym' => Icons.fitness_center,
      'fitness' => Icons.sports_gymnastics,
      'running' => Icons.directions_run,
      'cycling' => Icons.directions_bike,
      'football' => Icons.sports_soccer,
      'winterSports' => Icons.downhill_skiing,
      'nutrition' => Icons.restaurant,
      'recovery' => Icons.bedtime,
      _ => Icons.help_outline,
    };

/// "14:02" today, "Mon" within the last six days, "5 Oct" before that.
String chatTime(BuildContext context, DateTime at, DateTime now) {
  final locale = Localizations.localeOf(context).toString();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(at.year, at.month, at.day))
      .inDays;
  if (days <= 0) return DateFormat('HH:mm', locale).format(at);
  if (days < 7) return DateFormat('E', locale).format(at);
  return DateFormat('d MMM', locale).format(at);
}

class _RowShell extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Widget body;
  final Widget? trailing;

  const _RowShell({
    required this.icon,
    required this.onTap,
    required this.body,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.bubble,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(icon, size: 24, color: palette.textPrimary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: body),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A topic: icon, title, what it covers, chevron.
class TopicRow extends StatelessWidget {
  final AssistantTopic topic;
  final VoidCallback onTap;

  const TopicRow({super.key, required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return _RowShell(
      icon: topicIcon(topic),
      onTap: onTap,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(topicTitle(l10n, topic),
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
          Text(topicSubtitle(l10n, topic),
              style: AppText.caption.copyWith(color: palette.textSecondary)),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: palette.textSecondary),
    );
  }
}

/// A chat with its last message in one line and when it was written.
class RecentChatRow extends StatelessWidget {
  final RecentChat chat;
  final DateTime now;
  final VoidCallback onTap;

  const RecentChatRow({
    super.key,
    required this.chat,
    required this.now,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return _RowShell(
      icon: topicIcon(chat.topic),
      onTap: onTap,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(topicTitle(l10n, chat.topic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
          Text(chat.last.content.replaceAll('\n', ' '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(color: palette.textSecondary)),
        ],
      ),
      trailing: Text(chatTime(context, chat.last.timestamp, now),
          style: AppText.caption.copyWith(color: palette.textSecondary)),
    );
  }
}
