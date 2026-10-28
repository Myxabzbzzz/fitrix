import 'package:flutter/material.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/running/data/ski_live.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/widgets/live_stat.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The numbers of a ski day in progress: what the skier is doing, time on
/// the slopes, descents so far, vertical down and top speed.
class LiveSkiStats extends StatelessWidget {
  const LiveSkiStats({super.key, required this.live, required this.paused});

  /// Null until the recorder has anything (no ski day).
  final SkiLive? live;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final live = this.live;
    final state = paused
        ? l10n.runPausedLabel
        : switch (live?.motion ?? SkiMotion.stopped) {
            SkiMotion.descending => l10n.skiStateDescending,
            SkiMotion.lift => l10n.skiStateLift,
            SkiMotion.moving => l10n.skiStateMoving,
            SkiMotion.stopped => l10n.skiStateStopped,
          };
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            state,
            key: const ValueKey('ski-state'),
            style: AppText.headingM.copyWith(color: palette.accent),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        LiveStat(
          label: l10n.skiTimeOnSlopes,
          value: formatClock(live?.onSlopes ?? Duration.zero),
          size: 64,
          valueKey: const ValueKey('ski-slopes-time'),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: LiveStat(
                label: l10n.skiDescents,
                value: '${live?.descents ?? 0}',
                size: 32,
                valueKey: const ValueKey('ski-descents'),
              ),
            ),
            Expanded(
              child: LiveStat(
                label: l10n.skiVerticalDown,
                value: formatMeters(live?.verticalDown ?? 0, locale),
                size: 32,
                valueKey: const ValueKey('ski-vertical'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        LiveStat(
          label: '${l10n.rideMaxSpeed}, ${l10n.unitKmh}',
          value: formatSpeed(live?.maxSpeed, locale),
          size: 32,
          valueKey: const ValueKey('ski-max-speed'),
        ),
      ],
    );
  }
}
