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

  @override
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

  @override
  String get chatQuickPlanWeek => 'Plan my week';

  @override
  String get chatQuickEatToday => 'What should I eat today?';

  @override
  String get chatQuickTired => 'I feel tired today';

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

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverNotifications => 'Notifications';

  @override
  String get discoverNoNotifications => 'No new notifications';

  @override
  String get discoverForYou => 'For you';

  @override
  String get discoverChallenges => 'Challenges';

  @override
  String get discoverPrograms => 'Programs';

  @override
  String get discoverArticles => 'Articles';

  @override
  String get discoverThisWeek => 'This week';

  @override
  String get discoverJoin => 'Join challenge';

  @override
  String get discoverJoined => 'Joined';

  @override
  String get discoverSignInToJoin => 'Sign in to join challenges';

  @override
  String get discoverSignIn => 'Sign in';

  @override
  String get discoverJoinFailed => 'Couldn’t join. Try again.';

  @override
  String get discoverProgramsForYou => 'Programs for you';

  @override
  String get discoverAll => 'All';

  @override
  String discoverProgramSoon(String title) {
    return '$title: preview coming soon';
  }

  @override
  String get discoverFelixEyebrow => 'Tip from Felix';

  @override
  String get discoverFelixTitle => 'Rest keeps you strong';

  @override
  String get discoverFelixMessage =>
      'Two easy days a week lower injury risk and keep your lifts climbing.';

  @override
  String get discoverAskFelix => 'Ask Felix';

  @override
  String get discoverRead => 'Read';

  @override
  String discoverMinRead(int n) {
    return '$n min read';
  }

  @override
  String get discoverArticleMissing => 'This article isn’t available.';

  @override
  String get shopTitle => 'Shop';

  @override
  String shopCartLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cart, $n items',
      one: 'Cart, 1 item',
      zero: 'Cart, empty',
    );
    return '$_temp0';
  }

  @override
  String get shopSearchHint => 'Search products';

  @override
  String get shopAll => 'All';

  @override
  String get shopCatSupplements => 'Supplements';

  @override
  String get shopCatEquipment => 'Equipment';

  @override
  String get shopCatApparel => 'Apparel';

  @override
  String get shopProBlurb =>
      'Unlimited chats with Felix, custom plans and form checks.';

  @override
  String get shopProButton => 'Learn more';

  @override
  String get shopProSoonTitle => 'FITRIX Pro is coming soon';

  @override
  String get shopProSoonBody => 'We’ll let you know as soon as it’s ready.';

  @override
  String get shopGotIt => 'Got it';

  @override
  String shopNothingFound(String query) {
    return 'Nothing found for “$query”.';
  }

  @override
  String shopAdd(String name) {
    return 'Add $name';
  }

  @override
  String get shopCartTitle => 'Cart';

  @override
  String get shopClose => 'Close';

  @override
  String get shopRemoveOne => 'Remove one';

  @override
  String get shopAddOne => 'Add one';

  @override
  String get shopTotal => 'Total';

  @override
  String get shopPlaceOrder => 'Place order';

  @override
  String get shopCartEmpty =>
      'Your cart is empty. Tap + on any product to add it.';

  @override
  String get shopOrderPlaced => 'Order placed';

  @override
  String get shopSignInToOrder => 'Sign in to place an order';

  @override
  String get shopOrderFailed =>
      'Couldn’t place the order. Check your connection.';

  @override
  String shopOrderRejected(String message) {
    return 'Order rejected: $message';
  }

  @override
  String get shopRetry => 'Retry';

  @override
  String get shopNoProducts => 'No products yet';

  @override
  String workoutSetsProgress(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done of $total sets',
      one: '$done of $total set',
    );
    return '$_temp0';
  }

  @override
  String workoutSetCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sets',
      one: '$n set',
    );
    return '$_temp0';
  }

  @override
  String workoutSetDone(int n) {
    return 'Set $n done';
  }

  @override
  String get workoutFinishTitle => 'Finish workout?';

  @override
  String get workoutFinishNoSets =>
      'No sets are checked off, so this workout won’t be saved.';

  @override
  String workoutFinishSummary(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done of $total sets completed.',
      one: '$done of $total set completed.',
    );
    return '$_temp0 The workout will be saved to your history.';
  }

  @override
  String get workoutKeepGoing => 'Keep going';

  @override
  String get workoutFinish => 'Finish';

  @override
  String get workoutSaved => 'Workout saved to My progress';

  @override
  String get workoutNoExercises =>
      'No exercises yet. Add some with “Edit” on the workout card.';

  @override
  String get workoutAddSet => 'Add set';

  @override
  String get workoutFinishButton => 'Finish workout';

  @override
  String get workoutColSet => 'Set';

  @override
  String get workoutColPrevious => 'Previous';

  @override
  String get workoutColKg => 'Kg';

  @override
  String get workoutColReps => 'Reps';

  @override
  String get gymCoachFirstTitle => 'Ready for your first workout?';

  @override
  String gymCoachFirstMessage(String workout) {
    return 'Start with $workout. Felix will adjust the plan after it.';
  }

  @override
  String get gymCoachBackTitle => 'Welcome back';

  @override
  String gymCoachBackMessage(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return 'Your last workout was $_temp0 ago. A lighter session today gets you back on track.';
  }

  @override
  String get gymFinishCurrentTitle => 'Finish current workout?';

  @override
  String gymFinishCurrentBody(String current, String next) {
    return '“$current” is still in progress. Start “$next” instead?';
  }

  @override
  String get gymMyWorkouts => 'My workouts';

  @override
  String get gymNewWorkout => 'New workout';

  @override
  String get gymNewWorkoutHint => 'e.g. Shoulders';

  @override
  String get gymAdd => 'Add';

  @override
  String get gymEditNameHint => 'Workout name';

  @override
  String get gymEditDelete => 'Delete workout';

  @override
  String get gymEditAddExerciseHint => 'Add exercise';

  @override
  String get gymEditSave => 'Save';

  @override
  String get sportGym => 'Gym';

  @override
  String get sportFitness => 'Fitness';

  @override
  String get sportCycling => 'Cycling';

  @override
  String get sportRunning => 'Running';

  @override
  String get sportFootball => 'Football';

  @override
  String get sportWinterSports => 'Winter sports';

  @override
  String get sportWinterSportsTile => 'WINTER\nSPORTS';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabShop => 'Shop';

  @override
  String get tabHome => 'Home';

  @override
  String get tabFelix => 'Felix';

  @override
  String get tabProfile => 'Profile';

  @override
  String get homeTileProgress => 'MY\nPROGRESS';

  @override
  String get homeTileNutrition => 'MY\nNUTRITION';

  @override
  String get homeTileWorkouts => 'MY\nWORKOUTS';

  @override
  String get homeTileShop => 'SHOP';

  @override
  String get homeTileMap => 'FITRIX\nMAP';

  @override
  String get homeMenuNutrition => 'My nutrition';

  @override
  String get homeMenuMap => 'Fitrix map';

  @override
  String get chatTyping => 'Felix is typing';

  @override
  String chatError(String error) {
    return 'Error: $error';
  }

  @override
  String get chatStart => 'Start';

  @override
  String get chatMessageHint => 'Message...';

  @override
  String get chatAllChats => 'All chats';

  @override
  String get chatTapToRetry => 'Tap to retry';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get progressWeightTitle => 'My weight (kg)';

  @override
  String get progressCaloriesTitle => 'Calories: intake vs burn';

  @override
  String signInCodeResent(String email) {
    return 'We sent a new code to $email';
  }

  @override
  String get signInChangeEmail => 'Change email';

  @override
  String get profileFieldName => 'Name';

  @override
  String get profileFieldSurname => 'Surname';

  @override
  String get profileFieldWeightKg => 'Weight, kg';

  @override
  String get profileFieldHeightCm => 'Height, cm';
}
