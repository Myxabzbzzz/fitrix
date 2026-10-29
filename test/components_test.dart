import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitrix/core/theme/app_palette.dart';
import 'package:fitrix/core/theme/app_theme.dart';
import 'package:fitrix/core/theme/app_tokens.dart';
import 'package:fitrix/core/widgets/app_button.dart';
import 'package:fitrix/core/widgets/coach_card.dart';
import 'package:fitrix/core/widgets/day_badge.dart';
import 'package:fitrix/core/widgets/pill_selector.dart';
import 'package:fitrix/core/widgets/section_header.dart';
import 'package:fitrix/core/widgets/workout_card.dart';

Widget host(Widget child, {double width = 360, double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Center(child: SizedBox(width: width, child: child)),
        ),
      ),
    );

void main() {
  testWidgets('AppButton calls onPressed', (t) async {
    var n = 0;
    await t.pumpWidget(host(AppButton(label: 'Go', onPressed: () => n++)));
    await t.tap(find.text('Go'));
    expect(n, 1);
  });

  testWidgets('AppButton is disabled when onPressed is null', (t) async {
    await t.pumpWidget(host(const AppButton(label: 'Go')));
    final op = t.widget<Opacity>(find.descendant(
        of: find.byType(AppButton), matching: find.byType(Opacity)));
    expect(op.opacity, 0.4);
    await t.tap(find.text('Go')); // must not throw
  });

  testWidgets('primary AppButton uses palette.accent', (t) async {
    await t.pumpWidget(host(AppButton(label: 'Go', onPressed: () {})));
    final box = t.widget<DecoratedBox>(find
        .descendant(
            of: find.byType(AppButton), matching: find.byType(DecoratedBox))
        .first);
    expect((box.decoration as BoxDecoration).color, AppPalette.light.accent);
  });

  testWidgets('DayBadge uppercases its label', (t) async {
    await t.pumpWidget(host(const DayBadge(label: 'Mon')));
    expect(find.text('MON'), findsOneWidget);
  });

  testWidgets('WorkoutCard shows title/day and calls onStart', (t) async {
    var n = 0;
    await t.pumpWidget(
        host(WorkoutCard(title: 'Legs', dayLabel: 'Tue', onStart: () => n++)));
    expect(find.text('Legs'), findsOneWidget);
    expect(find.text('TUE'), findsOneWidget);
    await t.tap(find.text('Start'));
    expect(n, 1);
  });

  testWidgets('WorkoutCard done shows Done and no Start', (t) async {
    await t.pumpWidget(host(WorkoutCard(
        title: 'Legs', dayLabel: 'Tue', done: true, onStart: () {})));
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.byType(AppButton), findsNothing);
    final chip = t.widget<Container>(find
        .ancestor(of: find.text('Done'), matching: find.byType(Container))
        .first);
    expect(
        (chip.decoration as BoxDecoration).color, AppPalette.light.buttonMuted);
    // only the card's own 0.55 fade, no second opacity layer
    expect(
        find.descendant(
            of: find.byType(WorkoutCard), matching: find.byType(Opacity)),
        findsOneWidget);
    final sem = t.getSemantics(find.text('Done'));
    expect(sem.label, 'Done');
    expect(sem.flagsCollection.isButton, isFalse);
  });

  testWidgets('WorkoutCard Start style follows today', (t) async {
    await t.pumpWidget(
        host(WorkoutCard(title: 'Legs', dayLabel: 'Tue', onStart: () {})));
    expect(t.widget<AppButton>(find.byType(AppButton)).style,
        AppButtonStyle.secondary);
    await t.pumpWidget(host(WorkoutCard(
        title: 'Legs', dayLabel: 'Tue', today: true, onStart: () {})));
    expect(t.widget<AppButton>(find.byType(AppButton)).style,
        AppButtonStyle.primary);
    expect(t.widget<Text>(find.text('Legs')).style!.fontFamily, 'Inter');
  });

  testWidgets('CoachCard hides buttons with null label', (t) async {
    await t.pumpWidget(host(const CoachCard(
        eyebrow: 'Coach', title: 'Hi', message: 'Msg', primaryLabel: 'Yes')));
    expect(find.text('Yes'), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
    final eyebrow = t.widget<Text>(find.text('COACH'));
    expect(eyebrow.style!.color, AppPalette.light.accent);
  });

  testWidgets('primary AppButton text uses onAccent', (t) async {
    await t.pumpWidget(host(AppButton(label: 'Go', onPressed: () {})));
    expect(t.widget<Text>(find.text('Go')).style!.color,
        AppPalette.light.onAccent);
    expect(AppPalette.dark.onAccent, const Color(0xFFFFFFFF));
  });

  testWidgets('CoachCard image size is configurable', (t) async {
    await t.pumpWidget(host(const CoachCard(
        eyebrow: 'c',
        title: 't',
        message: 'm',
        imageAsset: 'assets/images/felix_robot.png',
        imageWidth: 64,
        imageHeight: 84)));
    final box = find
        .ancestor(of: find.byType(Image), matching: find.byType(SizedBox))
        .first;
    expect(t.getSize(box), const Size(64, 84));
  });

  testWidgets('CoachCard message uses caption in textPrimary', (t) async {
    await t.pumpWidget(
        host(const CoachCard(eyebrow: 'c', title: 't', message: 'Hello msg')));
    final st = t.widget<Text>(find.text('Hello msg')).style!;
    expect(st.fontSize, AppText.caption.fontSize);
    expect(st.fontWeight, AppText.caption.fontWeight);
    expect(st.color, AppPalette.light.textPrimary);
  });

  testWidgets('SectionHeader style and action semantics', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(
        host(SectionHeader('Week', actionLabel: 'All', onAction: () {})));
    final st = t.widget<Text>(find.text('Week')).style!;
    expect(st.fontSize, 16);
    expect(st.fontWeight, FontWeight.w600);
    expect(
        t
            .getSize(find
                .ancestor(
                    of: find.text('All'), matching: find.byType(ConstrainedBox))
                .first)
            .height,
        greaterThanOrEqualTo(44));
    final sem = t.getSemantics(find.text('All'));
    expect(sem.flagsCollection.isButton, isTrue);
    h.dispose();
  });

  testWidgets('AppButton button semantics reflect enabled', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(host(AppButton(label: 'Go', onPressed: () {})));
    var s = t.getSemantics(find.text('Go'));
    expect(s.flagsCollection.isButton, isTrue);
    expect(s.flagsCollection.isEnabled, Tristate.isTrue);
    await t.pumpWidget(host(const AppButton(label: 'Go')));
    s = t.getSemantics(find.text('Go'));
    expect(s.flagsCollection.isButton, isTrue);
    expect(s.flagsCollection.isEnabled, Tristate.isFalse);
    h.dispose();
  });

  testWidgets('PillSelector selected pill uses pillSelected', (t) async {
    await t.pumpWidget(host(PillSelector<String>(
      items: const ['a', 'b'],
      selected: 'a',
      labelOf: (s) => s,
      onSelected: (_) {},
    )));
    final c = t.widget<AnimatedContainer>(find.ancestor(
        of: find.text('a'), matching: find.byType(AnimatedContainer)));
    expect(
        (c.decoration as BoxDecoration).color, AppPalette.light.pillSelected);
  });

  testWidgets('components do not overflow at 320px and 1.3x text', (t) async {
    await t.pumpWidget(host(
      SingleChildScrollView(
        child: Column(children: [
          AppButton(label: 'Continue now', onPressed: () {}, expand: true),
          const DayBadge(label: 'Today', today: true),
          SizedBox(
            height: 140,
            child: Row(children: [
              Expanded(
                  child: WorkoutCard(
                      title: 'Upper body strength',
                      dayLabel: 'Mon',
                      today: true,
                      onStart: () {})),
              Expanded(child: AddWorkoutCard(onTap: () {})),
            ]),
          ),
          CoachCard(
              eyebrow: 'Coach',
              title: 'Ready for today?',
              message: 'Your next workout is waiting for you.',
              primaryLabel: 'Start',
              onPrimary: () {},
              secondaryLabel: 'Later',
              onSecondary: () {}),
          SectionHeader('This week', actionLabel: 'See all', onAction: () {}),
        ]),
      ),
      width: 320,
      scale: 1.3,
    ));
    expect(t.takeException(), isNull);
  });
}
