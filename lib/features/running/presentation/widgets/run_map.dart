import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/features/map/data/routing_service.dart';
import 'package:fitrix/features/map/presentation/map_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The recorded route on OpenStreetMap tiles, fitted to the screen. Not
/// interactive, so the page around it keeps scrolling.
class RunMap extends ConsumerStatefulWidget {
  const RunMap({
    super.key,
    required this.route,
    this.height = 200,
    this.descents,
    this.selected,
  });

  /// `[[lat, lng], ...]`.
  final List<List<double>> route;
  final double height;

  /// A ski day: index ranges into [route]. The whole route is drawn faint
  /// (lifts, queues) and these stretches in the accent colour.
  final List<({int from, int to})>? descents;

  /// The descent (index into [descents]) drawn on top, thicker.
  final int? selected;

  @override
  ConsumerState<RunMap> createState() => _RunMapState();
}

class _RunMapState extends ConsumerState<RunMap> {
  // The TileLayer disposes its provider when it unmounts.
  TileProvider? _ownTiles;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final points = [for (final p in widget.route) LatLng(p[0], p[1])];

    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: SizedBox(
        height: widget.height,
        child: points.isEmpty
            ? ColoredBox(
                color: palette.tile,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      AppLocalizations.of(context).runNoRoute,
                      textAlign: TextAlign.center,
                      style:
                          AppText.body14.copyWith(color: palette.textSecondary),
                    ),
                  ),
                ),
              )
            : _map(palette, dark, points),
      ),
    );
  }

  Widget _map(AppPalette palette, bool dark, List<LatLng> points) {
    final tileProvider = ref.watch(mapTileProviderProvider) ??
        (_ownTiles ??= NetworkTileProvider());
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.elibayev.fitrix',
      tileProvider: tileProvider,
    );
    final single = points.length < 2 || points.every((p) => p == points.first);
    return FlutterMap(
      options: MapOptions(
        backgroundColor: palette.tile,
        initialCenter: points.first,
        initialZoom: 16,
        initialCameraFit: single
            ? null
            : CameraFit.coordinates(
                coordinates: points,
                padding: const EdgeInsets.all(32),
                maxZoom: 17,
              ),
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        ColorFiltered(
            colorFilter: dark ? osmDarkTiles : osmIdentityTiles, child: tiles),
        if (!single && widget.descents == null)
          PolylineLayer(polylines: [
            Polyline(
              points: points,
              strokeWidth: 6,
              color: palette.background.withValues(alpha: dark ? 0.6 : 0.9),
              strokeJoin: StrokeJoin.round,
              strokeCap: StrokeCap.round,
            ),
            Polyline(
              points: points,
              strokeWidth: 4,
              color: palette.accent,
              strokeJoin: StrokeJoin.round,
              strokeCap: StrokeCap.round,
            ),
          ]),
        if (!single && widget.descents != null)
          PolylineLayer(polylines: _skiLines(palette, dark, points)),
        CircleLayer(circles: [
          CircleMarker(
              point: points.first,
              radius: 6,
              color: palette.accent,
              borderColor: palette.background,
              borderStrokeWidth: 2),
          if (!single)
            CircleMarker(
                point: points.last,
                radius: 6,
                color: palette.textPrimary,
                borderColor: palette.background,
                borderStrokeWidth: 2),
        ]),
        OsmAttribution(dark: dark),
      ],
    );
  }

  /// Lifts and the rest faint, descents in the accent colour, the selected
  /// one thick and in the primary text colour with a halo.
  List<Polyline> _skiLines(AppPalette palette, bool dark, List<LatLng> all) {
    final halo = palette.background.withValues(alpha: dark ? 0.6 : 0.9);
    List<LatLng> part(({int from, int to}) d) {
      final from = d.from.clamp(0, all.length - 1);
      final to = d.to.clamp(from, all.length - 1);
      return all.sublist(from, to + 1);
    }

    Polyline line(List<LatLng> pts, double w, Color c) => Polyline(
          points: pts,
          strokeWidth: w,
          color: c,
          strokeJoin: StrokeJoin.round,
          strokeCap: StrokeCap.round,
        );

    final descents = widget.descents!;
    final sel = widget.selected;
    return [
      line(all, 3, palette.textSecondary.withValues(alpha: 0.5)),
      for (var i = 0; i < descents.length; i++)
        if (i != sel) ...[
          if (part(descents[i]).length > 1) line(part(descents[i]), 6, halo),
          if (part(descents[i]).length > 1)
            line(part(descents[i]), 4, palette.accent),
        ],
      if (sel != null && sel >= 0 && sel < descents.length) ...[
        line(part(descents[sel]), 9, halo),
        line(part(descents[sel]), 6, palette.textPrimary),
      ],
    ];
  }
}
