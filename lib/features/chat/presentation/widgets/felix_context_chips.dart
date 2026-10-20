import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/chat/data/felix_snapshot.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Up to three display-only chips with the numbers Felix has for this chat.
/// Nothing is shown when there is nothing to show.
class FelixContextChips extends StatelessWidget {
  final FelixSnapshot snapshot;
  final AssistantTopic topic;

  const FelixContextChips(
      {super.key, required this.snapshot, required this.topic});

  List<String> _labels(AppLocalizations l10n) {
    final number = NumberFormat.decimalPattern(l10n.localeName);
    if (topic == AssistantTopic.nutrition) {
      final eaten = snapshot.eaten;
      final targets = snapshot.targets;
      return [
        if (eaten != null && targets != null)
          l10n.felixChipKcal(
              number.format(eaten.kcal), number.format(targets.kcal)),
        if (eaten != null)
          l10n.felixChipProtein(number.format(eaten.protein.round())),
      ];
    }
    final readiness = snapshot.readiness;
    final session = snapshot.todaySession;
    final last = snapshot.lastWorkout;
    return [
      if (readiness != null) l10n.felixChipReadiness(readiness.score),
      if (session != null)
        l10n.felixChipToday(session.title)
      else if (snapshot.todayKind == TodayKind.rest)
        l10n.felixChipRest,
      if (last != null) l10n.felixChipLast(last.name),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels(AppLocalizations.of(context));
    if (labels.isEmpty) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final width = MediaQuery.sizeOf(context).width;
    return SingleChildScrollView(
      key: const ValueKey('felix-context-chips'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          for (var i = 0; i < labels.length && i < 3; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.xs),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width * 0.7),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.fullAll,
                  border: Border.all(color: palette.border),
                ),
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(color: palette.textSecondary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
