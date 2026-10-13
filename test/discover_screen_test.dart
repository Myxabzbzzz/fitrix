import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/supabase/supabase_providers.dart';
import 'package:fitrix/features/content/data/content_repository.dart';
import 'package:fitrix/features/content/presentation/article_screen.dart';
import 'package:fitrix/features/content/presentation/discover_screen.dart';
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/fake_content_source.dart';

const _user = User(
  id: 'u1',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

FakeContentSource _source() => FakeContentSource()
  ..programTable = const [
    Program(
        id: 'p1',
        title: 'Strength base',
        meta: '8 weeks',
        level: 'beginner',
        sport: 'gym',
        image: 'sport_gym'),
    Program(
        id: 'p2',
        title: 'Fat burn',
        meta: '6 weeks',
        level: 'medium',
        sport: 'fitness'),
  ]
  ..articleTable = const [
    Article(
        id: 'rest',
        tag: 'Recovery',
        title: 'Why rest days matter',
        body: 'First paragraph here.\n\nSecond paragraph here.',
        minutes: 4),
  ]
  ..challengeTable = [
    Challenge(
        id: 'steps-7',
        title: '7-day steps challenge',
        description: 'Walk',
        dailyTarget: '10,000 steps a day',
        days: 7,
        startsOn: DateTime(2026, 10, 12),
        endsOn: DateTime(2027, 12, 31)),
  ];

late GoRouter router;

Future<void> _pump(
  WidgetTester tester,
  FakeContentSource source, {
  bool signedIn = false,
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  router = GoRouter(initialLocation: '/discover', routes: [
    GoRoute(
      path: '/discover',
      builder: (_, __) => const DiscoverScreen(),
      routes: [
        GoRoute(
          path: 'article/:id',
          builder: (_, s) => ArticleScreen(id: s.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(path: '/sign-in', builder: (_, __) => const Text('sign-in page')),
    GoRoute(path: '/felix', builder: (_, __) => const Text('felix page')),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      contentRepositoryProvider
          .overrideWithValue(ContentRepository(source, () async => {})),
      currentUserProvider
          .overrideWith((ref) => Stream.value(signedIn ? _user : null)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _pill(WidgetTester tester, String label) async {
  if (find.text(label).evaluate().isEmpty) {
    // The pill row scrolls; bring the last pills into the built range.
    await tester.drag(find.byType(Scrollable).first, const Offset(-300, 0));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

final _list = find.descendant(
    of: find.byType(RefreshIndicator), matching: find.byType(Scrollable));

void main() {
  testWidgets('shows every section under For you', (tester) async {
    await _pump(tester, _source());
    expect(find.text('7-day steps challenge'), findsOneWidget);
    expect(find.text('Programs for you'), findsOneWidget);
    expect(find.text('Strength base'), findsOneWidget);
    expect(find.text('Ask Felix'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Why rest days matter'), 200,
        scrollable: _list.first);
    expect(find.text('Why rest days matter'), findsOneWidget);
  });

  testWidgets('filter pills hide sections', (tester) async {
    await _pump(tester, _source());
    await _pill(tester, 'Programs');
    expect(find.text('Programs for you'), findsOneWidget);
    expect(find.text('Join challenge'), findsNothing);
    expect(find.text('Ask Felix'), findsNothing);

    await _pill(tester, 'Challenges');
    expect(find.text('Join challenge'), findsOneWidget);
    expect(find.text('Programs for you'), findsNothing);

    await _pill(tester, 'Articles');
    expect(find.text('Why rest days matter'), findsOneWidget);
    expect(find.text('Join challenge'), findsNothing);
  });

  testWidgets('joining while signed out prompts to sign in', (tester) async {
    final source = _source();
    await _pump(tester, source);
    await tester.tap(find.text('Join challenge'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to join challenges'), findsOneWidget);
    expect(source.joined, isEmpty);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('sign-in page'), findsOneWidget);
  });

  testWidgets('joining while signed in joins and shows Joined', (tester) async {
    final source = _source();
    await _pump(tester, source, signedIn: true);
    expect(find.text('Joined'), findsNothing);
    await tester.tap(find.text('Join challenge'));
    await tester.pumpAndSettle();
    expect(source.joined['u1'], {'steps-7'});
    expect(find.text('Joined'), findsOneWidget);
    expect(find.text('Join challenge'), findsNothing);
  });

  testWidgets('already joined challenge shows Joined', (tester) async {
    final source = _source()..joined['u1'] = {'steps-7'};
    await _pump(tester, source, signedIn: true);
    expect(find.text('Joined'), findsOneWidget);
  });

  testWidgets('first program card aligns with the section title',
      (tester) async {
    await _pump(tester, _source());
    final title = tester.getTopLeft(find.text('Programs for you'));
    final card = tester.getTopLeft(find.byKey(const Key('program-p1')));
    expect(card.dx, title.dx);
  });

  testWidgets('Ask Felix goes to the Felix tab', (tester) async {
    await _pump(tester, _source());
    await tester.ensureVisible(find.text('Ask Felix'));
    await tester.tap(find.text('Ask Felix'));
    await tester.pumpAndSettle();
    expect(find.text('felix page'), findsOneWidget);
  });

  testWidgets('article opens and shows its paragraphs', (tester) async {
    await _pump(tester, _source());
    await _pill(tester, 'Articles');
    await tester.tap(find.text('Why rest days matter'));
    await tester.pumpAndSettle();
    expect(find.text('First paragraph here.'), findsOneWidget);
    expect(find.text('Second paragraph here.'), findsOneWidget);
    expect(find.text('RECOVERY').hitTestable(), findsOneWidget);
  });

  testWidgets('unknown article shows a message', (tester) async {
    await _pump(tester, _source());
    router.go('/discover/article/nope');
    await tester.pumpAndSettle();
    expect(find.text('This article isn’t available.'), findsOneWidget);
  });

  for (final code in ['en', 'ru', 'uz', 'es']) {
    testWidgets('no overflow on iPhone SE ($code)', (tester) async {
      await _pump(tester, _source(),
          size: const Size(375, 667), locale: Locale(code));
      expect(tester.takeException(), isNull);
      await tester.drag(_list.first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
