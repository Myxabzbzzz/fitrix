// Shared helpers for the on-simulator e2e walk (see tool/e2e/README.md).
//
// The app runs for real (real Supabase client against the LOCAL stack, real
// plugins). Anything only the Mac can do — simulator screenshots and videos,
// simulated GPS, backgrounding the app, reading the sign-in code from the
// local mail catcher — goes through tool/e2e/host_helper.py on 127.0.0.1:8765.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Talks to tool/e2e/host_helper.py.
class Host {
  static const _base = 'http://127.0.0.1:8765';

  static Future<String> get(String path, [Map<String, String>? q]) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: q);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(uri);
      final res = await req.close().timeout(const Duration(seconds: 90));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        throw HttpException('$path -> ${res.statusCode}: $body');
      }
      return body;
    } finally {
      client.close(force: true);
    }
  }

  static Future<void> log(String msg) async {
    debugPrint('E2E: $msg');
    try {
      await get('/log', {'msg': msg});
    } catch (_) {}
  }

  static Future<void> shot(String name) async {
    try {
      await get('/shot', {'name': name});
    } catch (e) {
      debugPrint('E2E: shot $name failed: $e');
    }
  }

  static Future<void> videoStart(String name) =>
      get('/video/start', {'name': name});
  static Future<void> videoStop() => get('/video/stop');

  /// Drives the simulated location along [pts] ("lat,lon") at [speed] m/s.
  static Future<void> route(List<String> pts, {double speed = 3}) =>
      get('/loc/start', {'pts': pts.join(';'), 'speed': '$speed'});
  static Future<void> setLocation(double lat, double lon) =>
      get('/loc/set', {'lat': '$lat', 'lon': '$lon'});
  static Future<void> clearLocation() => get('/loc/clear');

  /// Puts another app in front for [seconds], then brings FITRIX back.
  static Future<void> background(int seconds) =>
      get('/bg', {'seconds': '$seconds'});

  static Future<void> markMail(String email) =>
      get('/otp/mark', {'email': email});
  static Future<String> otp(String email) => get('/otp', {'email': email});
}

/// Errors the framework reported while the walk ran; logged, not fatal, so
/// one broken screen doesn't hide the rest of the walk.
final List<String> reportedErrors = [];

/// Must run right after the app's `main()` (which replaces nothing, but the
/// test binding installs its own handler that would fail the test).
void captureFlutterErrors() {
  FlutterError.onError = (details) {
    final text = details.exceptionAsString();
    final where = details.context?.toDescription() ?? '';
    final stack =
        details.stack?.toString().split('\n').take(12).join('\n') ?? '';
    reportedErrors.add('$text | $where\n$stack');
    // ignore: avoid_print
    print('E2E_FLUTTER_ERROR: $text | $where\n$stack');
    unawaited(Host.log('FLUTTER_ERROR $text | $where'));
  };
}

IntegrationTestWidgetsFlutterBinding initBinding() {
  final b = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Frames are drawn as the app asks for them, like a real run, so videos
  // show the real animations.
  b.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  return b;
}

/// Lets the app run for [d] of real time.
Future<void> idle(WidgetTester t,
    [Duration d = const Duration(milliseconds: 800)]) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(milliseconds: 16));
  }
}

/// Pumps until [f] finds something or [timeout] passes; returns whether found.
Future<bool> waitFor(WidgetTester t, Finder f,
    {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 100));
    if (f.evaluate().isNotEmpty) return true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return f.evaluate().isNotEmpty;
}

Future<bool> waitGone(WidgetTester t, Finder f,
    {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 100));
    if (f.evaluate().isEmpty) return true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return f.evaluate().isEmpty;
}

/// A step that logs and screenshots; a failure is recorded, not thrown, so
/// the walk continues with the next flow.
final List<String> stepFailures = [];

Future<void> step(WidgetTester t, String name, Future<void> Function() body,
    {bool shotAfter = true}) async {
  await Host.log('STEP $name');
  try {
    await body();
    if (shotAfter) {
      await idle(t, const Duration(milliseconds: 600));
      await Host.shot(name);
    }
  } catch (e, s) {
    final msg =
        'STEP FAILED $name: $e\n${s.toString().split('\n').take(8).join('\n')}';
    stepFailures.add(msg);
    // ignore: avoid_print
    print('E2E_STEP_FAILED: $msg');
    await Host.log('STEP_FAILED $name: $e');
    await Host.shot('FAILED_$name');
  }
}

/// Taps the first hit of [f] after waiting for it; throws if it never shows.
Future<void> tap(WidgetTester t, Finder f,
    {Duration timeout = const Duration(seconds: 20),
    bool scroll = true}) async {
  if (!await waitFor(t, f, timeout: timeout)) {
    throw StateError('not found: $f');
  }
  if (scroll) {
    try {
      await t.ensureVisible(f.first);
      await idle(t, const Duration(milliseconds: 300));
    } catch (_) {}
  }
  await t.tap(f.first, warnIfMissed: false);
  await idle(t, const Duration(milliseconds: 500));
}

Future<void> tapText(WidgetTester t, String text,
        {Duration timeout = const Duration(seconds: 20)}) =>
    tap(t, find.text(text), timeout: timeout);

Future<void> tapKey(WidgetTester t, String key,
        {Duration timeout = const Duration(seconds: 20)}) =>
    tap(t, find.byKey(Key(key)), timeout: timeout);

/// Scrolls the first scrollable until [f] is built, then taps it.
Future<void> scrollTap(WidgetTester t, Finder f,
    {Finder? scrollable, double delta = 250}) async {
  await scrollTo(t, f, scrollable: scrollable, delta: delta);
  await tap(t, f);
}

Future<void> scrollTo(WidgetTester t, Finder f,
    {Finder? scrollable, double delta = 250}) async {
  for (var i = 0; i < 30 && f.evaluate().isEmpty; i++) {
    final s = scrollable ?? mainScrollable();
    if (s.evaluate().isEmpty) break;
    await t.drag(s.first, Offset(0, -delta), warnIfMissed: false);
    await idle(t, const Duration(milliseconds: 250));
  }
  if (f.evaluate().isEmpty) throw StateError('not found after scrolling: $f');
  try {
    await t.ensureVisible(f.first);
  } catch (_) {}
  await idle(t, const Duration(milliseconds: 300));
}

Future<void> enter(WidgetTester t, Finder f, String text) async {
  if (!await waitFor(t, f)) throw StateError('not found: $f');
  await t.ensureVisible(f.first);
  await t.tap(f.first, warnIfMissed: false);
  await idle(t, const Duration(milliseconds: 300));
  await t.enterText(f.first, text);
  await idle(t, const Duration(milliseconds: 300));
}

/// Back like the system/app bar back: the first BackButton, else pop.
Future<void> back(WidgetTester t) async {
  final b = find.byType(BackButton);
  if (b.evaluate().isNotEmpty) {
    await t.tap(b.first, warnIfMissed: false);
  } else {
    final nav = t.state<NavigatorState>(find.byType(Navigator).last);
    await nav.maybePop();
  }
  await idle(t, const Duration(milliseconds: 700));
}

/// Writes collected errors and failures where the host can read them.
Future<void> writeReport(String phase) async {
  final out = Platform.environment['E2E_OUT'] ??
      '/private/tmp/claude-501/-Users-myxabzbzzzz--------fitrix/3181f353-a107-40c3-9418-ab2c1542d488/scratchpad/e2e';
  final buf = StringBuffer()
    ..writeln('# $phase')
    ..writeln('## step failures (${stepFailures.length})')
    ..writeAll(stepFailures, '\n\n')
    ..writeln()
    ..writeln('## flutter errors (${reportedErrors.length})')
    ..writeAll(reportedErrors, '\n\n');
  try {
    File('$out/report_$phase.txt').writeAsStringSync(buf.toString());
  } catch (e) {
    debugPrint('E2E: report write failed $e');
  }
  // ignore: avoid_print
  print('E2E_REPORT $phase\n$buf');
}

/// Text (plain or rich) equal to [s], ignoring case (tiles upper-case labels).
Finder ftext(String s) => find.byWidgetPredicate((w) {
      String? v;
      if (w is Text) v = w.data ?? w.textSpan?.toPlainText();
      if (w is RichText) v = w.text.toPlainText();
      return v != null && v.trim().toLowerCase() == s.trim().toLowerCase();
    });

/// Text containing [s], ignoring case.
Finder fcontains(String s) => find.byWidgetPredicate((w) {
      String? v;
      if (w is Text) v = w.data ?? w.textSpan?.toPlainText();
      if (w is RichText) v = w.text.toPlainText();
      return v != null && v.toLowerCase().contains(s.toLowerCase());
    });

/// Widgets whose key is a ValueKey<String> starting with [prefix].
Finder keyPrefix(String prefix) => find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key as ValueKey<String>).value.startsWith(prefix));

Finder byTypeName(String name) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

/// Taps a bottom tab by its icon (outlined or filled).
Future<void> goTab(WidgetTester t, IconData outlined, IconData filled) async {
  // Full-screen routes (run summary, live run) hide the tab bar: go back first.
  for (var i = 0;
      i < 3 &&
          find.byIcon(outlined).evaluate().isEmpty &&
          find.byIcon(filled).evaluate().isEmpty;
      i++) {
    await back(t);
  }
  final f = find.byIcon(outlined).evaluate().isNotEmpty
      ? find.byIcon(outlined)
      : find.byIcon(filled);
  await tap(t, f.last, scroll: false);
  await idle(t, const Duration(milliseconds: 900));
}

Future<void> goHome(WidgetTester t) =>
    goTab(t, Icons.home_outlined, Icons.home);

/// Holds a press on [f] for [hold] (hold-to-finish buttons).
Future<void> holdPress(WidgetTester t, Finder f, Duration hold) async {
  if (!await waitFor(t, f)) throw StateError('not found: $f');
  final g = await t.startGesture(t.getCenter(f.first));
  await idle(t, hold);
  await g.up();
  await idle(t, const Duration(milliseconds: 800));
}

/// Pops routes until [f] shows (max [n] backs).
Future<void> backUntil(WidgetTester t, Finder f, {int n = 4}) async {
  for (var i = 0; i < n && f.evaluate().isEmpty; i++) {
    await back(t);
  }
}

/// E2E_ONLY=gym,nutrition runs just those sections of a phase (all if empty).
const _only = String.fromEnvironment('E2E_ONLY');
bool want(String section) =>
    _only.isEmpty || _only.split(',').map((s) => s.trim()).contains(section);

/// Stops / starts the e2e Felix backend (port 3100, never 3000).
Future<void> backend(String action) => Host.get('/backend', {'action': action});

/// The biggest vertical scrollable on screen (not a chip row).
Finder mainScrollable() {
  final all = find.byType(Scrollable).evaluate().where((e) {
    final w = e.widget as Scrollable;
    final box = e.renderObject as RenderBox?;
    return axisDirectionToAxis(w.axisDirection) == Axis.vertical && box != null && box.hasSize;
  }).toList();
  if (all.isEmpty) return find.byType(Scrollable);
  all.sort((a, b) {
    final sa = (a.renderObject as RenderBox).size, sb = (b.renderObject as RenderBox).size;
    return (sb.width * sb.height).compareTo(sa.width * sa.height);
  });
  final target = all.first;
  return find.byElementPredicate((e) => e == target);
}
