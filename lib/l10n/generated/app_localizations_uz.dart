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

  @override
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

  @override
  String get chatQuickPlanWeek => 'Haftamni rejalashtir';

  @override
  String get chatQuickEatToday => 'Bugun nima yeyishim kerak?';

  @override
  String get chatQuickTired => 'Bugun o‘zimni charchagan his qilyapman';

  @override
  String get gymToday => 'Bugun';

  @override
  String get gymStart => 'Boshlash';

  @override
  String get gymDone => 'Tayyor';

  @override
  String get gymAskFelix => 'So‘rash';

  @override
  String gymCoachEyebrow(String sport) {
    return 'AI TRENER: $sport';
  }

  @override
  String gymTileCaption(int plans, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      plans,
      locale: localeName,
      other: '$plans reja',
      one: '$plans reja',
    );
    return '$_temp0 · shu hafta: $week';
  }

  @override
  String get discoverTitle => 'Kashf etish';

  @override
  String get discoverNotifications => 'Bildirishnomalar';

  @override
  String get discoverNoNotifications => 'Yangi bildirishnomalar yo‘q';

  @override
  String get discoverForYou => 'Siz uchun';

  @override
  String get discoverChallenges => 'Chellenjlar';

  @override
  String get discoverPrograms => 'Dasturlar';

  @override
  String get discoverArticles => 'Maqolalar';

  @override
  String get discoverThisWeek => 'Shu hafta';

  @override
  String get discoverJoin => 'Qatnashish';

  @override
  String get discoverJoined => 'Qatnashyapsiz';

  @override
  String get discoverSignInToJoin =>
      'Chellenjlarda qatnashish uchun hisobga kiring';

  @override
  String get discoverSignIn => 'Kirish';

  @override
  String get discoverJoinFailed => 'Qo‘shilib bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get discoverProgramsForYou => 'Siz uchun dasturlar';

  @override
  String get discoverAll => 'Hammasi';

  @override
  String discoverProgramSoon(String title) {
    return '$title: tez orada ko‘rib chiqish mumkin';
  }

  @override
  String get discoverFelixEyebrow => 'Felixdan maslahat';

  @override
  String get discoverFelixTitle => 'Dam olish kuchli qiladi';

  @override
  String get discoverFelixMessage =>
      'Haftada ikki yengil kun jarohat xavfini kamaytiradi va yuklarni oshirishga yordam beradi.';

  @override
  String get discoverAskFelix => 'Felixdan so‘rash';

  @override
  String get discoverRead => 'O‘qish';

  @override
  String discoverMinRead(int n) {
    return '$n daqiqa o‘qish';
  }

  @override
  String get discoverArticleMissing => 'Bu maqola mavjud emas.';

  @override
  String get shopTitle => 'Do‘kon';

  @override
  String shopCartLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Savat, $n mahsulot',
      one: 'Savat, $n mahsulot',
      zero: 'Savat bo‘sh',
    );
    return '$_temp0';
  }

  @override
  String get shopSearchHint => 'Mahsulot qidirish';

  @override
  String get shopAll => 'Hammasi';

  @override
  String get shopCatSupplements => 'Qo‘shimchalar';

  @override
  String get shopCatEquipment => 'Jihozlar';

  @override
  String get shopCatApparel => 'Kiyim';

  @override
  String get shopProBlurb =>
      'Felix bilan cheksiz suhbat, shaxsiy rejalar va texnika tahlili.';

  @override
  String get shopProButton => 'Batafsil';

  @override
  String get shopProSoonTitle => 'FITRIX Pro tez orada';

  @override
  String get shopProSoonBody => 'Tayyor bo‘lishi bilan xabar beramiz.';

  @override
  String get shopGotIt => 'Tushunarli';

  @override
  String shopNothingFound(String query) {
    return '“$query” bo‘yicha hech narsa topilmadi.';
  }

  @override
  String shopAdd(String name) {
    return 'Qo‘shish: $name';
  }

  @override
  String get shopCartTitle => 'Savat';

  @override
  String get shopClose => 'Yopish';

  @override
  String get shopRemoveOne => 'Bittasini olib tashlash';

  @override
  String get shopAddOne => 'Bittasini qo‘shish';

  @override
  String get shopTotal => 'Jami';

  @override
  String get shopPlaceOrder => 'Buyurtma berish';

  @override
  String get shopCartEmpty =>
      'Savat bo‘sh. Mahsulotni qo‘shish uchun + tugmasini bosing.';

  @override
  String get shopOrderPlaced => 'Buyurtma qabul qilindi';

  @override
  String get shopSignInToOrder => 'Buyurtma berish uchun hisobga kiring';

  @override
  String get shopOrderFailed =>
      'Buyurtma berib bo‘lmadi. Internetni tekshiring.';

  @override
  String shopOrderRejected(String message) {
    return 'Buyurtma rad etildi: $message';
  }

  @override
  String get shopRetry => 'Qayta urinish';

  @override
  String get shopNoProducts => 'Hozircha mahsulotlar yo‘q';

  @override
  String workoutSetsProgress(int done, int total) {
    return '$done / $total yondashuv';
  }

  @override
  String workoutSetCount(int n) {
    return '$n yondashuv';
  }

  @override
  String workoutSetDone(int n) {
    return '$n-yondashuv bajarildi';
  }

  @override
  String get workoutFinishTitle => 'Mashg‘ulotni yakunlaysizmi?';

  @override
  String get workoutFinishNoSets =>
      'Birorta yondashuv belgilanmagan, shuning uchun mashg‘ulot saqlanmaydi.';

  @override
  String workoutFinishSummary(int done, int total) {
    return '$total yondashuvdan $done tasi bajarildi. Mashg‘ulot tarixingizga saqlanadi.';
  }

  @override
  String get workoutKeepGoing => 'Davom etish';

  @override
  String get workoutFinish => 'Yakunlash';

  @override
  String get workoutSaved =>
      'Mashg‘ulot “Mening yutuqlarim” bo‘limiga saqlandi';

  @override
  String get workoutNoExercises =>
      'Hozircha mashqlar yo‘q. Mashg‘ulot kartasidagi “Tahrirlash” orqali qo‘shing.';

  @override
  String get workoutAddSet => 'Yondashuv qo‘shish';

  @override
  String get workoutFinishButton => 'Mashg‘ulotni yakunlash';

  @override
  String get workoutColSet => 'Yond.';

  @override
  String get workoutColPrevious => 'Oldingi';

  @override
  String get workoutColKg => 'Kg';

  @override
  String get workoutColReps => 'Takror';

  @override
  String get gymCoachFirstTitle => 'Birinchi mashg‘ulotga tayyormisiz?';

  @override
  String gymCoachFirstMessage(String workout) {
    return '$workout bilan boshlang. Undan keyin Felix rejani moslashtiradi.';
  }

  @override
  String get gymCoachBackTitle => 'Qaytganingiz bilan';

  @override
  String gymCoachBackMessage(int days) {
    return 'Oxirgi mashg‘ulotingiz $days kun oldin bo‘lgan. Bugungi yengil mashg‘ulot sizni izga qaytaradi.';
  }

  @override
  String get gymFinishCurrentTitle => 'Joriy mashg‘ulotni yakunlaysizmi?';

  @override
  String gymFinishCurrentBody(String current, String next) {
    return '“$current” hali davom etmoqda. Uning o‘rniga “$next” ni boshlaysizmi?';
  }

  @override
  String get gymMyWorkouts => 'Mening mashg‘ulotlarim';

  @override
  String get gymNewWorkout => 'Yangi mashg‘ulot';

  @override
  String get gymNewWorkoutHint => 'masalan, Yelkalar';

  @override
  String get gymAdd => 'Qo‘shish';

  @override
  String get gymEditNameHint => 'Mashg‘ulot nomi';

  @override
  String get gymEditDelete => 'Mashg‘ulotni o‘chirish';

  @override
  String get gymEditAddExerciseHint => 'Mashq qo‘shish';

  @override
  String get gymEditSave => 'Saqlash';

  @override
  String get sportGym => 'Sport zali';

  @override
  String get sportFitness => 'Fitnes';

  @override
  String get sportCycling => 'Velosport';

  @override
  String get sportRunning => 'Yugurish';

  @override
  String get sportFootball => 'Futbol';

  @override
  String get sportWinterSports => 'Qishki sport turlari';

  @override
  String get sportWinterSportsTile => 'QISHKI\nSPORT';

  @override
  String get tabDiscover => 'Kashfiyot';

  @override
  String get tabShop => 'Do‘kon';

  @override
  String get tabHome => 'Bosh sahifa';

  @override
  String get tabFelix => 'Felix';

  @override
  String get tabProfile => 'Profil';

  @override
  String get homeTileProgress => 'MENING\nYUTUQLARIM';

  @override
  String get homeTileNutrition => 'MENING\nOVQATIM';

  @override
  String get homeTileWorkouts => 'MENING\nMASHQLARIM';

  @override
  String get homeTileShop => 'DO‘KON';

  @override
  String get homeTileMap => 'FITRIX\nXARITASI';

  @override
  String get homeMenuNutrition => 'Mening ovqatim';

  @override
  String get homeMenuMap => 'Fitrix xaritasi';

  @override
  String get chatTyping => 'Felix yozmoqda';

  @override
  String chatError(String error) {
    return 'Xato: $error';
  }

  @override
  String get chatStart => 'Boshlash';

  @override
  String get chatMessageHint => 'Xabar...';

  @override
  String get chatAllChats => 'Barcha chatlar';

  @override
  String get chatTapToRetry => 'Qayta urinish uchun bosing';

  @override
  String get comingSoon => 'Tez orada';

  @override
  String get progressWeightTitle => 'Mening vaznim (kg)';

  @override
  String get progressCaloriesTitle => 'Kaloriya: qabul va sarf';

  @override
  String signInCodeResent(String email) {
    return 'Yangi kodni $email manziliga yubordik';
  }

  @override
  String get signInChangeEmail => 'Emailni o‘zgartirish';

  @override
  String get profileFieldName => 'Ism';

  @override
  String get profileFieldSurname => 'Familiya';

  @override
  String get profileFieldWeightKg => 'Vazn, kg';

  @override
  String get profileFieldHeightCm => 'Bo‘y, sm';
}
