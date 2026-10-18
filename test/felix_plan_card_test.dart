import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitrix/core/router/app_router.dart';
import 'package:fitrix/core/session/session_providers.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/time/today_provider.dart';
import 'package:fitrix/features/chat/data/models/chat_action.dart';
import 'package:fitrix/features/chat/data/models/chat_message.dart';
import 'package:fitrix/features/chat/presentation/widgets/chat_action_card.dart';
import 'package:fitrix/features/plan/data/week_plan.dart';
import 'package:fitrix/features/plan/presentation/providers/week_plan_provider.dart';
import 'package:fitrix/features/workouts/data/felix_templates_store.dart';
import 'package:fitrix/features/workouts/data/models/workout.dart';
import 'package:fitrix/features/workouts/presentation/providers/workouts_provider.dart';
import 'package:fitrix/features/workouts/presentation/screens/my_workouts_screen.dart';
import 'package:fitrix/features/workouts/presentation/screens/sport_workouts_screen.dart';
import 'package:fitrix/features/workouts/presentation/widgets/edit_workout_sheet.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

WorkoutTemplate _t(String id, {Sport sport = Sport.gym}) => WorkoutTemplate(
      id: id,
      sport: sport,
      name: 'Plan $id',
      focus: 'Upper',
      estimatedDuration: const Duration(minutes: 45),
      exercises: const [],
      updatedAt: DateTime(2026, 10, 1),
    );

PlannedSession _s(String id, DateTime day, Sport sport, Intensity i) =>
    PlannedSession(
        id: id, day: day, sport: sport, title: id, minutes: 60, intensity: i);

Map<String, dynamic> _plan(Map<String, dynamic> extra, {int n = 2}) => {
      'type': 'workout_plan',
      'sport': 'gym',
      'templates': [
        for (var i = 0; i < n; i++)
          {
            'name': 'Day ${i + 1}',
            'exercises': [
              for (final e in ['Bench Press', 'Row', 'Squat', 'Curl'])
                {'name': e, 'sets': 3, 'reps': 8}
            ]
          }
      ],
      ...extra,
    };

void main() {
  group('scheduleFelixPlan', () {
    final created = [_t('a'), _t('b'), _t('c')];
    // Monday 2026-10-12.
    final mon = DateTime(2026, 10, 12);
    final wed = DateTime(2026, 10, 14);

    test('today: one session today', () {
      final out = scheduleFelixPlan(
          created: [created.first],
          when: 'today',
          days: const ['today'],
          today: wed,
          existing: [_s('x', wed, Sport.gym, Intensity.normal)]);
      expect(out, hasLength(1));
      expect(out.single.day, wed);
      expect(out.single.templateId, 'a');
    });

    test('week with days on a Wednesday: this week if not past, else next', () {
      final out = scheduleFelixPlan(
          created: created,
          when: 'week',
          days: const ['mon', 'wed', 'fri'],
          today: wed,
          existing: const []);
      expect(out.map((s) => s.templateId), ['a', 'b', 'c']);
      expect(out[0].day, DateTime(2026, 10, 19));
      expect(out[1].day, DateTime(2026, 10, 14));
      expect(out[2].day, DateTime(2026, 10, 16));
    });

    test('week without days avoids hard days and their neighbours', () {
      final out = scheduleFelixPlan(
          created: created,
          when: 'week',
          days: const [],
          today: mon,
          existing: [
            _s('fb', DateTime(2026, 10, 17), Sport.football, Intensity.hard)
          ]);
      expect(out, hasLength(3));
      for (final s in out) {
        expect(s.day.isBefore(DateTime(2026, 10, 16)), isTrue,
            reason: '${s.day}');
        expect(s.day.isBefore(mon), isFalse);
      }
      expect({for (final s in out) s.day}, hasLength(3));
    });

    test('an old or far football session blocks nothing; this week\'s does',
        () {
      List<DateTime> days(PlannedSession fb) => scheduleFelixPlan(
          created: created,
          when: 'week',
          days: const [],
          today: mon,
          existing: [fb]).map((s) => s.day).toList();
      final old =
          days(_s('fb', DateTime(2026, 9, 12), Sport.football, Intensity.hard));
      // Same weekday (Saturday) 4 weeks ago: Fri and Sun stay usable.
      expect(old, [mon, DateTime(2026, 10, 15), DateTime(2026, 10, 18)]);
      final now = days(
          _s('fb', DateTime(2026, 10, 17), Sport.football, Intensity.hard));
      expect(now.any((d) => d.weekday >= 5), isFalse);
    });

    test('null when: no sessions', () {
      expect(
          scheduleFelixPlan(
              created: created,
              when: null,
              days: const [],
              today: mon,
              existing: const []),
          isEmpty);
    });
  });

  group('felix plan card', () {
    late SharedPreferences prefs;
    late ProviderContainer container;
    var routed = <String>[];

    Future<void> pumpCard(WidgetTester tester, Map<String, dynamic> action,
        {double scale = 1, bool applied = false}) async {
      tester.view.physicalSize = const Size(375, 667) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      routed = [];
      container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 14, 9)),
      ]);
      addTearDown(container.dispose);
      var msg = ChatMessage(
        id: 'm',
        content: 'Here you go.',
        sender: MessageSender.assistant,
        timestamp: DateTime(2026, 10, 14, 9),
        action: ChatAction.tryParse(action),
        actionApplied: applied,
        appliedResult: applied ? {'at': 1, 'scheduled': 1} : null,
      );
      final router = GoRouter(routes: [
        GoRoute(
            path: '/',
            builder: (_, __) => Scaffold(
                  body: StatefulBuilder(
                    builder: (context, set) => SingleChildScrollView(
                      child: ChatActionCard(
                        message: msg,
                        onApplied: (r) => set(() => msg = msg.copyWith(
                            actionApplied: true, appliedResult: r)),
                        onUndone: () =>
                            set(() => msg = msg.copyWith(actionApplied: false)),
                      ),
                    ),
                  ),
                )),
        GoRoute(
            path: AppRouter.workouts,
            builder: (_, __) {
              routed.add(AppRouter.workouts);
              return const Scaffold(body: Text('workouts-page'));
            }),
        GoRoute(
            path: AppRouter.sportWorkouts(Sport.gym),
            builder: (_, __) {
              routed.add(AppRouter.sportWorkouts(Sport.gym));
              return const Scaffold(body: Text('sport-page'));
            }),
        GoRoute(
            path: AppRouter.weekPlan,
            builder: (_, __) {
              routed.add(AppRouter.weekPlan);
              return const Scaffold(body: Text('plan-page'));
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
      await tester.pumpAndSettle();
    }

    testWidgets('shows eyebrow, sessions and the primary button',
        (tester) async {
      await pumpCard(tester, _plan({}));
      expect(find.text('FELIX PLAN'), findsOneWidget);
      expect(find.text('2 workouts'), findsOneWidget);
      expect(find.textContaining('Bench Press, Row, Squat'), findsWidgets);
      expect(find.text('Add to My workouts'), findsOneWidget);
    });

    testWidgets('when=today offers "Add to today\'s plan"', (tester) async {
      await pumpCard(
          tester,
          _plan({
            'when': 'today',
            'days': ['today']
          }, n: 1));
      expect(find.text('Add to today’s plan'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
    });

    testWidgets('apply adds templates, ids and sessions; badge on Gym screen',
        (tester) async {
      await pumpCard(
          tester,
          _plan({
            'when': 'week',
            'days': ['wed', 'fri']
          }));
      final before = container.read(workoutTemplatesProvider).length;
      await tester.tap(find.text('Add to My workouts'));
      await tester.pumpAndSettle();
      expect(container.read(workoutTemplatesProvider).length, before + 2);
      expect(container.read(felixTemplateIdsProvider), hasLength(2));
      expect(container.read(weekPlanProvider), hasLength(2));
      expect(find.text('Added ✓'), findsOneWidget);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(routed, [AppRouter.weekPlan]);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SportWorkoutsScreen(sport: Sport.gym),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Felix plan'), findsNWidgets(2));
    });

    testWidgets('Gym screen with badges fits SE at 1.3 text', (tester) async {
      await pumpCard(tester, _plan({}));
      await tester.tap(find.text('Add to My workouts'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const SportWorkoutsScreen(sport: Sport.gym),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Felix plan'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('without a day, Open goes to My workouts', (tester) async {
      await pumpCard(tester, _plan({}));
      await tester.tap(find.text('Add to My workouts'));
      await tester.pumpAndSettle();
      expect(container.read(weekPlanProvider), isEmpty);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(routed, [AppRouter.sportWorkouts(Sport.gym)]);
    });

    testWidgets('My workouts lists Felix plans; Open goes to the sport screen',
        (tester) async {
      await pumpCard(tester, _plan({}, n: 1));
      await tester.tap(find.text('Add to My workouts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(routed, [AppRouter.sportWorkouts(Sport.gym)]);

      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MyWorkoutsScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('felix-plans-section')), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
    });

    testWidgets('My workouts hides the Felix section when there are none',
        (tester) async {
      await pumpCard(tester, _plan({}, n: 1));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MyWorkoutsScreen(),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('felix-plans-section')), findsNothing);
    });

    testWidgets('undo without a batch record changes nothing and says so',
        (tester) async {
      await pumpCard(tester, _plan({}), applied: true);
      final before = container.read(workoutTemplatesProvider).length;
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(container.read(workoutTemplatesProvider).length, before);
      expect(find.text('Add to My workouts'), findsNothing);
      expect(
          find.text('Couldn’t apply this. Please try again.'), findsOneWidget);
    });

    testWidgets('deleting a Felix plan in the edit sheet drops its id',
        (tester) async {
      await pumpCard(tester, _plan({}, n: 1));
      await tester.tap(find.text('Add to My workouts'));
      await tester.pumpAndSettle();
      final t = container.read(workoutTemplatesProvider).firstWhere(
          (t) => container.read(felixTemplateIdsProvider).contains(t.id));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => EditWorkoutSheet(template: t)),
              child: const Text('open-sheet'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open-sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      expect(container.read(felixTemplateIdsProvider), isEmpty);
    });

    testWidgets('undo removes templates, sessions and ids', (tester) async {
      await pumpCard(
          tester,
          _plan({
            'when': 'week',
            'days': ['wed', 'fri']
          }));
      final before = container.read(workoutTemplatesProvider).length;
      await tester.tap(find.text('Add to My workouts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(container.read(workoutTemplatesProvider).length, before);
      expect(container.read(weekPlanProvider), isEmpty);
      expect(container.read(felixTemplateIdsProvider), isEmpty);
      expect(find.text('Add to My workouts'), findsOneWidget);
    });

    for (final applied in [false, true]) {
      testWidgets('fits SE at 1.3 text (${applied ? 'added' : 'ask'})',
          (tester) async {
        await pumpCard(
            tester,
            _plan({
              'when': 'week',
              'days': ['mon', 'wed', 'fri']
            }, n: 3),
            scale: 1.3,
            applied: applied);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
