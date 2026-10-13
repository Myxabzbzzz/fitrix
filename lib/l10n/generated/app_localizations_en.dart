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
<<<<<<< HEAD
  String get homeToday => 'Today';

  @override
  String homeTodayMeta(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0 · about $minutes min';
  }

  @override
  String get homeStart => 'Start';

  @override
  String get homeContinue => 'Continue';

  @override
  String get progressTitle => 'My progress';

  @override
  String get progressStrength => 'Strength';

  @override
  String progressNoWorkouts(String sport) {
    return 'No $sport workouts yet. Finish one with at least one set checked off and your progress will show up here.';
  }

  @override
  String get progressRecentWorkouts => 'Recent workouts';

  @override
  String get progressBody => 'Body';

  @override
  String get progressSampleNote => 'Sample data — tracking is coming soon.';

  @override
  String progressFirst(String value) {
    return 'First: $value';
  }

  @override
  String progressLatest(String value) {
    return 'Latest: $value';
  }

  @override
  String progressCurrent(String value) {
    return 'Current: $value';
  }

  @override
  String progressMonthAgo(String value) {
    return 'One month ago: $value';
  }

  @override
  String get progressIntake => 'Intake, avg';

  @override
  String get progressBurn => 'Burn, avg';

  @override
  String get progressKcalPerDay => 'kcal / day';

  @override
  String progressSets(String count) {
    return '$count sets';
  }

  @override
  String get nutritionTitle => 'My Nutrition';

  @override
  String nutritionOfGoal(String goal) {
    return 'of $goal kcal';
  }

  @override
  String nutritionLeft(String kcal) {
    return '$kcal kcal left today';
  }

  @override
  String get nutritionGoalReached => 'Goal reached for today';

  @override
  String get nutritionProtein => 'Protein';

  @override
  String get nutritionCarbs => 'Carbs';

  @override
  String get nutritionFat => 'Fat';

  @override
  String get nutritionBreakfast => 'Breakfast';

  @override
  String get nutritionBreakfastItems => 'Oatmeal, banana, coffee';

  @override
  String get nutritionLunch => 'Lunch';

  @override
  String get nutritionLunchItems => 'Chicken, rice, salad';

  @override
  String get nutritionSnack => 'Snack';

  @override
  String get nutritionSnackItems => 'Yogurt and nuts';

  @override
  String get nutritionDinner => 'Dinner';

  @override
  String get nutritionNotLogged => 'Not logged yet';

  @override
  String nutritionKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String get nutritionTipEyebrow => 'Felix tip';

  @override
  String get nutritionTipTitle => 'Protein at dinner';

  @override
  String get nutritionTipMessage =>
      'For dinner, aim for about 40 g of protein. Chicken, rice and greens fit your plan.';
=======
  String get profileTitle => 'Profile';

  @override
  String get profileWorkouts => 'workouts';

  @override
  String get profileDayStreak => 'day streak';

  @override
  String get profileKgNow => 'kg now';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileTheme => 'Theme';

  @override
  String get profileThemeAuto => 'Auto';

  @override
  String get profileThemeLight => 'Light';

  @override
  String get profileThemeDark => 'Dark';
>>>>>>> t10
}
