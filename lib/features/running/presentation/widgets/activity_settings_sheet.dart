import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/data/activity_settings.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The small "Workout settings" sheet of a run, ride or ski day.
Future<void> showActivitySettingsSheet(
    BuildContext context, ActivityKind kind) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppPalette.of(context).background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => ActivitySettingsSheet(kind: kind),
  );
}

class ActivitySettingsSheet extends ConsumerWidget {
  const ActivitySettingsSheet({super.key, required this.kind});

  final ActivityKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(activityVoiceProvider)[kind] ?? false;
    final hint = switch (kind) {
      ActivityKind.run => l10n.activitySettingsVoiceRun,
      ActivityKind.ride => l10n.activitySettingsVoiceRide,
      ActivityKind.ski => l10n.activitySettingsVoiceSki,
    };
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.activitySettingsTitle,
                style: AppText.headingM.copyWith(color: palette.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.activitySettingsVoice,
                          style: AppText.bodyStrong
                              .copyWith(color: palette.textPrimary)),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(hint,
                          style: AppText.caption
                              .copyWith(color: palette.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  key: const ValueKey('activity-voice-toggle'),
                  value: on,
                  onChanged: (v) =>
                      ref.read(activityVoiceProvider.notifier).set(kind, v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
