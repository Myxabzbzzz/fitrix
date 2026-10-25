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
  /// **'Everything you logged is stored only on this device and will be deleted: profile, workouts, chats, check-ins, plans, food and body weight.'**
  String get signOutLocalBody;

  /// No description provided for @signOutAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Everything you logged is saved to your account and will be removed from this device. Sign in with the same email to get it back.'**
  String get signOutAccountBody;

  /// No description provided for @signOutPendingBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} change hasn\'t reached your account yet (no connection?). Signing out now deletes it.} other{{count} changes haven\'t reached your account yet (no connection?). Signing out now deletes them.}}'**
  String signOutPendingBody(int count);

  /// No description provided for @signOutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Sign out anyway'**
  String get signOutAnyway;

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
  /// **'This permanently deletes your FITRIX account and everything in it: your profile, workout plans, workout history, chats with Felix, check-ins, food and body weight, on all your devices.'**
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

  /// No description provided for @nutritionLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get nutritionLunch;

  /// No description provided for @nutritionSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get nutritionSnack;

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
  /// **'It isn’t available yet. It will appear here in a later update.'**
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

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Fitrix map'**
  String get mapTitle;

  /// No description provided for @mapFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mapFilterAll;

  /// No description provided for @mapFilterGyms.
  ///
  /// In en, this message translates to:
  /// **'Gyms'**
  String get mapFilterGyms;

  /// No description provided for @mapFilterParks.
  ///
  /// In en, this message translates to:
  /// **'Parks'**
  String get mapFilterParks;

  /// No description provided for @mapFilterTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get mapFilterTracks;

  /// No description provided for @mapFilterPools.
  ///
  /// In en, this message translates to:
  /// **'Pools'**
  String get mapFilterPools;

  /// No description provided for @mapLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location off: showing central Tashkent'**
  String get mapLocationOff;

  /// No description provided for @mapHoursUnknown.
  ///
  /// In en, this message translates to:
  /// **'Hours not listed'**
  String get mapHoursUnknown;

  /// No description provided for @mapAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String mapAway(String distance);

  /// No description provided for @mapShowRoute.
  ///
  /// In en, this message translates to:
  /// **'Show route'**
  String get mapShowRoute;

  /// No description provided for @mapHideRoute.
  ///
  /// In en, this message translates to:
  /// **'Hide route'**
  String get mapHideRoute;

  /// No description provided for @mapModesLabel.
  ///
  /// In en, this message translates to:
  /// **'How to get there'**
  String get mapModesLabel;

  /// No description provided for @mapModeWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get mapModeWalk;

  /// No description provided for @mapModeBike.
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get mapModeBike;

  /// No description provided for @mapModeCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get mapModeCar;

  /// No description provided for @mapModeMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get mapModeMetro;

  /// No description provided for @mapComputing.
  ///
  /// In en, this message translates to:
  /// **'Working out routes…'**
  String get mapComputing;

  /// No description provided for @mapCoverage.
  ///
  /// In en, this message translates to:
  /// **'Routes cover central Tashkent'**
  String get mapCoverage;

  /// No description provided for @mapNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route for this mode'**
  String get mapNoRoute;

  /// No description provided for @mapMetroNoHelp.
  ///
  /// In en, this message translates to:
  /// **'Metro does not help on this trip: no station pair that saves time.'**
  String get mapMetroNoHelp;

  /// No description provided for @mapPlanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not work out routes. Try another place.'**
  String get mapPlanFailed;

  /// No description provided for @mapMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String mapMinutes(int n);

  /// No description provided for @mapHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String mapHoursMinutes(int h, int m);

  /// No description provided for @mapArrive.
  ///
  /// In en, this message translates to:
  /// **'{duration} · arrive {time}'**
  String mapArrive(String duration, String time);

  /// No description provided for @mapRide.
  ///
  /// In en, this message translates to:
  /// **'{from} → {to}, {count, plural, one{{count} stop} other{{count} stops}}'**
  String mapRide(String from, String to, int count);

  /// No description provided for @mapWalkTotal.
  ///
  /// In en, this message translates to:
  /// **'{distance} on foot in total'**
  String mapWalkTotal(String distance);

  /// No description provided for @mapWalkingFaster.
  ///
  /// In en, this message translates to:
  /// **'walking is faster here'**
  String get mapWalkingFaster;

  /// No description provided for @mapNoteWalk.
  ///
  /// In en, this message translates to:
  /// **'{distance} on foot'**
  String mapNoteWalk(String distance);

  /// No description provided for @mapNoteBike.
  ///
  /// In en, this message translates to:
  /// **'{distance} by bike, paths included'**
  String mapNoteBike(String distance);

  /// No description provided for @mapNoteCar.
  ///
  /// In en, this message translates to:
  /// **'{distance} by car, no traffic data, 2 min to park'**
  String mapNoteCar(String distance);

  /// No description provided for @mapMeters.
  ///
  /// In en, this message translates to:
  /// **'{n} m'**
  String mapMeters(int n);

  /// No description provided for @mapKilometers.
  ///
  /// In en, this message translates to:
  /// **'{n} km'**
  String mapKilometers(String n);

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
  /// **'Start with {workout}. Next time Felix suggests weights from what you log.'**
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
  /// **'Discard current workout?'**
  String get gymFinishCurrentTitle;

  /// No description provided for @gymFinishCurrentBody.
  ///
  /// In en, this message translates to:
  /// **'“{current}” is still in progress and won\'t be saved. Start “{next}” instead?'**
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

  /// No description provided for @signInUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Accounts are unavailable right now. Try again later.'**
  String get signInUnavailable;

  /// No description provided for @programLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get programLevelBeginner;

  /// No description provided for @programLevelMedium.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get programLevelMedium;

  /// No description provided for @programLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get programLevelAdvanced;

  /// No description provided for @shopOrderUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Some items are no longer available. Update your cart and try again.'**
  String get shopOrderUnavailable;

  /// No description provided for @workoutKeyboardDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get workoutKeyboardDone;

  /// No description provided for @workoutEditLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit workout'**
  String get workoutEditLabel;

  /// No description provided for @aboutMeSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get aboutMeSave;

  /// No description provided for @aboutMeSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get aboutMeSaved;

  /// No description provided for @aboutMeDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get aboutMeDiscardTitle;

  /// No description provided for @aboutMeDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits to this profile won\'t be saved.'**
  String get aboutMeDiscardBody;

  /// No description provided for @aboutMeDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get aboutMeDiscard;

  /// No description provided for @aboutMeKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get aboutMeKeepEditing;

  /// No description provided for @aboutMeEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get aboutMeEmail;

  /// No description provided for @aboutMeGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get aboutMeGoal;

  /// No description provided for @aboutMeGoalOther.
  ///
  /// In en, this message translates to:
  /// **'Other…'**
  String get aboutMeGoalOther;

  /// No description provided for @aboutMeGoalOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your goal'**
  String get aboutMeGoalOtherHint;

  /// No description provided for @aboutMeLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get aboutMeLevel;

  /// No description provided for @aboutMeSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get aboutMeSports;

  /// No description provided for @aboutMeSportsLimit.
  ///
  /// In en, this message translates to:
  /// **'You can pick up to 6 sports.'**
  String get aboutMeSportsLimit;

  /// No description provided for @aboutGoalBuild.
  ///
  /// In en, this message translates to:
  /// **'Build muscle and strength'**
  String get aboutGoalBuild;

  /// No description provided for @aboutGoalEndurance.
  ///
  /// In en, this message translates to:
  /// **'Improve endurance and stamina'**
  String get aboutGoalEndurance;

  /// No description provided for @aboutGoalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose weight and get toned'**
  String get aboutGoalLose;

  /// No description provided for @aboutGoalHealthy.
  ///
  /// In en, this message translates to:
  /// **'Feel healthier and balanced'**
  String get aboutGoalHealthy;

  /// No description provided for @aboutGoalTrack.
  ///
  /// In en, this message translates to:
  /// **'Just track my progress'**
  String get aboutGoalTrack;

  /// No description provided for @chatAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get chatAddPhoto;

  /// No description provided for @chatTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get chatTakePhoto;

  /// No description provided for @chatChooseFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get chatChooseFromLibrary;

  /// No description provided for @chatRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get chatRemovePhoto;

  /// No description provided for @chatPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'That photo is too large. Try another one.'**
  String get chatPhotoTooLarge;

  /// No description provided for @chatPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the photo. Check camera and photo permissions in Settings.'**
  String get chatPhotoFailed;

  /// No description provided for @chatPhotoPrompt.
  ///
  /// In en, this message translates to:
  /// **'What do you think of this photo?'**
  String get chatPhotoPrompt;

  /// No description provided for @chatMicStart.
  ///
  /// In en, this message translates to:
  /// **'Dictate a message'**
  String get chatMicStart;

  /// No description provided for @chatMicStop.
  ///
  /// In en, this message translates to:
  /// **'Stop dictation'**
  String get chatMicStop;

  /// No description provided for @chatMicDenied.
  ///
  /// In en, this message translates to:
  /// **'Felix can\'t hear you yet. Open Settings and allow microphone and speech recognition for FITRIX.'**
  String get chatMicDenied;

  /// No description provided for @chatPhotoViewer.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get chatPhotoViewer;

  /// No description provided for @chatPhotoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The photo is missing or too large to send.'**
  String get chatPhotoUnavailable;

  /// No description provided for @chatMicListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get chatMicListening;

  /// No description provided for @chatMicStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped listening'**
  String get chatMicStopped;

  /// No description provided for @chatActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get chatActionConfirm;

  /// No description provided for @chatActionApplied.
  ///
  /// In en, this message translates to:
  /// **'Added ✓'**
  String get chatActionApplied;

  /// No description provided for @chatActionWeightChange.
  ///
  /// In en, this message translates to:
  /// **'Update weight: {from} → {to} kg'**
  String chatActionWeightChange(String from, String to);

  /// No description provided for @chatActionWorkoutExercises.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} exercise} other{{count} exercises}}'**
  String chatActionWorkoutExercises(int count);

  /// No description provided for @chatActionMealTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to today’s nutrition'**
  String get chatActionMealTitle;

  /// No description provided for @chatActionMealTotal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal in total'**
  String chatActionMealTotal(String kcal);

  /// No description provided for @chatActionOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get chatActionOpen;

  /// No description provided for @chatActionWeightDone.
  ///
  /// In en, this message translates to:
  /// **'Weight updated: {from} → {to} kg'**
  String chatActionWeightDone(String from, String to);

  /// No description provided for @chatActionWeightDoneSet.
  ///
  /// In en, this message translates to:
  /// **'Weight updated to {to} kg'**
  String chatActionWeightDoneSet(String to);

  /// No description provided for @chatActionNoProfile.
  ///
  /// In en, this message translates to:
  /// **'Fill in your profile first, then I can update your weight.'**
  String get chatActionNoProfile;

  /// No description provided for @chatActionError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t apply this. Please try again.'**
  String get chatActionError;

  /// No description provided for @chatActionUndoError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t undo this. Please try again.'**
  String get chatActionUndoError;

  /// No description provided for @chatActionWeightChangedSince.
  ///
  /// In en, this message translates to:
  /// **'Weight changed since — nothing undone'**
  String get chatActionWeightChangedSince;

  /// No description provided for @unitTonnes.
  ///
  /// In en, this message translates to:
  /// **'t'**
  String get unitTonnes;

  /// No description provided for @workoutLiveCaption.
  ///
  /// In en, this message translates to:
  /// **'Set {x} of {y} · {t} lifted'**
  String workoutLiveCaption(int x, int y, String t);

  /// No description provided for @workoutColRpe.
  ///
  /// In en, this message translates to:
  /// **'RPE'**
  String get workoutColRpe;

  /// No description provided for @workoutRestShort.
  ///
  /// In en, this message translates to:
  /// **'rest {time}'**
  String workoutRestShort(String time);

  /// No description provided for @workoutBestShort.
  ///
  /// In en, this message translates to:
  /// **'best {value}'**
  String workoutBestShort(String value);

  /// No description provided for @workoutPr.
  ///
  /// In en, this message translates to:
  /// **'PR'**
  String get workoutPr;

  /// No description provided for @workoutE1rm.
  ///
  /// In en, this message translates to:
  /// **'e1RM'**
  String get workoutE1rm;

  /// No description provided for @workoutBodyweight.
  ///
  /// In en, this message translates to:
  /// **'BW'**
  String get workoutBodyweight;

  /// No description provided for @workoutFelixLine.
  ///
  /// In en, this message translates to:
  /// **'Last time {last}. Try {next} kg today.'**
  String workoutFelixLine(String last, String next);

  /// No description provided for @workoutRestLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get workoutRestLabel;

  /// No description provided for @workoutRestNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {label}'**
  String workoutRestNext(String label);

  /// No description provided for @workoutNextSet.
  ///
  /// In en, this message translates to:
  /// **'Set {n} · {kg} × {reps}'**
  String workoutNextSet(int n, String kg, int reps);

  /// No description provided for @workoutRestAdd.
  ///
  /// In en, this message translates to:
  /// **'+{n}s'**
  String workoutRestAdd(int n);

  /// No description provided for @workoutRestSub.
  ///
  /// In en, this message translates to:
  /// **'−{n}s'**
  String workoutRestSub(int n);

  /// No description provided for @workoutRestSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get workoutRestSkip;

  /// No description provided for @workoutMenuSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap exercise'**
  String get workoutMenuSwap;

  /// No description provided for @workoutMenuSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar: {names}'**
  String workoutMenuSimilar(String names);

  /// No description provided for @workoutMenuWarmup.
  ///
  /// In en, this message translates to:
  /// **'Add warm-up sets'**
  String get workoutMenuWarmup;

  /// No description provided for @workoutMenuWarmupSub.
  ///
  /// In en, this message translates to:
  /// **'2 sets: {plan}'**
  String workoutMenuWarmupSub(String plan);

  /// No description provided for @workoutMenuRest.
  ///
  /// In en, this message translates to:
  /// **'Rest timer'**
  String get workoutMenuRest;

  /// No description provided for @workoutMenuRestSub.
  ///
  /// In en, this message translates to:
  /// **'For this exercise'**
  String get workoutMenuRestSub;

  /// No description provided for @workoutMenuNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get workoutMenuNote;

  /// No description provided for @workoutMenuNoteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get workoutMenuNoteEmpty;

  /// No description provided for @workoutMenuNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Straps on the last set'**
  String get workoutMenuNoteHint;

  /// No description provided for @workoutNoteSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get workoutNoteSave;

  /// No description provided for @workoutMenuReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get workoutMenuReorder;

  /// No description provided for @workoutMenuReorderSub.
  ///
  /// In en, this message translates to:
  /// **'Move up or down in the workout'**
  String get workoutMenuReorderSub;

  /// No description provided for @workoutMenuRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get workoutMenuRemove;

  /// No description provided for @workoutRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this exercise?'**
  String get workoutRemoveTitle;

  /// No description provided for @workoutRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'Its logged sets will be lost.'**
  String get workoutRemoveBody;

  /// No description provided for @workoutRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get workoutRemoveConfirm;

  /// No description provided for @workoutRpeTitle.
  ///
  /// In en, this message translates to:
  /// **'RPE for set {n} · how hard was it?'**
  String workoutRpeTitle(int n);

  /// No description provided for @workoutRpeCaption.
  ///
  /// In en, this message translates to:
  /// **'RPE {n} · about {left, plural, one{{left} rep} other{{left} reps}} left in the tank'**
  String workoutRpeCaption(int n, int left);

  /// No description provided for @workoutCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout complete'**
  String get workoutCompleteTitle;

  /// No description provided for @workoutCompleteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name} · {n, plural, =0{no new records} one{{n} new record} other{{n} new records}}'**
  String workoutCompleteSubtitle(String name, int n);

  /// No description provided for @workoutTileDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutTileDuration;

  /// No description provided for @workoutTileVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get workoutTileVolume;

  /// No description provided for @workoutTileSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get workoutTileSets;

  /// No description provided for @workoutTileRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get workoutTileRecords;

  /// No description provided for @workoutTileLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get workoutTileLoad;

  /// No description provided for @workoutOverallTitle.
  ///
  /// In en, this message translates to:
  /// **'How hard was it overall?'**
  String get workoutOverallTitle;

  /// No description provided for @workoutOverallHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. It counts toward your training load and recovery score.'**
  String get workoutOverallHint;

  /// No description provided for @workoutOverallCaption.
  ///
  /// In en, this message translates to:
  /// **'RPE {n} · {label}. Counts toward your training load.'**
  String workoutOverallCaption(int n, String label);

  /// No description provided for @workoutRpeVeryEasy.
  ///
  /// In en, this message translates to:
  /// **'Very easy'**
  String get workoutRpeVeryEasy;

  /// No description provided for @workoutRpeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get workoutRpeEasy;

  /// No description provided for @workoutRpeModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get workoutRpeModerate;

  /// No description provided for @workoutRpeHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get workoutRpeHard;

  /// No description provided for @workoutRpeVeryHard.
  ///
  /// In en, this message translates to:
  /// **'Very hard'**
  String get workoutRpeVeryHard;

  /// No description provided for @workoutRpeMax.
  ///
  /// In en, this message translates to:
  /// **'Max effort'**
  String get workoutRpeMax;

  /// No description provided for @workoutExercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get workoutExercisesTitle;

  /// No description provided for @workoutBestSetE1rm.
  ///
  /// In en, this message translates to:
  /// **'best set · e1RM'**
  String get workoutBestSetE1rm;

  /// No description provided for @workoutBestSet.
  ///
  /// In en, this message translates to:
  /// **'Best set {value}'**
  String workoutBestSet(String value);

  /// No description provided for @workoutNextTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Next time'**
  String get workoutNextTimeTitle;

  /// No description provided for @workoutNextTimeBody.
  ///
  /// In en, this message translates to:
  /// **'{exercise}: every set done. Try {kg} kg next time.'**
  String workoutNextTimeBody(String exercise, String kg);

  /// No description provided for @workoutSave.
  ///
  /// In en, this message translates to:
  /// **'Save workout'**
  String get workoutSave;

  /// No description provided for @workoutDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get workoutDiscard;

  /// No description provided for @workoutDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this workout?'**
  String get workoutDiscardTitle;

  /// No description provided for @workoutDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'It won’t be saved to your history.'**
  String get workoutDiscardBody;

  /// No description provided for @workoutAddExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get workoutAddExercise;

  /// No description provided for @homeGreetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String homeGreetingMorning(String name);

  /// No description provided for @homeGreetingMorningNoName.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get homeGreetingMorningNoName;

  /// No description provided for @homeGreetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon, {name}'**
  String homeGreetingAfternoon(String name);

  /// No description provided for @homeGreetingAfternoonNoName.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get homeGreetingAfternoonNoName;

  /// No description provided for @homeGreetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening, {name}'**
  String homeGreetingEvening(String name);

  /// No description provided for @homeGreetingEveningNoName.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get homeGreetingEveningNoName;

  /// No description provided for @checkinCardPrompt.
  ///
  /// In en, this message translates to:
  /// **'How do you feel today? 20 seconds to see how ready you are to train.'**
  String get checkinCardPrompt;

  /// No description provided for @checkinCardAction.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get checkinCardAction;

  /// No description provided for @checkinCardRecovered.
  ///
  /// In en, this message translates to:
  /// **'{score}% recovered'**
  String checkinCardRecovered(int score);

  /// No description provided for @checkinCardSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See what shaped it'**
  String get checkinCardSeeMore;

  /// No description provided for @checkinTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning check-in'**
  String get checkinTitle;

  /// No description provided for @checkinSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get checkinSleep;

  /// No description provided for @checkinSleepDuration.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} m'**
  String checkinSleepDuration(int hours, int minutes);

  /// No description provided for @checkinSleepLess.
  ///
  /// In en, this message translates to:
  /// **'Sleep 15 minutes less'**
  String get checkinSleepLess;

  /// No description provided for @checkinSleepMore.
  ///
  /// In en, this message translates to:
  /// **'Sleep 15 minutes more'**
  String get checkinSleepMore;

  /// No description provided for @sleepQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get sleepQualityPoor;

  /// No description provided for @sleepQualityOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get sleepQualityOk;

  /// No description provided for @sleepQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get sleepQualityGood;

  /// No description provided for @checkinSoreness.
  ///
  /// In en, this message translates to:
  /// **'Muscle soreness'**
  String get checkinSoreness;

  /// No description provided for @sorenessNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sorenessNone;

  /// No description provided for @sorenessLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get sorenessLight;

  /// No description provided for @sorenessMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get sorenessMedium;

  /// No description provided for @sorenessStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get sorenessStrong;

  /// No description provided for @bodyLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get bodyLegs;

  /// No description provided for @bodyBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get bodyBack;

  /// No description provided for @bodyChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get bodyChest;

  /// No description provided for @bodyArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get bodyArms;

  /// No description provided for @bodyShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get bodyShoulders;

  /// No description provided for @checkinEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get checkinEnergy;

  /// No description provided for @checkinStress.
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get checkinStress;

  /// No description provided for @levelLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get levelLow;

  /// No description provided for @levelOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get levelOk;

  /// No description provided for @levelHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get levelHigh;

  /// No description provided for @stressLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get stressLow;

  /// No description provided for @stressMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get stressMedium;

  /// No description provided for @stressHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get stressHigh;

  /// No description provided for @checkinSave.
  ///
  /// In en, this message translates to:
  /// **'Save check-in'**
  String get checkinSave;

  /// No description provided for @readinessReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to train'**
  String get readinessReady;

  /// No description provided for @readinessTrainLight.
  ///
  /// In en, this message translates to:
  /// **'Train light'**
  String get readinessTrainLight;

  /// No description provided for @readinessRest.
  ///
  /// In en, this message translates to:
  /// **'Rest today'**
  String get readinessRest;

  /// No description provided for @checkinHintReady.
  ///
  /// In en, this message translates to:
  /// **'A hard session is fine.'**
  String get checkinHintReady;

  /// No description provided for @checkinHintReadySore.
  ///
  /// In en, this message translates to:
  /// **'A hard session is fine. {areas} need one more day.'**
  String checkinHintReadySore(String areas);

  /// No description provided for @checkinHintLight.
  ///
  /// In en, this message translates to:
  /// **'Keep it lighter today.'**
  String get checkinHintLight;

  /// No description provided for @checkinHintRest.
  ///
  /// In en, this message translates to:
  /// **'Take it easy. Recovery is training too.'**
  String get checkinHintRest;

  /// No description provided for @recoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get recoveryTitle;

  /// No description provided for @recoverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Today · check-in at {time}'**
  String recoverySubtitle(String time);

  /// No description provided for @recoveryRecovered.
  ///
  /// In en, this message translates to:
  /// **'recovered'**
  String get recoveryRecovered;

  /// No description provided for @recoveryHintReadySore.
  ///
  /// In en, this message translates to:
  /// **'A hard session is fine. Keep {areas} light today.'**
  String recoveryHintReadySore(String areas);

  /// No description provided for @recoveryShaped.
  ///
  /// In en, this message translates to:
  /// **'What shaped it'**
  String get recoveryShaped;

  /// No description provided for @factorSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep {duration}'**
  String factorSleep(String duration);

  /// No description provided for @factorSleepQuality.
  ///
  /// In en, this message translates to:
  /// **'{quality} quality'**
  String factorSleepQuality(String quality);

  /// No description provided for @factorSoreness.
  ///
  /// In en, this message translates to:
  /// **'Soreness: {level}'**
  String factorSoreness(String level);

  /// No description provided for @factorEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy: {level}'**
  String factorEnergy(String level);

  /// No description provided for @factorStress.
  ///
  /// In en, this message translates to:
  /// **'Stress: {level}'**
  String factorStress(String level);

  /// No description provided for @factorLoad.
  ///
  /// In en, this message translates to:
  /// **'Training load'**
  String get factorLoad;

  /// No description provided for @factorLoadSub.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hard day} other{{count} hard days}} in the last 7'**
  String factorLoadSub(int count);

  /// No description provided for @recoveryPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Today’s plan, adjusted'**
  String get recoveryPlanTitle;

  /// No description provided for @recoveryPlanApplied.
  ///
  /// In en, this message translates to:
  /// **'{plan} stays. Swapped: {swaps}. This spares your {areas}.'**
  String recoveryPlanApplied(String plan, String swaps, String areas);

  /// No description provided for @recoveryPlanSuggested.
  ///
  /// In en, this message translates to:
  /// **'{plan} can stay. Suggested swaps: {swaps}, to spare your {areas}.'**
  String recoveryPlanSuggested(String plan, String swaps, String areas);

  /// No description provided for @recoveryStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get recoveryStartWorkout;

  /// No description provided for @recoveryUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get recoveryUndo;

  /// No description provided for @recoveryApplySwaps.
  ///
  /// In en, this message translates to:
  /// **'Apply swaps'**
  String get recoveryApplySwaps;

  /// No description provided for @recoveryLast7.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get recoveryLast7;

  /// No description provided for @recoveryAvg.
  ///
  /// In en, this message translates to:
  /// **'avg {score}%'**
  String recoveryAvg(int score);

  /// No description provided for @recoveryNoCheckin.
  ///
  /// In en, this message translates to:
  /// **'No check-in yet'**
  String get recoveryNoCheckin;

  /// No description provided for @recoveryNoCheckinBody.
  ///
  /// In en, this message translates to:
  /// **'Check in to see how recovered you are and what shaped it.'**
  String get recoveryNoCheckinBody;

  /// No description provided for @planTitle.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get planTitle;

  /// No description provided for @planSummary.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} session} other{{n} sessions}} · {m} done'**
  String planSummary(int n, int m);

  /// No description provided for @planLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Training load'**
  String get planLoadTitle;

  /// No description provided for @planLoadEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get planLoadEasy;

  /// No description provided for @planLoadNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get planLoadNormal;

  /// No description provided for @planLoadHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get planLoadHigh;

  /// No description provided for @planLoadCaption.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} hard session in the next 3 days.} other{{n} hard sessions in the next 3 days.}}'**
  String planLoadCaption(int n);

  /// No description provided for @planRecoveryToday.
  ///
  /// In en, this message translates to:
  /// **'Recovery today {score}%.'**
  String planRecoveryToday(int score);

  /// No description provided for @planFelixLabel.
  ///
  /// In en, this message translates to:
  /// **'FELIX SUGGESTS'**
  String get planFelixLabel;

  /// No description provided for @planFelixText.
  ///
  /// In en, this message translates to:
  /// **'{a} ({aDay}) and {b} ({bDay}) are both hard. Move {b} to {target} so your legs recover.'**
  String planFelixText(
      String a, String aDay, String b, String bDay, String target);

  /// No description provided for @planOptimize.
  ///
  /// In en, this message translates to:
  /// **'Optimize plan'**
  String get planOptimize;

  /// No description provided for @planKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get planKeep;

  /// No description provided for @planTodayDay.
  ///
  /// In en, this message translates to:
  /// **'Today · {day}'**
  String planTodayDay(String day);

  /// No description provided for @planDoneCount.
  ///
  /// In en, this message translates to:
  /// **'{n} done'**
  String planDoneCount(int n);

  /// No description provided for @planPlannedCount.
  ///
  /// In en, this message translates to:
  /// **'{n} planned'**
  String planPlannedCount(int n);

  /// No description provided for @planMissedHeader.
  ///
  /// In en, this message translates to:
  /// **'missed'**
  String get planMissedHeader;

  /// No description provided for @planMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get planMissed;

  /// No description provided for @planRestDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get planRestDay;

  /// No description provided for @planExercisesMeta.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} exercise} other{{count} exercises}} · {duration}'**
  String planExercisesMeta(int count, String duration);

  /// No description provided for @planDurationHM.
  ///
  /// In en, this message translates to:
  /// **'{h}h {m}m'**
  String planDurationHM(int h, int m);

  /// No description provided for @planDurationH.
  ///
  /// In en, this message translates to:
  /// **'{h}h'**
  String planDurationH(int h);

  /// No description provided for @planDurationM.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String planDurationM(int m);

  /// No description provided for @planIntensityEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get planIntensityEasy;

  /// No description provided for @planIntensityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get planIntensityNormal;

  /// No description provided for @planIntensityHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get planIntensityHard;

  /// No description provided for @planDoneMeta.
  ///
  /// In en, this message translates to:
  /// **'{duration} · RPE {rpe}'**
  String planDoneMeta(String duration, int rpe);

  /// No description provided for @planAddSession.
  ///
  /// In en, this message translates to:
  /// **'Add session'**
  String get planAddSession;

  /// No description provided for @planAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a session'**
  String get planAddTitle;

  /// No description provided for @planWorkoutLabel.
  ///
  /// In en, this message translates to:
  /// **'WORKOUT'**
  String get planWorkoutLabel;

  /// No description provided for @planDayLabel.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get planDayLabel;

  /// No description provided for @planAddButton.
  ///
  /// In en, this message translates to:
  /// **'Add {title} · {day}'**
  String planAddButton(String title, String day);

  /// No description provided for @planWarnThird.
  ///
  /// In en, this message translates to:
  /// **'{day} would be your 3rd hard day in a row'**
  String planWarnThird(String day);

  /// No description provided for @planWarnAuto.
  ///
  /// In en, this message translates to:
  /// **'{day} gives you more time to recover. Felix picked it for you.'**
  String planWarnAuto(String day);

  /// No description provided for @planWarnPick.
  ///
  /// In en, this message translates to:
  /// **'Pick another day to keep your recovery.'**
  String get planWarnPick;

  /// No description provided for @planGenericFootball.
  ///
  /// In en, this message translates to:
  /// **'Football 7×7'**
  String get planGenericFootball;

  /// No description provided for @planSkiing.
  ///
  /// In en, this message translates to:
  /// **'Skiing'**
  String get planSkiing;

  /// No description provided for @planEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No plan yet'**
  String get planEmptyTitle;

  /// No description provided for @planEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Set up your gym workouts for the rest of this week in one tap.'**
  String get planEmptyBody;

  /// No description provided for @planPlanWeek.
  ///
  /// In en, this message translates to:
  /// **'Plan my week'**
  String get planPlanWeek;

  /// No description provided for @planEntryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Plan your training week'**
  String get planEntryEmpty;

  /// No description provided for @planNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get planNextWeek;

  /// No description provided for @planPlanNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Plan next week'**
  String get planPlanNextWeek;

  /// No description provided for @exercisesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesTitle;

  /// No description provided for @exercisesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search {n} exercises'**
  String exercisesSearch(int n);

  /// No description provided for @exercisesSearchShort.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get exercisesSearchShort;

  /// No description provided for @exercisesAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exercisesAll;

  /// No description provided for @exercisesAnyEquipment.
  ///
  /// In en, this message translates to:
  /// **'Any equipment'**
  String get exercisesAnyEquipment;

  /// No description provided for @exercisesRecent.
  ///
  /// In en, this message translates to:
  /// **'Your recent'**
  String get exercisesRecent;

  /// No description provided for @exercisesFromWorkouts.
  ///
  /// In en, this message translates to:
  /// **'from workouts'**
  String get exercisesFromWorkouts;

  /// No description provided for @exercisesBest.
  ///
  /// In en, this message translates to:
  /// **'best'**
  String get exercisesBest;

  /// No description provided for @exercisesAZ.
  ///
  /// In en, this message translates to:
  /// **'All · A–Z'**
  String get exercisesAZ;

  /// No description provided for @exercisesCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} exercise} other{{n} exercises}}'**
  String exercisesCount(int n);

  /// No description provided for @exercisesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No exercises match. Try another filter.'**
  String get exercisesNoMatch;

  /// No description provided for @muscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscleChest;

  /// No description provided for @muscleBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get muscleBack;

  /// No description provided for @muscleShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get muscleShoulders;

  /// No description provided for @muscleArms.
  ///
  /// In en, this message translates to:
  /// **'Arms'**
  String get muscleArms;

  /// No description provided for @muscleLegs.
  ///
  /// In en, this message translates to:
  /// **'Legs'**
  String get muscleLegs;

  /// No description provided for @muscleGlutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get muscleGlutes;

  /// No description provided for @muscleCore.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get muscleCore;

  /// No description provided for @equipBarbell.
  ///
  /// In en, this message translates to:
  /// **'Barbell'**
  String get equipBarbell;

  /// No description provided for @equipDumbbell.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell'**
  String get equipDumbbell;

  /// No description provided for @equipCable.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get equipCable;

  /// No description provided for @equipMachine.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get equipMachine;

  /// No description provided for @equipBodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get equipBodyweight;

  /// No description provided for @equipKettlebell.
  ///
  /// In en, this message translates to:
  /// **'Kettlebell'**
  String get equipKettlebell;

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get levelAdvanced;

  /// No description provided for @exerciseCompound.
  ///
  /// In en, this message translates to:
  /// **'Compound'**
  String get exerciseCompound;

  /// No description provided for @exerciseDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseDetailTitle;

  /// No description provided for @exercisePrimary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get exercisePrimary;

  /// No description provided for @exerciseSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get exerciseSecondary;

  /// No description provided for @exerciseYourNumbers.
  ///
  /// In en, this message translates to:
  /// **'Your numbers'**
  String get exerciseYourNumbers;

  /// No description provided for @exerciseBestSet.
  ///
  /// In en, this message translates to:
  /// **'Best set'**
  String get exerciseBestSet;

  /// No description provided for @exerciseE1rm.
  ///
  /// In en, this message translates to:
  /// **'e1RM'**
  String get exerciseE1rm;

  /// No description provided for @exerciseSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get exerciseSessions;

  /// No description provided for @exerciseChangeSince.
  ///
  /// In en, this message translates to:
  /// **'{pct} since {month}'**
  String exerciseChangeSince(String pct, String month);

  /// No description provided for @exerciseNoHistory.
  ///
  /// In en, this message translates to:
  /// **'Do it once to see your numbers'**
  String get exerciseNoHistory;

  /// No description provided for @exerciseHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to do it'**
  String get exerciseHowTo;

  /// No description provided for @exerciseMistakes.
  ///
  /// In en, this message translates to:
  /// **'Common mistakes'**
  String get exerciseMistakes;

  /// No description provided for @exerciseSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar'**
  String get exerciseSimilar;

  /// No description provided for @exerciseAskFelix.
  ///
  /// In en, this message translates to:
  /// **'Ask Felix'**
  String get exerciseAskFelix;

  /// No description provided for @exerciseAskFelixDraft.
  ///
  /// In en, this message translates to:
  /// **'How do I improve my {name}?'**
  String exerciseAskFelixDraft(String name);

  /// No description provided for @exerciseAddToWorkout.
  ///
  /// In en, this message translates to:
  /// **'Add to workout'**
  String get exerciseAddToWorkout;

  /// No description provided for @exerciseAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to your workout'**
  String get exerciseAdded;

  /// No description provided for @exerciseQuickWorkout.
  ///
  /// In en, this message translates to:
  /// **'Quick workout'**
  String get exerciseQuickWorkout;

  /// No description provided for @addExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to {workout}'**
  String addExerciseTitle(String workout);

  /// No description provided for @addExerciseSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap in {workout}'**
  String addExerciseSwapTitle(String workout);

  /// No description provided for @addExerciseHint.
  ///
  /// In en, this message translates to:
  /// **'{group} got {n} sets this week, target is {target}.'**
  String addExerciseHint(String group, int n, int target);

  /// No description provided for @addExerciseSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get addExerciseSuggested;

  /// No description provided for @addExerciseSelected.
  ///
  /// In en, this message translates to:
  /// **'{n} selected'**
  String addExerciseSelected(int n);

  /// No description provided for @addExerciseLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get addExerciseLibrary;

  /// No description provided for @addExerciseInWorkout.
  ///
  /// In en, this message translates to:
  /// **'In this workout'**
  String get addExerciseInWorkout;

  /// No description provided for @addExerciseButton.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{Add {n} exercise} other{Add {n} exercises}}'**
  String addExerciseButton(int n);

  /// No description provided for @addExerciseSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get addExerciseSwap;

  /// No description provided for @workoutMenuSwapSub.
  ///
  /// In en, this message translates to:
  /// **'Choose from the library'**
  String get workoutMenuSwapSub;

  /// No description provided for @gymExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get gymExercises;

  /// No description provided for @gymExercisesSub.
  ///
  /// In en, this message translates to:
  /// **'{n} with technique and your best sets'**
  String gymExercisesSub(int n);

  /// No description provided for @profileEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditTooltip;

  /// No description provided for @profileMySports.
  ///
  /// In en, this message translates to:
  /// **'My sports'**
  String get profileMySports;

  /// No description provided for @profileSportsSelected.
  ///
  /// In en, this message translates to:
  /// **'{n} selected'**
  String profileSportsSelected(int n);

  /// No description provided for @profileWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'kg · weight'**
  String get profileWeightLabel;

  /// No description provided for @profileHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'cm · height'**
  String get profileHeightLabel;

  /// No description provided for @profileAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'years · age'**
  String get profileAgeLabel;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @hrZonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Heart-rate zones'**
  String get hrZonesTitle;

  /// No description provided for @profileHrZonesSummary.
  ///
  /// In en, this message translates to:
  /// **'Rest {rest} · max {max} bpm'**
  String profileHrZonesSummary(int rest, int max);

  /// No description provided for @profileHrZonesSetUp.
  ///
  /// In en, this message translates to:
  /// **'Set up'**
  String get profileHrZonesSetUp;

  /// No description provided for @profileConnectedApps.
  ///
  /// In en, this message translates to:
  /// **'Connected apps'**
  String get profileConnectedApps;

  /// No description provided for @profileConnectedAppsCount.
  ///
  /// In en, this message translates to:
  /// **'{connected} of {total} connected'**
  String profileConnectedAppsCount(int connected, int total);

  /// No description provided for @hrZonesMax.
  ///
  /// In en, this message translates to:
  /// **'Max HR'**
  String get hrZonesMax;

  /// No description provided for @hrZonesRest.
  ///
  /// In en, this message translates to:
  /// **'Resting HR'**
  String get hrZonesRest;

  /// No description provided for @hrZonesLthr.
  ///
  /// In en, this message translates to:
  /// **'LTHR'**
  String get hrZonesLthr;

  /// No description provided for @hrZonesEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit heart rates'**
  String get hrZonesEdit;

  /// No description provided for @hrZonesKarvonen.
  ///
  /// In en, this message translates to:
  /// **'Karvonen'**
  String get hrZonesKarvonen;

  /// No description provided for @hrZonesFriel.
  ///
  /// In en, this message translates to:
  /// **'LTHR (Friel)'**
  String get hrZonesFriel;

  /// No description provided for @hrZonesKarvonenTitle.
  ///
  /// In en, this message translates to:
  /// **'Karvonen zones'**
  String get hrZonesKarvonenTitle;

  /// No description provided for @hrZonesKarvonenSub.
  ///
  /// In en, this message translates to:
  /// **'% of reserve'**
  String get hrZonesKarvonenSub;

  /// No description provided for @hrZonesFrielTitle.
  ///
  /// In en, this message translates to:
  /// **'LTHR zones'**
  String get hrZonesFrielTitle;

  /// No description provided for @hrZonesColZone.
  ///
  /// In en, this message translates to:
  /// **'ZONE'**
  String get hrZonesColZone;

  /// No description provided for @hrZonesColBpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get hrZonesColBpm;

  /// No description provided for @hrZonesColHrr.
  ///
  /// In en, this message translates to:
  /// **'50–100% HRR'**
  String get hrZonesColHrr;

  /// No description provided for @hrZonesColLthr.
  ///
  /// In en, this message translates to:
  /// **'% OF LTHR'**
  String get hrZonesColLthr;

  /// No description provided for @hrZonesLthrValue.
  ///
  /// In en, this message translates to:
  /// **'LTHR {lthr} bpm'**
  String hrZonesLthrValue(int lthr);

  /// No description provided for @hrZonesFormula.
  ///
  /// In en, this message translates to:
  /// **'HR = rest + % × (max − rest). Your reserve is {reserve} bpm.'**
  String hrZonesFormula(int reserve);

  /// No description provided for @hrZonesZ2Tip.
  ///
  /// In en, this message translates to:
  /// **'Most of your running should sit in Z2, {low}–{high} bpm. Z4 only for short intervals.'**
  String hrZonesZ2Tip(int low, int high);

  /// No description provided for @hrZonesHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How to measure max HR'**
  String get hrZonesHowTitle;

  /// No description provided for @hrZonesHowBody.
  ///
  /// In en, this message translates to:
  /// **'Warm up 15 min, then run a hard 3–4 min uphill effort twice. The highest HR you see is your max.'**
  String get hrZonesHowBody;

  /// No description provided for @hrZonesTanaka.
  ///
  /// In en, this message translates to:
  /// **'No test yet? Tanaka estimate: 208 − 0.7 × {age} = {max} bpm (±10).'**
  String hrZonesTanaka(int age, int max);

  /// No description provided for @hrZonesRestingTip.
  ///
  /// In en, this message translates to:
  /// **'Resting HR: measure on waking, lying down.'**
  String get hrZonesRestingTip;

  /// No description provided for @hrZonesFrielNote.
  ///
  /// In en, this message translates to:
  /// **'Friel zones for running. LTHR test: run 30 min solo all-out, average HR of the last 20 min is your LTHR.'**
  String get hrZonesFrielNote;

  /// No description provided for @hrZonesNeedAge.
  ///
  /// In en, this message translates to:
  /// **'Add your age to your profile to get an estimate of your max HR.'**
  String get hrZonesNeedAge;

  /// No description provided for @hrZonesCompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get hrZonesCompleteProfile;

  /// No description provided for @hrZonesNeedRates.
  ///
  /// In en, this message translates to:
  /// **'Add your resting and max HR to see your zones.'**
  String get hrZonesNeedRates;

  /// No description provided for @hrZonesNeedLthr.
  ///
  /// In en, this message translates to:
  /// **'Add your LTHR to see Friel zones.'**
  String get hrZonesNeedLthr;

  /// No description provided for @hrZoneRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get hrZoneRecovery;

  /// No description provided for @hrZoneAerobic.
  ///
  /// In en, this message translates to:
  /// **'Aerobic'**
  String get hrZoneAerobic;

  /// No description provided for @hrZoneTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get hrZoneTempo;

  /// No description provided for @hrZoneThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get hrZoneThreshold;

  /// No description provided for @hrZoneVo2max.
  ///
  /// In en, this message translates to:
  /// **'VO2max'**
  String get hrZoneVo2max;

  /// No description provided for @hrZoneSubThr.
  ///
  /// In en, this message translates to:
  /// **'Sub-thr.'**
  String get hrZoneSubThr;

  /// No description provided for @hrZoneThreshPlus.
  ///
  /// In en, this message translates to:
  /// **'Thresh.+'**
  String get hrZoneThreshPlus;

  /// No description provided for @hrZoneCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get hrZoneCapacity;

  /// No description provided for @hrZoneAnaerobic.
  ///
  /// In en, this message translates to:
  /// **'Anaerob.'**
  String get hrZoneAnaerobic;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get editProfileBody;

  /// No description provided for @editProfilePerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get editProfilePerformance;

  /// No description provided for @editProfileSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get editProfileSex;

  /// No description provided for @sexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get sexMale;

  /// No description provided for @sexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get sexFemale;

  /// No description provided for @editProfileRestingHr.
  ///
  /// In en, this message translates to:
  /// **'Resting HR'**
  String get editProfileRestingHr;

  /// No description provided for @editProfileMaxHr.
  ///
  /// In en, this message translates to:
  /// **'Max HR'**
  String get editProfileMaxHr;

  /// No description provided for @editProfileLthr.
  ///
  /// In en, this message translates to:
  /// **'LTHR (optional)'**
  String get editProfileLthr;

  /// No description provided for @editProfileFtp.
  ///
  /// In en, this message translates to:
  /// **'Cycling FTP'**
  String get editProfileFtp;

  /// No description provided for @editProfileFiveK.
  ///
  /// In en, this message translates to:
  /// **'Running 5K personal best'**
  String get editProfileFiveK;

  /// No description provided for @unitBpm.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get unitBpm;

  /// No description provided for @unitWatts.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get unitWatts;

  /// No description provided for @unitMinSec.
  ///
  /// In en, this message translates to:
  /// **'min:sec'**
  String get unitMinSec;

  /// No description provided for @unitYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get unitYears;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editProfileSave;

  /// No description provided for @editProfileErrHr.
  ///
  /// In en, this message translates to:
  /// **'Enter {min}–{max} bpm'**
  String editProfileErrHr(int min, int max);

  /// No description provided for @editProfileErrRestMax.
  ///
  /// In en, this message translates to:
  /// **'Resting HR must be lower than max HR'**
  String get editProfileErrRestMax;

  /// No description provided for @editProfileErrFtp.
  ///
  /// In en, this message translates to:
  /// **'Enter {min}–{max} W'**
  String editProfileErrFtp(int min, int max);

  /// No description provided for @editProfileErrFiveK.
  ///
  /// In en, this message translates to:
  /// **'Enter a time from 12:00 to 60:00'**
  String get editProfileErrFiveK;

  /// No description provided for @connectedAppsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connected apps'**
  String get connectedAppsTitle;

  /// No description provided for @connectedAppsWhyHeader.
  ///
  /// In en, this message translates to:
  /// **'WHY CONNECT'**
  String get connectedAppsWhyHeader;

  /// No description provided for @connectedAppsWhyBody.
  ///
  /// In en, this message translates to:
  /// **'{health} fills in last night\'s sleep for your check-in, resting HR and HRV for recovery, steps, and weight from smart scales. Workouts from your watch appear in your history and training load. Apple Watch, Garmin, WHOOP and Mi Band (Zepp / Mi Fitness) data arrives through {health} once that app\'s sync to {health} is on.'**
  String connectedAppsWhyBody(String health);

  /// No description provided for @connectedAppsWhyBodyAndroid.
  ///
  /// In en, this message translates to:
  /// **'{health} fills in last night\'s sleep for your check-in, resting HR and HRV for recovery, steps, and weight from smart scales. Workouts from your watch appear in your history and training load. Garmin, WHOOP and Mi Band (Zepp / Mi Fitness) data arrives through {health} once that app\'s sync to {health} is on.'**
  String connectedAppsWhyBodyAndroid(String health);

  /// No description provided for @connectedAppsHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Sleep, heart rate, HRV, steps, weight, workouts'**
  String get connectedAppsHealthDesc;

  /// No description provided for @connectedAppsGarminDesc.
  ///
  /// In en, this message translates to:
  /// **'Activities, HR, sleep, HRV'**
  String get connectedAppsGarminDesc;

  /// No description provided for @connectedAppsStravaDesc.
  ///
  /// In en, this message translates to:
  /// **'Runs, rides and ski activities'**
  String get connectedAppsStravaDesc;

  /// No description provided for @connectedAppsWhoopDesc.
  ///
  /// In en, this message translates to:
  /// **'Recovery, strain, sleep, HRV'**
  String get connectedAppsWhoopDesc;

  /// No description provided for @connectedAppsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get connectedAppsNotConnected;

  /// No description provided for @connectedAppsConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connectedAppsConnect;

  /// No description provided for @connectedAppsFooter.
  ///
  /// In en, this message translates to:
  /// **'You can disconnect at any time.'**
  String get connectedAppsFooter;

  /// No description provided for @connectedAppsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect {app}'**
  String connectedAppsSheetTitle(String app);

  /// No description provided for @connectedAppsSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What FITRIX could read'**
  String get connectedAppsSheetSubtitle;

  /// No description provided for @connectedAppsSheetPrivacy.
  ///
  /// In en, this message translates to:
  /// **'When this arrives, FITRIX will only read data and never post.'**
  String get connectedAppsSheetPrivacy;

  /// No description provided for @connectedAppsSheetSoon.
  ///
  /// In en, this message translates to:
  /// **'Connecting {app} directly is not available yet. Meanwhile send its data to {health} and FITRIX will read it from there.'**
  String connectedAppsSheetSoon(String app, String health);

  /// No description provided for @connectedAppsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming in a later update'**
  String get connectedAppsComingSoon;

  /// No description provided for @connectedAppsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get connectedAppsClose;

  /// No description provided for @connectedAppsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedAppsConnected;

  /// No description provided for @connectedAppsLastRead.
  ///
  /// In en, this message translates to:
  /// **'Last read {time}'**
  String connectedAppsLastRead(String time);

  /// No description provided for @connectedAppsReading.
  ///
  /// In en, this message translates to:
  /// **'Reading your data…'**
  String get connectedAppsReading;

  /// No description provided for @connectedAppsWriteWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Save my FITRIX workouts to {health}'**
  String connectedAppsWriteWorkouts(String health);

  /// No description provided for @connectedAppsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get connectedAppsDisconnect;

  /// No description provided for @connectedAppsDisconnectedIos.
  ///
  /// In en, this message translates to:
  /// **'To remove access, open Settings › Health › Data Access & Devices › FITRIX.'**
  String get connectedAppsDisconnectedIos;

  /// No description provided for @connectedAppsDisconnectedAndroid.
  ///
  /// In en, this message translates to:
  /// **'To remove access, open Health Connect › App permissions › FITRIX.'**
  String get connectedAppsDisconnectedAndroid;

  /// No description provided for @connectedAppsDeniedIos.
  ///
  /// In en, this message translates to:
  /// **'Access wasn\'t granted. You can change it in the Health app.'**
  String get connectedAppsDeniedIos;

  /// No description provided for @connectedAppsDeniedAndroid.
  ///
  /// In en, this message translates to:
  /// **'Access wasn\'t granted. You can change it in Health Connect.'**
  String get connectedAppsDeniedAndroid;

  /// No description provided for @connectedAppsInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get connectedAppsInstall;

  /// No description provided for @connectedAppsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get connectedAppsUpdate;

  /// No description provided for @connectedAppsNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Health Connect is not installed on this phone.'**
  String get connectedAppsNotInstalled;

  /// No description provided for @connectedAppsNeedsUpdate.
  ///
  /// In en, this message translates to:
  /// **'Health Connect needs an update.'**
  String get connectedAppsNeedsUpdate;

  /// No description provided for @connectedAppsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available on this device.'**
  String get connectedAppsUnavailable;

  /// No description provided for @connectedAppsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Health data stays on this phone; only workouts you import and your check-in are saved to your account.'**
  String get connectedAppsPrivacy;

  /// No description provided for @connectedAppsDeleteHelp.
  ///
  /// In en, this message translates to:
  /// **'Deleting a workout in FITRIX does not delete it from {health}.'**
  String connectedAppsDeleteHelp(String health);

  /// No description provided for @nutritionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nutritionToday;

  /// No description provided for @nutritionDateTraining.
  ///
  /// In en, this message translates to:
  /// **'{date} · training day'**
  String nutritionDateTraining(String date);

  /// No description provided for @nutritionCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get nutritionCompleteTitle;

  /// No description provided for @nutritionCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Add your sex, age, weight and height to get daily targets.'**
  String get nutritionCompleteBody;

  /// No description provided for @nutritionLeftToday.
  ///
  /// In en, this message translates to:
  /// **'Left today'**
  String get nutritionLeftToday;

  /// No description provided for @nutritionBurned.
  ///
  /// In en, this message translates to:
  /// **'Burned in training'**
  String get nutritionBurned;

  /// No description provided for @nutritionBurnedValue.
  ///
  /// In en, this message translates to:
  /// **'≈ +{kcal} kcal'**
  String nutritionBurnedValue(String kcal);

  /// No description provided for @nutritionHowSet.
  ///
  /// In en, this message translates to:
  /// **'How it’s set ›'**
  String get nutritionHowSet;

  /// No description provided for @nutritionMacros.
  ///
  /// In en, this message translates to:
  /// **'Macros'**
  String get nutritionMacros;

  /// No description provided for @nutritionProteinPerKg.
  ///
  /// In en, this message translates to:
  /// **'protein {value} g/kg'**
  String nutritionProteinPerKg(String value);

  /// No description provided for @nutritionGramsOf.
  ///
  /// In en, this message translates to:
  /// **'{eaten} / {target} g'**
  String nutritionGramsOf(String eaten, String target);

  /// No description provided for @nutritionWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water · {drunk} of {target} L'**
  String nutritionWaterTitle(String drunk, String target);

  /// No description provided for @nutritionWaterNoTarget.
  ///
  /// In en, this message translates to:
  /// **'Water · {drunk} L'**
  String nutritionWaterNoTarget(String drunk);

  /// No description provided for @nutritionWaterWorkout.
  ///
  /// In en, this message translates to:
  /// **'+0.5 L for today’s workout'**
  String get nutritionWaterWorkout;

  /// No description provided for @nutritionStepsBonus.
  ///
  /// In en, this message translates to:
  /// **'+{kcal} kcal for steps today (steps: {steps})'**
  String nutritionStepsBonus(String kcal, String steps);

  /// No description provided for @nutritionAddMl.
  ///
  /// In en, this message translates to:
  /// **'+{ml} ml'**
  String nutritionAddMl(String ml);

  /// No description provided for @nutritionMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get nutritionMeals;

  /// No description provided for @nutritionMealsLogged.
  ///
  /// In en, this message translates to:
  /// **'{n} of 4 logged'**
  String nutritionMealsLogged(String n);

  /// No description provided for @nutritionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get nutritionAdd;

  /// No description provided for @nutritionLowToday.
  ///
  /// In en, this message translates to:
  /// **'Low today'**
  String get nutritionLowToday;

  /// No description provided for @nutritionAllMicros.
  ///
  /// In en, this message translates to:
  /// **'All {n} ›'**
  String nutritionAllMicros(String n);

  /// No description provided for @nutritionDinnerIdea.
  ///
  /// In en, this message translates to:
  /// **'Dinner idea'**
  String get nutritionDinnerIdea;

  /// No description provided for @nutritionIdeaMessage.
  ///
  /// In en, this message translates to:
  /// **'Protein is {gap} g behind. {food} ({portion}) gives about {protein} g.'**
  String nutritionIdeaMessage(
      String gap, String food, String portion, String protein);

  /// No description provided for @nutritionAddToDinner.
  ///
  /// In en, this message translates to:
  /// **'Add to dinner'**
  String get nutritionAddToDinner;

  /// No description provided for @nutritionOtherIdea.
  ///
  /// In en, this message translates to:
  /// **'Other idea'**
  String get nutritionOtherIdea;

  /// No description provided for @nutritionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get nutritionRemove;

  /// No description provided for @nutritionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search foods'**
  String get nutritionSearch;

  /// No description provided for @nutritionFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get nutritionFood;

  /// No description provided for @nutritionGrams.
  ///
  /// In en, this message translates to:
  /// **'{grams} g'**
  String nutritionGrams(String grams);

  /// No description provided for @nutritionAddToSlot.
  ///
  /// In en, this message translates to:
  /// **'{slot, select, breakfast{Add to breakfast} lunch{Add to lunch} dinner{Add to dinner} snack{Add to snack} other{Add to dinner}}'**
  String nutritionAddToSlot(String slot);

  /// No description provided for @nutritionAddToSlotKcal.
  ///
  /// In en, this message translates to:
  /// **'{slot, select, breakfast{Add to breakfast · {kcal} kcal} lunch{Add to lunch · {kcal} kcal} dinner{Add to dinner · {kcal} kcal} snack{Add to snack · {kcal} kcal} other{Add to dinner · {kcal} kcal}}'**
  String nutritionAddToSlotKcal(String slot, String kcal);

  /// No description provided for @nutritionAddedTo.
  ///
  /// In en, this message translates to:
  /// **'{slot, select, breakfast{Added {name} to breakfast} lunch{Added {name} to lunch} dinner{Added {name} to dinner} snack{Added {name} to snack} other{Added {name}}}'**
  String nutritionAddedTo(String name, String slot);

  /// No description provided for @nutritionResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get nutritionResults;

  /// No description provided for @nutritionResultsCount.
  ///
  /// In en, this message translates to:
  /// **'{n} foods · per portion'**
  String nutritionResultsCount(String n);

  /// No description provided for @nutritionNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Try another name.'**
  String get nutritionNoResults;

  /// No description provided for @nutritionRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get nutritionRecent;

  /// No description provided for @nutritionRecentNote.
  ///
  /// In en, this message translates to:
  /// **'you ate it this week'**
  String get nutritionRecentNote;

  /// No description provided for @nutritionPortionLine.
  ///
  /// In en, this message translates to:
  /// **'{portion} · {kcal} kcal · P {protein} g'**
  String nutritionPortionLine(String portion, String kcal, String protein);

  /// No description provided for @nutritionCantFind.
  ///
  /// In en, this message translates to:
  /// **'Can’t find it?'**
  String get nutritionCantFind;

  /// No description provided for @nutritionCantFindBody.
  ///
  /// In en, this message translates to:
  /// **'Ask Felix to estimate it'**
  String get nutritionCantFindBody;

  /// No description provided for @foodBaseError.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t load the food base.'**
  String get foodBaseError;

  /// No description provided for @foodNotFound.
  ///
  /// In en, this message translates to:
  /// **'This food isn’t in the base.'**
  String get foodNotFound;

  /// No description provided for @foodCatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get foodCatAll;

  /// No description provided for @foodCatUzbek.
  ///
  /// In en, this message translates to:
  /// **'Uzbek dishes'**
  String get foodCatUzbek;

  /// No description provided for @foodCatMeatFish.
  ///
  /// In en, this message translates to:
  /// **'Meat & fish'**
  String get foodCatMeatFish;

  /// No description provided for @foodCatDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get foodCatDairy;

  /// No description provided for @foodCatFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get foodCatFruit;

  /// No description provided for @foodCatVeg.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get foodCatVeg;

  /// No description provided for @foodCatGrains.
  ///
  /// In en, this message translates to:
  /// **'Grains'**
  String get foodCatGrains;

  /// No description provided for @foodCatBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get foodCatBread;

  /// No description provided for @foodCatDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get foodCatDrinks;

  /// No description provided for @foodCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get foodCatOther;

  /// No description provided for @foodRecipeEstimate.
  ///
  /// In en, this message translates to:
  /// **'Recipe estimate'**
  String get foodRecipeEstimate;

  /// No description provided for @foodPer100.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal / 100 g'**
  String foodPer100(String kcal);

  /// No description provided for @foodPortion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get foodPortion;

  /// No description provided for @foodKcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get foodKcal;

  /// No description provided for @foodFitsDay.
  ///
  /// In en, this message translates to:
  /// **'Fits your day?'**
  String get foodFitsDay;

  /// No description provided for @foodKcalLeftAfter.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal left after'**
  String foodKcalLeftAfter(String kcal);

  /// No description provided for @foodKcalOver.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over'**
  String foodKcalOver(String kcal);

  /// No description provided for @foodEaten.
  ///
  /// In en, this message translates to:
  /// **'Eaten {kcal}'**
  String foodEaten(String kcal);

  /// No description provided for @foodPlus.
  ///
  /// In en, this message translates to:
  /// **'+ {name} {kcal}'**
  String foodPlus(String name, String kcal);

  /// No description provided for @foodTarget.
  ///
  /// In en, this message translates to:
  /// **'Target {kcal}'**
  String foodTarget(String kcal);

  /// No description provided for @foodFatWould.
  ///
  /// In en, this message translates to:
  /// **'Fat would reach {fat} of {target} g.'**
  String foodFatWould(String fat, String target);

  /// No description provided for @foodProteinBehind.
  ///
  /// In en, this message translates to:
  /// **'Protein stays {g} g behind.'**
  String foodProteinBehind(String g);

  /// No description provided for @foodRichIn.
  ///
  /// In en, this message translates to:
  /// **'Rich in'**
  String get foodRichIn;

  /// No description provided for @foodPctOfTarget.
  ///
  /// In en, this message translates to:
  /// **'% of your daily target'**
  String get foodPctOfTarget;

  /// No description provided for @micrTitle.
  ///
  /// In en, this message translates to:
  /// **'Micronutrients'**
  String get micrTitle;

  /// No description provided for @micrTargetsFor.
  ///
  /// In en, this message translates to:
  /// **'Targets for {who}, {age} · NASEM'**
  String micrTargetsFor(String who, String age);

  /// No description provided for @micrMen.
  ///
  /// In en, this message translates to:
  /// **'men'**
  String get micrMen;

  /// No description provided for @micrWomen.
  ///
  /// In en, this message translates to:
  /// **'women'**
  String get micrWomen;

  /// No description provided for @micrToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get micrToday;

  /// No description provided for @micr7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get micr7Days;

  /// No description provided for @micr30Days.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get micr30Days;

  /// No description provided for @micrAthlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete essentials'**
  String get micrAthlete;

  /// No description provided for @micrVitamins.
  ///
  /// In en, this message translates to:
  /// **'Vitamins'**
  String get micrVitamins;

  /// No description provided for @micrMinerals.
  ///
  /// In en, this message translates to:
  /// **'Minerals'**
  String get micrMinerals;

  /// No description provided for @micrAll.
  ///
  /// In en, this message translates to:
  /// **'All {n}'**
  String micrAll(String n);

  /// No description provided for @micrEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log food to see your micronutrients.'**
  String get micrEmpty;

  /// No description provided for @micrAverage.
  ///
  /// In en, this message translates to:
  /// **'Average over {n} logged days'**
  String micrAverage(String n);

  /// No description provided for @micrLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get micrLow;

  /// No description provided for @micrOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get micrOk;

  /// No description provided for @micrHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get micrHigh;

  /// No description provided for @micrVitDTitle.
  ///
  /// In en, this message translates to:
  /// **'Vitamin D is low all week'**
  String get micrVitDTitle;

  /// No description provided for @micrVitDBody.
  ///
  /// In en, this message translates to:
  /// **'Fatty fish, eggs and fortified dairy help a little. Ask your doctor about a D3 supplement.'**
  String get micrVitDBody;

  /// No description provided for @micrInSeason.
  ///
  /// In en, this message translates to:
  /// **'In season now'**
  String get micrInSeason;

  /// No description provided for @micrUzbekistanMonth.
  ///
  /// In en, this message translates to:
  /// **'Uzbekistan · {month}'**
  String micrUzbekistanMonth(String month);

  /// No description provided for @microVitD.
  ///
  /// In en, this message translates to:
  /// **'Vitamin D'**
  String get microVitD;

  /// No description provided for @microCalcium.
  ///
  /// In en, this message translates to:
  /// **'Calcium'**
  String get microCalcium;

  /// No description provided for @microMagnesium.
  ///
  /// In en, this message translates to:
  /// **'Magnesium'**
  String get microMagnesium;

  /// No description provided for @microIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get microIron;

  /// No description provided for @microZinc.
  ///
  /// In en, this message translates to:
  /// **'Zinc'**
  String get microZinc;

  /// No description provided for @microPotassium.
  ///
  /// In en, this message translates to:
  /// **'Potassium'**
  String get microPotassium;

  /// No description provided for @microSodium.
  ///
  /// In en, this message translates to:
  /// **'Sodium'**
  String get microSodium;

  /// No description provided for @microB12.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B12'**
  String get microB12;

  /// No description provided for @microSelenium.
  ///
  /// In en, this message translates to:
  /// **'Selenium'**
  String get microSelenium;

  /// No description provided for @microVitE.
  ///
  /// In en, this message translates to:
  /// **'Vitamin E'**
  String get microVitE;

  /// No description provided for @microVitC.
  ///
  /// In en, this message translates to:
  /// **'Vitamin C'**
  String get microVitC;

  /// No description provided for @microVitA.
  ///
  /// In en, this message translates to:
  /// **'Vitamin A'**
  String get microVitA;

  /// No description provided for @microHintVitD.
  ///
  /// In en, this message translates to:
  /// **'Fatty fish, eggs, sunlight'**
  String get microHintVitD;

  /// No description provided for @microHintCalcium.
  ///
  /// In en, this message translates to:
  /// **'Dairy, sesame, greens'**
  String get microHintCalcium;

  /// No description provided for @microHintMagnesium.
  ///
  /// In en, this message translates to:
  /// **'Nuts, buckwheat, legumes'**
  String get microHintMagnesium;

  /// No description provided for @microHintIron.
  ///
  /// In en, this message translates to:
  /// **'Meat, liver, lentils'**
  String get microHintIron;

  /// No description provided for @microHintZinc.
  ///
  /// In en, this message translates to:
  /// **'Beef, lamb, pumpkin seeds'**
  String get microHintZinc;

  /// No description provided for @microHintPotassium.
  ///
  /// In en, this message translates to:
  /// **'Potatoes, bananas, legumes'**
  String get microHintPotassium;

  /// No description provided for @microHintSodium.
  ///
  /// In en, this message translates to:
  /// **'Bread, salted cheese, broths'**
  String get microHintSodium;

  /// No description provided for @microHintB12.
  ///
  /// In en, this message translates to:
  /// **'Beef, eggs, dairy'**
  String get microHintB12;

  /// No description provided for @microHintSelenium.
  ///
  /// In en, this message translates to:
  /// **'Fish, eggs, meat'**
  String get microHintSelenium;

  /// No description provided for @microHintVitE.
  ///
  /// In en, this message translates to:
  /// **'Nuts, seeds, vegetable oil'**
  String get microHintVitE;

  /// No description provided for @microHintVitC.
  ///
  /// In en, this message translates to:
  /// **'Peppers, citrus, pomegranate'**
  String get microHintVitC;

  /// No description provided for @microHintVitA.
  ///
  /// In en, this message translates to:
  /// **'Carrots, pumpkin, spinach'**
  String get microHintVitA;

  /// No description provided for @targetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your targets'**
  String get targetsTitle;

  /// No description provided for @targetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Based on your profile and the last 4 weeks of training'**
  String get targetsSubtitle;

  /// No description provided for @targetsGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get targetsGoal;

  /// No description provided for @targetsLoseFat.
  ///
  /// In en, this message translates to:
  /// **'Lose fat'**
  String get targetsLoseFat;

  /// No description provided for @targetsMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get targetsMaintain;

  /// No description provided for @targetsLeanBulk.
  ///
  /// In en, this message translates to:
  /// **'Lean bulk'**
  String get targetsLeanBulk;

  /// No description provided for @targetsBmr.
  ///
  /// In en, this message translates to:
  /// **'Base metabolism'**
  String get targetsBmr;

  /// No description provided for @targetsBmrFormula.
  ///
  /// In en, this message translates to:
  /// **'Mifflin-St Jeor · {weight} kg, {height} cm, {age} y'**
  String targetsBmrFormula(String weight, String height, String age);

  /// No description provided for @targetsActivity.
  ///
  /// In en, this message translates to:
  /// **'× {factor} activity'**
  String targetsActivity(String factor);

  /// No description provided for @targetsHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h training a week in FITRIX'**
  String targetsHours(String hours);

  /// No description provided for @targetsHoursEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated {hours} h a week: no workouts in the last 4 weeks'**
  String targetsHoursEstimated(String hours);

  /// No description provided for @targetsAdjLose.
  ///
  /// In en, this message translates to:
  /// **'−15% to lose fat'**
  String get targetsAdjLose;

  /// No description provided for @targetsAdjMaintain.
  ///
  /// In en, this message translates to:
  /// **'Keep your weight'**
  String get targetsAdjMaintain;

  /// No description provided for @targetsAdjBulk.
  ///
  /// In en, this message translates to:
  /// **'+10% lean bulk'**
  String get targetsAdjBulk;

  /// No description provided for @targetsDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily target'**
  String get targetsDaily;

  /// No description provided for @targetsProteinG.
  ///
  /// In en, this message translates to:
  /// **'Protein · {g} g'**
  String targetsProteinG(String g);

  /// No description provided for @targetsFatG.
  ///
  /// In en, this message translates to:
  /// **'Fat · {g} g'**
  String targetsFatG(String g);

  /// No description provided for @targetsCarbsG.
  ///
  /// In en, this message translates to:
  /// **'Carbs · {g} g'**
  String targetsCarbsG(String g);

  /// No description provided for @targetsPerKg.
  ///
  /// In en, this message translates to:
  /// **'{value} g per kg body weight'**
  String targetsPerKg(String value);

  /// No description provided for @targetsFatPerKg.
  ///
  /// In en, this message translates to:
  /// **'{value} g per kg, about {pct}% of kcal'**
  String targetsFatPerKg(String value, String pct);

  /// No description provided for @targetsCarbsNote.
  ///
  /// In en, this message translates to:
  /// **'The rest of the calories'**
  String get targetsCarbsNote;

  /// No description provided for @targetsAuto.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get targetsAuto;

  /// No description provided for @targetsSave.
  ///
  /// In en, this message translates to:
  /// **'Save targets'**
  String get targetsSave;

  /// No description provided for @progressOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get progressOverall;

  /// No description provided for @progressEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log a workout to see your load'**
  String get progressEmpty;

  /// No description provided for @progressLoadThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Load this week'**
  String get progressLoadThisWeek;

  /// No description provided for @progressLoadNote.
  ///
  /// In en, this message translates to:
  /// **'session RPE × min'**
  String get progressLoadNote;

  /// No description provided for @progressAu.
  ///
  /// In en, this message translates to:
  /// **'AU'**
  String get progressAu;

  /// No description provided for @progressPercentOfUsual.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of your usual'**
  String progressPercentOfUsual(int percent);

  /// No description provided for @progressFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get progressFitness;

  /// No description provided for @progressFatigue.
  ///
  /// In en, this message translates to:
  /// **'Fatigue'**
  String get progressFatigue;

  /// No description provided for @progressForm.
  ///
  /// In en, this message translates to:
  /// **'Form'**
  String get progressForm;

  /// No description provided for @progress42Day.
  ///
  /// In en, this message translates to:
  /// **'42-day load'**
  String get progress42Day;

  /// No description provided for @progress7Day.
  ///
  /// In en, this message translates to:
  /// **'7-day load'**
  String get progress7Day;

  /// No description provided for @progressEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated: some sessions use a default effort of 6'**
  String get progressEstimated;

  /// No description provided for @progressFormFresh.
  ///
  /// In en, this message translates to:
  /// **'Fresh'**
  String get progressFormFresh;

  /// No description provided for @progressFormNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get progressFormNeutral;

  /// No description provided for @progressFormTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get progressFormTired;

  /// No description provided for @progressRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get progressRecords;

  /// No description provided for @progressRecordsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get progressRecordsThisWeek;

  /// No description provided for @progressBalance.
  ///
  /// In en, this message translates to:
  /// **'Load balance'**
  String get progressBalance;

  /// No description provided for @progressBandLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get progressBandLow;

  /// No description provided for @progressBandSweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet spot'**
  String get progressBandSweet;

  /// No description provided for @progressBandRisky.
  ///
  /// In en, this message translates to:
  /// **'Risky'**
  String get progressBandRisky;

  /// No description provided for @progressBalanceLow.
  ///
  /// In en, this message translates to:
  /// **'Too little'**
  String get progressBalanceLow;

  /// No description provided for @progressBalanceSweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet spot 0.8–1.3'**
  String get progressBalanceSweet;

  /// No description provided for @progressBalanceRisky.
  ///
  /// In en, this message translates to:
  /// **'Risky'**
  String get progressBalanceRisky;

  /// No description provided for @progressFelixInsight.
  ///
  /// In en, this message translates to:
  /// **'Felix insight'**
  String get progressFelixInsight;

  /// No description provided for @progressInsightLow.
  ///
  /// In en, this message translates to:
  /// **'Your recent load is below your usual. Add one session this week to get back above 0.8.'**
  String get progressInsightLow;

  /// No description provided for @progressInsightSweet.
  ///
  /// In en, this message translates to:
  /// **'Your load is in the sweet spot. Keep the rhythm and add weight where sets feel easy.'**
  String get progressInsightSweet;

  /// No description provided for @progressInsightRisky.
  ///
  /// In en, this message translates to:
  /// **'Your load jumped above what you are used to. Keep the next sessions easier and sleep well.'**
  String get progressInsightRisky;

  /// No description provided for @progressLiftsE1rm.
  ///
  /// In en, this message translates to:
  /// **'Lifts · e1RM'**
  String get progressLiftsE1rm;

  /// No description provided for @progressBodyWeight.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get progressBodyWeight;

  /// No description provided for @loadTitle.
  ///
  /// In en, this message translates to:
  /// **'Training load'**
  String get loadTitle;

  /// No description provided for @loadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{sport} · session RPE × minutes'**
  String loadSubtitle(String sport);

  /// No description provided for @loadAllSports.
  ///
  /// In en, this message translates to:
  /// **'All sports'**
  String get loadAllSports;

  /// No description provided for @loadWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks'**
  String loadWeeks(int count);

  /// No description provided for @loadFitnessExplain.
  ///
  /// In en, this message translates to:
  /// **'Your 42-day average load. Goes up slowly when you train consistently.'**
  String get loadFitnessExplain;

  /// No description provided for @loadFatigueExplain.
  ///
  /// In en, this message translates to:
  /// **'Your 7-day load. Jumps after hard weeks and drops fast with rest.'**
  String get loadFatigueExplain;

  /// No description provided for @loadFormExplain.
  ///
  /// In en, this message translates to:
  /// **'Fitness minus fatigue. Positive means fresh: race, test or PR.'**
  String get loadFormExplain;

  /// No description provided for @loadByWeek.
  ///
  /// In en, this message translates to:
  /// **'By week'**
  String get loadByWeek;

  /// No description provided for @loadAvg.
  ///
  /// In en, this message translates to:
  /// **'AU · avg {value}'**
  String loadAvg(String value);

  /// No description provided for @loadThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This'**
  String get loadThisWeek;

  /// No description provided for @loadNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get loadNextWeek;

  /// No description provided for @loadAim.
  ///
  /// In en, this message translates to:
  /// **'Aim for about {value} AU, close to your recent weekly average.'**
  String loadAim(String value);

  /// No description provided for @loadChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not enough load yet'**
  String get loadChartEmpty;

  /// No description provided for @recordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsTitle;

  /// No description provided for @recordsSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} personal record} other{{count} personal records}} · {sports, plural, one{{sports} sport} other{{sports} sports}}'**
  String recordsSummary(int count, int sports);

  /// No description provided for @recordsAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get recordsAll;

  /// No description provided for @recordsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get recordsThisMonth;

  /// No description provided for @recordsBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get recordsBestStreak;

  /// No description provided for @recordsWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} week} other{{count} weeks}}'**
  String recordsWeeks(int count);

  /// No description provided for @recordsMonthCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} record} other{{count} records}}'**
  String recordsMonthCount(int count);

  /// No description provided for @recordsPr.
  ///
  /// In en, this message translates to:
  /// **'PR'**
  String get recordsPr;

  /// No description provided for @recordsE1rm.
  ///
  /// In en, this message translates to:
  /// **'{exercise} · e1RM {value}'**
  String recordsE1rm(String exercise, String value);

  /// No description provided for @recordsRepsLine.
  ///
  /// In en, this message translates to:
  /// **'{exercise} · {count, plural, one{{count} rep} other{{count} reps}}'**
  String recordsRepsLine(int count, String exercise);

  /// No description provided for @recordsGainWhen.
  ///
  /// In en, this message translates to:
  /// **'{gain} · {when}'**
  String recordsGainWhen(String gain, String when);

  /// No description provided for @recordsGainReps.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{+{count} rep} other{+{count} reps}}'**
  String recordsGainReps(int count);

  /// No description provided for @recordsToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get recordsToday;

  /// No description provided for @recordsYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get recordsYesterday;

  /// No description provided for @recordsDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String recordsDaysAgo(int count);

  /// No description provided for @recordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Beat a previous best in a workout and it shows up here.'**
  String get recordsEmpty;

  /// No description provided for @liftTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifts'**
  String get liftTitle;

  /// No description provided for @liftEstimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated 1RM · Epley'**
  String get liftEstimated;

  /// No description provided for @liftSince.
  ///
  /// In en, this message translates to:
  /// **'since {since} · best set {kg} × {reps} on {date}'**
  String liftSince(String date, String kg, String reps, String since);

  /// No description provided for @liftBestSet.
  ///
  /// In en, this message translates to:
  /// **'best set {kg} × {reps} on {date}'**
  String liftBestSet(String date, String kg, String reps);

  /// No description provided for @liftChartE1rm.
  ///
  /// In en, this message translates to:
  /// **'e1RM'**
  String get liftChartE1rm;

  /// No description provided for @liftChartTop.
  ///
  /// In en, this message translates to:
  /// **'Top set load'**
  String get liftChartTop;

  /// No description provided for @liftStrengthLevel.
  ///
  /// In en, this message translates to:
  /// **'Strength level'**
  String get liftStrengthLevel;

  /// No description provided for @liftLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get liftLevelBeginner;

  /// No description provided for @liftLevelNovice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get liftLevelNovice;

  /// No description provided for @liftLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get liftLevelIntermediate;

  /// No description provided for @liftLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get liftLevelAdvanced;

  /// No description provided for @liftLevelElite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get liftLevelElite;

  /// No description provided for @liftRatio.
  ///
  /// In en, this message translates to:
  /// **'{ratio} × body weight'**
  String liftRatio(String ratio);

  /// No description provided for @liftNextBand.
  ///
  /// In en, this message translates to:
  /// **'{level} at {ratio} × · {kg}'**
  String liftNextBand(String kg, String level, String ratio);

  /// No description provided for @liftTopBand.
  ///
  /// In en, this message translates to:
  /// **'Top level reached'**
  String get liftTopBand;

  /// No description provided for @liftNeedWeight.
  ///
  /// In en, this message translates to:
  /// **'Log your body weight to see your strength level.'**
  String get liftNeedWeight;

  /// No description provided for @liftNextSession.
  ///
  /// In en, this message translates to:
  /// **'Next session'**
  String get liftNextSession;

  /// No description provided for @liftReserve.
  ///
  /// In en, this message translates to:
  /// **'2 reps in reserve'**
  String get liftReserve;

  /// No description provided for @liftColSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get liftColSet;

  /// No description provided for @liftCol1rm.
  ///
  /// In en, this message translates to:
  /// **'%1RM'**
  String get liftCol1rm;

  /// No description provided for @liftColLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get liftColLoad;

  /// No description provided for @liftColReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get liftColReps;

  /// No description provided for @liftTopSet.
  ///
  /// In en, this message translates to:
  /// **'Top set'**
  String get liftTopSet;

  /// No description provided for @liftBackOff.
  ///
  /// In en, this message translates to:
  /// **'Back-off'**
  String get liftBackOff;

  /// No description provided for @liftVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get liftVolume;

  /// No description provided for @liftFelix.
  ///
  /// In en, this message translates to:
  /// **'Felix'**
  String get liftFelix;

  /// No description provided for @liftPaceUp.
  ///
  /// In en, this message translates to:
  /// **'Steady {kg} a week.'**
  String liftPaceUp(String kg);

  /// No description provided for @liftPaceTo.
  ///
  /// In en, this message translates to:
  /// **'Steady {kg} a week. At this pace you reach {ratio} × body weight around {date}.'**
  String liftPaceTo(String date, String kg, String ratio);

  /// No description provided for @liftPaceFlat.
  ///
  /// In en, this message translates to:
  /// **'Your e1RM has been flat lately. A lighter week, then push again.'**
  String get liftPaceFlat;

  /// No description provided for @liftNone.
  ///
  /// In en, this message translates to:
  /// **'Finish a workout with a weighted exercise to see your lifts here.'**
  String get liftNone;

  /// No description provided for @bodyPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{value} / wk'**
  String bodyPerWeek(String value);

  /// No description provided for @bodyTrendLine.
  ///
  /// In en, this message translates to:
  /// **'{weeks}-week trend · goal: {goal}'**
  String bodyTrendLine(String goal, int weeks);

  /// No description provided for @bodyTrendNone.
  ///
  /// In en, this message translates to:
  /// **'Not enough weigh-ins for a trend yet · goal: {goal}'**
  String bodyTrendNone(String goal);

  /// No description provided for @bodyGoalLoseFat.
  ///
  /// In en, this message translates to:
  /// **'lose fat −0.3 to −0.7 {unit} / wk'**
  String bodyGoalLoseFat(String unit);

  /// No description provided for @bodyGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'maintain ±0.2 {unit} / wk'**
  String bodyGoalMaintain(String unit);

  /// No description provided for @bodyGoalLeanBulk.
  ///
  /// In en, this message translates to:
  /// **'lean bulk +0.2 to +0.4 {unit} / wk'**
  String bodyGoalLeanBulk(String unit);

  /// No description provided for @bodyGoalNameLoseFat.
  ///
  /// In en, this message translates to:
  /// **'fat loss'**
  String get bodyGoalNameLoseFat;

  /// No description provided for @bodyGoalNameMaintain.
  ///
  /// In en, this message translates to:
  /// **'maintenance'**
  String get bodyGoalNameMaintain;

  /// No description provided for @bodyGoalNameLeanBulk.
  ///
  /// In en, this message translates to:
  /// **'lean bulk'**
  String get bodyGoalNameLeanBulk;

  /// No description provided for @bodyOffTrack.
  ///
  /// In en, this message translates to:
  /// **'Off track for {goal}'**
  String bodyOffTrack(String goal);

  /// No description provided for @bodyAdd.
  ///
  /// In en, this message translates to:
  /// **'Your trend is below your goal. Add about {kcal} kcal a day, mostly carbs around workouts.'**
  String bodyAdd(int kcal);

  /// No description provided for @bodyCut.
  ///
  /// In en, this message translates to:
  /// **'Your trend is above your goal. Cut about {kcal} kcal a day, mostly from fats and sweet drinks.'**
  String bodyCut(int kcal);

  /// No description provided for @bodyUpdateTargets.
  ///
  /// In en, this message translates to:
  /// **'Update my targets'**
  String get bodyUpdateTargets;

  /// No description provided for @bodyRange8.
  ///
  /// In en, this message translates to:
  /// **'8 weeks'**
  String get bodyRange8;

  /// No description provided for @bodyRange26.
  ///
  /// In en, this message translates to:
  /// **'6 months'**
  String get bodyRange26;

  /// No description provided for @bodyRange52.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get bodyRange52;

  /// No description provided for @bodyLegendTrend.
  ///
  /// In en, this message translates to:
  /// **'Trend'**
  String get bodyLegendTrend;

  /// No description provided for @bodyLegendWeighIns.
  ///
  /// In en, this message translates to:
  /// **'Weigh-ins'**
  String get bodyLegendWeighIns;

  /// No description provided for @bodyLegendGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal range'**
  String get bodyLegendGoal;

  /// No description provided for @bodyToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get bodyToday;

  /// No description provided for @bodyWeighIns.
  ///
  /// In en, this message translates to:
  /// **'Weigh-ins'**
  String get bodyWeighIns;

  /// No description provided for @bodyWeighInsNote.
  ///
  /// In en, this message translates to:
  /// **'morning, after the toilet'**
  String get bodyWeighInsNote;

  /// No description provided for @bodyLog.
  ///
  /// In en, this message translates to:
  /// **'Log today\'s weight'**
  String get bodyLog;

  /// No description provided for @bodySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s weight'**
  String get bodySheetTitle;

  /// No description provided for @bodySave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bodySave;

  /// No description provided for @bodyWeightRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a weight between 20 and 400 kg.'**
  String get bodyWeightRange;

  /// No description provided for @bodyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log your weight to see your trend.'**
  String get bodyEmpty;

  /// No description provided for @programsTitle.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programsTitle;

  /// No description provided for @programsEntrySub.
  ///
  /// In en, this message translates to:
  /// **'Ready-made plans for the next weeks'**
  String get programsEntrySub;

  /// No description provided for @programsActiveEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Active program'**
  String get programsActiveEyebrow;

  /// No description provided for @programsWeekOf.
  ///
  /// In en, this message translates to:
  /// **'Week {w} of {n}'**
  String programsWeekOf(int w, int n);

  /// No description provided for @programsNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {session} · {day} · {duration}'**
  String programsNext(String session, String day, String duration);

  /// No description provided for @programsNoneLeft.
  ///
  /// In en, this message translates to:
  /// **'No sessions left in this program'**
  String get programsNoneLeft;

  /// No description provided for @programsDoneOf.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} sessions done'**
  String programsDoneOf(int done, int total);

  /// No description provided for @programsOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get programsOpen;

  /// No description provided for @programsPickedEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Picked for you'**
  String get programsPickedEyebrow;

  /// No description provided for @programsPickedText.
  ///
  /// In en, this message translates to:
  /// **'{name} · {perWeek} days a week · {level}. A good fit for your goal and experience.'**
  String programsPickedText(String name, int perWeek, String level);

  /// No description provided for @programsFelixPick.
  ///
  /// In en, this message translates to:
  /// **'Felix pick'**
  String get programsFelixPick;

  /// No description provided for @programsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get programsFilterAll;

  /// No description provided for @programsGoalMuscle.
  ///
  /// In en, this message translates to:
  /// **'Muscle'**
  String get programsGoalMuscle;

  /// No description provided for @programsGoalStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get programsGoalStrength;

  /// No description provided for @programsGoalFatLoss.
  ///
  /// In en, this message translates to:
  /// **'Fat loss'**
  String get programsGoalFatLoss;

  /// No description provided for @programsLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get programsLevelBeginner;

  /// No description provided for @programsLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get programsLevelIntermediate;

  /// No description provided for @programsLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get programsLevelAdvanced;

  /// No description provided for @programsAtHome.
  ///
  /// In en, this message translates to:
  /// **'At home'**
  String get programsAtHome;

  /// No description provided for @programsDaysAWeek.
  ///
  /// In en, this message translates to:
  /// **'Days a week'**
  String get programsDaysAWeek;

  /// No description provided for @programsAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get programsAny;

  /// No description provided for @programsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} program} other{{n} programs}}'**
  String programsCount(int n);

  /// No description provided for @programsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{n}× / week'**
  String programsPerWeek(int n);

  /// No description provided for @programsWeeksMin.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, one{{weeks} week} other{{weeks} weeks}} · {min} min'**
  String programsWeeksMin(int weeks, int min);

  /// No description provided for @programsDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get programsDetails;

  /// No description provided for @programsEmptyFilter.
  ///
  /// In en, this message translates to:
  /// **'No program matches these filters.'**
  String get programsEmptyFilter;

  /// No description provided for @programTitle.
  ///
  /// In en, this message translates to:
  /// **'Program'**
  String get programTitle;

  /// No description provided for @programNotFound.
  ///
  /// In en, this message translates to:
  /// **'This program is not available.'**
  String get programNotFound;

  /// No description provided for @programLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get programLength;

  /// No description provided for @programPerWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get programPerWeekLabel;

  /// No description provided for @programSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get programSessionLabel;

  /// No description provided for @programWeeksShort.
  ///
  /// In en, this message translates to:
  /// **'{n} wk'**
  String programWeeksShort(int n);

  /// No description provided for @programYourWeek.
  ///
  /// In en, this message translates to:
  /// **'Your week'**
  String get programYourWeek;

  /// No description provided for @programClashes.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} clash} other{{n} clashes}}'**
  String programClashes(int n);

  /// No description provided for @programRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get programRest;

  /// No description provided for @programWorkoutsCount.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} workout} other{{n} workouts}}'**
  String programWorkoutsCount(int n);

  /// No description provided for @programRir.
  ///
  /// In en, this message translates to:
  /// **'RIR {n}'**
  String programRir(int n);

  /// No description provided for @programHowYouProgress.
  ///
  /// In en, this message translates to:
  /// **'How you progress'**
  String get programHowYouProgress;

  /// No description provided for @programFelixEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Felix adjusted it for you'**
  String get programFelixEyebrow;

  /// No description provided for @programFelixText.
  ///
  /// In en, this message translates to:
  /// **'Training days avoid {days} and the days right before and after it because of {what}. You can change the days when you start.'**
  String programFelixText(String days, String what);

  /// No description provided for @programAskFelix.
  ///
  /// In en, this message translates to:
  /// **'Ask Felix'**
  String get programAskFelix;

  /// No description provided for @programAskFelixDraft.
  ///
  /// In en, this message translates to:
  /// **'Is {name} a good program for me? Check it against my week.'**
  String programAskFelixDraft(String name);

  /// No description provided for @programStart.
  ///
  /// In en, this message translates to:
  /// **'Start program'**
  String get programStart;

  /// No description provided for @programStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Start {name}'**
  String programStartTitle(String name);

  /// No description provided for @programStartSub.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, one{{weeks} week} other{{weeks} weeks}} · ends {date}'**
  String programStartSub(int weeks, String date);

  /// No description provided for @programStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get programStartDate;

  /// No description provided for @programToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get programToday;

  /// No description provided for @programPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get programPickDate;

  /// No description provided for @programTrainingDays.
  ///
  /// In en, this message translates to:
  /// **'Training days'**
  String get programTrainingDays;

  /// No description provided for @programDaysPicked.
  ///
  /// In en, this message translates to:
  /// **'{n} of {total} picked'**
  String programDaysPicked(int n, int total);

  /// No description provided for @programClashTitle.
  ///
  /// In en, this message translates to:
  /// **'{day} is {title}'**
  String programClashTitle(String day, String title);

  /// No description provided for @programClashHit.
  ///
  /// In en, this message translates to:
  /// **'Training that day stacks two hard sessions. Pick another day.'**
  String get programClashHit;

  /// No description provided for @programClashNear.
  ///
  /// In en, this message translates to:
  /// **'A program day is right next to it. Keep your legs fresh before and after.'**
  String get programClashNear;

  /// No description provided for @programClashAvoid.
  ///
  /// In en, this message translates to:
  /// **'Program days stay clear of it, so you recover before and after.'**
  String get programClashAvoid;

  /// No description provided for @programStartWeights.
  ///
  /// In en, this message translates to:
  /// **'Start weights'**
  String get programStartWeights;

  /// No description provided for @programFromRecords.
  ///
  /// In en, this message translates to:
  /// **'from your records'**
  String get programFromRecords;

  /// No description provided for @programReplacePlan.
  ///
  /// In en, this message translates to:
  /// **'Replace my weekly plan'**
  String get programReplacePlan;

  /// No description provided for @programReplaceSub.
  ///
  /// In en, this message translates to:
  /// **'Runs and football stay, gym days switch'**
  String get programReplaceSub;

  /// No description provided for @programStartOn.
  ///
  /// In en, this message translates to:
  /// **'Start on {date}'**
  String programStartOn(String date);

  /// No description provided for @programReplacesActive.
  ///
  /// In en, this message translates to:
  /// **'This replaces your active program.'**
  String get programReplacesActive;

  /// No description provided for @programProgressSub.
  ///
  /// In en, this message translates to:
  /// **'Week {w} of {n} · started {date}'**
  String programProgressSub(int w, int n, String date);

  /// No description provided for @programDeloadNote.
  ///
  /// In en, this message translates to:
  /// **'Week {w} is a deload: do about half your usual sets.'**
  String programDeloadNote(int w);

  /// No description provided for @programTileSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get programTileSessions;

  /// No description provided for @programTileOnTime.
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get programTileOnTime;

  /// No description provided for @programTileRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get programTileRecords;

  /// No description provided for @programThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get programThisWeek;

  /// No description provided for @programWeekDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String programWeekDone(int done, int total);

  /// No description provided for @programNoSessionsWeek.
  ///
  /// In en, this message translates to:
  /// **'No program sessions this week.'**
  String get programNoSessionsWeek;

  /// No description provided for @programPlanned.
  ///
  /// In en, this message translates to:
  /// **'planned'**
  String get programPlanned;

  /// No description provided for @programMainLifts.
  ///
  /// In en, this message translates to:
  /// **'Main lifts'**
  String get programMainLifts;

  /// No description provided for @programTopSetKg.
  ///
  /// In en, this message translates to:
  /// **'top set, kg'**
  String get programTopSetKg;

  /// No description provided for @programColLift.
  ///
  /// In en, this message translates to:
  /// **'Lift'**
  String get programColLift;

  /// No description provided for @programColStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get programColStart;

  /// No description provided for @programColNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get programColNow;

  /// No description provided for @programColGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get programColGoal;

  /// No description provided for @programNextIncrease.
  ///
  /// In en, this message translates to:
  /// **'Next increase'**
  String get programNextIncrease;

  /// No description provided for @programNextIncreaseText.
  ///
  /// In en, this message translates to:
  /// **'You hit {sets} × {reps} on {lift} twice in a row. Next session: {kg} kg.'**
  String programNextIncreaseText(int sets, int reps, String lift, String kg);

  /// No description provided for @programNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active program'**
  String get programNoActive;

  /// No description provided for @programNoActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a program to get a plan for the next weeks.'**
  String get programNoActiveBody;

  /// No description provided for @programBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse programs'**
  String get programBrowse;

  /// No description provided for @programEnd.
  ///
  /// In en, this message translates to:
  /// **'End program'**
  String get programEnd;

  /// No description provided for @programEndTitle.
  ///
  /// In en, this message translates to:
  /// **'End this program?'**
  String get programEndTitle;

  /// No description provided for @programEndBody.
  ///
  /// In en, this message translates to:
  /// **'Your workouts and records stay. Its remaining sessions leave your plan.'**
  String get programEndBody;

  /// No description provided for @programKgReps.
  ///
  /// In en, this message translates to:
  /// **'{kg} kg × {reps}'**
  String programKgReps(String kg, int reps);

  /// No description provided for @coachAskFelix.
  ///
  /// In en, this message translates to:
  /// **'Ask Felix'**
  String get coachAskFelix;

  /// No description provided for @gymAskFirstDraft.
  ///
  /// In en, this message translates to:
  /// **'I\'m about to do my first {sport} workout. What should I focus on?'**
  String gymAskFirstDraft(String sport);

  /// No description provided for @gymAskBackDraft.
  ///
  /// In en, this message translates to:
  /// **'My last workout was {days, plural, one{{days} day} other{{days} days}} ago. How should I get back into training?'**
  String gymAskBackDraft(int days);

  /// No description provided for @recoveryAskDraft.
  ///
  /// In en, this message translates to:
  /// **'My readiness today is {score}% ({label}). Sleep {sleep}, soreness: {soreness}. How hard should I train today?'**
  String recoveryAskDraft(
      int score, String label, String sleep, String soreness);

  /// No description provided for @planAskDraft.
  ///
  /// In en, this message translates to:
  /// **'{a} on {aDay} and {b} on {bDay} are both hard. How should I arrange my week?'**
  String planAskDraft(String a, String aDay, String b, String bDay);

  /// No description provided for @progressAskDraft.
  ///
  /// In en, this message translates to:
  /// **'My training load this week is {week} and my load balance is {balance} ({band}). What should I do next week?'**
  String progressAskDraft(String week, String balance, String band);

  /// No description provided for @liftAskDraft.
  ///
  /// In en, this message translates to:
  /// **'My {lift} e1RM is {e1rm}. How do I keep it climbing?'**
  String liftAskDraft(String lift, String e1rm);

  /// No description provided for @bodyAskDraft.
  ///
  /// In en, this message translates to:
  /// **'My weight is {weight}, changing {trend} a week. My goal: {goal}. How should I change what I eat?'**
  String bodyAskDraft(String weight, String trend, String goal);

  /// No description provided for @nutritionAskDraft.
  ///
  /// In en, this message translates to:
  /// **'I have {kcal} kcal and {protein} g of protein left today. What should I eat for dinner?'**
  String nutritionAskDraft(String kcal, String protein);

  /// No description provided for @nutritionCantFindDraft.
  ///
  /// In en, this message translates to:
  /// **'Estimate the calories in: '**
  String get nutritionCantFindDraft;

  /// No description provided for @planEmptyBodyNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Set up your gym workouts for next week in one tap.'**
  String get planEmptyBodyNextWeek;

  /// No description provided for @programsPickedGoalText.
  ///
  /// In en, this message translates to:
  /// **'{name} · {perWeek} days a week · {level}. Matches your goal.'**
  String programsPickedGoalText(String name, int perWeek, String level);

  /// No description provided for @programsPickedLevelText.
  ///
  /// In en, this message translates to:
  /// **'{name} · {perWeek} days a week · {level}. Matches your experience.'**
  String programsPickedLevelText(String name, int perWeek, String level);

  /// No description provided for @programsStartEyebrow.
  ///
  /// In en, this message translates to:
  /// **'A place to start'**
  String get programsStartEyebrow;

  /// No description provided for @programsStartText.
  ///
  /// In en, this message translates to:
  /// **'{name} · {perWeek} days a week · {level}. Add your goal and experience in About me for a closer match.'**
  String programsStartText(String name, int perWeek, String level);

  /// No description provided for @programDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Program details'**
  String get programDetailsTooltip;

  /// No description provided for @nutritionKcalOver.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal over'**
  String nutritionKcalOver(String kcal);

  /// No description provided for @homeDoneForToday.
  ///
  /// In en, this message translates to:
  /// **'Done for today'**
  String get homeDoneForToday;

  /// No description provided for @homeNextSession.
  ///
  /// In en, this message translates to:
  /// **'Next: {day} · {title}'**
  String homeNextSession(String day, String title);

  /// No description provided for @homeNothingNext.
  ///
  /// In en, this message translates to:
  /// **'Nothing else planned yet'**
  String get homeNothingNext;

  /// No description provided for @chatFoodLogTo.
  ///
  /// In en, this message translates to:
  /// **'Log to {slot}'**
  String chatFoodLogTo(String slot);

  /// No description provided for @chatFoodItemMeta.
  ///
  /// In en, this message translates to:
  /// **'{grams} g · {kcal} kcal'**
  String chatFoodItemMeta(String grams, String kcal);

  /// No description provided for @chatFoodEstimateName.
  ///
  /// In en, this message translates to:
  /// **'≈ {name}'**
  String chatFoodEstimateName(String name);

  /// No description provided for @chatFoodEstimateNote.
  ///
  /// In en, this message translates to:
  /// **'≈ Felix estimate'**
  String get chatFoodEstimateNote;

  /// No description provided for @chatFoodTotal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal · {protein} g protein'**
  String chatFoodTotal(String kcal, String protein);

  /// No description provided for @chatFoodAdd.
  ///
  /// In en, this message translates to:
  /// **'Add to My nutrition · {kcal} kcal'**
  String chatFoodAdd(String kcal);

  /// No description provided for @chatFoodAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to {slot}'**
  String chatFoodAdded(String slot);

  /// No description provided for @chatActionWeightSetFirst.
  ///
  /// In en, this message translates to:
  /// **'Set your weight first'**
  String get chatActionWeightSetFirst;

  /// No description provided for @chatActionSetWeight.
  ///
  /// In en, this message translates to:
  /// **'Set weight'**
  String get chatActionSetWeight;

  /// No description provided for @gymDiscardAndStart.
  ///
  /// In en, this message translates to:
  /// **'Discard and start'**
  String get gymDiscardAndStart;

  /// No description provided for @chatActionWeightSet.
  ///
  /// In en, this message translates to:
  /// **'Update weight to {to} kg'**
  String chatActionWeightSet(String to);

  /// No description provided for @felixPlanBadge.
  ///
  /// In en, this message translates to:
  /// **'Felix plan'**
  String get felixPlanBadge;

  /// No description provided for @felixPlanTitleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} workout} other{{count} workouts}}'**
  String felixPlanTitleCount(int count);

  /// No description provided for @felixPlanAddToWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Add to My workouts'**
  String get felixPlanAddToWorkouts;

  /// No description provided for @felixPlanAddToToday.
  ///
  /// In en, this message translates to:
  /// **'Add to today’s plan'**
  String get felixPlanAddToToday;

  /// No description provided for @felixPlansSection.
  ///
  /// In en, this message translates to:
  /// **'From Felix'**
  String get felixPlansSection;

  /// No description provided for @felixChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Felix · {topic}'**
  String felixChatTitle(String topic);

  /// No description provided for @felixTopicNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get felixTopicNutrition;

  /// No description provided for @felixTopicRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get felixTopicRecovery;

  /// No description provided for @felixTopicApp.
  ///
  /// In en, this message translates to:
  /// **'App assistant'**
  String get felixTopicApp;

  /// No description provided for @felixTopicSubGym.
  ///
  /// In en, this message translates to:
  /// **'Strength, muscle, programs, technique'**
  String get felixTopicSubGym;

  /// No description provided for @felixTopicSubFitness.
  ///
  /// In en, this message translates to:
  /// **'HIIT, bodyweight, mobility, tests'**
  String get felixTopicSubFitness;

  /// No description provided for @felixTopicSubRunning.
  ///
  /// In en, this message translates to:
  /// **'Paces, plans, races'**
  String get felixTopicSubRunning;

  /// No description provided for @felixTopicSubCycling.
  ///
  /// In en, this message translates to:
  /// **'Power, FTP, climbs, routes'**
  String get felixTopicSubCycling;

  /// No description provided for @felixTopicSubFootball.
  ///
  /// In en, this message translates to:
  /// **'Match fitness, drills, injuries'**
  String get felixTopicSubFootball;

  /// No description provided for @felixTopicSubWinterSports.
  ///
  /// In en, this message translates to:
  /// **'Skiing at Amirsoy and Chimgan, safety'**
  String get felixTopicSubWinterSports;

  /// No description provided for @felixTopicSubNutrition.
  ///
  /// In en, this message translates to:
  /// **'Food log, macros, Uzbek dishes'**
  String get felixTopicSubNutrition;

  /// No description provided for @felixTopicSubRecovery.
  ///
  /// In en, this message translates to:
  /// **'Sleep, soreness, readiness, deloads'**
  String get felixTopicSubRecovery;

  /// No description provided for @felixTopicSubApp.
  ///
  /// In en, this message translates to:
  /// **'How FITRIX works, plans, habits'**
  String get felixTopicSubApp;

  /// No description provided for @felixTopicGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi! I’m Felix. Let’s talk {topic}.'**
  String felixTopicGreeting(String topic);

  /// No description provided for @felixTopicGreetingHint.
  ///
  /// In en, this message translates to:
  /// **'Ask anything or pick a question below.'**
  String get felixTopicGreetingHint;

  /// No description provided for @felixHubAiCoach.
  ///
  /// In en, this message translates to:
  /// **'AI coach'**
  String get felixHubAiCoach;

  /// No description provided for @felixHubIntro.
  ///
  /// In en, this message translates to:
  /// **'Training, recovery and food in one place. Ask in English, Русский, O‘zbekcha or Español.'**
  String get felixHubIntro;

  /// No description provided for @felixHubToday.
  ///
  /// In en, this message translates to:
  /// **'{title} today'**
  String felixHubToday(String title);

  /// No description provided for @felixHubRest.
  ///
  /// In en, this message translates to:
  /// **'Rest day today'**
  String get felixHubRest;

  /// No description provided for @felixHubDone.
  ///
  /// In en, this message translates to:
  /// **'Today’s session is done'**
  String get felixHubDone;

  /// No description provided for @felixHubNext.
  ///
  /// In en, this message translates to:
  /// **'{sport} on {weekday}'**
  String felixHubNext(String sport, String weekday);

  /// No description provided for @felixHubTopicsHeader.
  ///
  /// In en, this message translates to:
  /// **'Chat with Felix about'**
  String get felixHubTopicsHeader;

  /// No description provided for @felixHubTopicsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} topic} other{{count} topics}}'**
  String felixHubTopicsCount(int count);

  /// No description provided for @felixHubRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent chats'**
  String get felixHubRecent;

  /// No description provided for @felixHubSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get felixHubSeeAll;

  /// No description provided for @felixAllTopics.
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get felixAllTopics;

  /// No description provided for @felixSeesPlan.
  ///
  /// In en, this message translates to:
  /// **'Sees your plan, check-in and workouts'**
  String get felixSeesPlan;

  /// No description provided for @felixSeesNutrition.
  ///
  /// In en, this message translates to:
  /// **'Sees today’s food, targets and weight'**
  String get felixSeesNutrition;

  /// No description provided for @felixSeesRecovery.
  ///
  /// In en, this message translates to:
  /// **'Sees your check-in, sleep and training load'**
  String get felixSeesRecovery;

  /// No description provided for @felixChipReadiness.
  ///
  /// In en, this message translates to:
  /// **'Recovery {score}%'**
  String felixChipReadiness(int score);

  /// No description provided for @felixChipToday.
  ///
  /// In en, this message translates to:
  /// **'Today: {title}'**
  String felixChipToday(String title);

  /// No description provided for @felixChipRest.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get felixChipRest;

  /// No description provided for @felixChipLast.
  ///
  /// In en, this message translates to:
  /// **'Last: {name}'**
  String felixChipLast(String name);

  /// No description provided for @felixChipKcal.
  ///
  /// In en, this message translates to:
  /// **'{eaten} of {target} kcal'**
  String felixChipKcal(String eaten, String target);

  /// No description provided for @felixChipProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein {eaten} g'**
  String felixChipProtein(String eaten);

  /// No description provided for @felixAskAbout.
  ///
  /// In en, this message translates to:
  /// **'Ask Felix about {topic}'**
  String felixAskAbout(String topic);

  /// No description provided for @felixAskAboutApp.
  ///
  /// In en, this message translates to:
  /// **'Ask Felix about FITRIX'**
  String get felixAskAboutApp;

  /// No description provided for @felixPromptGym1.
  ///
  /// In en, this message translates to:
  /// **'How do I break my bench plateau?'**
  String get felixPromptGym1;

  /// No description provided for @felixPromptGym2.
  ///
  /// In en, this message translates to:
  /// **'Build me a 3-day split'**
  String get felixPromptGym2;

  /// No description provided for @felixPromptGym3.
  ///
  /// In en, this message translates to:
  /// **'Check my squat technique cues'**
  String get felixPromptGym3;

  /// No description provided for @felixPromptFitness1.
  ///
  /// In en, this message translates to:
  /// **'A 20-minute HIIT for today'**
  String get felixPromptFitness1;

  /// No description provided for @felixPromptFitness2.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight workout at home'**
  String get felixPromptFitness2;

  /// No description provided for @felixPromptFitness3.
  ///
  /// In en, this message translates to:
  /// **'Mobility routine for tight hips'**
  String get felixPromptFitness3;

  /// No description provided for @felixPromptRunning1.
  ///
  /// In en, this message translates to:
  /// **'What should my easy pace be?'**
  String get felixPromptRunning1;

  /// No description provided for @felixPromptRunning2.
  ///
  /// In en, this message translates to:
  /// **'Plan for my first 10K'**
  String get felixPromptRunning2;

  /// No description provided for @felixPromptRunning3.
  ///
  /// In en, this message translates to:
  /// **'How to avoid shin splints'**
  String get felixPromptRunning3;

  /// No description provided for @felixPromptCycling1.
  ///
  /// In en, this message translates to:
  /// **'How do I test my FTP?'**
  String get felixPromptCycling1;

  /// No description provided for @felixPromptCycling2.
  ///
  /// In en, this message translates to:
  /// **'Intervals for climbing'**
  String get felixPromptCycling2;

  /// No description provided for @felixPromptCycling3.
  ///
  /// In en, this message translates to:
  /// **'What to eat on a 3-hour ride'**
  String get felixPromptCycling3;

  /// No description provided for @felixPromptFootball1.
  ///
  /// In en, this message translates to:
  /// **'Warm-up before a match'**
  String get felixPromptFootball1;

  /// No description provided for @felixPromptFootball2.
  ///
  /// In en, this message translates to:
  /// **'Speed drills for this week'**
  String get felixPromptFootball2;

  /// No description provided for @felixPromptFootball3.
  ///
  /// In en, this message translates to:
  /// **'Legs the day after a match?'**
  String get felixPromptFootball3;

  /// No description provided for @felixPromptWinter1.
  ///
  /// In en, this message translates to:
  /// **'Leg prep for the ski season'**
  String get felixPromptWinter1;

  /// No description provided for @felixPromptWinter2.
  ///
  /// In en, this message translates to:
  /// **'Exercises for knee safety'**
  String get felixPromptWinter2;

  /// No description provided for @felixPromptWinter3.
  ///
  /// In en, this message translates to:
  /// **'Staying warm on the slopes'**
  String get felixPromptWinter3;

  /// No description provided for @felixPromptNutrition1.
  ///
  /// In en, this message translates to:
  /// **'What should I eat today?'**
  String get felixPromptNutrition1;

  /// No description provided for @felixPromptNutrition2.
  ///
  /// In en, this message translates to:
  /// **'How much protein do I need?'**
  String get felixPromptNutrition2;

  /// No description provided for @felixPromptNutrition3.
  ///
  /// In en, this message translates to:
  /// **'Is plov OK after training?'**
  String get felixPromptNutrition3;

  /// No description provided for @felixPromptRecovery1.
  ///
  /// In en, this message translates to:
  /// **'Should I train hard today?'**
  String get felixPromptRecovery1;

  /// No description provided for @felixPromptRecovery2.
  ///
  /// In en, this message translates to:
  /// **'How to sleep better'**
  String get felixPromptRecovery2;

  /// No description provided for @felixPromptRecovery3.
  ///
  /// In en, this message translates to:
  /// **'Where do legs fit this week?'**
  String get felixPromptRecovery3;

  /// No description provided for @felixPromptApp1.
  ///
  /// In en, this message translates to:
  /// **'How do I use the weekly plan?'**
  String get felixPromptApp1;

  /// No description provided for @felixPromptApp2.
  ///
  /// In en, this message translates to:
  /// **'How does the check-in work?'**
  String get felixPromptApp2;

  /// No description provided for @runNameMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning run'**
  String get runNameMorning;

  /// No description provided for @runNameAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon run'**
  String get runNameAfternoon;

  /// No description provided for @runNameEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening run'**
  String get runNameEvening;

  /// No description provided for @runNameNight.
  ///
  /// In en, this message translates to:
  /// **'Night run'**
  String get runNameNight;

  /// No description provided for @runNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording your run'**
  String get runNotificationTitle;

  /// No description provided for @runNotificationText.
  ///
  /// In en, this message translates to:
  /// **'FITRIX records distance and time while the screen is locked.'**
  String get runNotificationText;

  /// No description provided for @runNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Run recording'**
  String get runNotificationChannel;

  /// No description provided for @rideNameMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning ride'**
  String get rideNameMorning;

  /// No description provided for @rideNameAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon ride'**
  String get rideNameAfternoon;

  /// No description provided for @rideNameEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening ride'**
  String get rideNameEvening;

  /// No description provided for @rideNameNight.
  ///
  /// In en, this message translates to:
  /// **'Night ride'**
  String get rideNameNight;

  /// No description provided for @skiDayName.
  ///
  /// In en, this message translates to:
  /// **'Ski day'**
  String get skiDayName;

  /// No description provided for @rideNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording your ride'**
  String get rideNotificationTitle;

  /// No description provided for @rideNotificationText.
  ///
  /// In en, this message translates to:
  /// **'FITRIX records distance and time while the screen is locked.'**
  String get rideNotificationText;

  /// No description provided for @rideNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Ride recording'**
  String get rideNotificationChannel;

  /// No description provided for @skiNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Recording your ski day'**
  String get skiNotificationTitle;

  /// No description provided for @skiNotificationText.
  ///
  /// In en, this message translates to:
  /// **'FITRIX records distance and time while the screen is locked.'**
  String get skiNotificationText;

  /// No description provided for @skiNotificationChannel.
  ///
  /// In en, this message translates to:
  /// **'Ski day recording'**
  String get skiNotificationChannel;

  /// No description provided for @runVoiceHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String runVoiceHours(int count);

  /// No description provided for @runVoiceMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute} other{{count} minutes}}'**
  String runVoiceMinutes(int count);

  /// No description provided for @runVoiceSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 second} other{{count} seconds}}'**
  String runVoiceSeconds(int count);

  /// No description provided for @runVoicePace.
  ///
  /// In en, this message translates to:
  /// **'{time} per kilometre'**
  String runVoicePace(String time);

  /// No description provided for @runVoiceStart.
  ///
  /// In en, this message translates to:
  /// **'Run started.'**
  String get runVoiceStart;

  /// No description provided for @runVoicePause.
  ///
  /// In en, this message translates to:
  /// **'Paused.'**
  String get runVoicePause;

  /// No description provided for @runVoiceResume.
  ///
  /// In en, this message translates to:
  /// **'Resumed.'**
  String get runVoiceResume;

  /// No description provided for @runVoiceKm.
  ///
  /// In en, this message translates to:
  /// **'Kilometre {km}. Time {time}. Last kilometre {lastPace}. Average {avgPace}.'**
  String runVoiceKm(int km, String time, String lastPace, String avgPace);

  /// No description provided for @runVoiceFinish.
  ///
  /// In en, this message translates to:
  /// **'Run finished. {distance} kilometres in {time}. Average {avgPace}.'**
  String runVoiceFinish(String distance, String time, String avgPace);

  /// No description provided for @runVoiceFinishShort.
  ///
  /// In en, this message translates to:
  /// **'Run finished. {distance} kilometres in {time}.'**
  String runVoiceFinishShort(String distance, String time);

  /// No description provided for @runUnfinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'You have an unfinished run'**
  String get runUnfinishedTitle;

  /// No description provided for @runUnfinishedBody.
  ///
  /// In en, this message translates to:
  /// **'Resume it, or discard it and start {next}.'**
  String runUnfinishedBody(String next);

  /// No description provided for @runResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get runResume;

  /// No description provided for @runPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get runPause;

  /// No description provided for @runDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this run?'**
  String get runDiscardTitle;

  /// No description provided for @runDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Its distance and route will be lost.'**
  String get runDiscardBody;

  /// No description provided for @runDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get runDiscardAction;

  /// No description provided for @runDiscardRun.
  ///
  /// In en, this message translates to:
  /// **'Discard run'**
  String get runDiscardRun;

  /// No description provided for @runHoldToFinish.
  ///
  /// In en, this message translates to:
  /// **'Hold to finish'**
  String get runHoldToFinish;

  /// No description provided for @runLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off for FITRIX. Allow it in Settings to record a run.'**
  String get runLocationOff;

  /// No description provided for @runLocationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are off. Turn them on in Settings to record a run.'**
  String get runLocationServiceOff;

  /// No description provided for @runOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get runOpenSettings;

  /// No description provided for @runTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get runTime;

  /// No description provided for @runDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get runDistance;

  /// No description provided for @runPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get runPace;

  /// No description provided for @runAvgPace.
  ///
  /// In en, this message translates to:
  /// **'Avg pace'**
  String get runAvgPace;

  /// No description provided for @runUnitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get runUnitKm;

  /// No description provided for @runUnitPerKm.
  ///
  /// In en, this message translates to:
  /// **'/km'**
  String get runUnitPerKm;

  /// No description provided for @runPausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get runPausedLabel;

  /// No description provided for @runMovingTime.
  ///
  /// In en, this message translates to:
  /// **'Moving time'**
  String get runMovingTime;

  /// No description provided for @runElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation gain'**
  String get runElevation;

  /// No description provided for @runElevationValue.
  ///
  /// In en, this message translates to:
  /// **'{meters} m'**
  String runElevationValue(String meters);

  /// No description provided for @runElapsedLine.
  ///
  /// In en, this message translates to:
  /// **'{elapsed} total, {pauses}'**
  String runElapsedLine(String elapsed, String pauses);

  /// No description provided for @runPausesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{no pauses} =1{1 pause} other{{count} pauses}}'**
  String runPausesCount(int count);

  /// No description provided for @runSplits.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get runSplits;

  /// No description provided for @runRpeTitle.
  ///
  /// In en, this message translates to:
  /// **'How hard did it feel?'**
  String get runRpeTitle;

  /// No description provided for @runSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get runSave;

  /// No description provided for @runDeleteRun.
  ///
  /// In en, this message translates to:
  /// **'Delete run'**
  String get runDeleteRun;

  /// No description provided for @runDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this run?'**
  String get runDeleteTitle;

  /// No description provided for @runDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your history.'**
  String get runDeleteBody;

  /// No description provided for @runDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get runDeleteAction;

  /// No description provided for @runNoRoute.
  ///
  /// In en, this message translates to:
  /// **'No route recorded'**
  String get runNoRoute;

  /// No description provided for @runNotFound.
  ///
  /// In en, this message translates to:
  /// **'This run is no longer here.'**
  String get runNotFound;

  /// No description provided for @runStartRun.
  ///
  /// In en, this message translates to:
  /// **'Start run'**
  String get runStartRun;

  /// No description provided for @runThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get runThisWeek;

  /// No description provided for @runWeekRuns.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run} other{{count} runs}}'**
  String runWeekRuns(int count);

  /// No description provided for @runHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get runHistory;

  /// No description provided for @runHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No runs yet. The runs you record will show up here.'**
  String get runHistoryEmpty;

  /// No description provided for @runWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get runWorkouts;

  /// No description provided for @runBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Run in progress'**
  String get runBarTitle;

  /// No description provided for @runBarReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get runBarReturn;

  /// No description provided for @runUnfinishedLaunchTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfinished run · {distance} km'**
  String runUnfinishedLaunchTitle(String distance);

  /// No description provided for @runUnfinishedLaunchBody.
  ///
  /// In en, this message translates to:
  /// **'Pick it up where you left off, save what was recorded, or discard it.'**
  String get runUnfinishedLaunchBody;

  /// No description provided for @runFinishFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t finish the run. Try again.'**
  String get runFinishFailed;

  /// No description provided for @runGpsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS…'**
  String get runGpsWaiting;

  /// No description provided for @runGpsWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak GPS signal'**
  String get runGpsWeak;

  /// No description provided for @runGpsReduced.
  ///
  /// In en, this message translates to:
  /// **'Turn on Precise Location for accurate distance'**
  String get runGpsReduced;

  /// No description provided for @footballLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get footballLog;

  /// No description provided for @footballLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log football'**
  String get footballLogTitle;

  /// No description provided for @footballEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit football log'**
  String get footballEditTitle;

  /// No description provided for @footballTypeMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get footballTypeMatch;

  /// No description provided for @footballTypeTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get footballTypeTraining;

  /// No description provided for @footballDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get footballDate;

  /// No description provided for @footballFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get footballFormat;

  /// No description provided for @footballMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get footballMinutes;

  /// No description provided for @footballMinShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get footballMinShort;

  /// No description provided for @footballPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get footballPosition;

  /// No description provided for @footballPosGK.
  ///
  /// In en, this message translates to:
  /// **'GK'**
  String get footballPosGK;

  /// No description provided for @footballPosCB.
  ///
  /// In en, this message translates to:
  /// **'CB'**
  String get footballPosCB;

  /// No description provided for @footballPosFB.
  ///
  /// In en, this message translates to:
  /// **'FB'**
  String get footballPosFB;

  /// No description provided for @footballPosCM.
  ///
  /// In en, this message translates to:
  /// **'CM'**
  String get footballPosCM;

  /// No description provided for @footballPosWM.
  ///
  /// In en, this message translates to:
  /// **'WM'**
  String get footballPosWM;

  /// No description provided for @footballPosST.
  ///
  /// In en, this message translates to:
  /// **'ST'**
  String get footballPosST;

  /// No description provided for @footballResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get footballResult;

  /// No description provided for @footballScoreFor.
  ///
  /// In en, this message translates to:
  /// **'Us'**
  String get footballScoreFor;

  /// No description provided for @footballScoreAgainst.
  ///
  /// In en, this message translates to:
  /// **'Them'**
  String get footballScoreAgainst;

  /// No description provided for @footballGoals.
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get footballGoals;

  /// No description provided for @footballAssists.
  ///
  /// In en, this message translates to:
  /// **'Your assists'**
  String get footballAssists;

  /// No description provided for @footballNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get footballNote;

  /// No description provided for @footballSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get footballSave;

  /// No description provided for @footballDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete entry'**
  String get footballDelete;

  /// No description provided for @footballDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get footballDeleteTitle;

  /// No description provided for @footballDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from your history.'**
  String get footballDeleteBody;

  /// No description provided for @footballDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get footballDeleteAction;

  /// No description provided for @footballHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get footballHistory;

  /// No description provided for @footballHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No games logged yet. Log one after you play.'**
  String get footballHistoryEmpty;

  /// No description provided for @footballWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get footballWorkouts;

  /// No description provided for @healthFromSource.
  ///
  /// In en, this message translates to:
  /// **'from {source}'**
  String healthFromSource(String source);

  /// No description provided for @healthInBedFromSource.
  ///
  /// In en, this message translates to:
  /// **'in bed, from {source}'**
  String healthInBedFromSource(String source);

  /// No description provided for @healthSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Health data'**
  String get healthSectionTitle;

  /// No description provided for @healthRestingHr.
  ///
  /// In en, this message translates to:
  /// **'Resting heart rate'**
  String get healthRestingHr;

  /// No description provided for @healthHrv.
  ///
  /// In en, this message translates to:
  /// **'Heart rate variability'**
  String get healthHrv;

  /// No description provided for @healthSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get healthSteps;

  /// No description provided for @healthRestingHrValue.
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm'**
  String healthRestingHrValue(int bpm);

  /// No description provided for @healthRestingHrNormal.
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm · your normal {normal}'**
  String healthRestingHrNormal(int bpm, int normal);

  /// No description provided for @healthHrvValue.
  ///
  /// In en, this message translates to:
  /// **'{value} ms {kind}'**
  String healthHrvValue(int value, String kind);

  /// No description provided for @healthHrvNormal.
  ///
  /// In en, this message translates to:
  /// **'{value} ms {kind} · your normal {normal}'**
  String healthHrvNormal(int value, String kind, int normal);

  /// No description provided for @healthStepsDailyAvg.
  ///
  /// In en, this message translates to:
  /// **'Daily average: {avg}'**
  String healthStepsDailyAvg(int avg);

  /// No description provided for @healthStepsToday.
  ///
  /// In en, this message translates to:
  /// **'Steps today: {steps}'**
  String healthStepsToday(int steps);

  /// No description provided for @healthStepsTodayAvg.
  ///
  /// In en, this message translates to:
  /// **'Steps today: {steps} · 7-day avg {avg}'**
  String healthStepsTodayAvg(int steps, int avg);

  /// No description provided for @factorRestingHrHigh.
  ///
  /// In en, this message translates to:
  /// **'Resting heart rate above normal'**
  String get factorRestingHrHigh;

  /// No description provided for @factorRestingHrNormal.
  ///
  /// In en, this message translates to:
  /// **'Resting heart rate near normal'**
  String get factorRestingHrNormal;

  /// No description provided for @factorHrvLow.
  ///
  /// In en, this message translates to:
  /// **'HRV below normal'**
  String get factorHrvLow;

  /// No description provided for @factorHrvNormal.
  ///
  /// In en, this message translates to:
  /// **'HRV near normal'**
  String get factorHrvNormal;

  /// No description provided for @factorHrvHigh.
  ///
  /// In en, this message translates to:
  /// **'HRV above normal'**
  String get factorHrvHigh;

  /// No description provided for @importedFromHealth.
  ///
  /// In en, this message translates to:
  /// **'From {health}'**
  String importedFromHealth(String health);

  /// No description provided for @importedAvgHr.
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm avg'**
  String importedAvgHr(int bpm);

  /// No description provided for @importedDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this workout?'**
  String get importedDeleteTitle;

  /// No description provided for @importedDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete workout'**
  String get importedDelete;

  /// No description provided for @connectedAppsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'From {health} · last 7 days'**
  String connectedAppsSummaryTitle(String health);

  /// No description provided for @connectedAppsSummarySteps.
  ///
  /// In en, this message translates to:
  /// **'Days with steps'**
  String get connectedAppsSummarySteps;

  /// No description provided for @connectedAppsSummarySleep.
  ///
  /// In en, this message translates to:
  /// **'Nights with sleep'**
  String get connectedAppsSummarySleep;

  /// No description provided for @connectedAppsSummaryRhr.
  ///
  /// In en, this message translates to:
  /// **'Days with resting HR'**
  String get connectedAppsSummaryRhr;

  /// No description provided for @connectedAppsSummaryHrv.
  ///
  /// In en, this message translates to:
  /// **'Days with HRV'**
  String get connectedAppsSummaryHrv;

  /// No description provided for @connectedAppsSummaryWeight.
  ///
  /// In en, this message translates to:
  /// **'Weigh-ins from {health}'**
  String connectedAppsSummaryWeight(String health);

  /// No description provided for @connectedAppsSummaryImported.
  ///
  /// In en, this message translates to:
  /// **'Workouts from {health}'**
  String connectedAppsSummaryImported(String health);

  /// No description provided for @connectedAppsSummaryWritten.
  ///
  /// In en, this message translates to:
  /// **'Workouts saved to {health}'**
  String connectedAppsSummaryWritten(String health);

  /// No description provided for @connectedAppsSummaryHintIos.
  ///
  /// In en, this message translates to:
  /// **'No watch data yet — a watch (Apple Watch, Garmin, WHOOP, Mi Band) adds sleep, heart rate and workouts.'**
  String get connectedAppsSummaryHintIos;

  /// No description provided for @connectedAppsSummaryHintAndroid.
  ///
  /// In en, this message translates to:
  /// **'No watch data yet — a watch (Garmin, WHOOP, Mi Band) adds sleep, heart rate and workouts.'**
  String get connectedAppsSummaryHintAndroid;

  /// No description provided for @rideVoiceStart.
  ///
  /// In en, this message translates to:
  /// **'Ride started.'**
  String get rideVoiceStart;

  /// No description provided for @rideVoiceDistance.
  ///
  /// In en, this message translates to:
  /// **'{km} kilometres. Time {time}. Last 5 kilometres {lastSpeed} kilometres per hour. Average {avgSpeed}.'**
  String rideVoiceDistance(
      String km, String time, String lastSpeed, String avgSpeed);

  /// No description provided for @rideVoiceFinish.
  ///
  /// In en, this message translates to:
  /// **'Ride finished. {distance} kilometres in {time}.'**
  String rideVoiceFinish(String distance, String time);

  /// No description provided for @skiVoiceStart.
  ///
  /// In en, this message translates to:
  /// **'Ski day started.'**
  String get skiVoiceStart;

  /// No description provided for @skiVoiceDescent.
  ///
  /// In en, this message translates to:
  /// **'Descent {index}. Distance {distance} km, vertical drop {vertical} metres, top speed {topSpeed} kilometres per hour.'**
  String skiVoiceDescent(
      int index, String distance, int vertical, String topSpeed);

  /// No description provided for @skiVoiceFinish.
  ///
  /// In en, this message translates to:
  /// **'Ski day finished. {distance} kilometres of descents in {time}.'**
  String skiVoiceFinish(String distance, String time);

  /// No description provided for @activitySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout settings'**
  String get activitySettingsTitle;

  /// No description provided for @activitySettingsVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get activitySettingsVoice;

  /// No description provided for @activitySettingsVoiceRun.
  ///
  /// In en, this message translates to:
  /// **'Speaks the start, every kilometre and the finish.'**
  String get activitySettingsVoiceRun;

  /// No description provided for @activitySettingsVoiceRide.
  ///
  /// In en, this message translates to:
  /// **'Speaks the start, every 5 km and the finish.'**
  String get activitySettingsVoiceRide;

  /// No description provided for @activitySettingsVoiceSki.
  ///
  /// In en, this message translates to:
  /// **'Speaks the start, each descent and the finish.'**
  String get activitySettingsVoiceSki;

  /// No description provided for @unitKmh.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get unitKmh;

  /// No description provided for @rideSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get rideSpeed;

  /// No description provided for @rideAvgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg speed'**
  String get rideAvgSpeed;

  /// No description provided for @rideMaxSpeed.
  ///
  /// In en, this message translates to:
  /// **'Max speed'**
  String get rideMaxSpeed;

  /// No description provided for @rideAvgPower.
  ///
  /// In en, this message translates to:
  /// **'Avg power, W'**
  String get rideAvgPower;

  /// No description provided for @skiStateDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get skiStateDescending;

  /// No description provided for @skiStateLift.
  ///
  /// In en, this message translates to:
  /// **'On a lift'**
  String get skiStateLift;

  /// No description provided for @skiStateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get skiStateStopped;

  /// No description provided for @skiDescents.
  ///
  /// In en, this message translates to:
  /// **'Descents'**
  String get skiDescents;

  /// No description provided for @skiVerticalDown.
  ///
  /// In en, this message translates to:
  /// **'Vertical down, m'**
  String get skiVerticalDown;

  /// No description provided for @skiTimeOnSlopes.
  ///
  /// In en, this message translates to:
  /// **'Time on slopes'**
  String get skiTimeOnSlopes;

  /// No description provided for @skiDistance.
  ///
  /// In en, this message translates to:
  /// **'Ski distance, km'**
  String get skiDistance;

  /// No description provided for @skiAvgDescentSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg descent speed'**
  String get skiAvgDescentSpeed;

  /// No description provided for @skiLifts.
  ///
  /// In en, this message translates to:
  /// **'Lifts'**
  String get skiLifts;

  /// No description provided for @skiDescentN.
  ///
  /// In en, this message translates to:
  /// **'Descent {n}'**
  String skiDescentN(int n);

  /// No description provided for @skiDescentDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get skiDescentDuration;

  /// No description provided for @skiDescentVertical.
  ///
  /// In en, this message translates to:
  /// **'Vertical drop, m'**
  String get skiDescentVertical;

  /// No description provided for @rideElevationLoss.
  ///
  /// In en, this message translates to:
  /// **'Elevation loss'**
  String get rideElevationLoss;
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
