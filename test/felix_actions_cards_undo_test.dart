import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/data/repositories/chat_repository.dart';
import 'package:fitrix/features/chat/presentation/chat_action_apply.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_action_card.dart';
import 'package:fitrix/features/nutrition/data/food_catalog.dart';
import 'package:fitrix/features/nutrition/presentation/providers/nutrition_provider.dart';
import 'package:fitrix/features/profile/presentation/providers/profile_provider.dart';
import 'package:fitrix/features/progress/data/body_weight_store.dart';
import 'package:fitrix/features/progress/presentation/providers/progress_providers.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/felix_action_fixtures.dart';

void main() {
  late FoodCatalog catalog;
  setUpAll(() => catalog = loadFoodCatalog());

  group('cards', () {
    late SharedPreferences prefs;
    late ProviderContainer container;

    Future<void> seed(Map<String, dynamic> action,
        {String weight = '78.4'}) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyUserName: 'Ann',
        AppConstants.keyUserWeight: weight,
        AppConstants.keyChatHistory: ChatMessage.encodeMessages([
          ChatMessage(
            id: 'm1',
            content: 'Okay.',
            sender: MessageSender.assistant,
            timestamp: DateTime(2026, 10, 18, 12),
            action: ChatAction.tryParse(action),
          ),
        ]),
      });
      prefs = await SharedPreferences.getInstance();
    }

    var routed = <String>[];

    Future<void> pumpFelix(WidgetTester tester,
        {double scale = 1, DateTime Function()? clock}) async {
      tester.view.physicalSize = const Size(375, 667) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      routed = [];
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider
            .overrideWithValue(clock ?? () => DateTime(2026, 10, 18, 13, 30)),
        foodCatalogProvider.overrideWith((ref) async => catalog),
        chatMessagesProvider.overrideWith((ref) => ChatNotifier(ChatRepository(
            FakeFelixApi(),
            prefs: prefs,
            greeting: () => const ['Hi']))),
      ]);
      addTearDown(container.dispose);
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, __) => const Scaffold(
                body: FelixChatScreen(topic: AssistantTopic.app))),
        GoRoute(
            path: AppRouter.nutrition,
            builder: (_, __) {
              routed.add(AppRouter.nutrition);
              return const Scaffold(body: Text('nutrition-page'));
            }),
        GoRoute(
            path: AppRouter.editProfile,
            builder: (_, __) {
              routed.add(AppRouter.editProfile);
              return const Scaffold(body: Text('edit-page'));
            }),
      ]);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    }

    final today = DateTime(2026, 10, 18);

    testWidgets('food card shows rows and total, adds, undoes, opens',
        (tester) async {
      await seed(foodLogAction);
      await pumpFelix(tester);
      expect(find.text('Log to Lunch'), findsOneWidget);
      expect(find.text('Chicken breast, cooked'), findsOneWidget);
      expect(find.text('≈ dragonfruit smoothie'), findsOneWidget);
      // 330 + 195 + 180 from catalog: 330, 195, and Felix's 180.
      final total = (165 * 2).round() + (130 * 1.5).round() + 180;
      expect(find.textContaining('Add to My nutrition · $total kcal'),
          findsOneWidget);

      await tester.tap(find.textContaining('Add to My nutrition'));
      await tester.pumpAndSettle();
      final entries = container.read(foodLogStoreProvider).day(today);
      expect(entries, hasLength(3));
      expect(entries.map((e) => e.slot).toSet(), {MealSlot.lunch});
      expect(entries[0].kcal, 330);
      expect(entries[1].kcal, 195);
      expect(entries[2].kcal, 180);
      expect(entries[2].estimate, isTrue);
      expect(find.text('Added to Lunch'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(container.read(foodLogStoreProvider).day(today), isEmpty);
      expect(find.textContaining('Add to My nutrition'), findsOneWidget);

      await tester.tap(find.textContaining('Add to My nutrition'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(routed, [AppRouter.nutrition]);
    });

    testWidgets('slot defaults to the time of day and can be changed',
        (tester) async {
      await seed({...foodLogAction, 'slot': null});
      await pumpFelix(tester); // 13:30 -> lunch
      expect(find.text('Log to Lunch'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('food-slot-picker')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dinner').last);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Add to My nutrition'));
      await tester.pumpAndSettle();
      final entries = container.read(foodLogStoreProvider).day(today);
      expect(entries.map((e) => e.slot).toSet(), {MealSlot.dinner});
    });

    testWidgets('"I gained 3 kg" at 78.4 logs 81.4 and undo restores',
        (tester) async {
      await seed({'type': 'weight', 'mode': 'delta', 'kg': 3});
      await pumpFelix(tester);
      expect(find.text('Update weight: 78.4 → 81.4 kg'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '81.4');
      var weighIns = container.read(bodyWeightStoreProvider).all();
      expect(weighIns.map((w) => w.kg), [81.4]);
      expect(weighIns.single.at, DateTime(2026, 10, 18, 13, 30));

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '78.4');
      weighIns = container.read(bodyWeightStoreProvider).all();
      expect(weighIns, isEmpty);
      expect(container.read(bodyWeightProvider), isEmpty);
    });

    testWidgets('undo removes the weigh-in when the clock has microseconds',
        (tester) async {
      await seed({'type': 'weight', 'mode': 'delta', 'kg': 3});
      final at = DateTime(2026, 10, 18, 13, 30, 5, 123, 456);
      await pumpFelix(tester, clock: () => at);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(container.read(bodyWeightStoreProvider).all(), hasLength(1));
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(container.read(bodyWeightStoreProvider).all(), isEmpty);
      expect(container.read(bodyWeightProvider), isEmpty);
      expect(prefs.getString(AppConstants.keyUserWeight), '78.4');
    });

    testWidgets('weight changed since apply: Undo is hidden', (tester) async {
      await seed({'type': 'weight', 'mode': 'delta', 'kg': 3});
      await pumpFelix(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsOneWidget);
      await container.read(profileProvider.notifier).saveWeight('83');
      await tester.pumpAndSettle();
      expect(find.text('Undo'), findsNothing);

      // A direct undo is refused too and changes nothing.
      final ref = tester.element(find.byType(ChatActionCard)) as WidgetRef;
      final action =
          ChatAction.tryParse({'type': 'weight', 'mode': 'delta', 'kg': 3})
              as WeightAction;
      await expectLater(
          undoChatAction(ref, action, {
            'from': 78.4,
            'to': 81.4,
            'at': DateTime(2026, 10, 18, 13, 30).millisecondsSinceEpoch,
          }),
          throwsA(isA<WeightChangedSince>()));
      expect(prefs.getString(AppConstants.keyUserWeight), '83');
      expect(container.read(bodyWeightStoreProvider).all(), hasLength(1));
    });

    testWidgets('weight changed elsewhere: Undo says so and keeps it',
        (tester) async {
      await seed({'type': 'weight', 'mode': 'delta', 'kg': 3});
      await pumpFelix(tester);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      // Changed behind the provider's back (e.g. a sync).
      await prefs.setString(AppConstants.keyUserWeight, '83');
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(
          find.text('Weight changed since — nothing undone'), findsOneWidget);
      expect(prefs.getString(AppConstants.keyUserWeight), '83');
      expect(container.read(bodyWeightStoreProvider).all(), hasLength(1));
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('undo brings back a same-day weigh-in that was replaced',
        (tester) async {
      await seed({'type': 'weight', 'mode': 'set', 'kg': 80});
      await pumpFelix(tester);
      await container
          .read(bodyWeightStoreProvider)
          .add(WeighIn(at: DateTime(2026, 10, 18, 7), kg: 78.4));
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(
          container.read(bodyWeightStoreProvider).all().map((w) => w.kg), [80]);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(container.read(bodyWeightStoreProvider).all().map((w) => w.kg),
          [78.4]);
    });

    testWidgets('"set" with no profile weight applies, logs, and undo reverts',
        (tester) async {
      await seed({'type': 'weight', 'mode': 'set', 'kg': 82}, weight: '');
      await pumpFelix(tester);
      expect(find.text('Set your weight first'), findsNothing);
      expect(find.text('Update weight to 82 kg'), findsOneWidget);
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight), '82');
      expect(
          container.read(bodyWeightStoreProvider).all().map((w) => w.kg), [82]);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(prefs.getString(AppConstants.keyUserWeight) ?? '', '');
      expect(container.read(bodyWeightStoreProvider).all(), isEmpty);
    });

    testWidgets('no profile weight asks to set it first', (tester) async {
      await seed({'type': 'weight', 'mode': 'delta', 'kg': 3}, weight: '');
      await pumpFelix(tester);
      expect(find.text('Set your weight first'), findsOneWidget);
      expect(find.text('Confirm'), findsNothing);
      await tester.tap(find.text('Set weight'));
      await tester.pumpAndSettle();
      expect(routed, [AppRouter.editProfile]);
    });

    // The card alone: the chat header has its own layout at 1.3 text.
    for (final action in [
      foodLogAction,
      {'type': 'weight', 'mode': 'delta', 'kg': 3},
      {'type': 'weight', 'mode': 'delta', 'kg': 3, 'noWeight': true},
    ]) {
      for (final applied in [false, true]) {
        testWidgets(
            '${action['type']} card fits SE at 1.3 text '
            '(${applied ? 'added' : 'ask'})', (tester) async {
          final noWeight = action['noWeight'] == true;
          await seed(action, weight: noWeight ? '' : '78.4');
          tester.view.physicalSize = const Size(375, 667) * 3;
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          final container = ProviderContainer(overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            clockProvider
                .overrideWithValue(() => DateTime(2026, 10, 18, 13, 30)),
            foodCatalogProvider.overrideWith((ref) async => catalog),
          ]);
          addTearDown(container.dispose);
          await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.3)),
                child: child!,
              ),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ChatActionCard(
                    message: ChatMessage(
                      id: 'x',
                      content: 'Okay.',
                      sender: MessageSender.assistant,
                      timestamp: DateTime(2026, 10, 18, 12),
                      action: ChatAction.tryParse(action),
                      actionApplied: applied && !noWeight,
                      appliedResult: applied
                          ? {
                              'at': DateTime(2026, 10, 18, 13, 30)
                                  .microsecondsSinceEpoch,
                              'count': 3,
                              'slot': 1,
                              'from': 78.4,
                              'to': 81.4,
                            }
                          : null,
                    ),
                    onApplied: (_) {},
                  ),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
