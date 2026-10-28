import 'package:flutter/material.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/widgets/run_figure.dart';
import 'package:fitrix/features/running/presentation/widgets/run_map.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The middle of a ride's summary: map (outdoor), figures and 5 km splits.
/// An indoor ride has no map and no splits, and an unknown distance is
/// dashes.
class RideSummaryBody extends StatelessWidget {
  const RideSummaryBody({super.key, required this.details});

  final RunDetails details;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = l10n.localeName;
    final indoor = details.indoor;
    final known = details.meters > 0;
    final avg = averageSpeed(details.meters, details.moving);
    final loss = details.elevationLoss;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!indoor && details.route.isNotEmpty) ...[
          RunMap(route: details.route),
          const SizedBox(height: AppSpacing.md),
        ],
        RunFigureGrid(
          children: [
            RunFigure(
                label: '${l10n.runDistance}, ${l10n.runUnitKm}',
                value: known ? formatKm(details.meters, locale) : noValue),
            RunFigure(
                label: l10n.runMovingTime, value: formatClock(details.moving)),
            if (known || !indoor)
              RunFigure(
                  label: '${l10n.rideAvgSpeed}, ${l10n.unitKmh}',
                  value: formatSpeed(avg, locale)),
            if (details.maxSpeed != null)
              RunFigure(
                  label: '${l10n.rideMaxSpeed}, ${l10n.unitKmh}',
                  value: formatSpeed(details.maxSpeed, locale)),
            if (details.elevationGain != null)
              RunFigure(
                  label: l10n.runElevation,
                  value: l10n.runElevationValue(
                      formatMeters(details.elevationGain!, locale))),
            if (loss != null && !indoor)
              RunFigure(
                  label: l10n.rideElevationLoss,
                  value: l10n.runElevationValue(formatMeters(loss, locale))),
            if (details.avgPowerW != null)
              RunFigure(
                  label: l10n.rideAvgPower, value: '${details.avgPowerW}'),
          ],
        ),
        if (details.note != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(l10n.rideNote,
              style:
                  AppText.captionStrong.copyWith(color: palette.textSecondary)),
          const SizedBox(height: AppSpacing.xxs),
          Text(details.note!,
              key: const ValueKey('ride-summary-note'),
              style: AppText.body14.copyWith(color: palette.textPrimary)),
        ],
        if (details.splits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.runSplits,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          for (final s in details.splits) _RideSplitRow(split: s),
        ],
      ],
    );
  }
}

class _RideSplitRow extends StatelessWidget {
  const _RideSplitRow({required this.split});

  final RunSplit split;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final style = AppText.body14.copyWith(
        color: palette.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()]);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        children: [
          // A full 5 km split by the km it ends at; the rest by its length,
          // as the run summary does.
          Expanded(
            flex: 2,
            child: Text(
              split.meters >= rideProfile.splitMeters
                  ? '${split.km}'
                  : '${formatKm(split.meters, l10n.localeName)} ${l10n.runUnitKm}',
              style: style,
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(formatClock(split.time),
                  textAlign: TextAlign.end, style: style)),
          Expanded(
            flex: 3,
            child: Text(
              '${formatSpeed(averageSpeed(split.meters, split.time), l10n.localeName)} ${l10n.unitKmh}',
              textAlign: TextAlign.end,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
