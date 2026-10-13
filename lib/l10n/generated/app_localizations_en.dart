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
  String get gymToday => 'Today';

  @override
  String get gymStart => 'Start';

  @override
  String get gymDone => 'Done';

  @override
  String get gymAskFelix => 'Ask';

  @override
  String gymCoachEyebrow(String sport) {
    return 'AI $sport COACH';
  }

  @override
  String gymTileCaption(int plans, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      plans,
      locale: localeName,
      other: '$plans plans',
      one: '$plans plan',
    );
    return '$_temp0 · $week this week';
  }
}
