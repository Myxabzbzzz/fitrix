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
<<<<<<< HEAD
<<<<<<< HEAD
  String get homeToday => 'Bugun';

  @override
  String homeTodayMeta(int count, int minutes) {
    return '$count mashq · taxminan $minutes daq';
  }

  @override
  String get homeStart => 'Boshlash';

  @override
  String get homeContinue => 'Davom etish';

  @override
  String get progressTitle => 'Mening yutuqlarim';

  @override
  String get progressStrength => 'Kuch';

  @override
  String progressNoWorkouts(String sport) {
    return 'Hozircha $sport mashg‘ulotlari yo‘q. Kamida bitta yondashuvni belgilab, birini yakunlang — yutuqlaringiz shu yerda ko‘rinadi.';
  }

  @override
  String get progressRecentWorkouts => 'So‘nggi mashg‘ulotlar';

  @override
  String get progressBody => 'Tana';

  @override
  String get progressSampleNote =>
      'Namunaviy ma’lumotlar — kuzatuv tez orada qo‘shiladi.';

  @override
  String progressFirst(String value) {
    return 'Birinchi: $value';
  }

  @override
  String progressLatest(String value) {
    return 'Oxirgi: $value';
  }

  @override
  String progressCurrent(String value) {
    return 'Hozir: $value';
  }

  @override
  String progressMonthAgo(String value) {
    return 'Bir oy oldin: $value';
  }

  @override
  String get progressIntake => 'Iste’mol, o‘rtacha';

  @override
  String get progressBurn => 'Sarf, o‘rtacha';

  @override
  String get progressKcalPerDay => 'kkal / kun';

  @override
  String progressSets(String count) {
    return '$count yondashuv';
  }

  @override
  String get nutritionTitle => 'Mening ovqatlanishim';

  @override
  String nutritionOfGoal(String goal) {
    return '$goal kkaldan';
  }

  @override
  String nutritionLeft(String kcal) {
    return 'Bugun $kcal kkal qoldi';
  }

  @override
  String get nutritionGoalReached => 'Bugungi maqsadga erishildi';

  @override
  String get nutritionProtein => 'Oqsil';

  @override
  String get nutritionCarbs => 'Uglevodlar';

  @override
  String get nutritionFat => 'Yog‘lar';

  @override
  String get nutritionBreakfast => 'Nonushta';

  @override
  String get nutritionBreakfastItems => 'Suli bo‘tqasi, banan, qahva';

  @override
  String get nutritionLunch => 'Tushlik';

  @override
  String get nutritionLunchItems => 'Tovuq, guruch, salat';

  @override
  String get nutritionSnack => 'Gazak';

  @override
  String get nutritionSnackItems => 'Yogurt va yong‘oq';

  @override
  String get nutritionDinner => 'Kechki ovqat';

  @override
  String get nutritionNotLogged => 'Hali kiritilmagan';

  @override
  String nutritionKcal(String kcal) {
    return '$kcal kkal';
  }

  @override
  String get nutritionTipEyebrow => 'Felix maslahati';

  @override
  String get nutritionTipTitle => 'Kechki ovqatda oqsil';

  @override
  String get nutritionTipMessage =>
      'Kechki ovqatga taxminan 40 g oqsil oling. Tovuq, guruch va ko‘kat rejangizga mos.';
=======
  String get profileTitle => 'Profil';

  @override
  String get profileWorkouts => 'mashg‘ulot';

  @override
  String get profileDayStreak => 'kun ketma-ket';

  @override
  String get profileKgNow => 'kg hozir';

  @override
  String get profileLanguage => 'Til';

  @override
  String get profileTheme => 'Mavzu';

  @override
  String get profileThemeAuto => 'Avto';

  @override
  String get profileThemeLight => 'Yorug‘';

  @override
  String get profileThemeDark => 'Qorong‘i';
>>>>>>> t10
=======
  String get chatQuickPlanWeek => 'Haftamni rejalashtir';

  @override
  String get chatQuickEatToday => 'Bugun nima yeyishim kerak?';

  @override
  String get chatQuickTired => 'Bugun o\'zimni charchagan his qilyapman';
>>>>>>> t9
}
