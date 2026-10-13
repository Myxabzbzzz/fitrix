import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/features/content/data/models.dart';
import 'package:fitrix/features/map/data/routing_service.dart';
import 'package:fitrix/features/map/routing/router.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

String formatDuration(AppLocalizations l10n, Duration d) {
  final m = (d.inSeconds / 60).round().clamp(1, 100000);
  return m < 60 ? l10n.mapMinutes(m) : l10n.mapHoursMinutes(m ~/ 60, m % 60);
}

String formatLength(AppLocalizations l10n, double meters) => meters < 1000
    ? l10n.mapMeters(((meters / 10).round() * 10))
    : l10n.mapKilometers((meters / 1000).toStringAsFixed(1));

IconData _modeIcon(TravelMode m) => switch (m) {
      TravelMode.walk => Icons.directions_walk,
      TravelMode.bike => Icons.directions_bike,
      TravelMode.car => Icons.directions_car,
      TravelMode.metro => Icons.subway_outlined,
    };

String _modeLabel(AppLocalizations l10n, TravelMode m) => switch (m) {
      TravelMode.walk => l10n.mapModeWalk,
      TravelMode.bike => l10n.mapModeBike,
      TravelMode.car => l10n.mapModeCar,
      TravelMode.metro => l10n.mapModeMetro,
    };

/// The sheet below the map: the selected place, how to get there in four
/// ways and a summary of the chosen one.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.distanceMeters,
    required this.mode,
    required this.onMode,
    required this.routes,
    required this.failed,
    required this.routeShown,
    required this.onToggleRoute,
    required this.now,
  });

  final Place place;

  /// Null while the user's position is still being determined.
  final double? distanceMeters;
  final TravelMode mode;
  final ValueChanged<TravelMode> onMode;

  /// Null while the routes are being computed.
  final RouteSet? routes;
  final bool failed;
  final bool routeShown;
  final VoidCallback onToggleRoute;
  final DateTime now;

  RoutePlan? get _plan => routes?.plans[mode];
  bool get _covered => routes?.covered ?? false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);

    return Container(
      key: const ValueKey('place-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration:
          BoxDecoration(color: palette.sheet, borderRadius: AppRadius.mdAll),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  place.name,
                  key: const ValueKey('place-title'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.headingS.copyWith(color: palette.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(place.type,
                  style:
                      AppText.caption.copyWith(color: palette.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            children: [
              _Meta(
                  icon: Icons.place_outlined,
                  text: l10n.mapAway(distanceMeters == null
                      ? '…'
                      : formatLength(l10n, distanceMeters!))),
              _Meta(
                  icon: Icons.schedule,
                  text: place.hours ?? l10n.mapHoursUnknown),
            ],
          ),
          if (place.note != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(place.note!,
                style: AppText.captionStrong.copyWith(color: palette.accent)),
          ],
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            container: true,
            label: l10n.mapModesLabel,
            child: Row(
              children: [
                for (final m in TravelMode.values) ...[
                  if (m != TravelMode.walk) const SizedBox(width: 6),
                  Expanded(child: _modeButton(context, l10n, palette, m)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: _summary(context, l10n, palette),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            key: const ValueKey('route-toggle'),
            label: routeShown ? l10n.mapHideRoute : l10n.mapShowRoute,
            icon: Icons.route,
            expand: true,
            onPressed: _plan == null ? null : onToggleRoute,
          ),
        ],
      ),
    );
  }

  Widget _modeButton(BuildContext context, AppLocalizations l10n,
      AppPalette palette, TravelMode m) {
    final selected = m == mode;
    final plan = routes?.plans[m];
    final enabled = routes != null && _covered;
    final text = routes == null
        ? (failed ? '—' : '…')
        : plan == null
            ? '—'
            : formatDuration(l10n, plan.duration);
    final fg = selected ? palette.onPillSelected : palette.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '${_modeLabel(l10n, m)}, $text',
      excludeSemantics: true,
      child: Material(
        key: ValueKey('mode-${m.name}'),
        color: selected ? palette.pillSelected : palette.background,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? () => onMode(m) : null,
          child: Opacity(
            opacity: routes != null && !_covered ? 0.4 : 1,
            child: SizedBox(
              height: 50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_modeIcon(m), size: 18, color: fg),
                  const SizedBox(height: 2),
                  Text(text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.captionStrong.copyWith(
                          color: fg,
                          fontFeatures: const [FontFeature.tabularFigures()])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(
      BuildContext context, AppLocalizations l10n, AppPalette palette) {
    Text plain(String t) =>
        Text(t, style: AppText.caption.copyWith(color: palette.textSecondary));
    if (failed) return plain(l10n.mapPlanFailed);
    if (routes == null) return plain(l10n.mapComputing);
    if (!_covered) return plain(l10n.mapCoverage);
    final plan = _plan;
    if (plan == null) {
      return plain(
          mode == TravelMode.metro ? l10n.mapMetroNoHelp : l10n.mapNoRoute);
    }
    final arrive = DateFormat('HH:mm').format(now.add(plan.duration));
    final head = Text(
      l10n.mapArrive(formatDuration(l10n, plan.duration), arrive),
      style: AppText.bodyStrong.copyWith(color: palette.textPrimary),
    );
    if (mode == TravelMode.metro) {
      final total = l10n.mapWalkTotal(formatLength(l10n, plan.meters));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          head,
          for (var i = 0; i < plan.rides.length; i++)
            Row(
              children: [
                Container(
                  key: ValueKey('line-dot-$i'),
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                      color: plan.rides[i].color, shape: BoxShape.circle),
                ),
                Expanded(
                  child: Text(
                    l10n.mapRide(plan.rides[i].from, plan.rides[i].to,
                        plan.rides[i].stops),
                    style: AppText.caption.copyWith(color: palette.textPrimary),
                  ),
                ),
              ],
            ),
          Text(
            plan.walkingIsFaster ? '$total · ${l10n.mapWalkingFaster}' : total,
            style: AppText.caption.copyWith(color: palette.textSecondary),
          ),
        ],
      );
    }
    final length = formatLength(l10n, plan.meters);
    final note = switch (mode) {
      TravelMode.bike => l10n.mapNoteBike(length),
      TravelMode.car => l10n.mapNoteCar(length),
      _ => l10n.mapNoteWalk(length),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [head, plain(note)],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: palette.textSecondary),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(text,
              style: AppText.caption.copyWith(color: palette.textPrimary)),
        ),
      ],
    );
  }
}
