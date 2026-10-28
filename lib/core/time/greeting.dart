import 'package:fitrix/l10n/generated/app_localizations.dart';

/// Part of the day by the app clock: morning 05:00-11:59, afternoon
/// 12:00-17:59, evening 18:00-04:59 (so 00:03 is still the evening).
enum DayPart { morning, afternoon, evening }

DayPart dayPartOf(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return DayPart.morning;
  if (h >= 12 && h < 18) return DayPart.afternoon;
  return DayPart.evening;
}

/// "Good morning, Alex" by [dayPartOf] [now]; without the name when [name]
/// is empty.
String timeOfDayGreeting(AppLocalizations l10n, DateTime now, String name) {
  final hasName = name.isNotEmpty;
  return switch (dayPartOf(now)) {
    DayPart.morning =>
      hasName ? l10n.homeGreetingMorning(name) : l10n.homeGreetingMorningNoName,
    DayPart.afternoon => hasName
        ? l10n.homeGreetingAfternoon(name)
        : l10n.homeGreetingAfternoonNoName,
    DayPart.evening =>
      hasName ? l10n.homeGreetingEvening(name) : l10n.homeGreetingEveningNoName,
  };
}

/// The check-in sheet's title for a check-in at [at].
String checkinTitleAt(AppLocalizations l10n, DateTime at) =>
    switch (dayPartOf(at)) {
      DayPart.morning => l10n.checkinTitle,
      DayPart.afternoon => l10n.checkinTitleAfternoon,
      DayPart.evening => l10n.checkinTitleEvening,
    };
