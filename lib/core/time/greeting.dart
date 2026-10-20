import 'package:fitrix/l10n/generated/app_localizations.dart';

/// "Good morning, Alex" by the hour of [now] (before 12, before 18, then
/// evening); without the name when [name] is empty.
String timeOfDayGreeting(AppLocalizations l10n, DateTime now, String name) {
  final hasName = name.isNotEmpty;
  if (now.hour < 12) {
    return hasName
        ? l10n.homeGreetingMorning(name)
        : l10n.homeGreetingMorningNoName;
  }
  if (now.hour < 18) {
    return hasName
        ? l10n.homeGreetingAfternoon(name)
        : l10n.homeGreetingAfternoonNoName;
  }
  return hasName
      ? l10n.homeGreetingEvening(name)
      : l10n.homeGreetingEveningNoName;
}
