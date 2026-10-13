import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ru'),
    Locale('uz')
  ];

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @introStart.
  ///
  /// In en, this message translates to:
  /// **'Start your journey'**
  String get introStart;

  /// No description provided for @aboutMeTitle.
  ///
  /// In en, this message translates to:
  /// **'About me'**
  String get aboutMeTitle;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get unitCm;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// No description provided for @signOutLocalBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile, chats and workouts are stored only on this device and will be deleted.'**
  String get signOutLocalBody;

  /// No description provided for @signOutAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your profile, workouts and chats are saved to your account and will be removed from this device. Sign in with the same email to get them back.'**
  String get signOutAccountBody;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your FITRIX account and everything in it: your profile, workout plans, workout history and chats with Felix, on all your devices.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountAppleNote.
  ///
  /// In en, this message translates to:
  /// **'Apple will ask you to confirm.'**
  String get deleteAccountAppleNote;

  /// No description provided for @deleteForGoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete for good?'**
  String get deleteForGoodTitle;

  /// No description provided for @deleteForGoodBody.
  ///
  /// In en, this message translates to:
  /// **'Your account can\'t be recovered once it\'s deleted.'**
  String get deleteForGoodBody;

  /// No description provided for @deletingAccount.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account…'**
  String get deletingAccount;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. {reason}'**
  String deleteAccountFailed(String reason);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @workoutDeleted.
  ///
  /// In en, this message translates to:
  /// **'“{name}” deleted'**
  String workoutDeleted(String name);

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync. Check your connection and try again.'**
  String get syncFailed;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeTodayMeta.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}} · about {minutes} min'**
  String homeTodayMeta(int count, int minutes);

  /// No description provided for @homeStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeStart;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get homeContinue;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'My progress'**
  String get progressTitle;

  /// No description provided for @progressStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get progressStrength;

  /// No description provided for @progressNoWorkouts.
  ///
  /// In en, this message translates to:
  /// **'No {sport} workouts yet. Finish one with at least one set checked off and your progress will show up here.'**
  String progressNoWorkouts(String sport);

  /// No description provided for @progressRecentWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Recent workouts'**
  String get progressRecentWorkouts;

  /// No description provided for @progressBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get progressBody;

  /// No description provided for @progressSampleNote.
  ///
  /// In en, this message translates to:
  /// **'Sample data — tracking is coming soon.'**
  String get progressSampleNote;

  /// No description provided for @progressFirst.
  ///
  /// In en, this message translates to:
  /// **'First: {value}'**
  String progressFirst(String value);

  /// No description provided for @progressLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest: {value}'**
  String progressLatest(String value);

  /// No description provided for @progressCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current: {value}'**
  String progressCurrent(String value);

  /// No description provided for @progressMonthAgo.
  ///
  /// In en, this message translates to:
  /// **'One month ago: {value}'**
  String progressMonthAgo(String value);

  /// No description provided for @progressIntake.
  ///
  /// In en, this message translates to:
  /// **'Intake, avg'**
  String get progressIntake;

  /// No description provided for @progressBurn.
  ///
  /// In en, this message translates to:
  /// **'Burn, avg'**
  String get progressBurn;

  /// No description provided for @progressKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'kcal / day'**
  String get progressKcalPerDay;

  /// No description provided for @progressSets.
  ///
  /// In en, this message translates to:
  /// **'{count} sets'**
  String progressSets(String count);

  /// No description provided for @nutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'My Nutrition'**
  String get nutritionTitle;

  /// No description provided for @nutritionOfGoal.
  ///
  /// In en, this message translates to:
  /// **'of {goal} kcal'**
  String nutritionOfGoal(String goal);

  /// No description provided for @nutritionLeft.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal left today'**
  String nutritionLeft(String kcal);

  /// No description provided for @nutritionGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached for today'**
  String get nutritionGoalReached;

  /// No description provided for @nutritionProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionProtein;

  /// No description provided for @nutritionCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutritionCarbs;

  /// No description provided for @nutritionFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionFat;

  /// No description provided for @nutritionBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get nutritionBreakfast;

  /// No description provided for @nutritionBreakfastItems.
  ///
  /// In en, this message translates to:
  /// **'Oatmeal, banana, coffee'**
  String get nutritionBreakfastItems;

  /// No description provided for @nutritionLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get nutritionLunch;

  /// No description provided for @nutritionLunchItems.
  ///
  /// In en, this message translates to:
  /// **'Chicken, rice, salad'**
  String get nutritionLunchItems;

  /// No description provided for @nutritionSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get nutritionSnack;

  /// No description provided for @nutritionSnackItems.
  ///
  /// In en, this message translates to:
  /// **'Yogurt and nuts'**
  String get nutritionSnackItems;

  /// No description provided for @nutritionDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get nutritionDinner;

  /// No description provided for @nutritionNotLogged.
  ///
  /// In en, this message translates to:
  /// **'Not logged yet'**
  String get nutritionNotLogged;

  /// No description provided for @nutritionKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String nutritionKcal(String kcal);

  /// No description provided for @nutritionTipEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Felix tip'**
  String get nutritionTipEyebrow;

  /// No description provided for @nutritionTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Protein at dinner'**
  String get nutritionTipTitle;

  /// No description provided for @nutritionTipMessage.
  ///
  /// In en, this message translates to:
  /// **'For dinner, aim for about 40 g of protein. Chicken, rice and greens fit your plan.'**
  String get nutritionTipMessage;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileWorkouts.
  ///
  /// In en, this message translates to:
  /// **'workouts'**
  String get profileWorkouts;

  /// No description provided for @profileDayStreak.
  ///
  /// In en, this message translates to:
  /// **'day streak'**
  String get profileDayStreak;

  /// No description provided for @profileKgNow.
  ///
  /// In en, this message translates to:
  /// **'kg now'**
  String get profileKgNow;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get profileTheme;

  /// No description provided for @profileThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get profileThemeAuto;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @chatQuickPlanWeek.
  ///
  /// In en, this message translates to:
  /// **'Plan my week'**
  String get chatQuickPlanWeek;

  /// No description provided for @chatQuickEatToday.
  ///
  /// In en, this message translates to:
  /// **'What should I eat today?'**
  String get chatQuickEatToday;

  /// No description provided for @chatQuickTired.
  ///
  /// In en, this message translates to:
  /// **'I feel tired today'**
  String get chatQuickTired;

  /// No description provided for @gymToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get gymToday;

  /// No description provided for @gymStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get gymStart;

  /// No description provided for @gymDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get gymDone;

  /// No description provided for @gymAskFelix.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get gymAskFelix;

  /// No description provided for @gymCoachEyebrow.
  ///
  /// In en, this message translates to:
  /// **'AI {sport} COACH'**
  String gymCoachEyebrow(String sport);

  /// No description provided for @gymTileCaption.
  ///
  /// In en, this message translates to:
  /// **'{plans, plural, one{{plans} plan} other{{plans} plans}} · {week} this week'**
  String gymTileCaption(int plans, int week);

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get discoverNotifications;

  /// No description provided for @discoverNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No new notifications'**
  String get discoverNoNotifications;

  /// No description provided for @discoverForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get discoverForYou;

  /// No description provided for @discoverChallenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get discoverChallenges;

  /// No description provided for @discoverPrograms.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get discoverPrograms;

  /// No description provided for @discoverArticles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get discoverArticles;

  /// No description provided for @discoverThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get discoverThisWeek;

  /// No description provided for @discoverJoin.
  ///
  /// In en, this message translates to:
  /// **'Join challenge'**
  String get discoverJoin;

  /// No description provided for @discoverJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get discoverJoined;

  /// No description provided for @discoverSignInToJoin.
  ///
  /// In en, this message translates to:
  /// **'Sign in to join challenges'**
  String get discoverSignInToJoin;

  /// No description provided for @discoverSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get discoverSignIn;

  /// No description provided for @discoverJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t join. Try again.'**
  String get discoverJoinFailed;

  /// No description provided for @discoverProgramsForYou.
  ///
  /// In en, this message translates to:
  /// **'Programs for you'**
  String get discoverProgramsForYou;

  /// No description provided for @discoverAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoverAll;

  /// No description provided for @discoverProgramSoon.
  ///
  /// In en, this message translates to:
  /// **'{title}: preview coming soon'**
  String discoverProgramSoon(String title);

  /// No description provided for @discoverFelixEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Tip from Felix'**
  String get discoverFelixEyebrow;

  /// No description provided for @discoverFelixTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest keeps you strong'**
  String get discoverFelixTitle;

  /// No description provided for @discoverFelixMessage.
  ///
  /// In en, this message translates to:
  /// **'Two easy days a week lower injury risk and keep your lifts climbing.'**
  String get discoverFelixMessage;

  /// No description provided for @discoverAskFelix.
  ///
  /// In en, this message translates to:
  /// **'Ask Felix'**
  String get discoverAskFelix;

  /// No description provided for @discoverRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get discoverRead;

  /// No description provided for @discoverMinRead.
  ///
  /// In en, this message translates to:
  /// **'{n} min read'**
  String discoverMinRead(int n);

  /// No description provided for @discoverArticleMissing.
  ///
  /// In en, this message translates to:
  /// **'This article isn’t available.'**
  String get discoverArticleMissing;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @shopCartLabel.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Cart, empty} one{Cart, 1 item} other{Cart, {n} items}}'**
  String shopCartLabel(int n);

  /// No description provided for @shopSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search products'**
  String get shopSearchHint;

  /// No description provided for @shopAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shopAll;

  /// No description provided for @shopCatSupplements.
  ///
  /// In en, this message translates to:
  /// **'Supplements'**
  String get shopCatSupplements;

  /// No description provided for @shopCatEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get shopCatEquipment;

  /// No description provided for @shopCatApparel.
  ///
  /// In en, this message translates to:
  /// **'Apparel'**
  String get shopCatApparel;

  /// No description provided for @shopProBlurb.
  ///
  /// In en, this message translates to:
  /// **'Unlimited chats with Felix, custom plans and form checks.'**
  String get shopProBlurb;

  /// No description provided for @shopProButton.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get shopProButton;

  /// No description provided for @shopProSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'FITRIX Pro is coming soon'**
  String get shopProSoonTitle;

  /// No description provided for @shopProSoonBody.
  ///
  /// In en, this message translates to:
  /// **'We’ll let you know as soon as it’s ready.'**
  String get shopProSoonBody;

  /// No description provided for @shopGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get shopGotIt;

  /// No description provided for @shopNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for “{query}”.'**
  String shopNothingFound(String query);

  /// No description provided for @shopAdd.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String shopAdd(String name);

  /// No description provided for @shopCartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get shopCartTitle;

  /// No description provided for @shopClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get shopClose;

  /// No description provided for @shopRemoveOne.
  ///
  /// In en, this message translates to:
  /// **'Remove one'**
  String get shopRemoveOne;

  /// No description provided for @shopAddOne.
  ///
  /// In en, this message translates to:
  /// **'Add one'**
  String get shopAddOne;

  /// No description provided for @shopTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get shopTotal;

  /// No description provided for @shopPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Place order'**
  String get shopPlaceOrder;

  /// No description provided for @shopCartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty. Tap + on any product to add it.'**
  String get shopCartEmpty;

  /// No description provided for @shopOrderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get shopOrderPlaced;

  /// No description provided for @shopSignInToOrder.
  ///
  /// In en, this message translates to:
  /// **'Sign in to place an order'**
  String get shopSignInToOrder;

  /// No description provided for @shopOrderFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t place the order. Check your connection.'**
  String get shopOrderFailed;

  /// No description provided for @shopOrderRejected.
  ///
  /// In en, this message translates to:
  /// **'Order rejected: {message}'**
  String shopOrderRejected(String message);

  /// No description provided for @shopRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get shopRetry;

  /// No description provided for @shopNoProducts.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get shopNoProducts;

  /// No description provided for @workoutSetsProgress.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, one{{done} of {total} set} other{{done} of {total} sets}}'**
  String workoutSetsProgress(int done, int total);

  /// No description provided for @workoutSetCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} set} other{{n} sets}}'**
  String workoutSetCount(int n);

  /// No description provided for @workoutSetDone.
  ///
  /// In en, this message translates to:
  /// **'Set {n} done'**
  String workoutSetDone(int n);

  /// No description provided for @workoutFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish workout?'**
  String get workoutFinishTitle;

  /// No description provided for @workoutFinishNoSets.
  ///
  /// In en, this message translates to:
  /// **'No sets are checked off, so this workout won’t be saved.'**
  String get workoutFinishNoSets;

  /// No description provided for @workoutFinishSummary.
  ///
  /// In en, this message translates to:
  /// **'{total, plural, one{{done} of {total} set completed.} other{{done} of {total} sets completed.}} The workout will be saved to your history.'**
  String workoutFinishSummary(int done, int total);

  /// No description provided for @workoutKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get workoutKeepGoing;

  /// No description provided for @workoutFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get workoutFinish;

  /// No description provided for @workoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout saved to My progress'**
  String get workoutSaved;

  /// No description provided for @workoutNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet. Long-press the workout card to add some.'**
  String get workoutNoExercises;

  /// No description provided for @workoutAddSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get workoutAddSet;

  /// No description provided for @workoutFinishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get workoutFinishButton;

  /// No description provided for @workoutColSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get workoutColSet;

  /// No description provided for @workoutColPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get workoutColPrevious;

  /// No description provided for @workoutColKg.
  ///
  /// In en, this message translates to:
  /// **'Kg'**
  String get workoutColKg;

  /// No description provided for @workoutColReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get workoutColReps;

  /// No description provided for @gymCoachFirstTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for your first workout?'**
  String get gymCoachFirstTitle;

  /// No description provided for @gymCoachFirstMessage.
  ///
  /// In en, this message translates to:
  /// **'Start with {workout}. Felix will adjust the plan after it.'**
  String gymCoachFirstMessage(String workout);

  /// No description provided for @gymCoachBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get gymCoachBackTitle;

  /// No description provided for @gymCoachBackMessage.
  ///
  /// In en, this message translates to:
  /// **'Your last workout was {days, plural, one{{days} day} other{{days} days}} ago. A lighter session today gets you back on track.'**
  String gymCoachBackMessage(int days);

  /// No description provided for @gymFinishCurrentTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish current workout?'**
  String get gymFinishCurrentTitle;

  /// No description provided for @gymFinishCurrentBody.
  ///
  /// In en, this message translates to:
  /// **'“{current}” is still in progress. Start “{next}” instead?'**
  String gymFinishCurrentBody(String current, String next);

  /// No description provided for @gymMyWorkouts.
  ///
  /// In en, this message translates to:
  /// **'My workouts'**
  String get gymMyWorkouts;

  /// No description provided for @gymNewWorkout.
  ///
  /// In en, this message translates to:
  /// **'New workout'**
  String get gymNewWorkout;

  /// No description provided for @gymNewWorkoutHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Shoulders'**
  String get gymNewWorkoutHint;

  /// No description provided for @gymAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get gymAdd;

  /// No description provided for @gymEditNameHint.
  ///
  /// In en, this message translates to:
  /// **'Workout name'**
  String get gymEditNameHint;

  /// No description provided for @gymEditDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete workout'**
  String get gymEditDelete;

  /// No description provided for @gymEditAddExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get gymEditAddExerciseHint;

  /// No description provided for @gymEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get gymEditSave;

  /// No description provided for @sportGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get sportGym;

  /// No description provided for @sportFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get sportFitness;

  /// No description provided for @sportCycling.
  ///
  /// In en, this message translates to:
  /// **'Cycling'**
  String get sportCycling;

  /// No description provided for @sportRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get sportRunning;

  /// No description provided for @sportFootball.
  ///
  /// In en, this message translates to:
  /// **'Football'**
  String get sportFootball;

  /// No description provided for @sportWinterSports.
  ///
  /// In en, this message translates to:
  /// **'Winter sports'**
  String get sportWinterSports;

  /// No description provided for @sportWinterSportsTile.
  ///
  /// In en, this message translates to:
  /// **'WINTER\nSPORTS'**
  String get sportWinterSportsTile;

  /// No description provided for @tabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @tabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tabShop;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabFelix.
  ///
  /// In en, this message translates to:
  /// **'Felix'**
  String get tabFelix;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @homeTileProgress.
  ///
  /// In en, this message translates to:
  /// **'MY\nPROGRESS'**
  String get homeTileProgress;

  /// No description provided for @homeTileNutrition.
  ///
  /// In en, this message translates to:
  /// **'MY\nNUTRITION'**
  String get homeTileNutrition;

  /// No description provided for @homeTileWorkouts.
  ///
  /// In en, this message translates to:
  /// **'MY\nWORKOUTS'**
  String get homeTileWorkouts;

  /// No description provided for @homeTileShop.
  ///
  /// In en, this message translates to:
  /// **'SHOP'**
  String get homeTileShop;

  /// No description provided for @homeTileMap.
  ///
  /// In en, this message translates to:
  /// **'FITRIX\nMAP'**
  String get homeTileMap;

  /// No description provided for @homeMenuMap.
  ///
  /// In en, this message translates to:
  /// **'Fitrix map'**
  String get homeMenuMap;

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'Felix is typing'**
  String get chatTyping;

  /// No description provided for @chatError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String chatError(String error);

  /// No description provided for @chatStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get chatStart;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get chatMessageHint;

  /// No description provided for @chatAllChats.
  ///
  /// In en, this message translates to:
  /// **'All chats'**
  String get chatAllChats;

  /// No description provided for @chatTapToRetry.
  ///
  /// In en, this message translates to:
  /// **'Tap to retry'**
  String get chatTapToRetry;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @progressWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'My weight (kg)'**
  String get progressWeightTitle;

  /// No description provided for @progressCaloriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Calories: intake vs burn'**
  String get progressCaloriesTitle;

  /// No description provided for @signInCodeResent.
  ///
  /// In en, this message translates to:
  /// **'We sent a new code to {email}'**
  String signInCodeResent(String email);

  /// No description provided for @signInChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get signInChangeEmail;

  /// No description provided for @profileFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileFieldName;

  /// No description provided for @profileFieldSurname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get profileFieldSurname;

  /// No description provided for @profileFieldWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight, kg'**
  String get profileFieldWeightKg;

  /// No description provided for @profileFieldHeightCm.
  ///
  /// In en, this message translates to:
  /// **'Height, cm'**
  String get profileFieldHeightCm;

  /// No description provided for @signInAgainTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get signInAgainTitle;

  /// No description provided for @signInAgainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Enter your email to continue.'**
  String get signInAgainSubtitle;

  /// No description provided for @signInCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get signInCreateTitle;

  /// No description provided for @signInCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to sign up for this app'**
  String get signInCreateSubtitle;

  /// No description provided for @signInGetCode.
  ///
  /// In en, this message translates to:
  /// **'Get code'**
  String get signInGetCode;

  /// No description provided for @signInTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get signInTryAgain;

  /// No description provided for @signInOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get signInOr;

  /// No description provided for @signInTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By clicking continue, you agree to our '**
  String get signInTermsPrefix;

  /// No description provided for @signInTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get signInTerms;

  /// No description provided for @signInTermsAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get signInTermsAnd;

  /// No description provided for @signInPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get signInPrivacy;

  /// No description provided for @signInTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get signInTermsSuffix;

  /// No description provided for @signInContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Continue with {provider}'**
  String signInContinueWith(String provider);

  /// No description provided for @signInCheckEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get signInCheckEmailTitle;

  /// No description provided for @signInCodePrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the {length}-digit code we sent to\n{email}'**
  String signInCodePrompt(String length, String email);

  /// No description provided for @signInResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get signInResend;

  /// No description provided for @signInResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {time}'**
  String signInResendIn(String time);

  /// No description provided for @signInSpamNote.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find it? Check your spam folder.'**
  String get signInSpamNote;

  /// No description provided for @signInComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider} is coming soon. Please use your email for now.'**
  String signInComingSoon(String provider);

  /// No description provided for @signInProfileLoadOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in, but your profile couldn\'t be loaded. Check your connection and try again.'**
  String get signInProfileLoadOffline;

  /// No description provided for @signInProfileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'You\'re signed in, but your profile couldn\'t be loaded. Please try again.'**
  String get signInProfileLoadFailed;

  /// No description provided for @signInErrInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired. Check the latest email or send a new code.'**
  String get signInErrInvalidCode;

  /// No description provided for @signInErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a minute and try again.'**
  String get signInErrRateLimited;

  /// No description provided for @signInErrNetwork.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet and try again.'**
  String get signInErrNetwork;

  /// No description provided for @signInErrInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get signInErrInvalidEmail;

  /// No description provided for @signInErrUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get signInErrUnknown;

  /// No description provided for @signInErrProviderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider} isn\'t set up on the server yet. Please use your email for now.'**
  String signInErrProviderDisabled(String provider);

  /// No description provided for @signInErrProviderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sign in with {provider} isn\'t available on this device. Please use your email instead.'**
  String signInErrProviderUnavailable(String provider);

  /// No description provided for @signInErrSocialFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in with {provider}. Please try again or use your email.'**
  String signInErrSocialFailed(String provider);

  /// No description provided for @profileErrNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get profileErrNameRequired;

  /// No description provided for @profileErrNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name is too long'**
  String get profileErrNameTooLong;

  /// No description provided for @profileErrSurnameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Surname is too long'**
  String get profileErrSurnameTooLong;

  /// No description provided for @profileErrAgeRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your age'**
  String get profileErrAgeRequired;

  /// No description provided for @profileErrAgeWhole.
  ///
  /// In en, this message translates to:
  /// **'Age must be a whole number'**
  String get profileErrAgeWhole;

  /// No description provided for @profileErrAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Age must be between {min} and {max}'**
  String profileErrAgeRange(String min, String max);

  /// No description provided for @profileErrWeightRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your weight'**
  String get profileErrWeightRequired;

  /// No description provided for @profileErrWeightNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your weight as a number'**
  String get profileErrWeightNumber;

  /// No description provided for @profileErrWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Weight must be between {min} and {max} kg'**
  String profileErrWeightRange(String min, String max);

  /// No description provided for @profileErrHeightRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your height'**
  String get profileErrHeightRequired;

  /// No description provided for @profileErrHeightNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter your height as a number'**
  String get profileErrHeightNumber;

  /// No description provided for @profileErrHeightRange.
  ///
  /// In en, this message translates to:
  /// **'Height must be between {min} and {max} cm'**
  String profileErrHeightRange(String min, String max);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
