// Screenshot tour of every user-facing screen.
//
// Not run by a plain `flutter test` (the file name does not end in
// `_test.dart`). Run it explicitly:
//
//   flutter test test/tour/tour.dart
//   flutter test test/tour/tour.dart --plain-name 'pro-ru-light'
//   flutter test test/tour/tour.dart --dart-define=TOUR_OUT=/tmp/tour
//
// PNGs land in TOUR_OUT/<config>/<screen>.png; layout errors (overflows)
// are appended to TOUR_OUT/errors.log.
@Tags(['tour'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'tour_scenes.dart';

void main() {
  for (final cfg in tourConfigs) {
    group(cfg.id, () {
      for (final scene in tourScenes) {
        if (!scene.runsIn(cfg)) continue;
        testWidgets(scene.id, (t) async {
          await scene.run(t, cfg);
        }, timeout: const Timeout(Duration(minutes: 2)));
      }
    });
  }
}
