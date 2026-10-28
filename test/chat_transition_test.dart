import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/transition/presentation/screens/chat_transition_screen.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

void main() {
  for (final language in ['ru', 'uz', 'es', 'en']) {
    testWidgets('the transition types and offers its button in $language',
        (tester) async {
      final l10n = lookupAppLocalizations(Locale(language));
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChatTransitionScreen(),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(
          Duration(milliseconds: l10n.transitionReady.length * 70 + 50));
      await tester.pump(const Duration(milliseconds: 900));

      expect(find.text(l10n.transitionReady), findsOneWidget);
      expect(find.text(l10n.transitionGo), findsOneWidget);
    });
  }
}
