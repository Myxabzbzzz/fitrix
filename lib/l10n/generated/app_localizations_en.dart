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
      'Everything you logged is stored only on this device and will be deleted: profile, workouts, chats, check-ins, plans, food and body weight.';

  @override
  String get signOutAccountBody =>
      'Your profile, workouts and chats are saved to your account and will be removed from this device. Sign in with the same email to get them back. Check-ins, plans, food and body weight are kept only on this device and will be deleted.';

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
  String progressSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '$count set',
    );
    return '$_temp0';
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
  String get shopProSoonBody =>
      'It isn’t available yet. It will appear here in a later update.';

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
  String get shopRetry => 'Retry';

  @override
  String get shopNoProducts => 'No products yet';

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
      'No exercises yet. Long-press the workout card to add some.';

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
    return 'Start with $workout. Next time Felix suggests weights from what you log.';
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

  @override
  String get signInAgainTitle => 'Sign in again';

  @override
  String get signInAgainSubtitle =>
      'Your session has ended. Enter your email to continue.';

  @override
  String get signInCreateTitle => 'Create an account';

  @override
  String get signInCreateSubtitle => 'Enter your email to sign up for this app';

  @override
  String get signInGetCode => 'Get code';

  @override
  String get signInTryAgain => 'Try again';

  @override
  String get signInOr => 'or';

  @override
  String get signInTermsPrefix => 'By clicking continue, you agree to our ';

  @override
  String get signInTerms => 'Terms of Service';

  @override
  String get signInTermsAnd => ' and ';

  @override
  String get signInPrivacy => 'Privacy Policy';

  @override
  String get signInTermsSuffix => '.';

  @override
  String signInContinueWith(String provider) {
    return 'Continue with $provider';
  }

  @override
  String get signInCheckEmailTitle => 'Check your email';

  @override
  String signInCodePrompt(String length, String email) {
    return 'Enter the $length-digit code we sent to\n$email';
  }

  @override
  String get signInResend => 'Resend code';

  @override
  String signInResendIn(String time) {
    return 'Resend code in $time';
  }

  @override
  String get signInSpamNote => 'Can\'t find it? Check your spam folder.';

  @override
  String signInComingSoon(String provider) {
    return 'Sign in with $provider is coming soon. Please use your email for now.';
  }

  @override
  String get signInProfileLoadOffline =>
      'You\'re signed in, but your profile couldn\'t be loaded. Check your connection and try again.';

  @override
  String get signInProfileLoadFailed =>
      'You\'re signed in, but your profile couldn\'t be loaded. Please try again.';

  @override
  String get signInErrInvalidCode =>
      'That code is wrong or has expired. Check the latest email or send a new code.';

  @override
  String get signInErrRateLimited =>
      'Too many attempts. Please wait a minute and try again.';

  @override
  String get signInErrNetwork =>
      'No connection. Check your internet and try again.';

  @override
  String get signInErrInvalidEmail => 'Enter a valid email address.';

  @override
  String get signInErrUnknown => 'Something went wrong. Please try again.';

  @override
  String signInErrProviderDisabled(String provider) {
    return 'Sign in with $provider isn\'t set up on the server yet. Please use your email for now.';
  }

  @override
  String signInErrProviderUnavailable(String provider) {
    return 'Sign in with $provider isn\'t available on this device. Please use your email instead.';
  }

  @override
  String signInErrSocialFailed(String provider) {
    return 'Couldn\'t sign in with $provider. Please try again or use your email.';
  }

  @override
  String get profileErrNameRequired => 'Enter your name';

  @override
  String get profileErrNameTooLong => 'Name is too long';

  @override
  String get profileErrSurnameTooLong => 'Surname is too long';

  @override
  String get profileErrAgeRequired => 'Enter your age';

  @override
  String get profileErrAgeWhole => 'Age must be a whole number';

  @override
  String profileErrAgeRange(String min, String max) {
    return 'Age must be between $min and $max';
  }

  @override
  String get profileErrWeightRequired => 'Enter your weight';

  @override
  String get profileErrWeightNumber => 'Enter your weight as a number';

  @override
  String profileErrWeightRange(String min, String max) {
    return 'Weight must be between $min and $max kg';
  }

  @override
  String get profileErrHeightRequired => 'Enter your height';

  @override
  String get profileErrHeightNumber => 'Enter your height as a number';

  @override
  String profileErrHeightRange(String min, String max) {
    return 'Height must be between $min and $max cm';
  }

  @override
  String get signInUnavailable =>
      'Accounts are unavailable right now. Try again later.';

  @override
  String get programLevelBeginner => 'Beginner';

  @override
  String get programLevelMedium => 'Intermediate';

  @override
  String get programLevelAdvanced => 'Advanced';

  @override
  String get shopOrderUnavailable =>
      'Some items are no longer available. Update your cart and try again.';

  @override
  String get workoutKeyboardDone => 'Done';

  @override
  String get workoutEditLabel => 'Edit workout';

  @override
  String get aboutMeSave => 'Save';

  @override
  String get aboutMeSaved => 'Saved';

  @override
  String get aboutMeDiscardTitle => 'Discard changes?';

  @override
  String get aboutMeDiscardBody =>
      'Your edits to this profile won\'t be saved.';

  @override
  String get aboutMeDiscard => 'Discard';

  @override
  String get aboutMeKeepEditing => 'Keep editing';

  @override
  String get aboutMeEmail => 'Email';

  @override
  String get aboutMeGoal => 'Goal';

  @override
  String get aboutMeGoalOther => 'Other…';

  @override
  String get aboutMeGoalOtherHint => 'Describe your goal';

  @override
  String get aboutMeLevel => 'Level';

  @override
  String get aboutMeSports => 'Sports';

  @override
  String get aboutMeSportsLimit => 'You can pick up to 6 sports.';

  @override
  String get aboutGoalBuild => 'Build muscle and strength';

  @override
  String get aboutGoalEndurance => 'Improve endurance and stamina';

  @override
  String get aboutGoalLose => 'Lose weight and get toned';

  @override
  String get aboutGoalHealthy => 'Feel healthier and balanced';

  @override
  String get aboutGoalTrack => 'Just track my progress';

  @override
  String get chatAddPhoto => 'Add photo';

  @override
  String get chatTakePhoto => 'Take photo';

  @override
  String get chatChooseFromLibrary => 'Choose from library';

  @override
  String get chatRemovePhoto => 'Remove photo';

  @override
  String get chatPhotoTooLarge => 'That photo is too large. Try another one.';

  @override
  String get chatPhotoFailed =>
      'Couldn\'t get the photo. Check camera and photo permissions in Settings.';

  @override
  String get chatPhotoPrompt => 'What do you think of this photo?';

  @override
  String get chatMicStart => 'Dictate a message';

  @override
  String get chatMicStop => 'Stop dictation';

  @override
  String get chatMicDenied =>
      'Felix can\'t hear you yet. Open Settings and allow microphone and speech recognition for FITRIX.';

  @override
  String get chatPhotoViewer => 'Photo';

  @override
  String get chatPhotoUnavailable =>
      'The photo is missing or too large to send.';

  @override
  String get chatMicListening => 'Listening';

  @override
  String get chatMicStopped => 'Stopped listening';

  @override
  String get chatActionConfirm => 'Confirm';

  @override
  String get chatActionApplied => 'Added ✓';

  @override
  String chatActionWeightChange(String from, String to) {
    return 'Update weight: $from → $to kg';
  }

  @override
  String chatActionWeightSet(String to) {
    return 'Update weight to $to kg';
  }

  @override
  String chatActionWeightUnknown(String delta) {
    return 'Weight change: $delta kg. Enter your current weight in your profile first.';
  }

  @override
  String chatActionWorkoutTitle(int count, String sport) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Add $count workouts to $sport',
      one: 'Add $count workout to $sport',
    );
    return '$_temp0';
  }

  @override
  String chatActionWorkoutExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0';
  }

  @override
  String get chatActionMealTitle => 'Add to today’s nutrition';

  @override
  String chatActionMealTotal(String kcal) {
    return '$kcal kcal in total';
  }

  @override
  String chatActionWorkoutsAdded(String sport) {
    return 'Workouts added to $sport';
  }

  @override
  String get chatActionOpen => 'Open';

  @override
  String chatActionWeightDone(String from, String to) {
    return 'Weight updated: $from → $to kg';
  }

  @override
  String chatActionWeightDoneSet(String to) {
    return 'Weight updated to $to kg';
  }

  @override
  String get chatActionNoProfile =>
      'Fill in your profile first, then I can update your weight.';

  @override
  String get chatActionError => 'Couldn’t apply this. Please try again.';

  @override
  String get unitTonnes => 't';

  @override
  String workoutLiveCaption(int x, int y, String t) {
    return 'Set $x of $y · $t lifted';
  }

  @override
  String get workoutColRpe => 'RPE';

  @override
  String workoutRestShort(String time) {
    return 'rest $time';
  }

  @override
  String workoutBestShort(String value) {
    return 'best $value';
  }

  @override
  String get workoutPr => 'PR';

  @override
  String get workoutE1rm => 'e1RM';

  @override
  String get workoutBodyweight => 'BW';

  @override
  String workoutFelixLine(String last, String next) {
    return 'Last time $last. Try $next kg today.';
  }

  @override
  String get workoutRestLabel => 'Rest';

  @override
  String workoutRestNext(String label) {
    return 'Next: $label';
  }

  @override
  String workoutNextSet(int n, String kg, int reps) {
    return 'Set $n · $kg × $reps';
  }

  @override
  String workoutRestAdd(int n) {
    return '+${n}s';
  }

  @override
  String workoutRestSub(int n) {
    return '−${n}s';
  }

  @override
  String get workoutRestSkip => 'Skip';

  @override
  String get workoutMenuSwap => 'Swap exercise';

  @override
  String workoutMenuSimilar(String names) {
    return 'Similar: $names';
  }

  @override
  String get workoutMenuNoSimilar => 'No similar exercises in the library';

  @override
  String get workoutMenuWarmup => 'Add warm-up sets';

  @override
  String workoutMenuWarmupSub(String plan) {
    return '2 sets: $plan';
  }

  @override
  String get workoutMenuRest => 'Rest timer';

  @override
  String get workoutMenuRestSub => 'For this exercise';

  @override
  String get workoutMenuNote => 'Note';

  @override
  String get workoutMenuNoteEmpty => 'Add a note';

  @override
  String get workoutMenuNoteHint => 'e.g. Straps on the last set';

  @override
  String get workoutNoteSave => 'Save';

  @override
  String get workoutMenuReorder => 'Reorder';

  @override
  String get workoutMenuReorderSub => 'Move up or down in the workout';

  @override
  String get workoutMenuRemove => 'Remove exercise';

  @override
  String get workoutRemoveTitle => 'Remove this exercise?';

  @override
  String get workoutRemoveBody => 'Its logged sets will be lost.';

  @override
  String get workoutRemoveConfirm => 'Remove';

  @override
  String workoutRpeTitle(int n) {
    return 'RPE for set $n · how hard was it?';
  }

  @override
  String workoutRpeCaption(int n, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left reps',
      one: '$left rep',
    );
    return 'RPE $n · about $_temp0 left in the tank';
  }

  @override
  String get workoutCompleteTitle => 'Workout complete';

  @override
  String workoutCompleteSubtitle(String name, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n new records',
      one: '$n new record',
      zero: 'no new records',
    );
    return '$name · $_temp0';
  }

  @override
  String get workoutTileDuration => 'Duration';

  @override
  String get workoutTileVolume => 'Volume';

  @override
  String get workoutTileSets => 'Sets';

  @override
  String get workoutTileRecords => 'Records';

  @override
  String get workoutTileLoad => 'Load';

  @override
  String get workoutOverallTitle => 'How hard was it overall?';

  @override
  String get workoutOverallHint =>
      'Optional. It counts toward your training load and recovery score.';

  @override
  String workoutOverallCaption(int n, String label) {
    return 'RPE $n · $label. Counts toward your training load.';
  }

  @override
  String get workoutRpeVeryEasy => 'Very easy';

  @override
  String get workoutRpeEasy => 'Easy';

  @override
  String get workoutRpeModerate => 'Moderate';

  @override
  String get workoutRpeHard => 'Hard';

  @override
  String get workoutRpeVeryHard => 'Very hard';

  @override
  String get workoutRpeMax => 'Max effort';

  @override
  String get workoutExercisesTitle => 'Exercises';

  @override
  String get workoutBestSetE1rm => 'best set · e1RM';

  @override
  String workoutBestSet(String value) {
    return 'Best set $value';
  }

  @override
  String get workoutNextTimeTitle => 'Next time';

  @override
  String workoutNextTimeBody(String exercise, String kg) {
    return '$exercise: every set done. Try $kg kg next time.';
  }

  @override
  String get workoutSave => 'Save workout';

  @override
  String get workoutDiscard => 'Discard';

  @override
  String get workoutDiscardTitle => 'Discard this workout?';

  @override
  String get workoutDiscardBody => 'It won’t be saved to your history.';

  @override
  String get workoutAddExercise => 'Exercise';

  @override
  String homeGreetingMorning(String name) {
    return 'Good morning, $name';
  }

  @override
  String get homeGreetingMorningNoName => 'Good morning';

  @override
  String homeGreetingAfternoon(String name) {
    return 'Good afternoon, $name';
  }

  @override
  String get homeGreetingAfternoonNoName => 'Good afternoon';

  @override
  String homeGreetingEvening(String name) {
    return 'Good evening, $name';
  }

  @override
  String get homeGreetingEveningNoName => 'Good evening';

  @override
  String get checkinCardPrompt =>
      'How do you feel today? 20 seconds to see how ready you are to train.';

  @override
  String get checkinCardAction => 'Check in';

  @override
  String checkinCardRecovered(int score) {
    return '$score% recovered';
  }

  @override
  String get checkinCardSeeMore => 'See what shaped it';

  @override
  String get checkinTitle => 'Morning check-in';

  @override
  String get checkinSleep => 'Sleep';

  @override
  String checkinSleepDuration(int hours, int minutes) {
    return '$hours h $minutes m';
  }

  @override
  String get checkinSleepLess => 'Sleep 15 minutes less';

  @override
  String get checkinSleepMore => 'Sleep 15 minutes more';

  @override
  String get sleepQualityPoor => 'Poor';

  @override
  String get sleepQualityOk => 'OK';

  @override
  String get sleepQualityGood => 'Good';

  @override
  String get checkinSoreness => 'Muscle soreness';

  @override
  String get sorenessNone => 'None';

  @override
  String get sorenessLight => 'Light';

  @override
  String get sorenessMedium => 'Medium';

  @override
  String get sorenessStrong => 'Strong';

  @override
  String get bodyLegs => 'Legs';

  @override
  String get bodyBack => 'Back';

  @override
  String get bodyChest => 'Chest';

  @override
  String get bodyArms => 'Arms';

  @override
  String get bodyShoulders => 'Shoulders';

  @override
  String get checkinEnergy => 'Energy';

  @override
  String get checkinStress => 'Stress';

  @override
  String get levelLow => 'Low';

  @override
  String get levelOk => 'OK';

  @override
  String get levelHigh => 'High';

  @override
  String get stressLow => 'Low';

  @override
  String get stressMedium => 'Medium';

  @override
  String get stressHigh => 'High';

  @override
  String get checkinSave => 'Save check-in';

  @override
  String get readinessReady => 'Ready to train';

  @override
  String get readinessTrainLight => 'Train light';

  @override
  String get readinessRest => 'Rest today';

  @override
  String get checkinHintReady => 'A hard session is fine.';

  @override
  String checkinHintReadySore(String areas) {
    return 'A hard session is fine. $areas need one more day.';
  }

  @override
  String get checkinHintLight => 'Keep it lighter today.';

  @override
  String get checkinHintRest => 'Take it easy. Recovery is training too.';

  @override
  String get recoveryTitle => 'Recovery';

  @override
  String recoverySubtitle(String time) {
    return 'Today · check-in at $time';
  }

  @override
  String get recoveryRecovered => 'recovered';

  @override
  String recoveryHintReadySore(String areas) {
    return 'A hard session is fine. Keep $areas light today.';
  }

  @override
  String get recoveryShaped => 'What shaped it';

  @override
  String factorSleep(String duration) {
    return 'Sleep $duration';
  }

  @override
  String factorSleepQuality(String quality) {
    return '$quality quality';
  }

  @override
  String factorSoreness(String level) {
    return 'Soreness: $level';
  }

  @override
  String factorEnergy(String level) {
    return 'Energy: $level';
  }

  @override
  String factorStress(String level) {
    return 'Stress: $level';
  }

  @override
  String get factorLoad => 'Training load';

  @override
  String factorLoadSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hard days',
      one: '1 hard day',
    );
    return '$_temp0 in the last 7';
  }

  @override
  String get recoveryPlanTitle => 'Today’s plan, adjusted';

  @override
  String recoveryPlanApplied(String plan, String swaps, String areas) {
    return '$plan stays. Swapped: $swaps. This spares your $areas.';
  }

  @override
  String recoveryPlanSuggested(String plan, String swaps, String areas) {
    return '$plan can stay. Suggested swaps: $swaps, to spare your $areas.';
  }

  @override
  String get recoveryStartWorkout => 'Start workout';

  @override
  String get recoveryUndo => 'Undo';

  @override
  String get recoveryApplySwaps => 'Apply swaps';

  @override
  String get recoveryLast7 => 'Last 7 days';

  @override
  String recoveryAvg(int score) {
    return 'avg $score%';
  }

  @override
  String get recoveryNoCheckin => 'No check-in yet';

  @override
  String get recoveryNoCheckinBody =>
      'Check in to see how recovered you are and what shaped it.';

  @override
  String get planTitle => 'This week';

  @override
  String planSummary(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sessions',
      one: '$n session',
    );
    return '$_temp0 · $m done';
  }

  @override
  String get planLoadTitle => 'Training load';

  @override
  String get planLoadEasy => 'Easy';

  @override
  String get planLoadNormal => 'Normal';

  @override
  String get planLoadHigh => 'High';

  @override
  String planLoadCaption(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n hard sessions in the next 3 days.',
      one: '$n hard session in the next 3 days.',
    );
    return '$_temp0';
  }

  @override
  String planRecoveryToday(int score) {
    return 'Recovery today $score%.';
  }

  @override
  String get planFelixLabel => 'FELIX SUGGESTS';

  @override
  String planFelixText(
      String a, String aDay, String b, String bDay, String target) {
    return '$a ($aDay) and $b ($bDay) are both hard. Move $b to $target so your legs recover.';
  }

  @override
  String get planOptimize => 'Optimize plan';

  @override
  String get planKeep => 'Keep';

  @override
  String planTodayDay(String day) {
    return 'Today · $day';
  }

  @override
  String planDoneCount(int n) {
    return '$n done';
  }

  @override
  String planPlannedCount(int n) {
    return '$n planned';
  }

  @override
  String get planMissedHeader => 'missed';

  @override
  String get planMissed => 'Missed';

  @override
  String get planRestDay => 'Rest day';

  @override
  String planExercisesMeta(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '$count exercise',
    );
    return '$_temp0 · $duration';
  }

  @override
  String planDurationHM(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String planDurationH(int h) {
    return '${h}h';
  }

  @override
  String planDurationM(int m) {
    return '$m min';
  }

  @override
  String get planIntensityEasy => 'Easy';

  @override
  String get planIntensityNormal => 'Normal';

  @override
  String get planIntensityHard => 'Hard';

  @override
  String planDoneMeta(String duration, int rpe) {
    return '$duration · RPE $rpe';
  }

  @override
  String get planAddSession => 'Add session';

  @override
  String get planAddTitle => 'Add a session';

  @override
  String get planWorkoutLabel => 'WORKOUT';

  @override
  String get planDayLabel => 'DAY';

  @override
  String planAddButton(String title, String day) {
    return 'Add $title · $day';
  }

  @override
  String planWarnThird(String day) {
    return '$day would be your 3rd hard day in a row';
  }

  @override
  String planWarnAuto(String day) {
    return '$day gives you more time to recover. Felix picked it for you.';
  }

  @override
  String get planWarnPick => 'Pick another day to keep your recovery.';

  @override
  String get planGenericFootball => 'Football 7×7';

  @override
  String get planSkiing => 'Skiing';

  @override
  String get planEmptyTitle => 'No plan yet';

  @override
  String get planEmptyBody =>
      'Set up your gym workouts for the rest of this week in one tap.';

  @override
  String get planPlanWeek => 'Plan my week';

  @override
  String get planEntryEmpty => 'Plan your training week';

  @override
  String get planNextWeek => 'Next week';

  @override
  String get planPlanNextWeek => 'Plan next week';

  @override
  String get exercisesTitle => 'Exercises';

  @override
  String exercisesSearch(int n) {
    return 'Search $n exercises';
  }

  @override
  String get exercisesSearchShort => 'Search exercises';

  @override
  String get exercisesAll => 'All';

  @override
  String get exercisesAnyEquipment => 'Any equipment';

  @override
  String get exercisesRecent => 'Your recent';

  @override
  String get exercisesFromWorkouts => 'from workouts';

  @override
  String get exercisesBest => 'best';

  @override
  String get exercisesAZ => 'All · A–Z';

  @override
  String exercisesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises',
      one: '$n exercise',
    );
    return '$_temp0';
  }

  @override
  String get exercisesNoMatch => 'No exercises match. Try another filter.';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleBack => 'Back';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleArms => 'Arms';

  @override
  String get muscleLegs => 'Legs';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleCore => 'Core';

  @override
  String get equipBarbell => 'Barbell';

  @override
  String get equipDumbbell => 'Dumbbell';

  @override
  String get equipCable => 'Cable';

  @override
  String get equipMachine => 'Machine';

  @override
  String get equipBodyweight => 'Bodyweight';

  @override
  String get equipKettlebell => 'Kettlebell';

  @override
  String get levelBeginner => 'Beginner';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get exerciseCompound => 'Compound';

  @override
  String get exerciseDetailTitle => 'Exercise';

  @override
  String get exercisePrimary => 'Primary';

  @override
  String get exerciseSecondary => 'Secondary';

  @override
  String get exerciseYourNumbers => 'Your numbers';

  @override
  String get exerciseBestSet => 'Best set';

  @override
  String get exerciseE1rm => 'e1RM';

  @override
  String get exerciseSessions => 'Sessions';

  @override
  String exerciseChangeSince(String pct, String month) {
    return '$pct since $month';
  }

  @override
  String get exerciseNoHistory => 'Do it once to see your numbers';

  @override
  String get exerciseHowTo => 'How to do it';

  @override
  String get exerciseMistakes => 'Common mistakes';

  @override
  String get exerciseSimilar => 'Similar';

  @override
  String get exerciseAskFelix => 'Ask Felix';

  @override
  String exerciseAskFelixDraft(String name) {
    return 'How do I improve my $name?';
  }

  @override
  String get exerciseAddToWorkout => 'Add to workout';

  @override
  String get exerciseAdded => 'Added to your workout';

  @override
  String get exerciseQuickWorkout => 'Quick workout';

  @override
  String addExerciseTitle(String workout) {
    return 'Add to $workout';
  }

  @override
  String addExerciseSwapTitle(String workout) {
    return 'Swap in $workout';
  }

  @override
  String addExerciseHint(String group, int n, int target) {
    return '$group got $n sets this week, target is $target.';
  }

  @override
  String get addExerciseSuggested => 'Suggested';

  @override
  String addExerciseSelected(int n) {
    return '$n selected';
  }

  @override
  String get addExerciseLibrary => 'Library';

  @override
  String get addExerciseInWorkout => 'In this workout';

  @override
  String addExerciseButton(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Add $n exercises',
      one: 'Add $n exercise',
    );
    return '$_temp0';
  }

  @override
  String get addExerciseSwap => 'Swap';

  @override
  String get workoutMenuSwapSub => 'Choose from the library';

  @override
  String get gymExercises => 'Exercises';

  @override
  String gymExercisesSub(int n) {
    return '$n with technique and your best sets';
  }

  @override
  String get profileEditTooltip => 'Edit profile';

  @override
  String get profileMySports => 'My sports';

  @override
  String profileSportsSelected(int n) {
    return '$n selected';
  }

  @override
  String get profileWeightLabel => 'kg · weight';

  @override
  String get profileHeightLabel => 'cm · height';

  @override
  String get profileAgeLabel => 'years · age';

  @override
  String get profileSettings => 'Settings';

  @override
  String get hrZonesTitle => 'Heart-rate zones';

  @override
  String profileHrZonesSummary(int rest, int max) {
    return 'Rest $rest · max $max bpm';
  }

  @override
  String get profileHrZonesSetUp => 'Set up';

  @override
  String get profileConnectedApps => 'Connected apps';

  @override
  String profileConnectedAppsCount(int connected, int total) {
    return '$connected of $total connected';
  }

  @override
  String get hrZonesMax => 'Max HR';

  @override
  String get hrZonesRest => 'Resting HR';

  @override
  String get hrZonesLthr => 'LTHR';

  @override
  String get hrZonesEdit => 'Edit heart rates';

  @override
  String get hrZonesKarvonen => 'Karvonen';

  @override
  String get hrZonesFriel => 'LTHR (Friel)';

  @override
  String get hrZonesKarvonenTitle => 'Karvonen zones';

  @override
  String get hrZonesKarvonenSub => '% of reserve';

  @override
  String get hrZonesFrielTitle => 'LTHR zones';

  @override
  String get hrZonesColZone => 'ZONE';

  @override
  String get hrZonesColBpm => 'BPM';

  @override
  String get hrZonesColHrr => '50–100% HRR';

  @override
  String get hrZonesColLthr => '% OF LTHR';

  @override
  String hrZonesLthrValue(int lthr) {
    return 'LTHR $lthr bpm';
  }

  @override
  String hrZonesFormula(int reserve) {
    return 'HR = rest + % × (max − rest). Your reserve is $reserve bpm.';
  }

  @override
  String hrZonesZ2Tip(int low, int high) {
    return 'Most of your running should sit in Z2, $low–$high bpm. Z4 only for short intervals.';
  }

  @override
  String get hrZonesHowTitle => 'How to measure max HR';

  @override
  String get hrZonesHowBody =>
      'Warm up 15 min, then run a hard 3–4 min uphill effort twice. The highest HR you see is your max.';

  @override
  String hrZonesTanaka(int age, int max) {
    return 'No test yet? Tanaka estimate: 208 − 0.7 × $age = $max bpm (±10).';
  }

  @override
  String get hrZonesRestingTip => 'Resting HR: measure on waking, lying down.';

  @override
  String get hrZonesFrielNote =>
      'Friel zones for running. LTHR test: run 30 min solo all-out, average HR of the last 20 min is your LTHR.';

  @override
  String get hrZonesNeedAge =>
      'Add your age to your profile to get an estimate of your max HR.';

  @override
  String get hrZonesCompleteProfile => 'Complete your profile';

  @override
  String get hrZonesNeedRates =>
      'Add your resting and max HR to see your zones.';

  @override
  String get hrZonesNeedLthr => 'Add your LTHR to see Friel zones.';

  @override
  String get hrZoneRecovery => 'Recovery';

  @override
  String get hrZoneAerobic => 'Aerobic';

  @override
  String get hrZoneTempo => 'Tempo';

  @override
  String get hrZoneThreshold => 'Threshold';

  @override
  String get hrZoneVo2max => 'VO2max';

  @override
  String get hrZoneSubThr => 'Sub-thr.';

  @override
  String get hrZoneThreshPlus => 'Thresh.+';

  @override
  String get hrZoneCapacity => 'Capacity';

  @override
  String get hrZoneAnaerobic => 'Anaerob.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileBody => 'Body';

  @override
  String get editProfilePerformance => 'Performance';

  @override
  String get editProfileSex => 'Sex';

  @override
  String get sexMale => 'Male';

  @override
  String get sexFemale => 'Female';

  @override
  String get editProfileRestingHr => 'Resting HR';

  @override
  String get editProfileMaxHr => 'Max HR';

  @override
  String get editProfileLthr => 'LTHR (optional)';

  @override
  String get editProfileFtp => 'Cycling FTP';

  @override
  String get editProfileFiveK => 'Running 5K personal best';

  @override
  String get unitBpm => 'bpm';

  @override
  String get unitWatts => 'W';

  @override
  String get unitMinSec => 'min:sec';

  @override
  String get unitYears => 'years';

  @override
  String get editProfileSave => 'Save';

  @override
  String editProfileErrHr(int min, int max) {
    return 'Enter $min–$max bpm';
  }

  @override
  String get editProfileErrRestMax => 'Resting HR must be lower than max HR';

  @override
  String editProfileErrFtp(int min, int max) {
    return 'Enter $min–$max W';
  }

  @override
  String get editProfileErrFiveK => 'Enter a time from 12:00 to 60:00';

  @override
  String get connectedAppsTitle => 'Connected apps';

  @override
  String get connectedAppsWhyHeader => 'WHY CONNECT';

  @override
  String get connectedAppsWhyBody =>
      'When connecting arrives in a later update, a watch could fill in sleep, resting HR and HRV for your morning check-in. Until then, you fill in the check-in yourself.';

  @override
  String get connectedAppsAppleDesc => 'Sleep, heart rate, steps, weight';

  @override
  String get connectedAppsGarminDesc => 'Activities, HR, sleep, HRV';

  @override
  String get connectedAppsStravaDesc => 'Runs, rides and ski activities';

  @override
  String get connectedAppsWhoopDesc => 'Recovery, strain, sleep, HRV';

  @override
  String get connectedAppsNotConnected => 'Not connected';

  @override
  String get connectedAppsConnect => 'Connect';

  @override
  String get connectedAppsFooter =>
      'Once apps can be connected, you will be able to disconnect any of them at any time.';

  @override
  String connectedAppsSheetTitle(String app) {
    return 'Connect $app';
  }

  @override
  String get connectedAppsSheetSubtitle => 'What FITRIX could read';

  @override
  String get connectedAppsSheetPrivacy =>
      'When this arrives, FITRIX will only read data and never post.';

  @override
  String get connectedAppsSheetSoon =>
      'Connecting apps is not available yet. We will add it in a later update.';

  @override
  String get connectedAppsComingSoon => 'Coming in a later update';

  @override
  String get connectedAppsClose => 'Close';

  @override
  String get nutritionToday => 'Today';

  @override
  String nutritionDateTraining(String date) {
    return '$date · training day';
  }

  @override
  String get nutritionCompleteTitle => 'Complete your profile';

  @override
  String get nutritionCompleteBody =>
      'Add your sex, age, weight and height to get daily targets.';

  @override
  String get nutritionLeftToday => 'Left today';

  @override
  String get nutritionBurned => 'Burned in training';

  @override
  String nutritionBurnedValue(String kcal) {
    return '≈ +$kcal kcal';
  }

  @override
  String get nutritionHowSet => 'How it’s set ›';

  @override
  String get nutritionMacros => 'Macros';

  @override
  String nutritionProteinPerKg(String value) {
    return 'protein $value g/kg';
  }

  @override
  String nutritionGramsOf(String eaten, String target) {
    return '$eaten / $target g';
  }

  @override
  String nutritionWaterTitle(String drunk, String target) {
    return 'Water · $drunk of $target L';
  }

  @override
  String nutritionWaterNoTarget(String drunk) {
    return 'Water · $drunk L';
  }

  @override
  String get nutritionWaterWorkout => '+0.5 L for today’s workout';

  @override
  String nutritionAddMl(String ml) {
    return '+$ml ml';
  }

  @override
  String get nutritionMeals => 'Meals';

  @override
  String nutritionMealsLogged(String n) {
    return '$n of 4 logged';
  }

  @override
  String get nutritionAdd => 'Add';

  @override
  String get nutritionLowToday => 'Low today';

  @override
  String nutritionAllMicros(String n) {
    return 'All $n ›';
  }

  @override
  String get nutritionDinnerIdea => 'Dinner idea';

  @override
  String nutritionIdeaMessage(
      String gap, String food, String portion, String protein) {
    return 'Protein is $gap g behind. $food ($portion) gives about $protein g.';
  }

  @override
  String get nutritionAddToDinner => 'Add to dinner';

  @override
  String get nutritionOtherIdea => 'Other idea';

  @override
  String get nutritionRemove => 'Remove';

  @override
  String get nutritionSearch => 'Search foods';

  @override
  String get nutritionFood => 'Food';

  @override
  String nutritionGrams(String grams) {
    return '$grams g';
  }

  @override
  String nutritionAddToSlot(String slot) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Add to breakfast',
        'lunch': 'Add to lunch',
        'dinner': 'Add to dinner',
        'snack': 'Add to snack',
        'other': 'Add to dinner',
      },
    );
    return '$_temp0';
  }

  @override
  String nutritionAddToSlotKcal(String slot, String kcal) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Add to breakfast · $kcal kcal',
        'lunch': 'Add to lunch · $kcal kcal',
        'dinner': 'Add to dinner · $kcal kcal',
        'snack': 'Add to snack · $kcal kcal',
        'other': 'Add to dinner · $kcal kcal',
      },
    );
    return '$_temp0';
  }

  @override
  String nutritionAddedTo(String name, String slot) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Added $name to breakfast',
        'lunch': 'Added $name to lunch',
        'dinner': 'Added $name to dinner',
        'snack': 'Added $name to snack',
        'other': 'Added $name',
      },
    );
    return '$_temp0';
  }

  @override
  String get nutritionResults => 'Results';

  @override
  String nutritionResultsCount(String n) {
    return '$n foods · per portion';
  }

  @override
  String get nutritionNoResults => 'Nothing found. Try another name.';

  @override
  String get nutritionRecent => 'Recent';

  @override
  String get nutritionRecentNote => 'you ate it this week';

  @override
  String nutritionPortionLine(String portion, String kcal, String protein) {
    return '$portion · $kcal kcal · P $protein g';
  }

  @override
  String get nutritionCantFind => 'Can’t find it?';

  @override
  String get nutritionCantFindBody => 'Ask Felix to estimate it';

  @override
  String get foodBaseError => 'Couldn’t load the food base.';

  @override
  String get foodNotFound => 'This food isn’t in the base.';

  @override
  String get foodCatAll => 'All';

  @override
  String get foodCatUzbek => 'Uzbek dishes';

  @override
  String get foodCatMeatFish => 'Meat & fish';

  @override
  String get foodCatDairy => 'Dairy';

  @override
  String get foodCatFruit => 'Fruit';

  @override
  String get foodCatVeg => 'Vegetables';

  @override
  String get foodCatGrains => 'Grains';

  @override
  String get foodCatBread => 'Bread';

  @override
  String get foodCatDrinks => 'Drinks';

  @override
  String get foodCatOther => 'Other';

  @override
  String get foodRecipeEstimate => 'Recipe estimate';

  @override
  String foodPer100(String kcal) {
    return '$kcal kcal / 100 g';
  }

  @override
  String get foodPortion => 'Portion';

  @override
  String get foodKcal => 'kcal';

  @override
  String get foodFitsDay => 'Fits your day?';

  @override
  String foodKcalLeftAfter(String kcal) {
    return '$kcal kcal left after';
  }

  @override
  String foodKcalOver(String kcal) {
    return '$kcal kcal over';
  }

  @override
  String foodEaten(String kcal) {
    return 'Eaten $kcal';
  }

  @override
  String foodPlus(String name, String kcal) {
    return '+ $name $kcal';
  }

  @override
  String foodTarget(String kcal) {
    return 'Target $kcal';
  }

  @override
  String foodFatWould(String fat, String target) {
    return 'Fat would reach $fat of $target g.';
  }

  @override
  String foodProteinBehind(String g) {
    return 'Protein stays $g g behind.';
  }

  @override
  String get foodRichIn => 'Rich in';

  @override
  String get foodPctOfTarget => '% of your daily target';

  @override
  String get micrTitle => 'Micronutrients';

  @override
  String micrTargetsFor(String who, String age) {
    return 'Targets for $who, $age · NASEM';
  }

  @override
  String get micrMen => 'men';

  @override
  String get micrWomen => 'women';

  @override
  String get micrToday => 'Today';

  @override
  String get micr7Days => '7 days';

  @override
  String get micr30Days => '30 days';

  @override
  String get micrAthlete => 'Athlete essentials';

  @override
  String get micrVitamins => 'Vitamins';

  @override
  String get micrMinerals => 'Minerals';

  @override
  String micrAll(String n) {
    return 'All $n';
  }

  @override
  String get micrEmpty => 'Log food to see your micronutrients.';

  @override
  String micrAverage(String n) {
    return 'Average over $n logged days';
  }

  @override
  String get micrLow => 'Low';

  @override
  String get micrOk => 'OK';

  @override
  String get micrHigh => 'High';

  @override
  String get micrVitDTitle => 'Vitamin D is low all week';

  @override
  String get micrVitDBody =>
      'Fatty fish, eggs and fortified dairy help a little. Ask your doctor about a D3 supplement.';

  @override
  String get micrInSeason => 'In season now';

  @override
  String micrUzbekistanMonth(String month) {
    return 'Uzbekistan · $month';
  }

  @override
  String get microVitD => 'Vitamin D';

  @override
  String get microCalcium => 'Calcium';

  @override
  String get microMagnesium => 'Magnesium';

  @override
  String get microIron => 'Iron';

  @override
  String get microZinc => 'Zinc';

  @override
  String get microPotassium => 'Potassium';

  @override
  String get microSodium => 'Sodium';

  @override
  String get microB12 => 'Vitamin B12';

  @override
  String get microSelenium => 'Selenium';

  @override
  String get microVitE => 'Vitamin E';

  @override
  String get microVitC => 'Vitamin C';

  @override
  String get microVitA => 'Vitamin A';

  @override
  String get microHintVitD => 'Fatty fish, eggs, sunlight';

  @override
  String get microHintCalcium => 'Dairy, sesame, greens';

  @override
  String get microHintMagnesium => 'Nuts, buckwheat, legumes';

  @override
  String get microHintIron => 'Meat, liver, lentils';

  @override
  String get microHintZinc => 'Beef, lamb, pumpkin seeds';

  @override
  String get microHintPotassium => 'Potatoes, bananas, legumes';

  @override
  String get microHintSodium => 'Bread, salted cheese, broths';

  @override
  String get microHintB12 => 'Beef, eggs, dairy';

  @override
  String get microHintSelenium => 'Fish, eggs, meat';

  @override
  String get microHintVitE => 'Nuts, seeds, vegetable oil';

  @override
  String get microHintVitC => 'Peppers, citrus, pomegranate';

  @override
  String get microHintVitA => 'Carrots, pumpkin, spinach';

  @override
  String get targetsTitle => 'Your targets';

  @override
  String get targetsSubtitle =>
      'Based on your profile and the last 4 weeks of training';

  @override
  String get targetsGoal => 'Goal';

  @override
  String get targetsLoseFat => 'Lose fat';

  @override
  String get targetsMaintain => 'Maintain';

  @override
  String get targetsLeanBulk => 'Lean bulk';

  @override
  String get targetsBmr => 'Base metabolism';

  @override
  String targetsBmrFormula(String weight, String height, String age) {
    return 'Mifflin-St Jeor · $weight kg, $height cm, $age y';
  }

  @override
  String targetsActivity(String factor) {
    return '× $factor activity';
  }

  @override
  String targetsHours(String hours) {
    return '$hours h training a week in FITRIX';
  }

  @override
  String targetsHoursEstimated(String hours) {
    return 'Estimated $hours h a week: no workouts in the last 4 weeks';
  }

  @override
  String get targetsAdjLose => '−15% to lose fat';

  @override
  String get targetsAdjMaintain => 'Keep your weight';

  @override
  String get targetsAdjBulk => '+10% lean bulk';

  @override
  String get targetsDaily => 'Daily target';

  @override
  String targetsProteinG(String g) {
    return 'Protein · $g g';
  }

  @override
  String targetsFatG(String g) {
    return 'Fat · $g g';
  }

  @override
  String targetsCarbsG(String g) {
    return 'Carbs · $g g';
  }

  @override
  String targetsPerKg(String value) {
    return '$value g per kg body weight';
  }

  @override
  String targetsFatPerKg(String value, String pct) {
    return '$value g per kg, about $pct% of kcal';
  }

  @override
  String get targetsCarbsNote => 'The rest of the calories';

  @override
  String get targetsAuto => 'auto';

  @override
  String get targetsSave => 'Save targets';

  @override
  String get progressOverall => 'Overall';

  @override
  String get progressEmpty => 'Log a workout to see your load';

  @override
  String get progressLoadThisWeek => 'Load this week';

  @override
  String get progressLoadNote => 'session RPE × min';

  @override
  String get progressAu => 'AU';

  @override
  String progressPercentOfUsual(int percent) {
    return '$percent% of your usual';
  }

  @override
  String get progressFitness => 'Fitness';

  @override
  String get progressFatigue => 'Fatigue';

  @override
  String get progressForm => 'Form';

  @override
  String get progress42Day => '42-day load';

  @override
  String get progress7Day => '7-day load';

  @override
  String get progressEstimated =>
      'Estimated: some sessions use a default effort of 6';

  @override
  String get progressFormFresh => 'Fresh';

  @override
  String get progressFormNeutral => 'Neutral';

  @override
  String get progressFormTired => 'Tired';

  @override
  String get progressRecords => 'Records';

  @override
  String get progressRecordsThisWeek => 'this week';

  @override
  String get progressBalance => 'Load balance';

  @override
  String get progressBandLow => 'Low';

  @override
  String get progressBandSweet => 'Sweet spot';

  @override
  String get progressBandRisky => 'Risky';

  @override
  String get progressBalanceLow => 'Too little';

  @override
  String get progressBalanceSweet => 'Sweet spot 0.8–1.3';

  @override
  String get progressBalanceRisky => 'Risky';

  @override
  String get progressFelixInsight => 'Felix insight';

  @override
  String get progressInsightLow =>
      'Your recent load is below your usual. Add one session this week to get back above 0.8.';

  @override
  String get progressInsightSweet =>
      'Your load is in the sweet spot. Keep the rhythm and add weight where sets feel easy.';

  @override
  String get progressInsightRisky =>
      'Your load jumped above what you are used to. Keep the next sessions easier and sleep well.';

  @override
  String get progressLiftsE1rm => 'Lifts · e1RM';

  @override
  String get progressBodyWeight => 'Body weight';

  @override
  String get loadTitle => 'Training load';

  @override
  String loadSubtitle(String sport) {
    return '$sport · session RPE × minutes';
  }

  @override
  String get loadAllSports => 'All sports';

  @override
  String loadWeeks(int count) {
    return '$count weeks';
  }

  @override
  String get loadFitnessExplain =>
      'Your 42-day average load. Goes up slowly when you train consistently.';

  @override
  String get loadFatigueExplain =>
      'Your 7-day load. Jumps after hard weeks and drops fast with rest.';

  @override
  String get loadFormExplain =>
      'Fitness minus fatigue. Positive means fresh: race, test or PR.';

  @override
  String get loadByWeek => 'By week';

  @override
  String loadAvg(String value) {
    return 'AU · avg $value';
  }

  @override
  String get loadThisWeek => 'This';

  @override
  String get loadNextWeek => 'Next week';

  @override
  String loadAim(String value) {
    return 'Aim for about $value AU, close to your recent weekly average.';
  }

  @override
  String get loadChartEmpty => 'Not enough load yet';

  @override
  String get recordsTitle => 'Records';

  @override
  String recordsSummary(int count, int sports) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personal records',
      one: '$count personal record',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sports,
      locale: localeName,
      other: '$sports sports',
      one: '$sports sport',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get recordsAll => 'All';

  @override
  String get recordsThisMonth => 'This month';

  @override
  String get recordsBestStreak => 'Best streak';

  @override
  String recordsWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '$count week',
    );
    return '$_temp0';
  }

  @override
  String recordsMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '$count record',
    );
    return '$_temp0';
  }

  @override
  String get recordsPr => 'PR';

  @override
  String recordsE1rm(String exercise, String value) {
    return '$exercise · e1RM $value';
  }

  @override
  String recordsRepsLine(int count, String exercise) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '$count rep',
    );
    return '$exercise · $_temp0';
  }

  @override
  String recordsGainWhen(String gain, String when) {
    return '$gain · $when';
  }

  @override
  String recordsGainReps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count reps',
      one: '+$count rep',
    );
    return '$_temp0';
  }

  @override
  String get recordsToday => 'today';

  @override
  String get recordsYesterday => 'yesterday';

  @override
  String recordsDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String get recordsEmpty =>
      'No records yet. Beat a previous best in a workout and it shows up here.';

  @override
  String get liftTitle => 'Lifts';

  @override
  String get liftEstimated => 'Estimated 1RM · Epley';

  @override
  String liftSince(String date, String kg, String reps, String since) {
    return 'since $since · best set $kg × $reps on $date';
  }

  @override
  String liftBestSet(String date, String kg, String reps) {
    return 'best set $kg × $reps on $date';
  }

  @override
  String get liftChartE1rm => 'e1RM';

  @override
  String get liftChartTop => 'Top set load';

  @override
  String get liftStrengthLevel => 'Strength level';

  @override
  String get liftLevelBeginner => 'Beginner';

  @override
  String get liftLevelNovice => 'Novice';

  @override
  String get liftLevelIntermediate => 'Intermediate';

  @override
  String get liftLevelAdvanced => 'Advanced';

  @override
  String get liftLevelElite => 'Elite';

  @override
  String liftRatio(String ratio) {
    return '$ratio × body weight';
  }

  @override
  String liftNextBand(String kg, String level, String ratio) {
    return '$level at $ratio × · $kg';
  }

  @override
  String get liftTopBand => 'Top level reached';

  @override
  String get liftNeedWeight =>
      'Log your body weight to see your strength level.';

  @override
  String get liftNextSession => 'Next session';

  @override
  String get liftReserve => '2 reps in reserve';

  @override
  String get liftColSet => 'Set';

  @override
  String get liftCol1rm => '%1RM';

  @override
  String get liftColLoad => 'Load';

  @override
  String get liftColReps => 'Reps';

  @override
  String get liftTopSet => 'Top set';

  @override
  String get liftBackOff => 'Back-off';

  @override
  String get liftVolume => 'Volume';

  @override
  String get liftFelix => 'Felix';

  @override
  String liftPaceUp(String kg) {
    return 'Steady $kg a week.';
  }

  @override
  String liftPaceTo(String date, String kg, String ratio) {
    return 'Steady $kg a week. At this pace you reach $ratio × body weight around $date.';
  }

  @override
  String get liftPaceFlat =>
      'Your e1RM has been flat lately. A lighter week, then push again.';

  @override
  String get liftNone =>
      'Finish a workout with a weighted exercise to see your lifts here.';

  @override
  String bodyPerWeek(String value) {
    return '$value / wk';
  }

  @override
  String bodyTrendLine(String goal, int weeks) {
    return '$weeks-week trend · goal: $goal';
  }

  @override
  String bodyTrendNone(String goal) {
    return 'Not enough weigh-ins for a trend yet · goal: $goal';
  }

  @override
  String bodyGoalLoseFat(String unit) {
    return 'lose fat −0.3 to −0.7 $unit / wk';
  }

  @override
  String bodyGoalMaintain(String unit) {
    return 'maintain ±0.2 $unit / wk';
  }

  @override
  String bodyGoalLeanBulk(String unit) {
    return 'lean bulk +0.2 to +0.4 $unit / wk';
  }

  @override
  String get bodyGoalNameLoseFat => 'fat loss';

  @override
  String get bodyGoalNameMaintain => 'maintenance';

  @override
  String get bodyGoalNameLeanBulk => 'lean bulk';

  @override
  String bodyOffTrack(String goal) {
    return 'Off track for $goal';
  }

  @override
  String bodyAdd(int kcal) {
    return 'Your trend is below your goal. Add about $kcal kcal a day, mostly carbs around workouts.';
  }

  @override
  String bodyCut(int kcal) {
    return 'Your trend is above your goal. Cut about $kcal kcal a day, mostly from fats and sweet drinks.';
  }

  @override
  String get bodyUpdateTargets => 'Update my targets';

  @override
  String get bodyRange8 => '8 weeks';

  @override
  String get bodyRange26 => '6 months';

  @override
  String get bodyRange52 => 'Year';

  @override
  String get bodyLegendTrend => 'Trend';

  @override
  String get bodyLegendWeighIns => 'Weigh-ins';

  @override
  String get bodyLegendGoal => 'Goal range';

  @override
  String get bodyToday => 'Today';

  @override
  String get bodyWeighIns => 'Weigh-ins';

  @override
  String get bodyWeighInsNote => 'morning, after the toilet';

  @override
  String get bodyLog => 'Log today\'s weight';

  @override
  String get bodySheetTitle => 'Today\'s weight';

  @override
  String get bodySave => 'Save';

  @override
  String get bodyWeightRange => 'Enter a weight between 20 and 400 kg.';

  @override
  String get bodyEmpty => 'Log your weight to see your trend.';

  @override
  String get programsTitle => 'Programs';

  @override
  String get programsEntrySub => 'Ready-made plans for the next weeks';

  @override
  String get programsActiveEyebrow => 'Active program';

  @override
  String programsWeekOf(int w, int n) {
    return 'Week $w of $n';
  }

  @override
  String programsNext(String session, String day, String duration) {
    return 'Next: $session · $day · $duration';
  }

  @override
  String get programsNoneLeft => 'No sessions left in this program';

  @override
  String programsDoneOf(int done, int total) {
    return '$done of $total sessions done';
  }

  @override
  String get programsOpen => 'Open';

  @override
  String get programsPickedEyebrow => 'Picked for you';

  @override
  String programsPickedText(String name, int perWeek, String level) {
    return '$name · $perWeek days a week · $level. A good fit for your goal and experience.';
  }

  @override
  String get programsFelixPick => 'Felix pick';

  @override
  String get programsFilterAll => 'All';

  @override
  String get programsGoalMuscle => 'Muscle';

  @override
  String get programsGoalStrength => 'Strength';

  @override
  String get programsGoalFatLoss => 'Fat loss';

  @override
  String get programsLevelBeginner => 'Beginner';

  @override
  String get programsLevelIntermediate => 'Intermediate';

  @override
  String get programsLevelAdvanced => 'Advanced';

  @override
  String get programsAtHome => 'At home';

  @override
  String get programsDaysAWeek => 'Days a week';

  @override
  String get programsAny => 'Any';

  @override
  String programsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n programs',
      one: '$n program',
    );
    return '$_temp0';
  }

  @override
  String programsPerWeek(int n) {
    return '$n× / week';
  }

  @override
  String programsWeeksMin(int weeks, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '$weeks week',
    );
    return '$_temp0 · $min min';
  }

  @override
  String get programsDetails => 'Details';

  @override
  String get programsEmptyFilter => 'No program matches these filters.';

  @override
  String get programTitle => 'Program';

  @override
  String get programNotFound => 'This program is not available.';

  @override
  String get programLength => 'Length';

  @override
  String get programPerWeekLabel => 'Per week';

  @override
  String get programSessionLabel => 'Session';

  @override
  String programWeeksShort(int n) {
    return '$n wk';
  }

  @override
  String get programYourWeek => 'Your week';

  @override
  String programClashes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n clashes',
      one: '$n clash',
    );
    return '$_temp0';
  }

  @override
  String get programRest => 'Rest';

  @override
  String programWorkoutsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n workouts',
      one: '$n workout',
    );
    return '$_temp0';
  }

  @override
  String programRir(int n) {
    return 'RIR $n';
  }

  @override
  String get programHowYouProgress => 'How you progress';

  @override
  String get programFelixEyebrow => 'Felix adjusted it for you';

  @override
  String programFelixText(String days, String what) {
    return 'Training days avoid $days and the days right before and after it because of $what. You can change the days when you start.';
  }

  @override
  String get programAskFelix => 'Ask Felix';

  @override
  String programAskFelixDraft(String name) {
    return 'Is $name a good program for me? Check it against my week.';
  }

  @override
  String get programStart => 'Start program';

  @override
  String programStartTitle(String name) {
    return 'Start $name';
  }

  @override
  String programStartSub(int weeks, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks weeks',
      one: '$weeks week',
    );
    return '$_temp0 · ends $date';
  }

  @override
  String get programStartDate => 'Start';

  @override
  String get programToday => 'Today';

  @override
  String get programPickDate => 'Pick date';

  @override
  String get programTrainingDays => 'Training days';

  @override
  String programDaysPicked(int n, int total) {
    return '$n of $total picked';
  }

  @override
  String programClashTitle(String day, String title) {
    return '$day is $title';
  }

  @override
  String get programClashHit =>
      'Training that day stacks two hard sessions. Pick another day.';

  @override
  String get programClashNear =>
      'A program day is right next to it. Keep your legs fresh before and after.';

  @override
  String get programClashAvoid =>
      'Program days stay clear of it, so you recover before and after.';

  @override
  String get programStartWeights => 'Start weights';

  @override
  String get programFromRecords => 'from your records';

  @override
  String get programReplacePlan => 'Replace my weekly plan';

  @override
  String get programReplaceSub => 'Runs and football stay, gym days switch';

  @override
  String programStartOn(String date) {
    return 'Start on $date';
  }

  @override
  String get programReplacesActive => 'This replaces your active program.';

  @override
  String programProgressSub(int w, int n, String date) {
    return 'Week $w of $n · started $date';
  }

  @override
  String programDeloadNote(int w) {
    return 'Week $w is a deload: do about half your usual sets.';
  }

  @override
  String get programTileSessions => 'Sessions';

  @override
  String get programTileOnTime => 'On time';

  @override
  String get programTileRecords => 'Records';

  @override
  String get programThisWeek => 'This week';

  @override
  String programWeekDone(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get programNoSessionsWeek => 'No program sessions this week.';

  @override
  String get programPlanned => 'planned';

  @override
  String get programMainLifts => 'Main lifts';

  @override
  String get programTopSetKg => 'top set, kg';

  @override
  String get programColLift => 'Lift';

  @override
  String get programColStart => 'Start';

  @override
  String get programColNow => 'Now';

  @override
  String get programColGoal => 'Goal';

  @override
  String get programNextIncrease => 'Next increase';

  @override
  String programNextIncreaseText(int sets, int reps, String lift, String kg) {
    return 'You hit $sets × $reps on $lift twice in a row. Next session: $kg kg.';
  }

  @override
  String get programNoActive => 'No active program';

  @override
  String get programNoActiveBody =>
      'Pick a program to get a plan for the next weeks.';

  @override
  String get programBrowse => 'Browse programs';

  @override
  String get programEnd => 'End program';

  @override
  String get programEndTitle => 'End this program?';

  @override
  String get programEndBody =>
      'Your workouts and records stay. Its remaining sessions leave your plan.';

  @override
  String programKgReps(String kg, int reps) {
    return '$kg kg × $reps';
  }

  @override
  String get coachAskFelix => 'Ask Felix';

  @override
  String gymAskFirstDraft(String sport) {
    return 'I\'m about to do my first $sport workout. What should I focus on?';
  }

  @override
  String gymAskBackDraft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return 'My last workout was $_temp0 ago. How should I get back into training?';
  }

  @override
  String recoveryAskDraft(
      int score, String label, String sleep, String soreness) {
    return 'My readiness today is $score% ($label). Sleep $sleep, soreness: $soreness. How hard should I train today?';
  }

  @override
  String planAskDraft(String a, String aDay, String b, String bDay) {
    return '$a on $aDay and $b on $bDay are both hard. How should I arrange my week?';
  }

  @override
  String progressAskDraft(String week, String balance, String band) {
    return 'My training load this week is $week and my load balance is $balance ($band). What should I do next week?';
  }

  @override
  String liftAskDraft(String lift, String e1rm) {
    return 'My $lift e1RM is $e1rm. How do I keep it climbing?';
  }

  @override
  String bodyAskDraft(String weight, String trend, String goal) {
    return 'My weight is $weight, changing $trend a week. My goal: $goal. How should I change what I eat?';
  }

  @override
  String nutritionAskDraft(String kcal, String protein) {
    return 'I have $kcal kcal and $protein g of protein left today. What should I eat for dinner?';
  }

  @override
  String get nutritionCantFindDraft => 'Estimate the calories in: ';

  @override
  String get planEmptyBodyNextWeek =>
      'Set up your gym workouts for next week in one tap.';

  @override
  String programsPickedGoalText(String name, int perWeek, String level) {
    return '$name · $perWeek days a week · $level. Matches your goal.';
  }

  @override
  String programsPickedLevelText(String name, int perWeek, String level) {
    return '$name · $perWeek days a week · $level. Matches your experience.';
  }

  @override
  String get programsStartEyebrow => 'A place to start';

  @override
  String programsStartText(String name, int perWeek, String level) {
    return '$name · $perWeek days a week · $level. Add your goal and experience in About me for a closer match.';
  }

  @override
  String get programDetailsTooltip => 'Program details';

  @override
  String nutritionKcalOver(String kcal) {
    return '$kcal kcal over';
  }

  @override
  String get homeDoneForToday => 'Done for today';

  @override
  String homeNextSession(String day, String title) {
    return 'Next: $day · $title';
  }

  @override
  String get homeNothingNext => 'Nothing else planned yet';
}
