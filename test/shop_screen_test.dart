import 'dart:async';
import 'dart:io';

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
import 'package:fitrix/features/content/providers.dart';
import 'package:fitrix/features/shop/presentation/shop_screen.dart';
import 'package:fitrix/features/shop/providers.dart';
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
  ..productTable = const [
    Product(
        id: 'whey',
        name: 'Whey protein, 2 kg',
        category: 'supplements',
        priceCents: 5400,
        word: 'WHEY'),
    Product(
        id: 'bands',
        name: 'Resistance bands',
        category: 'equipment',
        priceCents: 1600,
        word: 'BANDS'),
    Product(
        id: 'box',
        name: 'Starter box',
        category: 'equipment',
        priceCents: 3500,
        image: 'tile_shop'),
    Product(
        id: 'tee',
        name: 'FITRIX tee',
        category: 'apparel',
        priceCents: 2500,
        word: 'TEE'),
  ];

Future<ProviderContainer> _pump(
  WidgetTester tester,
  FakeContentSource source, {
  bool signedIn = false,
  Size size = const Size(390, 844),
  Locale locale = const Locale('en'),
  double textScale = 1,
  Map<String, Object> prefsInit = const {},
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefsInit);
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(initialLocation: '/shop', routes: [
    GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
    GoRoute(path: '/sign-in', builder: (_, __) => const Text('sign-in page')),
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
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
  return ProviderScope.containerOf(tester.element(find.byType(ShopScreen)));
}

Future<void> _add(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(Key('add-$id')));
  await tester.pump();
}

Future<void> _openCart(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('cart-button')));
  await tester.pumpAndSettle();
}

class _SlowSource extends FakeContentSource {
  final gate = Completer<void>();
  int calls = 0;

  @override
  Future<String> placeOrder(Map<String, int> quantities) async {
    calls++;
    await gate.future;
    return super.placeOrder(quantities);
  }
}

void main() {
  testWidgets('lists products with image or word placeholder', (tester) async {
    await _pump(tester, _source());
    expect(find.text('Whey protein, 2 kg'), findsOneWidget);
    expect(find.text('WHEY'), findsOneWidget);
    expect(find.text('\$54.00'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget); // Starter box
    expect(find.text('FITRIX Pro'), findsOneWidget);
  });

  testWidgets('search filters by name, case-insensitively', (tester) async {
    await _pump(tester, _source());
    await tester.enterText(find.byType(TextField), 'WhEy');
    await tester.pumpAndSettle();
    expect(find.text('Whey protein, 2 kg'), findsOneWidget);
    expect(find.text('Resistance bands'), findsNothing);
    expect(find.text('FITRIX tee'), findsNothing);
    expect(find.text('Learn more'), findsNothing); // promo hidden
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing found'), findsOneWidget);
  });

  testWidgets('category pills filter products', (tester) async {
    await _pump(tester, _source());
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    expect(find.text('Resistance bands'), findsOneWidget);
    expect(find.text('Starter box'), findsOneWidget);
    expect(find.text('Whey protein, 2 kg'), findsNothing);
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Whey protein, 2 kg'), findsOneWidget);
  });

  testWidgets('promo button opens the coming soon sheet', (tester) async {
    await _pump(tester, _source());
    await tester.tap(find.text('Learn more'));
    await tester.pumpAndSettle();
    expect(find.text('FITRIX Pro is coming soon'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('FITRIX Pro is coming soon'), findsNothing);
  });

  testWidgets('adding twice shows 2 on the cart badge', (tester) async {
    final c = await _pump(tester, _source());
    expect(find.byKey(const Key('cart-count')), findsNothing);
    await _add(tester, 'whey');
    await _add(tester, 'whey');
    await tester.pumpAndSettle();
    expect(
        find.descendant(
            of: find.byKey(const Key('cart-count')), matching: find.text('2')),
        findsOneWidget);
    expect(c.read(cartProvider), {'whey': 2});
  });

  testWidgets('cart sheet adjusts quantities and shows the total',
      (tester) async {
    final c = await _pump(tester, _source());
    await _add(tester, 'whey');
    await _add(tester, 'bands');
    await _openCart(tester);
    expect(find.text('\$70.00'), findsOneWidget); // total 54 + 16
    await tester.tap(find.byKey(const Key('cart-inc-bands')));
    await tester.pumpAndSettle();
    expect(c.read(cartProvider)['bands'], 2);
    await tester.tap(find.byKey(const Key('cart-dec-bands')));
    await tester.tap(find.byKey(const Key('cart-dec-bands')));
    await tester.pumpAndSettle();
    expect(c.read(cartProvider).containsKey('bands'), isFalse);
    expect(find.text('\$54.00'), findsWidgets);
  });

  testWidgets('placing an order signed in calls the source once and clears',
      (tester) async {
    final source = _source();
    final c = await _pump(tester, source, signedIn: true);
    await _add(tester, 'whey');
    await _add(tester, 'whey');
    await _openCart(tester);
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(source.lastOrder, {'whey': 2});
    expect(c.read(cartProvider), isEmpty);
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.byKey(const Key('cart-count')), findsNothing);
  });

  testWidgets('stale cart ids are left out of the order', (tester) async {
    final source = _source();
    await _pump(tester, source,
        signedIn: true, prefsInit: {'cart': '{"whey":1,"gone":3}'});
    await _openCart(tester);
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(source.lastOrder, {'whey': 1});
  });

  testWidgets('placing an order signed out asks to sign in', (tester) async {
    final source = _source();
    final c = await _pump(tester, source);
    await _add(tester, 'whey');
    await _openCart(tester);
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    // No accounts in this test app: nothing to sign in to.
    expect(find.text('Accounts are unavailable right now. Try again later.'),
        findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(source.lastOrder, isNull);
    expect(c.read(cartProvider), {'whey': 1});
  });

  testWidgets('network error keeps the cart and Retry places the order',
      (tester) async {
    final source = _source();
    final c = await _pump(tester, source, signedIn: true);
    await _add(tester, 'whey');
    await _openCart(tester);
    source.error = const SocketException('offline');
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(c.read(cartProvider), {'whey': 1});
    expect(source.lastOrder, isNull);

    source.error = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(source.lastOrder, {'whey': 1});
    expect(c.read(cartProvider), isEmpty);
  });

  testWidgets('rejected order keeps the cart', (tester) async {
    final source = _source();
    final c = await _pump(tester, source, signedIn: true);
    await _add(tester, 'whey');
    await _openCart(tester);
    source.error = OrderException('Out of stock');
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Out of stock'), findsNothing); // server text
    expect(
        find.text(
            'Some items are no longer available. Update your cart and try again.'),
        findsOneWidget);
    expect(c.read(cartProvider), {'whey': 1});
  });

  testWidgets('stale ids are hidden and uncounted but stay stored',
      (tester) async {
    final c = await _pump(tester, _source(),
        prefsInit: {'cart': '{"whey":1,"gone":3}'});
    expect(
        find.descendant(
            of: find.byKey(const Key('cart-count')), matching: find.text('1')),
        findsOneWidget);
    expect(c.read(cartProvider), {'whey': 1, 'gone': 3});
    await _openCart(tester);
    expect(find.byKey(const Key('cart-dec-whey')), findsOneWidget);
    expect(find.byKey(const Key('cart-dec-gone')), findsNothing);
  });

  testWidgets('a cart with only stale ids shows no badge', (tester) async {
    final c = await _pump(tester, _source(), prefsInit: {'cart': '{"gone":2}'});
    expect(find.byKey(const Key('cart-count')), findsNothing);
    expect(c.read(cartProvider), {'gone': 2});
  });

  testWidgets('empty catalog says no products yet', (tester) async {
    await _pump(tester, FakeContentSource());
    expect(find.text('No products yet'), findsOneWidget);
  });

  testWidgets('in flight: button disabled, one call, new items survive',
      (tester) async {
    final source = _SlowSource();
    source.productTable = _source().productTable;
    final c = await _pump(tester, source, signedIn: true);
    await _add(tester, 'whey');
    await _openCart(tester);
    await tester.tap(find.text('Place order'));
    await tester.pump();
    expect(find.byKey(const Key('order-progress')), findsOneWidget);
    await tester.tap(find.text('Place order'), warnIfMissed: false);
    await tester.pump();
    // Dismiss attempts while busy are ignored.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Place order'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'), warnIfMissed: false);
    await tester.pump();
    expect(find.text('Place order'), findsOneWidget);
    c.read(cartProvider.notifier).add('bands'); // added during the request
    source.gate.complete();
    await tester.pumpAndSettle();
    expect(source.calls, 1);
    expect(find.byType(ShopScreen), findsOneWidget);
    expect(source.lastOrder, {'whey': 1});
    expect(c.read(cartProvider), {'bands': 1});
    expect(find.text('Place order'), findsNothing); // sheet closed
  });

  for (final code in ['en', 'ru', 'uz', 'es']) {
    testWidgets('no overflow on iPhone SE ($code)', (tester) async {
      await _pump(tester, _source(),
          size: const Size(375, 667), locale: Locale(code));
      expect(tester.takeException(), isNull);
      await _add(tester, 'whey');
      await _openCart(tester);
      expect(tester.takeException(), isNull);
    });
  }

  for (final code in ['en', 'ru']) {
    testWidgets('no overflow at 1.3x text on iPhone SE ($code)',
        (tester) async {
      await _pump(tester, _source(),
          size: const Size(375, 667), locale: Locale(code), textScale: 1.3);
      expect(tester.takeException(), isNull);
      await _add(tester, 'whey');
      await _openCart(tester);
      expect(tester.takeException(), isNull);
    });
  }
}
