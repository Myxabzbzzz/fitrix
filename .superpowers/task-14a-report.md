# Task 14a report: routing engine (+ fix round 1)

Worktree: /Users/myxabzbzzzz/РАБОТА/fitrix/.claude/worktrees/agent-ae1c0c3fee51bf49b, branch worktree-agent-ae1c0c3fee51bf49b.

## Implemented
- lib/features/map/routing/graph.dart: RouteGraph (fromJson, load(AssetBundle), adjacency, per-mode largest component, nearestNode, covers = within 600 m of main walk-component node), TravelMode, speedOf/allowed, flatM.
- metro.dart: MinHeap, colour parser (red/blue/green, #hex, unknown -> null), MetroLine, MetroRide, RouteLeg, MetroNetwork (rides, transfers < 450 m, Dijkstra).
- router.dart: RoutePlan, RoutePlanner (A*, plan, planAll). Returns null outside coverage (either endpoint).
- assets/data/route-graph.json (identical to prototype); pubspec: latlong2 ^0.9.1, assets/data/.
- Unknown metro colour: RouteLeg.lineColor null, MetroRide.color grey fallback.

## TDD
RED: `flutter test test/routing_test.dart` failed to compile (Undefined name 'TravelMode') before implementation.
GREEN: all 7 tests passed after implementation (commit 2bcf724).

## Fix round 1
- Renamed Router -> RoutePlanner (avoids clash with Flutter's Router<T>); file name unchanged; tests updated.
- planAll evaluates coverage once for both ends, then calls internal _plan per mode; plan() still checks coverage.
- Added test: covered start (me) to destination (40.0, 70.0) -> all planAll values null. It passed immediately (behaviour already held via per-mode plan checks), so there is no RED for it; it guards the refactor.
- `flutter test test/routing_test.dart` -> `+8: All tests passed!`; `flutter test` -> `+175 ~4: All tests passed!`; `flutter analyze` -> No issues found.
- planAll timing (one destination, warm): 3 ms (limit 200 ms).

## Notes
- pub get regenerated lib/l10n/generated/app_localizations_uz.dart; reverted, not committed.
- No Co-Authored-By per owner rule.
