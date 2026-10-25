import 'package:flutter/material.dart';

import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/run_recorder.dart';
import 'package:fitrix/features/running/presentation/widgets/live_stat.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The numbers of a ride in progress: speed, distance, moving time (the
/// clock stops while standing) and average speed.
class LiveRideStats extends StatelessWidget {
  const LiveRideStats({
    super.key,
    required this.session,
    required this.moving,
    required this.now,
  });

  final RunSession session;
  final Duration moving;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final meters = session.track.meters;
    final paused = session.phase == RunPhase.paused;
    return Column(
      children: [
        LiveStat(
          label: '${l10n.rideSpeed}, ${l10n.unitKmh}',
          value: formatSpeed(currentSpeed(session.track, now), locale),
          size: 72,
          valueKey: const ValueKey('ride-speed'),
        ),
        const SizedBox(height: AppSpacing.md),
        LiveStat(
          label: '${l10n.runDistance}, ${l10n.runUnitKm}',
          value: formatKm(meters, locale),
          size: 48,
          valueKey: const ValueKey('run-distance'),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: LiveStat(
                label: paused ? l10n.runPausedLabel : l10n.runMovingTime,
                value: formatClock(moving),
                size: 32,
                valueKey: const ValueKey('run-time'),
              ),
            ),
            Expanded(
              child: LiveStat(
                label: '${l10n.rideAvgSpeed}, ${l10n.unitKmh}',
                value: formatSpeed(averageSpeed(meters, moving), locale),
                size: 32,
                valueKey: const ValueKey('ride-avg-speed'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
