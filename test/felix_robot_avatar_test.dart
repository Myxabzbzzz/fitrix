import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/felix_avatar.dart';

Widget _host(Widget child, {Brightness b = Brightness.light}) => MaterialApp(
      theme: ThemeData(brightness: b),
      home: MediaQuery(
        data: const MediaQueryData(
            size: Size(375, 667), textScaler: TextScaler.linear(1.3)),
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  test('no code or asset still references the grey mannequin avatar', () {
    for (final dir in ['lib', 'test', 'integration_test']) {
      if (!Directory(dir).existsSync()) continue;
      for (final f in Directory(dir).listSync(recursive: true)) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        if (f.path.endsWith('felix_robot_avatar_test.dart')) continue;
        expect(f.readAsStringSync().contains('felix_avatar.png'), isFalse,
            reason: f.path);
      }
    }
    expect(File('assets/images/felix_avatar.png').existsSync(), isFalse);
  });

  for (final b in Brightness.values) {
    testWidgets('FelixAvatar renders the robot head, $b', (t) async {
      await t.pumpWidget(_host(const FelixAvatar(size: 32), b: b));
      final img = t.widget<Image>(find.byType(Image));
      expect((img.image as AssetImage).assetName,
          'assets/images/felix_robot_head.png');
      expect(img.fit, BoxFit.contain);
      expect(t.getSize(find.byType(FelixAvatar)), const Size(32, 32));
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('robot coach card fits SE at 1.3x text', (t) async {
    await t.pumpWidget(_host(const Padding(
      padding: EdgeInsets.all(16),
      child: CoachCard(
        eyebrow: 'FELIX',
        title: 'Strength coach',
        message: 'A longer message that wraps over several lines of text.',
        imageAsset: 'assets/images/felix_robot.png',
        primaryLabel: 'Start',
        secondaryLabel: 'Ask Felix',
      ),
    )));
    expect(t.takeException(), isNull);
  });
}
