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
