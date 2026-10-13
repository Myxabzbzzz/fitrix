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

<<<<<<< HEAD
<<<<<<< HEAD
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
=======
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
>>>>>>> t10
=======
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
>>>>>>> t9
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
