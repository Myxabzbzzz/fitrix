// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get continueButton => 'Davom etish';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get introStart => 'Yo‘lni boshlash';

  @override
  String get aboutMeTitle => 'Men haqimda';

  @override
  String get age => 'Yosh';

  @override
  String get weight => 'Vazn';

  @override
  String get height => 'Bo‘y';

  @override
  String get unitKg => 'kg';

  @override
  String get unitCm => 'sm';

  @override
  String get signOut => 'Chiqish';

  @override
  String get signOutTitle => 'Hisobdan chiqasizmi?';

  @override
  String get signOutLocalBody =>
      'Profilingiz, chatlar va mashg‘ulotlar faqat shu qurilmada saqlanadi va o‘chiriladi.';

  @override
  String get signOutAccountBody =>
      'Profilingiz, mashg‘ulotlar va chatlar hisobingizda saqlangan va shu qurilmadan o‘chiriladi. Ularni qaytarish uchun o‘sha email bilan kiring.';

  @override
  String get deleteAccount => 'Hisobni o‘chirish';

  @override
  String get deleteAccountTitle => 'Hisob o‘chirilsinmi?';

  @override
  String get deleteAccountBody =>
      'FITRIX hisobingiz va undagi hamma narsa butunlay o‘chiriladi: profil, mashg‘ulot rejalari, mashg‘ulotlar tarixi va Felix bilan chatlar — barcha qurilmalaringizda.';

  @override
  String get deleteAccountAppleNote => 'Apple tasdiqlashni so‘raydi.';

  @override
  String get deleteForGoodTitle => 'Butunlay o‘chirilsinmi?';

  @override
  String get deleteForGoodBody => 'O‘chirilgan hisobni tiklab bo‘lmaydi.';

  @override
  String get deletingAccount => 'Hisob o‘chirilmoqda…';

  @override
  String deleteAccountFailed(String reason) {
    return 'Hisobni o‘chirib bo‘lmadi. $reason';
  }

  @override
  String get undo => 'Qaytarish';

  @override
  String workoutDeleted(String name) {
    return '“$name” o‘chirildi';
  }

  @override
  String get syncFailed =>
      'Sinxronlab bo‘lmadi. Internetni tekshirib, qayta urinib ko‘ring.';

  @override
  String get mapTitle => 'Fitrix xaritasi';

  @override
  String get mapFilterAll => 'Hammasi';

  @override
  String get mapFilterGyms => 'Zallar';

  @override
  String get mapFilterParks => 'Bog‘lar';

  @override
  String get mapFilterTracks => 'Yo‘laklar';

  @override
  String get mapFilterPools => 'Basseynlar';

  @override
  String get mapLocationOff =>
      'Joylashuv o‘chiq: Toshkent markazi ko‘rsatilmoqda';

  @override
  String get mapHoursUnknown => 'Ish vaqti ko‘rsatilmagan';

  @override
  String mapAway(String distance) {
    return '$distance uzoqlikda';
  }

  @override
  String get mapShowRoute => 'Marshrutni ko‘rsatish';

  @override
  String get mapHideRoute => 'Marshrutni yashirish';

  @override
  String get mapModesLabel => 'Qanday borish mumkin';

  @override
  String get mapModeWalk => 'Piyoda';

  @override
  String get mapModeBike => 'Velosiped';

  @override
  String get mapModeCar => 'Avto';

  @override
  String get mapModeMetro => 'Metro';

  @override
  String get mapComputing => 'Marshrutlar hisoblanmoqda…';

  @override
  String get mapCoverage => 'Marshrutlar faqat Toshkent markazini qamrab oladi';

  @override
  String get mapNoRoute => 'Bu usul uchun marshrut yo‘q';

  @override
  String get mapMetroNoHelp =>
      'Bu safarda metro yordam bermaydi: vaqtni tejaydigan bekatlar juftligi yo‘q.';

  @override
  String get mapPlanFailed =>
      'Marshrutlarni hisoblab bo‘lmadi. Boshqa joyni tanlang.';

  @override
  String mapMinutes(int n) {
    return '$n daq';
  }

  @override
  String mapHoursMinutes(int h, int m) {
    return '$h soat $m daq';
  }

  @override
  String mapArrive(String duration, String time) {
    return '$duration · yetib borish $time';
  }

  @override
  String mapRide(String from, String to, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bekat',
      one: '$count bekat',
    );
    return '$from → $to, $_temp0';
  }

  @override
  String mapWalkTotal(String distance) {
    return 'Jami piyoda: $distance';
  }

  @override
  String get mapWalkingFaster => 'bu yerda piyoda tezroq';

  @override
  String mapNoteWalk(String distance) {
    return '$distance piyoda';
  }

  @override
  String mapNoteBike(String distance) {
    return '$distance velosipedda, yo‘lakchalar bilan';
  }

  @override
  String mapNoteCar(String distance) {
    return '$distance avtoda, tirbandliksiz, to‘xtash uchun 2 daq';
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
