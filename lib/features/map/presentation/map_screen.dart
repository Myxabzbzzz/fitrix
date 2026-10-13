import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/screen_title.dart';
import 'package:fitrix/features/content/data/models.dart';
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/features/map/data/location.dart';
import 'package:fitrix/features/map/data/routing_service.dart';
import 'package:fitrix/features/map/presentation/place_card.dart';
import 'package:fitrix/features/map/routing/router.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

const _filters = ['all', 'gyms', 'parks', 'tracks', 'pools'];

IconData _kindIcon(String kind) => switch (kind) {
      'gyms' => Icons.fitness_center,
      'parks' => Icons.park_outlined,
      'tracks' => Icons.directions_run,
      'pools' => Icons.pool,
      _ => Icons.place_outlined,
    };

/// Fitrix map: gyms, parks, tracks and pools on OpenStreetMap, with the way
/// there on foot, by bike, car or metro.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();
  String _filter = 'all';
  String? _selectedId;
  TravelMode _mode = TravelMode.walk;
  String? _routeFor;
  final _routes = <String, RouteSet>{};
  final _requested = <String>{};
  final _failed = <String>{};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Place> _visible(List<Place> all) =>
      _filter == 'all' ? all : all.where((p) => p.kind == _filter).toList();

  Place? _selected(List<Place> visible) {
    if (visible.isEmpty) return null;
    return visible.firstWhere((p) => p.id == _selectedId,
        orElse: () => visible.first);
  }

  Future<void> _load(Place place) async {
    try {
      final from =
          await ref.read(myLocationProvider.future).catchError((_) => null) ??
              amirTimurSquare;
      final set = await ref
          .read(routingServiceProvider)
          .plan(from, LatLng(place.lat, place.lon));
      if (!mounted) return;
      setState(() => _routes[place.id] = set);
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed.add(place.id));
    }
  }

  void _select(Place p) {
    setState(() {
      _selectedId = p.id;
      _routeFor = null;
    });
  }

  void _setFilter(String f, List<Place> all) {
    setState(() {
      _filter = f;
      _routeFor = null;
    });
    final visible = _visible(all);
    if (visible.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fit(visible.map((p) => LatLng(p.lat, p.lon)).toList());
    });
  }

  void _fit(List<LatLng> points, {double padding = 48}) {
    if (points.isEmpty) return;
    try {
      _controller.fitCamera(CameraFit.coordinates(
        coordinates: points,
        padding: EdgeInsets.all(padding),
        maxZoom: 16,
      ));
    } catch (_) {
      // The map is not laid out yet; the initial fit covers that case.
    }
  }

  void _toggleRoute(Place place) {
    if (_routeFor == place.id) {
      setState(() => _routeFor = null);
      return;
    }
    setState(() => _routeFor = place.id);
    _fitRoute(place);
  }

  void _fitRoute(Place place) {
    final plan = _routes[place.id]?.plans[_mode];
    if (plan == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fit([for (final leg in plan.legs) ...leg.points], padding: 40);
      }
    });
  }

  void _setMode(TravelMode m, Place place) {
    setState(() => _mode = m);
    if (_routeFor == place.id) _fitRoute(place);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final places = ref.watch(placesProvider);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.mapTitle),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm),
              child: PillSelector<String>(
                items: _filters,
                selected: _filter,
                labelOf: (f) => switch (f) {
                  'gyms' => l10n.mapFilterGyms,
                  'parks' => l10n.mapFilterParks,
                  'tracks' => l10n.mapFilterTracks,
                  'pools' => l10n.mapFilterPools,
                  _ => l10n.mapFilterAll,
                },
                onSelected: (f) => _setFilter(f, places.valueOrNull ?? const []),
              ),
            ),
            Expanded(
              child: places.when(
                loading: () => Center(
                    child: CircularProgressIndicator(color: palette.accent)),
                error: (_, __) => _content(context, const []),
                data: (all) => _content(context, all),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<Place> all) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final visible = _visible(all);
    final selected = _selected(visible);
    final location = ref.watch(myLocationProvider);
    final me = location.valueOrNull;
    final locationOff = location.hasValue && me == null;

    if (selected != null && _requested.add(selected.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(selected);
      });
    }

    final from = me ?? amirTimurSquare;
    final routeShown = selected != null && _routeFor == selected.id;
    final plan = selected == null ? null : _routes[selected.id]?.plans[_mode];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _map(context, visible, selected, me, routeShown, plan),
                  ),
                  if (locationOff)
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.background,
                            borderRadius: AppRadius.fullAll,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xxs),
                            child: Text(l10n.mapLocationOff,
                                style: AppText.caption
                                    .copyWith(color: palette.textPrimary)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (selected != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: PlaceCard(
              place: selected,
              distanceMeters: const Distance()
                  .as(LengthUnit.Meter, from, LatLng(selected.lat, selected.lon))
                  .toDouble(),
              mode: _mode,
              onMode: (m) => _setMode(m, selected),
              routes: _routes[selected.id],
              failed: _failed.contains(selected.id),
              routeShown: routeShown,
              onToggleRoute: () => _toggleRoute(selected),
              now: ref.read(routeClockProvider)(),
            ),
          ),
      ],
    );
  }

  Widget _map(BuildContext context, List<Place> visible, Place? selected,
      LatLng? me, bool routeShown, RoutePlan? plan) {
    final palette = AppPalette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.elibayev.fitrix',
      tileProvider: ref.watch(mapTileProviderProvider),
    );
    final points = [for (final p in visible) LatLng(p.lat, p.lon)];

    // Selected pin last, so it draws on top.
    final ordered = [
      ...visible.where((p) => p.id != selected?.id),
      if (selected != null) selected,
    ];

    return FlutterMap(
      mapController: _controller,
      options: MapOptions(
        backgroundColor: palette.tile,
        initialCenter: amirTimurSquare,
        initialZoom: 13,
        initialCameraFit: points.isEmpty
            ? null
            : CameraFit.coordinates(
                coordinates: points,
                padding: const EdgeInsets.all(48),
                maxZoom: 16,
              ),
        interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        dark
            ? ColorFiltered(colorFilter: _darkTiles, child: tiles)
            : tiles,
        if (routeShown && plan != null) ..._routeLayers(palette, plan),
        MarkerLayer(
          markers: [
            if (me != null)
              Marker(
                point: me,
                width: 40,
                height: 40,
                child: const _MeDot(),
              ),
            for (final p in ordered)
              Marker(
                point: LatLng(p.lat, p.lon),
                width: p.id == selected?.id ? 220 : 30,
                height: 30,
                alignment: Alignment.topCenter,
                child: _Pin(
                  key: ValueKey('pin-${p.id}'),
                  place: p,
                  selected: p.id == selected?.id,
                  onTap: () => _select(p),
                ),
              ),
          ],
        ),
        const _Attribution(),
      ],
    );
  }

  List<Widget> _routeLayers(AppPalette palette, RoutePlan plan) {
    final casings = <Polyline>[];
    final lines = <Polyline>[];
    final stations = <CircleMarker>[];
    for (final leg in plan.legs) {
      if (leg.kind == 'metro') {
        final color = leg.lineColor ?? palette.accent;
        casings.add(Polyline(
            points: leg.points,
            strokeWidth: 10,
            color: palette.background.withValues(alpha: 0.9)));
        lines.add(Polyline(points: leg.points, strokeWidth: 6, color: color));
        for (final pt in leg.points) {
          stations.add(CircleMarker(
            point: pt,
            radius: 4,
            color: palette.background,
            borderColor: color,
            borderStrokeWidth: 2,
          ));
        }
      } else if (leg.kind == 'walk' && plan.mode != TravelMode.walk) {
        lines.add(Polyline(
          points: leg.points,
          strokeWidth: 4,
          color: palette.accent,
          pattern: StrokePattern.dashed(segments: const [4, 8]),
        ));
      } else {
        casings.add(Polyline(
            points: leg.points,
            strokeWidth: 9,
            color: palette.background.withValues(alpha: 0.9)));
        lines.add(
            Polyline(points: leg.points, strokeWidth: 5, color: palette.accent));
      }
    }
    return [
      PolylineLayer(polylines: [...casings, ...lines]),
      if (stations.isNotEmpty) CircleLayer(circles: stations),
    ];
  }
}

/// Inverts the light OSM tiles and dims them for the dark theme.
const ColorFilter _darkTiles = ColorFilter.matrix(<double>[
  -0.85, 0, 0, 0, 216.75, //
  0, -0.85, 0, 0, 216.75,
  0, 0, -0.85, 0, 216.75,
  0, 0, 0, 1, 0,
]);

class _Pin extends StatelessWidget {
  const _Pin({
    super.key,
    required this.place,
    required this.selected,
    required this.onTap,
  });

  final Place place;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final icon = Icon(_kindIcon(place.kind),
        size: 16, color: selected ? palette.onAccent : palette.accent);
    return Semantics(
      button: true,
      selected: selected,
      label: place.name,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? palette.accent : palette.background,
              borderRadius: AppRadius.fullAll,
              border: Border.all(
                  color: selected ? palette.accent : palette.border),
            ),
            child: SizedBox(
              height: 30,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: selected ? AppSpacing.sm : 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    if (selected) ...[
                      const SizedBox(width: AppSpacing.xxs),
                      Flexible(
                        child: Text(place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.captionStrong
                                .copyWith(color: palette.onAccent)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Center(
      key: const ValueKey('me-dot'),
      child: DecoratedBox(
        decoration:
            BoxDecoration(color: palette.accentSoft, shape: BoxShape.circle),
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.accent,
                shape: BoxShape.circle,
                border: Border.all(color: palette.background, width: 3),
              ),
              child: const SizedBox(width: 16, height: 16),
            ),
          ),
        ),
      ),
    );
  }
}

/// "© OpenStreetMap contributors", always visible in the map's corner.
class _Attribution extends StatelessWidget {
  const _Attribution();

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Align(
      alignment: Alignment.bottomRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.background.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          child: Text(
            '© OpenStreetMap contributors',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.micro.copyWith(color: palette.textPrimary),
          ),
        ),
      ),
    );
  }
}
