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
