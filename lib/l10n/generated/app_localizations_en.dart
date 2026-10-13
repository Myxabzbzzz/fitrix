// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get continueButton => 'Continue';

  @override
  String get cancel => 'Cancel';

  @override
  String get introStart => 'Start your journey';

  @override
  String get aboutMeTitle => 'About me';

  @override
  String get age => 'Age';

  @override
  String get weight => 'Weight';

  @override
  String get height => 'Height';

  @override
  String get unitKg => 'kg';

  @override
  String get unitCm => 'cm';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutLocalBody =>
      'Your profile, chats and workouts are stored only on this device and will be deleted.';

  @override
  String get signOutAccountBody =>
      'Your profile, workouts and chats are saved to your account and will be removed from this device. Sign in with the same email to get them back.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently deletes your FITRIX account and everything in it: your profile, workout plans, workout history and chats with Felix, on all your devices.';

  @override
  String get deleteAccountAppleNote => 'Apple will ask you to confirm.';

  @override
  String get deleteForGoodTitle => 'Delete for good?';

  @override
  String get deleteForGoodBody =>
      'Your account can\'t be recovered once it\'s deleted.';

  @override
  String get deletingAccount => 'Deleting your account…';

  @override
  String deleteAccountFailed(String reason) {
    return 'Couldn\'t delete your account. $reason';
  }

  @override
  String get undo => 'Undo';

  @override
  String workoutDeleted(String name) {
    return '“$name” deleted';
  }

  @override
  String get syncFailed =>
      'Couldn\'t sync. Check your connection and try again.';

  @override
  String get mapTitle => 'Fitrix map';

  @override
  String get mapFilterAll => 'All';

  @override
  String get mapFilterGyms => 'Gyms';

  @override
  String get mapFilterParks => 'Parks';

  @override
  String get mapFilterTracks => 'Tracks';

  @override
  String get mapFilterPools => 'Pools';

  @override
  String get mapLocationOff => 'Location off: showing central Tashkent';

  @override
  String get mapHoursUnknown => 'Hours not listed';

  @override
  String mapAway(String distance) {
    return '$distance away';
  }

  @override
  String get mapShowRoute => 'Show route';

  @override
  String get mapHideRoute => 'Hide route';

  @override
  String get mapModesLabel => 'How to get there';

  @override
  String get mapModeWalk => 'Walk';

  @override
  String get mapModeBike => 'Bike';

  @override
  String get mapModeCar => 'Car';

  @override
  String get mapModeMetro => 'Metro';

  @override
  String get mapComputing => 'Working out routes…';

  @override
  String get mapCoverage => 'Routes cover central Tashkent';

  @override
  String get mapNoRoute => 'No route for this mode';

  @override
  String get mapMetroNoHelp =>
      'Metro does not help on this trip: no station pair that saves time.';

  @override
  String get mapPlanFailed => 'Could not work out routes. Try another place.';

  @override
  String mapMinutes(int n) {
    return '$n min';
  }

  @override
  String mapHoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String mapArrive(String duration, String time) {
    return '$duration · arrive $time';
  }

  @override
  String mapRide(String from, String to, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '$count stop',
    );
    return '$from → $to, $_temp0';
  }

  @override
  String mapWalkTotal(String distance) {
    return '$distance on foot in total';
  }

  @override
  String get mapWalkingFaster => 'walking is faster here';

  @override
  String mapNoteWalk(String distance) {
    return '$distance on foot';
  }

  @override
  String mapNoteBike(String distance) {
    return '$distance by bike, paths included';
  }

  @override
  String mapNoteCar(String distance) {
    return '$distance by car, no traffic data, 2 min to park';
  }

  @override
  String mapMeters(int n) {
    return '$n m';
  }

  @override
  String mapKilometers(String n) {
    return '$n km';
  }
}
