import 'package:flutter/material.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/running/data/run_track.dart';
import 'package:fitrix/features/running/data/ski_math.dart';
import 'package:fitrix/features/running/presentation/run_format.dart';
import 'package:fitrix/features/running/presentation/widgets/run_figure.dart';
import 'package:fitrix/features/running/presentation/widgets/run_map.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The middle of a ski day's summary: the map with every descent drawn, the
/// day's totals and the list of descents. Tapping a descent shows its stats
/// and highlights it on the map; tapping it again lets go.
class SkiSummaryBody extends StatefulWidget {
  const SkiSummaryBody({super.key, required this.details});

  final RunDetails details;

  @override
  State<SkiSummaryBody> createState() => _SkiSummaryBodyState();
}

class _SkiSummaryBodyState extends State<SkiSummaryBody> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final locale = l10n.localeName;
    final details = widget.details;
    final ski = details.ski;
    final descents = ski?.descents ?? const <SkiDescent>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (details.route.isNotEmpty) ...[
          RunMap(
            route: details.route,
            descents: [
              for (final d in descents) (from: d.routeFrom, to: d.routeTo)
            ],
            selected: _selected,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        RunFigureGrid(
          children: [
            RunFigure(label: l10n.skiDescents, value: '${descents.length}'),
            RunFigure(
                label: l10n.skiDistance,
                value: formatKm(ski?.skiMeters ?? details.meters, locale)),
            RunFigure(
                label: l10n.skiVerticalDown,
                value: formatMeters(ski?.verticalDown ?? 0, locale)),
            RunFigure(
                label: '${l10n.rideMaxSpeed}, ${l10n.unitKmh}',
                value: formatSpeed(ski?.maxSpeed ?? details.maxSpeed, locale)),
            RunFigure(
                label: '${l10n.skiAvgDescentSpeed}, ${l10n.unitKmh}',
                value: formatSpeed(ski?.avgDescentSpeed, locale)),
            RunFigure(
                label: l10n.skiTimeOnSlopes,
                value: formatClock(details.moving)),
            RunFigure(label: l10n.skiLifts, value: '${ski?.lifts ?? 0}'),
          ],
        ),
        if (descents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.skiDescents,
              style: AppText.headingS.copyWith(color: palette.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          for (var i = 0; i < descents.length; i++)
            _DescentRow(
              index: i,
              descent: descents[i],
              selected: _selected == i,
              onTap: () =>
                  setState(() => _selected = _selected == i ? null : i),
            ),
        ],
      ],
    );
  }
}

class _DescentRow extends StatelessWidget {
  const _DescentRow({
    required this.index,
    required this.descent,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final SkiDescent descent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final d = descent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Material(
        color: selected ? palette.tile : Colors.transparent,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          key: ValueKey('ski-descent-$index'),
          borderRadius: AppRadius.mdAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.skiDescentN(index + 1),
                        style: AppText.bodyStrong
                            .copyWith(color: palette.textPrimary),
                      ),
                    ),
                    Text(
                      '${formatKm(d.meters, locale)} ${l10n.runUnitKm}',
                      style:
                          AppText.body14.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
                if (selected) ...[
                  const SizedBox(height: AppSpacing.xs),
                  RunFigureGrid(
                    runSpacing: AppSpacing.xs,
                    children: [
                      RunFigure(
                          label: '${l10n.runDistance}, ${l10n.runUnitKm}',
                          value: formatKm(d.meters, locale)),
                      RunFigure(
                          label: l10n.skiDescentVertical,
                          value: formatMeters(d.vertical, locale)),
                      RunFigure(
                          label: l10n.skiDescentDuration,
                          value: formatClock(d.end.difference(d.start))),
                      RunFigure(
                          label: '${l10n.rideMaxSpeed}, ${l10n.unitKmh}',
                          value: formatSpeed(d.maxSpeed, locale)),
                      RunFigure(
                          label: '${l10n.rideAvgSpeed}, ${l10n.unitKmh}',
                          value: formatSpeed(d.avgSpeed, locale)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
