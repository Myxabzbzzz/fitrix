import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// iPhone SE logical size, the smallest screen the layouts must fit.
const iPhoneSeSize = Size(375, 667);

/// Asserts that nothing threw while laying out: a RenderFlex overflow is
/// reported to the test binding as a FlutterError, which `takeException`
/// returns.
void expectNoOverflow(WidgetTester tester, {String? reason}) {
  expect(tester.takeException(), isNull, reason: reason);
}

/// Checks the first frame, scrolls [scrollable] by [dy] and checks again.
/// [settle] picks `pumpAndSettle` over a single `pump` after the drag.
Future<void> expectNoOverflowWhileScrolling(
    WidgetTester tester, Finder scrollable, double dy,
    {bool settle = true}) async {
  expectNoOverflow(tester);
  await tester.drag(scrollable, Offset(0, dy));
  settle ? await tester.pumpAndSettle() : await tester.pump();
  expectNoOverflow(tester);
}
