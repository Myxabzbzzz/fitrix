import 'package:flutter/material.dart';
import 'package:fitrix/core/time/greeting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitrix/core/navigation/circle_reveal.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/checkin/presentation/providers/checkin_provider.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_sheet.dart';
import 'package:fitrix/features/checkin/presentation/widgets/checkin_text.dart';
import 'package:fitrix/features/checkin/presentation/widgets/readiness_ring.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Home card: a greeting with "Check in" before today's check-in, a score
/// ring that opens Recovery after it.
class CheckInCard extends ConsumerWidget {
  const CheckInCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final checkIn = ref.watch(todayCheckInProvider);
    final r = ref.watch(todayReadinessProvider);

    if (checkIn != null && r != null) {
      return Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => openWithReveal(context, AppRouter.recovery),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
                color: palette.tile, borderRadius: AppRadius.smAll),
            child: Row(
              children: [
                ReadinessRing(
                  score: r.score,
                  size: 64,
                  strokeWidth: 6,
                  child: Text('${r.score}%',
                      style: AppText.bodyStrong
                          .copyWith(color: palette.textPrimary)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.readinessLabel(r.label),
                          style: AppText.headingS
                              .copyWith(color: palette.textPrimary)),
                      Text(l10n.checkinCardRecovered(r.score),
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                      Text(l10n.checkinCardSeeMore,
                          style:
                              AppText.caption.copyWith(color: palette.accent)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: palette.textSecondary),
              ],
            ),
          ),
        ),
      );
    }

    final name = ref.watch(profileProvider).valueOrNull?.name.trim() ?? '';
    ref.watch(todayProvider);
    final now = ref.read(clockProvider)();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: palette.tile, borderRadius: AppRadius.smAll),
      child: Row(
        children: [
          ReadinessRing(
            score: null,
            size: 56,
            strokeWidth: 5,
            child: Text('—',
                style:
                    AppText.bodyStrong.copyWith(color: palette.textSecondary)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timeOfDayGreeting(l10n, now, name),
                    style:
                        AppText.headingS.copyWith(color: palette.textPrimary)),
                Text(l10n.checkinCardPrompt,
                    style:
                        AppText.caption.copyWith(color: palette.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppButton(
            label: l10n.checkinCardAction,
            size: AppButtonSize.small,
            onPressed: () async {
              final saved = await showCheckInSheet(context);
              if (saved && context.mounted) {
                openWithReveal(context, AppRouter.recovery);
              }
            },
          ),
        ],
      ),
    );
  }
}
