import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/running/data/activity_kind.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';
import 'package:fitrix/features/running/presentation/screens/live_run_screen.dart';

/// "Run in progress · 2.30 km · Return": shown above the tab bar while a run
/// exists (recording, paused, or restored after a crash). Tap opens the live
/// run; it is the way back after leaving that screen with its arrow.
class RunInProgressBar extends ConsumerWidget {
  const RunInProgressBar({super.key});

  static const double height = 48;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meters = ref.watch(
      runRecorderProvider.select((s) => s?.track.meters),
    );
    final kind = ref.watch(runRecorderProvider.select((s) => s?.kind));
    if (meters == null || kind == null) return const SizedBox.shrink();
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: height,
      child: Material(
        key: const ValueKey('run-bar'),
        color: palette.accent,
        child: InkWell(
          onTap: () => openLiveRun(GoRouter.of(context)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                // Only the label gives way: the distance is the live figure.
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          switch (kind) {
                            ActivityKind.run => l10n.runBarTitle,
                            ActivityKind.ride => l10n.rideBarTitle,
                            ActivityKind.ski => l10n.skiBarTitle,
                          },
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyStrong
                              .copyWith(color: palette.onAccent),
                        ),
                      ),
                      Text(
                        ' · ${formatKm(meters, l10n.localeName)} ${l10n.runUnitKm}',
                        key: const ValueKey('run-bar-distance'),
                        maxLines: 1,
                        softWrap: false,
                        style: AppText.bodyStrong
                            .copyWith(color: palette.onAccent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    l10n.runBarReturn,
                    key: const ValueKey('run-bar-return'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyStrong.copyWith(color: palette.onAccent),
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: palette.onAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
