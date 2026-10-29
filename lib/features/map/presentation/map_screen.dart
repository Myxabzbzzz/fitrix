import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/animation/motion.dart';
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

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final _controller = MapController();
  late final AnimationController _pan;
  TileProvider? _ownTiles;
  late TileProvider _tileProvider;
  String _filter = 'all';
  String? _selectedId;
  TravelMode _mode = TravelMode.walk;
  String? _routeFor;
  final _routes = <String, RouteSet>{};
  final _requested = <String>{};
  final _failed = <String>{};

  @override
  void initState() {
    super.initState();
    _pan = AnimationController(vsync: this, duration: Motion.medium);
  }

  @override
  void dispose() {
    _pan.dispose();
    // The TileLayer disposes its provider when it unmounts.
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
    _panTo(LatLng(p.lat, p.lon));
  }

  /// Centres the map on [target], animated unless reduced motion is on.
  void _panTo(LatLng target) {
    try {
      final camera = _controller.camera;
      final from = camera.center;
      final zoom = camera.zoom;
      _pan.removeListener(_panTick);
      if (Motion.reduced(context)) {
        _controller.move(target, zoom);
        return;
      }
      _panTick = () {
        final t = Motion.curve.transform(_pan.value);
        _controller.move(
          LatLng(from.latitude + (target.latitude - from.latitude) * t,
              from.longitude + (target.longitude - from.longitude) * t),
          zoom,
        );
      };
      _pan
        ..addListener(_panTick)
        ..forward(from: 0);
    } catch (_) {
      // The map is not laid out yet.
    }
  }

  VoidCallback _panTick = () {};

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
    _pan.stop();
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
    final location = ref.watch(myLocationProvider);
    _tileProvider = ref.watch(mapTileProviderProvider) ??
        (_ownTiles ??= NetworkTileProvider());

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenTitle(l10n.mapTitle),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                onSelected: (f) =>
                    _setFilter(f, places.valueOrNull ?? const []),
              ),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, box) {
                // The map keeps at least 140 px; the card scrolls beyond that.
                final cardMax =
                    (box.maxHeight - 140).clamp(0.0, double.infinity);
                return places.when(
                  loading: () => Center(
                      child: CircularProgressIndicator(color: palette.accent)),
                  error: (_, __) =>
                      _content(context, const [], cardMax, location),
                  data: (all) => _content(
                      context,
                      [
                        for (final p in all)
                          ref.watch(catalogTextProvider).place(p),
                      ],
                      cardMax,
                      location),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, List<Place> all, double cardMax,
      AsyncValue<LatLng?> location) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final visible = _visible(all);
    final selected = _selected(visible);
    final me = location.valueOrNull;
    final locationOff = location.hasValue && me == null;
    final locating = location.isLoading;

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
                    child:
                        _map(context, visible, selected, me, routeShown, plan),
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
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: cardMax),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
              children: [
                PlaceCard(
                  place: selected,
                  distanceMeters: locating
                      ? null
                      : const Distance()
                          .as(LengthUnit.Meter, from,
                              LatLng(selected.lat, selected.lon))
                          .toDouble(),
                  mode: _mode,
                  onMode: (m) => _setMode(m, selected),
                  routes: _routes[selected.id],
                  failed: _failed.contains(selected.id),
                  routeShown: routeShown,
                  onToggleRoute: () => _toggleRoute(selected),
                  now: ref.read(routeClockProvider)(),
                )
              ],
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
      tileProvider: _tileProvider,
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
        onPointerDown: (_, __) => _pan.stop(),
        interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        // Always wrapped, so the TileLayer is never remounted (and its
        // provider never disposed) when the theme changes.
        ColorFiltered(
            colorFilter: dark ? osmDarkTiles : osmIdentityTiles, child: tiles),
        if (routeShown && plan != null) ..._routeLayers(palette, plan, dark),
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
        OsmAttribution(dark: dark),
      ],
    );
  }

  List<Widget> _routeLayers(AppPalette palette, RoutePlan plan, bool dark) {
    final casing = palette.background.withValues(alpha: dark ? 0.6 : 0.9);
    final casings = <Polyline>[];
    final lines = <Polyline>[];
    final stations = <CircleMarker>[];
    for (final leg in plan.legs) {
      if (leg.kind == 'metro') {
        final color = leg.lineColor ?? palette.accent;
        casings
            .add(Polyline(points: leg.points, strokeWidth: 10, color: casing));
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
        casings
            .add(Polyline(points: leg.points, strokeWidth: 9, color: casing));
        lines.add(Polyline(
            points: leg.points, strokeWidth: 5, color: palette.accent));
      }
    }
    return [
      PolylineLayer(polylines: [...casings, ...lines]),
      if (stations.isNotEmpty) CircleLayer(circles: stations),
    ];
  }
}

/// No filter (light theme).
const ColorFilter osmIdentityTiles = ColorFilter.matrix(<double>[
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0,
  0, 0, 1, 0, 0,
  0, 0, 0, 1, 0,
]);

/// "Soft" dark map: keeps hues recognisable (parks stay
/// green, water blue) instead of a plain invert.
const ColorFilter osmDarkTiles = ColorFilter.matrix(<double>[
  0.1713, -0.8644, -0.087, 0, 210.9, //
  -0.2577, -0.4354, -0.087, 0, 210.9,
  -0.2577, -0.8644, 0.342, 0, 210.9,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final icon = Icon(_kindIcon(place.kind),
        size: 16, color: selected ? palette.onAccent : palette.accent);
    return Semantics(
      button: true,
      selected: selected,
      label: place.name,
      excludeSemantics: true,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: selected
                  ? palette.accent
                  : (dark ? palette.tile : palette.background),
              borderRadius: AppRadius.fullAll,
              border: Border.all(
                  color: selected ? palette.accent : palette.border, width: 1),
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
class OsmAttribution extends StatelessWidget {
  const OsmAttribution({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Align(
      alignment: Alignment.bottomRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dark
              ? palette.tile.withValues(alpha: 0.85)
              : palette.background.withValues(alpha: 0.8),
          borderRadius:
              const BorderRadius.only(topLeft: Radius.circular(AppRadius.sm)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
          child: Text(
            '© OpenStreetMap contributors',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.micro.copyWith(
                color: dark ? palette.textSecondary : palette.textPrimary),
          ),
        ),
      ),
    );
  }
}
