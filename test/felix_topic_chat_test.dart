import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/i18n/catalog_overlay.dart';
import 'package:fitrix/core/i18n/catalog_text.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/features/chat/data/felix_snapshot.dart';
import 'package:fitrix/features/chat/data/models/assistant_topic.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/services/chat_api_service.dart';
import 'package:fitrix/features/chat/presentation/providers/chat_provider.dart';
import 'package:fitrix/features/chat/presentation/providers/felix_snapshot_provider.dart';
import 'package:fitrix/features/chat/presentation/screens/felix_chat_screen.dart';
import 'package:fitrix/features/chat/presentation/widgets/quick_reply_chip.dart';
import 'package:fitrix/features/checkin/data/checkin_models.dart';
import 'package:fitrix/features/nutrition/data/nutrition_targets.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

import 'support/catalog_fixtures.dart';
import 'support/overflow.dart';

class _FakeApi extends ChatApiService {
  final sent = <(String, String?)>[];

  @override
  Stream<String> streamMessage(
    String message,
    String conversationId, {
    String? topic,
    Map<String, Object>? profile,
    List<Map<String, String>>? history,
    String? language,
    Map<String, Object>? context,
    List<String>? images,
    void Function(ChatAction action)? onAction,
  }) async* {
    sent.add((message, topic));
    yield 'Sure';
  }
}

final _day = DateTime(2026, 10, 20);

PlannedSession _gymBack() => PlannedSession(
      id: 's1',
      day: _day,
      sport: Sport.gym,
      title: 'Back',
      minutes: 60,
      intensity: Intensity.normal,
    );

void main() {
  late _FakeApi api;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    api = _FakeApi();
  });

  Future<void> pump(
    WidgetTester tester,
    AssistantTopic topic,
    FelixSnapshot snapshot, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(375, 667),
    List<Override> extra = const [],
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        chatApiServiceProvider.overrideWithValue(api),
        felixSnapshotProvider.overrideWith((ref, t) => snapshot),
        ...extra,
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FelixChatScreen(topic: topic),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
  }

  final chipRow = find.byKey(const ValueKey('felix-context-chips'));

  testWidgets('chips read the workout names in the app language',
      (tester) async {
    final overlay = await CatalogOverlay.load(
        FixtureBundle.locale('ru', {
          'workout_catalog': {
            'templates': {
              'gym-legs': {'name': 'Ноги', 'focus': 'Низ тела'},
            },
          },
        }),
        'ru');
    final started = DateTime(2026, 10, 19, 18);
    await pump(
      tester,
      AssistantTopic.recovery,
      FelixSnapshot(
        today: _day,
        todayKind: TodayKind.session,
        todaySession: PlannedSession(
          id: 's2',
          day: _day,
          sport: Sport.gym,
          title: 'Legs',
          templateId: 'gym-legs',
          minutes: 60,
          intensity: Intensity.normal,
        ),
        lastWorkout: CompletedWorkout(
          templateId: 'gym-legs',
          name: 'Legs',
          sport: Sport.gym,
          startedAt: started,
          finishedAt: started.add(const Duration(hours: 1)),
          exercises: const [],
        ),
      ),
      locale: const Locale('ru'),
      extra: [catalogTextProvider.overrideWithValue(CatalogText(overlay))],
    );
    expect(find.descendant(of: chipRow, matching: find.text('Сегодня: Ноги')),
        findsOneWidget);
    expect(find.descendant(of: chipRow, matching: find.text('Последняя: Ноги')),
        findsOneWidget);
  });

  testWidgets('recovery chat: chips, what Felix sees, prompts, hint',
      (tester) async {
    await pump(
      tester,
      AssistantTopic.recovery,
      FelixSnapshot(
        today: _day,
        todayKind: TodayKind.session,
        todaySession: _gymBack(),
        readiness: const Readiness(78, [], ReadinessLabel.ready),
      ),
    );

    expect(find.descendant(of: chipRow, matching: find.text('Recovery 78%')),
        findsOneWidget);
    expect(find.descendant(of: chipRow, matching: find.text('Today: Back')),
        findsOneWidget);
    expect(find.text('Sees your check-in, sleep and training load'),
        findsOneWidget);
    for (final p in [
      'Should I train hard today?',
      'How to sleep better',
      'Where do legs fit this week?',
    ]) {
      expect(find.text(p), findsOneWidget);
    }
    expect(find.byType(QuickReplyChip), findsNWidgets(3));
    expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        'Ask Felix about recovery');
    expectNoOverflow(tester);
  });

  testWidgets('app chat: the hint names FITRIX', (tester) async {
    await pump(
      tester,
      AssistantTopic.app,
      FelixSnapshot(today: _day, todayKind: TodayKind.unplanned),
    );
    expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.hintText,
        'Ask Felix about FITRIX');
  });

  testWidgets('nutrition chat: calories use the locale number format',
      (tester) async {
    await pump(
      tester,
      AssistantTopic.nutrition,
      FelixSnapshot(
        today: _day,
        eaten: (kcal: 1523, protein: 96.4, carbs: 150.0, fat: 40.0),
        targets: const Targets(
            bmr: 1800,
            activity: 1.5,
            tdee: 2700,
            kcal: 3400,
            protein: 150,
            fat: 90,
            carbs: 400,
            waterMl: 2500),
      ),
    );

    expect(find.text('1,523 of 3,400 kcal'), findsOneWidget);
    expect(find.text('Protein 96 g'), findsOneWidget);
    expect(find.text('Sees today’s food, targets and weight'), findsOneWidget);
  });

  testWidgets('no data: no chip row; sport topics show the plan text',
      (tester) async {
    await pump(
        tester, AssistantTopic.forSport(Sport.gym), FelixSnapshot(today: _day));

    expect(chipRow, findsNothing);
    expect(find.text('Sees your plan, check-in and workouts'), findsOneWidget);
  });

  testWidgets('rest day and last workout chips, three at most', (tester) async {
    await pump(
      tester,
      AssistantTopic.app,
      FelixSnapshot(
        today: _day,
        todayKind: TodayKind.rest,
        readiness: const Readiness(60, [], ReadinessLabel.trainLight),
        lastWorkout: CompletedWorkout(
          templateId: 't',
          name: 'Legs',
          sport: Sport.gym,
          startedAt: _day,
          finishedAt: _day.add(const Duration(hours: 1)),
          exercises: const [],
        ),
      ),
    );

    expect(find.text('Recovery 60%'), findsOneWidget);
    expect(find.text('Rest day'), findsOneWidget);
    expect(find.text('Last: Legs'), findsOneWidget);
  });

  testWidgets('tapping a prompt sends it in that topic only', (tester) async {
    await pump(tester, AssistantTopic.recovery, FelixSnapshot(today: _day));

    await tester.tap(find.text('Should I train hard today?'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(api.sent.single, ('Should I train hard today?', 'recovery'));
  });

  testWidgets('SE, text 1.3, ru: no overflow', (tester) async {
    await pump(
      tester,
      AssistantTopic.recovery,
      FelixSnapshot(
        today: _day,
        todayKind: TodayKind.session,
        todaySession: PlannedSession(
          id: 's2',
          day: _day,
          sport: Sport.gym,
          title: 'Верх тела и плечи, длинное название',
          minutes: 60,
          intensity: Intensity.normal,
        ),
        readiness: const Readiness(78, [], ReadinessLabel.ready),
        lastWorkout: CompletedWorkout(
          templateId: 't',
          name: 'Ноги и ягодицы, тяжёлая сессия',
          sport: Sport.gym,
          startedAt: _day,
          finishedAt: _day.add(const Duration(hours: 1)),
          exercises: const [],
        ),
      ),
      locale: const Locale('ru'),
      textScale: 1.3,
    );

    expect(chipRow, findsOneWidget);
    expect(find.text('Восстановление 78%'), findsOneWidget);
    expectNoOverflow(tester);
  });
}
