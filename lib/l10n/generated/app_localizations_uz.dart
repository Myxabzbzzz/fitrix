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
      'Siz yozgan hamma narsa faqat shu qurilmada saqlanadi va o‘chiriladi: profil, mashg‘ulotlar, chatlar, tekshiruvlar, rejalar, ovqatlanish va vazn.';

  @override
  String get signOutAccountBody =>
      'Profilingiz, mashg‘ulotlar va chatlar hisobingizda saqlangan va shu qurilmadan o‘chiriladi. Ularni qaytarish uchun o‘sha email bilan kiring. Tekshiruvlar, rejalar, ovqatlanish va vazn faqat shu qurilmada saqlanadi va o‘chiriladi.';

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
  String progressSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yondashuv',
    );
    return '$_temp0';
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
  String get shopProSoonBody =>
      'Hozircha mavjud emas. Keyingi yangilanishlardan birida shu yerda paydo bo‘ladi.';

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
  String get shopRetry => 'Qayta urinish';

  @override
  String get shopNoProducts => 'Hozircha mahsulotlar yo‘q';

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
      'Hozircha mashqlar yo‘q. Qo‘shish uchun mashg‘ulot kartasini bosib turing.';

  @override
  String get workoutAddSet => 'Yondashuv qo‘shish';

  @override
  String get workoutFinishButton => 'Mashg‘ulotni yakunlash';

  @override
  String get workoutColSet => '#';

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
    return 'Bugun $workout bilan boshlang. Keyingi safar Felix yozganlaringiz asosida vazn taklif qiladi.';
  }

  @override
  String get gymCoachBackTitle => 'Qaytganingiz bilan';

  @override
  String gymCoachBackMessage(int days) {
    return 'Oxirgi mashg‘ulotingiz $days kun oldin bo‘lgan. Bugungi yengil mashg‘ulot sizni izga qaytaradi.';
  }

  @override
  String get gymFinishCurrentTitle => 'Joriy mashg‘ulotni bekor qilasizmi?';

  @override
  String gymFinishCurrentBody(String current, String next) {
    return '“$current” hali davom etmoqda va saqlanmaydi. Uning o‘rniga “$next” ni boshlaysizmi?';
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
  String get tabDiscover => 'Kashf etish';

  @override
  String get tabShop => 'Do‘kon';

  @override
  String get tabHome => 'Bosh sahifa';

  @override
  String get tabFelix => 'Felix';

  @override
  String get tabProfile => 'Profil';

  @override
  String get homeTileProgress => 'MENING\nNATIJAM';

  @override
  String get homeTileNutrition => 'MENING\nOVQATIM';

  @override
  String get homeTileWorkouts => 'MENING\nMASHG‘ULOT';

  @override
  String get homeTileShop => 'DO‘KON';

  @override
  String get homeTileMap => 'FITRIX\nXARITASI';

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

  @override
  String get signInAgainTitle => 'Qaytadan kiring';

  @override
  String get signInAgainSubtitle =>
      'Seans tugadi. Davom etish uchun emailingizni kiriting.';

  @override
  String get signInCreateTitle => 'Hisob yarating';

  @override
  String get signInCreateSubtitle =>
      'Ilovada ro‘yxatdan o‘tish uchun emailingizni kiriting';

  @override
  String get signInGetCode => 'Kodni olish';

  @override
  String get signInTryAgain => 'Qayta urinish';

  @override
  String get signInOr => 'yoki';

  @override
  String get signInTermsPrefix => '“Davom etish” tugmasini bosish orqali siz ';

  @override
  String get signInTerms => 'Foydalanish shartlari';

  @override
  String get signInTermsAnd => ' va ';

  @override
  String get signInPrivacy => 'Maxfiylik siyosati';

  @override
  String get signInTermsSuffix => 'ga rozilik bildirasiz.';

  @override
  String signInContinueWith(String provider) {
    return '$provider orqali davom etish';
  }

  @override
  String get signInCheckEmailTitle => 'Emailingizni tekshiring';

  @override
  String signInCodePrompt(String length, String email) {
    return 'Biz yuborgan $length xonali kodni kiriting:\n$email';
  }

  @override
  String get signInResend => 'Kodni qayta yuborish';

  @override
  String signInResendIn(String time) {
    return 'Kodni qayta yuborish: $time';
  }

  @override
  String get signInSpamNote => 'Topolmadingizmi? Spam jildini tekshiring.';

  @override
  String signInComingSoon(String provider) {
    return '$provider orqali kirish tez orada qo‘shiladi. Hozircha email orqali kiring.';
  }

  @override
  String get signInProfileLoadOffline =>
      'Siz kirdingiz, lekin profilni yuklab bo‘lmadi. Internetni tekshirib, qayta urinib ko‘ring.';

  @override
  String get signInProfileLoadFailed =>
      'Siz kirdingiz, lekin profilni yuklab bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get signInErrInvalidCode =>
      'Kod noto‘g‘ri yoki eskirgan. Eng so‘nggi xatni tekshiring yoki yangi kod so‘rang.';

  @override
  String get signInErrRateLimited =>
      'Urinishlar juda ko‘p. Bir daqiqa kutib, qayta urinib ko‘ring.';

  @override
  String get signInErrNetwork =>
      'Aloqa yo‘q. Internetni tekshirib, qayta urinib ko‘ring.';

  @override
  String get signInErrInvalidEmail => 'To‘g‘ri email manzilini kiriting.';

  @override
  String get signInErrUnknown => 'Nimadir xato ketdi. Qayta urinib ko‘ring.';

  @override
  String signInErrProviderDisabled(String provider) {
    return '$provider orqali kirish serverda hali sozlanmagan. Hozircha email orqali kiring.';
  }

  @override
  String signInErrProviderUnavailable(String provider) {
    return '$provider orqali kirish bu qurilmada mavjud emas. Email orqali kiring.';
  }

  @override
  String signInErrSocialFailed(String provider) {
    return '$provider orqali kirib bo‘lmadi. Qayta urinib ko‘ring yoki email orqali kiring.';
  }

  @override
  String get profileErrNameRequired => 'Ismingizni kiriting';

  @override
  String get profileErrNameTooLong => 'Ism juda uzun';

  @override
  String get profileErrSurnameTooLong => 'Familiya juda uzun';

  @override
  String get profileErrAgeRequired => 'Yoshingizni kiriting';

  @override
  String get profileErrAgeWhole => 'Yosh butun son bo‘lishi kerak';

  @override
  String profileErrAgeRange(String min, String max) {
    return 'Yosh $min dan $max gacha bo‘lishi kerak';
  }

  @override
  String get profileErrWeightRequired => 'Vazningizni kiriting';

  @override
  String get profileErrWeightNumber => 'Vazningizni son bilan kiriting';

  @override
  String profileErrWeightRange(String min, String max) {
    return 'Vazn $min dan $max kg gacha bo‘lishi kerak';
  }

  @override
  String get profileErrHeightRequired => 'Bo‘yingizni kiriting';

  @override
  String get profileErrHeightNumber => 'Bo‘yingizni son bilan kiriting';

  @override
  String profileErrHeightRange(String min, String max) {
    return 'Bo‘y $min dan $max sm gacha bo‘lishi kerak';
  }

  @override
  String get signInUnavailable =>
      'Hisoblar hozir mavjud emas. Keyinroq urinib ko‘ring.';

  @override
  String get programLevelBeginner => 'Boshlang‘ich';

  @override
  String get programLevelMedium => 'O‘rta';

  @override
  String get programLevelAdvanced => 'Ilg‘or';

  @override
  String get shopOrderUnavailable =>
      'Ba’zi mahsulotlar endi mavjud emas. Savatni yangilang va qayta urinib ko‘ring.';

  @override
  String get workoutKeyboardDone => 'Tayyor';

  @override
  String get workoutEditLabel => 'Mashg‘ulotni tahrirlash';

  @override
  String get aboutMeSave => 'Saqlash';

  @override
  String get aboutMeSaved => 'Saqlandi';

  @override
  String get aboutMeDiscardTitle => 'O‘zgarishlar bekor qilinsinmi?';

  @override
  String get aboutMeDiscardBody =>
      'Profilga kiritgan o‘zgarishlaringiz saqlanmaydi.';

  @override
  String get aboutMeDiscard => 'Bekor qilish';

  @override
  String get aboutMeKeepEditing => 'Tahrirlashni davom ettirish';

  @override
  String get aboutMeEmail => 'E-pochta';

  @override
  String get aboutMeGoal => 'Maqsad';

  @override
  String get aboutMeGoalOther => 'Boshqa…';

  @override
  String get aboutMeGoalOtherHint => 'Maqsadingizni yozing';

  @override
  String get aboutMeLevel => 'Daraja';

  @override
  String get aboutMeSports => 'Sport turlari';

  @override
  String get aboutMeSportsLimit => '6 tagacha sport turini tanlash mumkin.';

  @override
  String get aboutGoalBuild => 'Mushak va kuch orttirish';

  @override
  String get aboutGoalEndurance => 'Chidamlilikni oshirish';

  @override
  String get aboutGoalLose => 'Ozish va tarang tana';

  @override
  String get aboutGoalHealthy => 'Sog‘lom va muvozanatli bo‘lish';

  @override
  String get aboutGoalTrack => 'Shunchaki natijani kuzatish';

  @override
  String get chatAddPhoto => 'Rasm qo‘shish';

  @override
  String get chatTakePhoto => 'Rasmga olish';

  @override
  String get chatChooseFromLibrary => 'Galereyadan tanlash';

  @override
  String get chatRemovePhoto => 'Rasmni olib tashlash';

  @override
  String get chatPhotoTooLarge => 'Rasm juda katta. Boshqasini sinab ko‘ring.';

  @override
  String get chatPhotoFailed =>
      'Rasmni olib bo‘lmadi. Sozlamalarda kamera va rasmlarga ruxsatni tekshiring.';

  @override
  String get chatPhotoPrompt => 'Bu rasm haqida nima deysiz?';

  @override
  String get chatMicStart => 'Xabarni ovozda aytish';

  @override
  String get chatMicStop => 'Diktovkani to‘xtatish';

  @override
  String get chatMicDenied =>
      'Felix sizni hali eshitmayapti. Sozlamalarni oching va FITRIX uchun mikrofon va nutqni tanishga ruxsat bering.';

  @override
  String get chatPhotoViewer => 'Rasm';

  @override
  String get chatPhotoUnavailable =>
      'Rasm topilmadi yoki yuborish uchun juda katta.';

  @override
  String get chatMicListening => 'Tinglayapman';

  @override
  String get chatMicStopped => 'Tinglash to‘xtatildi';

  @override
  String get chatActionConfirm => 'Tasdiqlash';

  @override
  String get chatActionApplied => 'Qo‘shildi ✓';

  @override
  String chatActionWeightChange(String from, String to) {
    return 'Vaznni yangilash: $from → $to kg';
  }

  @override
  String chatActionWorkoutTitle(int count, String sport) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$sport bo‘limiga $count ta mashg‘ulot qo‘shish',
    );
    return '$_temp0';
  }

  @override
  String chatActionWorkoutExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta mashq',
    );
    return '$_temp0';
  }

  @override
  String get chatActionMealTitle => 'Bugungi ovqatlanishga qo‘shish';

  @override
  String chatActionMealTotal(String kcal) {
    return 'Jami $kcal kkal';
  }

  @override
  String chatActionWorkoutsAdded(String sport) {
    return 'Mashg‘ulotlar qo‘shildi: $sport';
  }

  @override
  String get chatActionOpen => 'Ochish';

  @override
  String chatActionWeightDone(String from, String to) {
    return 'Vazn yangilandi: $from → $to kg';
  }

  @override
  String chatActionWeightDoneSet(String to) {
    return 'Vazn yangilandi: $to kg';
  }

  @override
  String get chatActionNoProfile =>
      'Avval profilni to‘ldiring, shunda vazningizni yangilay olaman.';

  @override
  String get chatActionError => 'Qo‘llab bo‘lmadi. Qayta urinib ko‘ring.';

  @override
  String get unitTonnes => 't';

  @override
  String workoutLiveCaption(int x, int y, String t) {
    return '$x / $y-yondashuv · $t ko‘tarildi';
  }

  @override
  String get workoutColRpe => 'RPE';

  @override
  String workoutRestShort(String time) {
    return 'dam $time';
  }

  @override
  String workoutBestShort(String value) {
    return 'eng yaxshisi $value';
  }

  @override
  String get workoutPr => 'Rekord';

  @override
  String get workoutE1rm => 'e1RM';

  @override
  String get workoutBodyweight => 'TV';

  @override
  String workoutFelixLine(String last, String next) {
    return 'Oxirgi marta $last. Bugun $next kg ni sinab ko‘ring.';
  }

  @override
  String get workoutRestLabel => 'Dam';

  @override
  String workoutRestNext(String label) {
    return 'Keyingisi: $label';
  }

  @override
  String workoutNextSet(int n, String kg, int reps) {
    return '$n-yondashuv · $kg × $reps';
  }

  @override
  String workoutRestAdd(int n) {
    return '+$n s';
  }

  @override
  String workoutRestSub(int n) {
    return '−$n s';
  }

  @override
  String get workoutRestSkip => 'O‘tkazib yuborish';

  @override
  String get workoutMenuSwap => 'Mashqni almashtirish';

  @override
  String workoutMenuSimilar(String names) {
    return 'O‘xshash: $names';
  }

  @override
  String get workoutMenuNoSimilar => 'Kutubxonada o‘xshash mashqlar yo‘q';

  @override
  String get workoutMenuWarmup => 'Isitish yondashuvlarini qo‘shish';

  @override
  String workoutMenuWarmupSub(String plan) {
    return '2 yondashuv: $plan';
  }

  @override
  String get workoutMenuRest => 'Dam olish taymeri';

  @override
  String get workoutMenuRestSub => 'Shu mashq uchun';

  @override
  String get workoutMenuNote => 'Eslatma';

  @override
  String get workoutMenuNoteEmpty => 'Eslatma qo‘shish';

  @override
  String get workoutMenuNoteHint => 'Masalan: oxirgi yondashuvda tasma';

  @override
  String get workoutNoteSave => 'Saqlash';

  @override
  String get workoutMenuReorder => 'Tartib';

  @override
  String get workoutMenuReorderSub =>
      'Mashg‘ulotda yuqoriga yoki pastga siljitish';

  @override
  String get workoutMenuRemove => 'Mashqni olib tashlash';

  @override
  String get workoutRemoveTitle => 'Bu mashqni olib tashlaysizmi?';

  @override
  String get workoutRemoveBody => 'Yozilgan yondashuvlar yo‘qoladi.';

  @override
  String get workoutRemoveConfirm => 'Olib tashlash';

  @override
  String workoutRpeTitle(int n) {
    return '$n-yondashuv RPE · qanchalik og‘ir edi?';
  }

  @override
  String workoutRpeCaption(int n, int left) {
    return 'RPE $n · zaxirada taxminan $left ta takror';
  }

  @override
  String get workoutCompleteTitle => 'Mashg‘ulot yakunlandi';

  @override
  String workoutCompleteSubtitle(String name, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ta yangi rekord',
      zero: 'yangi rekordlar yo‘q',
    );
    return '$name · $_temp0';
  }

  @override
  String get workoutTileDuration => 'Davomiyligi';

  @override
  String get workoutTileVolume => 'Hajm';

  @override
  String get workoutTileSets => 'Yondashuvlar';

  @override
  String get workoutTileRecords => 'Rekordlar';

  @override
  String get workoutTileLoad => 'Yuklama';

  @override
  String get workoutOverallTitle => 'Umuman qanchalik og‘ir bo‘ldi?';

  @override
  String get workoutOverallHint =>
      'Majburiy emas. Mashg‘ulot yuklamasi va tiklanish bahosida hisobga olinadi.';

  @override
  String workoutOverallCaption(int n, String label) {
    return 'RPE $n · $label. Mashg‘ulot yuklamasida hisobga olinadi.';
  }

  @override
  String get workoutRpeVeryEasy => 'Juda yengil';

  @override
  String get workoutRpeEasy => 'Yengil';

  @override
  String get workoutRpeModerate => 'O‘rtacha';

  @override
  String get workoutRpeHard => 'Og‘ir';

  @override
  String get workoutRpeVeryHard => 'Juda og‘ir';

  @override
  String get workoutRpeMax => 'Maksimal';

  @override
  String get workoutExercisesTitle => 'Mashqlar';

  @override
  String get workoutBestSetE1rm => 'eng yaxshi yondashuv · e1RM';

  @override
  String workoutBestSet(String value) {
    return 'Eng yaxshi yondashuv $value';
  }

  @override
  String get workoutNextTimeTitle => 'Keyingi safar';

  @override
  String workoutNextTimeBody(String exercise, String kg) {
    return '$exercise: barcha yondashuvlar bajarildi. Keyingi safar $kg kg ni sinab ko‘ring.';
  }

  @override
  String get workoutSave => 'Mashg‘ulotni saqlash';

  @override
  String get workoutDiscard => 'Saqlamaslik';

  @override
  String get workoutDiscardTitle => 'Mashg‘ulot saqlanmasinmi?';

  @override
  String get workoutDiscardBody => 'U tarixingizga saqlanmaydi.';

  @override
  String get workoutAddExercise => 'Mashq';

  @override
  String homeGreetingMorning(String name) {
    return 'Xayrli tong, $name';
  }

  @override
  String get homeGreetingMorningNoName => 'Xayrli tong';

  @override
  String homeGreetingAfternoon(String name) {
    return 'Xayrli kun, $name';
  }

  @override
  String get homeGreetingAfternoonNoName => 'Xayrli kun';

  @override
  String homeGreetingEvening(String name) {
    return 'Xayrli kech, $name';
  }

  @override
  String get homeGreetingEveningNoName => 'Xayrli kech';

  @override
  String get checkinCardPrompt =>
      'Bugun o‘zingizni qanday his qilyapsiz? 20 soniyada mashg‘ulotga qanchalik tayyorligingizni bilib oling.';

  @override
  String get checkinCardAction => 'Belgilash';

  @override
  String checkinCardRecovered(int score) {
    return '$score% tiklangan';
  }

  @override
  String get checkinCardSeeMore => 'Nimalar ta’sir qilgani';

  @override
  String get checkinTitle => 'Ertalabki tekshiruv';

  @override
  String get checkinSleep => 'Uyqu';

  @override
  String checkinSleepDuration(int hours, int minutes) {
    return '$hours soat $minutes daq';
  }

  @override
  String get checkinSleepLess => 'Uyquni 15 daqiqa kamaytirish';

  @override
  String get checkinSleepMore => 'Uyquni 15 daqiqa oshirish';

  @override
  String get sleepQualityPoor => 'Yomon';

  @override
  String get sleepQualityOk => 'Yaxshi emas, yomon emas';

  @override
  String get sleepQualityGood => 'Yaxshi';

  @override
  String get checkinSoreness => 'Mushaklar og‘rig‘i';

  @override
  String get sorenessNone => 'Yo‘q';

  @override
  String get sorenessLight => 'Yengil';

  @override
  String get sorenessMedium => 'O‘rtacha';

  @override
  String get sorenessStrong => 'Kuchli';

  @override
  String get bodyLegs => 'Oyoqlar';

  @override
  String get bodyBack => 'Orqa';

  @override
  String get bodyChest => 'Ko‘krak';

  @override
  String get bodyArms => 'Qo‘llar';

  @override
  String get bodyShoulders => 'Yelkalar';

  @override
  String get checkinEnergy => 'Energiya';

  @override
  String get checkinStress => 'Stress';

  @override
  String get levelLow => 'Past';

  @override
  String get levelOk => 'O‘rtacha';

  @override
  String get levelHigh => 'Yuqori';

  @override
  String get stressLow => 'Past';

  @override
  String get stressMedium => 'O‘rtacha';

  @override
  String get stressHigh => 'Yuqori';

  @override
  String get checkinSave => 'Tekshiruvni saqlash';

  @override
  String get readinessReady => 'Mashqqa tayyor';

  @override
  String get readinessTrainLight => 'Yengil mashq qiling';

  @override
  String get readinessRest => 'Bugun dam oling';

  @override
  String get checkinHintReady => 'Og‘ir mashq mumkin.';

  @override
  String checkinHintReadySore(String areas) {
    return 'Og‘ir mashq mumkin. $areas uchun yana bir kun kerak.';
  }

  @override
  String get checkinHintLight => 'Bugun yengilroq mashq qiling.';

  @override
  String get checkinHintRest =>
      'Shoshilmang. Tiklanish ham mashqning bir qismi.';

  @override
  String get recoveryTitle => 'Tiklanish';

  @override
  String recoverySubtitle(String time) {
    return 'Bugun · tekshiruv soat $time';
  }

  @override
  String get recoveryRecovered => 'tiklanish';

  @override
  String recoveryHintReadySore(String areas) {
    return 'Og‘ir mashq mumkin. ${areas}ni bugun yengil saqlang.';
  }

  @override
  String get recoveryShaped => 'Nimalar ta’sir qildi';

  @override
  String factorSleep(String duration) {
    return 'Uyqu $duration';
  }

  @override
  String factorSleepQuality(String quality) {
    return 'Sifati: $quality';
  }

  @override
  String factorSoreness(String level) {
    return 'Og‘riq: $level';
  }

  @override
  String factorEnergy(String level) {
    return 'Energiya: $level';
  }

  @override
  String factorStress(String level) {
    return 'Stress: $level';
  }

  @override
  String get factorLoad => 'Mashq yuklamasi';

  @override
  String factorLoadSub(int count) {
    return 'So‘nggi 7 kunda $count ta og‘ir kun';
  }

  @override
  String get recoveryPlanTitle => 'Bugungi reja, moslangan';

  @override
  String recoveryPlanApplied(String plan, String swaps, String areas) {
    return '$plan qoladi. Almashtirildi: $swaps. Bu ${areas}ni asraydi.';
  }

  @override
  String recoveryPlanSuggested(String plan, String swaps, String areas) {
    return '${plan}ni qoldirish mumkin. Taklif etilgan almashtirishlar: $swaps, ${areas}ni asrash uchun.';
  }

  @override
  String get recoveryStartWorkout => 'Mashqni boshlash';

  @override
  String get recoveryUndo => 'Bekor qilish';

  @override
  String get recoveryApplySwaps => 'Almashtirish';

  @override
  String get recoveryLast7 => 'So‘nggi 7 kun';

  @override
  String recoveryAvg(int score) {
    return 'o‘rtacha $score%';
  }

  @override
  String get recoveryNoCheckin => 'Hali tekshiruv yo‘q';

  @override
  String get recoveryNoCheckinBody =>
      'Tiklanish darajangizni va unga nima ta’sir qilganini ko‘rish uchun belgilang.';

  @override
  String get planTitle => 'Shu hafta';

  @override
  String planSummary(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mashg‘ulot',
      one: '$n mashg‘ulot',
    );
    return '$_temp0 · bajarildi: $m';
  }

  @override
  String get planLoadTitle => 'Mashq yuklamasi';

  @override
  String get planLoadEasy => 'Past';

  @override
  String get planLoadNormal => 'O‘rtacha';

  @override
  String get planLoadHigh => 'Yuqori';

  @override
  String planLoadCaption(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Keyingi 3 kunda $n ta og‘ir mashg‘ulot.',
      one: 'Keyingi 3 kunda $n ta og‘ir mashg‘ulot.',
    );
    return '$_temp0';
  }

  @override
  String planRecoveryToday(int score) {
    return 'Bugun tiklanish: $score%.';
  }

  @override
  String get planFelixLabel => 'FELIX TAKLIF QILADI';

  @override
  String planFelixText(
      String a, String aDay, String b, String bDay, String target) {
    return '$a ($aDay) va $b ($bDay) ikkalasi ham og‘ir. Oyoqlar tiklanishi uchun $b ni $target ga ko‘chiring.';
  }

  @override
  String get planOptimize => 'Rejani optimallashtirish';

  @override
  String get planKeep => 'Qoldirish';

  @override
  String planTodayDay(String day) {
    return 'Bugun · $day';
  }

  @override
  String planDoneCount(int n) {
    return 'bajarildi: $n';
  }

  @override
  String planPlannedCount(int n) {
    return 'rejalashtirildi: $n';
  }

  @override
  String get planMissedHeader => 'o‘tkazib yuborilgan';

  @override
  String get planMissed => 'O‘tkazib yuborildi';

  @override
  String get planRestDay => 'Dam olish kuni';

  @override
  String planExercisesMeta(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mashq',
      one: '$count mashq',
    );
    return '$_temp0 · $duration';
  }

  @override
  String planDurationHM(int h, int m) {
    return '$h soat $m daq';
  }

  @override
  String planDurationH(int h) {
    return '$h soat';
  }

  @override
  String planDurationM(int m) {
    return '$m daq';
  }

  @override
  String get planIntensityEasy => 'Yengil';

  @override
  String get planIntensityNormal => 'O‘rtacha';

  @override
  String get planIntensityHard => 'Og‘ir';

  @override
  String planDoneMeta(String duration, int rpe) {
    return '$duration · RPE $rpe';
  }

  @override
  String get planAddSession => 'Mashg‘ulot qo‘shish';

  @override
  String get planAddTitle => 'Mashg‘ulot qo‘shish';

  @override
  String get planWorkoutLabel => 'MASHQ';

  @override
  String get planDayLabel => 'KUN';

  @override
  String planAddButton(String title, String day) {
    return 'Qo‘shish: $title · $day';
  }

  @override
  String planWarnThird(String day) {
    return '$day ketma-ket 3-og‘ir kun bo‘ladi';
  }

  @override
  String planWarnAuto(String day) {
    return '$day tiklanish uchun ko‘proq vaqt beradi. Felix uni siz uchun tanladi.';
  }

  @override
  String get planWarnPick => 'Tiklanishni saqlash uchun boshqa kunni tanlang.';

  @override
  String get planGenericFootball => 'Futbol 7×7';

  @override
  String get planSkiing => 'Chang‘i';

  @override
  String get planEmptyTitle => 'Reja hali yo‘q';

  @override
  String get planEmptyBody =>
      'Shu haftaning qolgan kunlari uchun zal mashqlarini bir bosishda rejalashtiring.';

  @override
  String get planPlanWeek => 'Haftamni rejalashtirish';

  @override
  String get planEntryEmpty => 'Mashq haftasini rejalashtiring';

  @override
  String get planNextWeek => 'Keyingi hafta';

  @override
  String get planPlanNextWeek => 'Keyingi haftani rejalashtirish';

  @override
  String get exercisesTitle => 'Mashqlar';

  @override
  String exercisesSearch(int n) {
    return '$n ta mashq ichidan qidirish';
  }

  @override
  String get exercisesSearchShort => 'Mashqlarni qidirish';

  @override
  String get exercisesAll => 'Hammasi';

  @override
  String get exercisesAnyEquipment => 'Istalgan jihoz';

  @override
  String get exercisesRecent => 'So‘nggi mashqlaringiz';

  @override
  String get exercisesFromWorkouts => 'mashg‘ulotlardan';

  @override
  String get exercisesBest => 'eng yaxshi';

  @override
  String get exercisesAZ => 'Hammasi · A–Z';

  @override
  String exercisesCount(int n) {
    return '$n ta mashq';
  }

  @override
  String get exercisesNoMatch =>
      'Hech narsa topilmadi. Boshqa filtrni sinab ko‘ring.';

  @override
  String get muscleChest => 'Ko‘krak';

  @override
  String get muscleBack => 'Orqa';

  @override
  String get muscleShoulders => 'Yelka';

  @override
  String get muscleArms => 'Qo‘llar';

  @override
  String get muscleLegs => 'Oyoqlar';

  @override
  String get muscleGlutes => 'Dumba';

  @override
  String get muscleCore => 'Korpus';

  @override
  String get equipBarbell => 'Shtanga';

  @override
  String get equipDumbbell => 'Gantel';

  @override
  String get equipCable => 'Trenajyor trosi';

  @override
  String get equipMachine => 'Trenajyor';

  @override
  String get equipBodyweight => 'O‘z vazni';

  @override
  String get equipKettlebell => 'Girya';

  @override
  String get levelBeginner => 'Boshlovchi';

  @override
  String get levelIntermediate => 'O‘rta';

  @override
  String get levelAdvanced => 'Yuqori';

  @override
  String get exerciseCompound => 'Asosiy';

  @override
  String get exerciseDetailTitle => 'Mashq';

  @override
  String get exercisePrimary => 'Asosiy';

  @override
  String get exerciseSecondary => 'Yordamchi';

  @override
  String get exerciseYourNumbers => 'Sizning natijalaringiz';

  @override
  String get exerciseBestSet => 'Eng yaxshi yondashuv';

  @override
  String get exerciseE1rm => 'e1RM';

  @override
  String get exerciseSessions => 'Mashg‘ulotlar';

  @override
  String exerciseChangeSince(String pct, String month) {
    return '${month}dan beri $pct';
  }

  @override
  String get exerciseNoHistory =>
      'Natijalaringizni ko‘rish uchun bir marta bajaring';

  @override
  String get exerciseHowTo => 'Qanday bajariladi';

  @override
  String get exerciseMistakes => 'Ko‘p uchraydigan xatolar';

  @override
  String get exerciseSimilar => 'O‘xshash';

  @override
  String get exerciseAskFelix => 'Felixdan so‘rash';

  @override
  String exerciseAskFelixDraft(String name) {
    return '$name mashqini qanday yaxshilayman?';
  }

  @override
  String get exerciseAddToWorkout => 'Mashg‘ulotga qo‘shish';

  @override
  String get exerciseAdded => 'Mashg‘ulotga qo‘shildi';

  @override
  String get exerciseQuickWorkout => 'Tezkor mashg‘ulot';

  @override
  String addExerciseTitle(String workout) {
    return '«$workout»ga qo‘shish';
  }

  @override
  String addExerciseSwapTitle(String workout) {
    return '«$workout»da almashtirish';
  }

  @override
  String addExerciseHint(String group, int n, int target) {
    return '$group: bu hafta $n yondashuv, maqsad — $target.';
  }

  @override
  String get addExerciseSuggested => 'Tavsiya etiladi';

  @override
  String addExerciseSelected(int n) {
    return 'Tanlandi: $n';
  }

  @override
  String get addExerciseLibrary => 'Kutubxona';

  @override
  String get addExerciseInWorkout => 'Shu mashg‘ulotda';

  @override
  String addExerciseButton(int n) {
    return '$n ta mashq qo‘shish';
  }

  @override
  String get addExerciseSwap => 'Almashtirish';

  @override
  String get workoutMenuSwapSub => 'Kutubxonadan tanlang';

  @override
  String get gymExercises => 'Mashqlar';

  @override
  String gymExercisesSub(int n) {
    return '$n ta mashq: texnika va eng yaxshi natijalar';
  }

  @override
  String get profileEditTooltip => 'Profilni tahrirlash';

  @override
  String get profileMySports => 'Mening sport turlarim';

  @override
  String profileSportsSelected(int n) {
    return 'Tanlangan: $n';
  }

  @override
  String get profileWeightLabel => 'kg · vazn';

  @override
  String get profileHeightLabel => 'sm · bo‘y';

  @override
  String get profileAgeLabel => 'yosh · yosh';

  @override
  String get profileSettings => 'Sozlamalar';

  @override
  String get hrZonesTitle => 'Yurak urishi zonalari';

  @override
  String profileHrZonesSummary(int rest, int max) {
    return 'Tinch $rest · maks $max urish/daq';
  }

  @override
  String get profileHrZonesSetUp => 'Sozlash';

  @override
  String get profileConnectedApps => 'Ulangan ilovalar';

  @override
  String profileConnectedAppsCount(int connected, int total) {
    return '$total tadan $connected tasi ulangan';
  }

  @override
  String get hrZonesMax => 'Maks. puls';

  @override
  String get hrZonesRest => 'Tinch holat pulsi';

  @override
  String get hrZonesLthr => 'LTHR';

  @override
  String get hrZonesEdit => 'Pulsni tahrirlash';

  @override
  String get hrZonesKarvonen => 'Karvonen';

  @override
  String get hrZonesFriel => 'LTHR (Friel)';

  @override
  String get hrZonesKarvonenTitle => 'Karvonen zonalari';

  @override
  String get hrZonesKarvonenSub => 'zaxiradan %';

  @override
  String get hrZonesFrielTitle => 'LTHR zonalari';

  @override
  String get hrZonesColZone => 'ZONA';

  @override
  String get hrZonesColBpm => 'URISH/DAQ';

  @override
  String get hrZonesColHrr => '50–100% zaxira';

  @override
  String get hrZonesColLthr => 'LTHR %';

  @override
  String hrZonesLthrValue(int lthr) {
    return 'LTHR $lthr urish/daq';
  }

  @override
  String hrZonesFormula(int reserve) {
    return 'Puls = tinch + % × (maks − tinch). Zaxirangiz: $reserve urish/daq.';
  }

  @override
  String hrZonesZ2Tip(int low, int high) {
    return 'Yugurishning ko‘p qismi Z2 da bo‘lsin, $low–$high urish/daq. Z4 faqat qisqa intervallar uchun.';
  }

  @override
  String get hrZonesHowTitle => 'Maksimal pulsni qanday o‘lchash';

  @override
  String get hrZonesHowBody =>
      '15 daqiqa isining, so‘ng tepalikka 3–4 daqiqa qattiq yugurishni ikki marta bajaring. Ko‘rgan eng yuqori pulsingiz maksimumingiz.';

  @override
  String hrZonesTanaka(int age, int max) {
    return 'Hali test yo‘qmi? Tanaka bahosi: 208 − 0,7 × $age = $max urish/daq (±10).';
  }

  @override
  String get hrZonesRestingTip =>
      'Tinch holat pulsi: uyg‘onganda, yotgan holda o‘lchang.';

  @override
  String get hrZonesFrielNote =>
      'Friel zonalari yugurish uchun. LTHR testi: yolg‘iz 30 daqiqa to‘liq kuch bilan yuguring, oxirgi 20 daqiqadagi o‘rtacha puls LTHR bo‘ladi.';

  @override
  String get hrZonesNeedAge =>
      'Maksimal pulsni baholash uchun profilingizga yoshingizni kiriting.';

  @override
  String get hrZonesCompleteProfile => 'Profilni to‘ldirish';

  @override
  String get hrZonesNeedRates =>
      'Zonalarni ko‘rish uchun tinch va maksimal pulsni kiriting.';

  @override
  String get hrZonesNeedLthr => 'Friel zonalarini ko‘rish uchun LTHR kiriting.';

  @override
  String get hrZoneRecovery => 'Tiklanish';

  @override
  String get hrZoneAerobic => 'Aerob';

  @override
  String get hrZoneTempo => 'Tempo';

  @override
  String get hrZoneThreshold => 'Bo‘sag‘a';

  @override
  String get hrZoneVo2max => 'VO2max';

  @override
  String get hrZoneSubThr => 'Bo‘sag‘a osti';

  @override
  String get hrZoneThreshPlus => 'Bo‘sag‘a+';

  @override
  String get hrZoneCapacity => 'Sig‘im';

  @override
  String get hrZoneAnaerobic => 'Anaerob';

  @override
  String get editProfileTitle => 'Profilni tahrirlash';

  @override
  String get editProfileBody => 'Tana';

  @override
  String get editProfilePerformance => 'Natijalar';

  @override
  String get editProfileSex => 'Jins';

  @override
  String get sexMale => 'Erkak';

  @override
  String get sexFemale => 'Ayol';

  @override
  String get editProfileRestingHr => 'Tinch holat pulsi';

  @override
  String get editProfileMaxHr => 'Maks. puls';

  @override
  String get editProfileLthr => 'LTHR (ixtiyoriy)';

  @override
  String get editProfileFtp => 'Velosiped FTP';

  @override
  String get editProfileFiveK => '5 km shaxsiy rekord';

  @override
  String get unitBpm => 'urish/daq';

  @override
  String get unitWatts => 'Vt';

  @override
  String get unitMinSec => 'daq:son';

  @override
  String get unitYears => 'yosh';

  @override
  String get editProfileSave => 'Saqlash';

  @override
  String editProfileErrHr(int min, int max) {
    return '$min–$max urish/daq kiriting';
  }

  @override
  String get editProfileErrRestMax =>
      'Tinch puls maksimal pulsdan past bo‘lishi kerak';

  @override
  String editProfileErrFtp(int min, int max) {
    return '$min–$max Vt kiriting';
  }

  @override
  String get editProfileErrFiveK => '12:00 dan 60:00 gacha vaqt kiriting';

  @override
  String get connectedAppsTitle => 'Ulangan ilovalar';

  @override
  String get connectedAppsWhyHeader => 'NEGA ULASH KERAK';

  @override
  String get connectedAppsWhyBody =>
      'Ulash keyingi yangilanishlardan birida paydo bo‘lganda, soat ertalabki tekshiruv uchun uyqu, tinch puls va HRVni o‘zi to‘ldira oladi. Hozircha tekshiruvni o‘zingiz to‘ldirasiz.';

  @override
  String get connectedAppsAppleDesc => 'Uyqu, puls, qadamlar, vazn';

  @override
  String get connectedAppsGarminDesc => 'Mashg‘ulotlar, puls, uyqu, HRV';

  @override
  String get connectedAppsStravaDesc => 'Yugurish, velosiped va chang‘i';

  @override
  String get connectedAppsWhoopDesc => 'Tiklanish, yuklama, uyqu, HRV';

  @override
  String get connectedAppsNotConnected => 'Ulanmagan';

  @override
  String get connectedAppsConnect => 'Ulash';

  @override
  String get connectedAppsFooter =>
      'Ilovalarni ulash imkoni paydo bo‘lgach, istalganini istalgan vaqtda uzishingiz mumkin bo‘ladi.';

  @override
  String connectedAppsSheetTitle(String app) {
    return '$app ni ulash';
  }

  @override
  String get connectedAppsSheetSubtitle => 'FITRIX nimalarni o‘qiy oladi';

  @override
  String get connectedAppsSheetPrivacy =>
      'Bu imkoniyat paydo bo‘lganda, FITRIX faqat ma‘lumotlarni o‘qiydi va hech narsa joylamaydi.';

  @override
  String get connectedAppsSheetSoon =>
      'Ilovalarni ulash hozircha mavjud emas. Keyingi yangilanishda qo‘shamiz.';

  @override
  String get connectedAppsComingSoon => 'Keyingi yangilanishda';

  @override
  String get connectedAppsClose => 'Yopish';

  @override
  String get nutritionToday => 'Bugun';

  @override
  String nutritionDateTraining(String date) {
    return '$date · mashg‘ulot kuni';
  }

  @override
  String get nutritionCompleteTitle => 'Profilingizni to‘ldiring';

  @override
  String get nutritionCompleteBody =>
      'Kunlik me’yorlarni olish uchun jinsingiz, yoshingiz, vazningiz va bo‘yingizni kiriting.';

  @override
  String get nutritionLeftToday => 'Bugun qoldi';

  @override
  String get nutritionBurned => 'Mashg‘ulotda yoqildi';

  @override
  String nutritionBurnedValue(String kcal) {
    return '≈ +$kcal kkal';
  }

  @override
  String get nutritionHowSet => 'Qanday hisoblanadi ›';

  @override
  String get nutritionMacros => 'Makrolar';

  @override
  String nutritionProteinPerKg(String value) {
    return 'oqsil $value g/kg';
  }

  @override
  String nutritionGramsOf(String eaten, String target) {
    return '$eaten / $target g';
  }

  @override
  String nutritionWaterTitle(String drunk, String target) {
    return 'Suv · $drunk / $target l';
  }

  @override
  String nutritionWaterNoTarget(String drunk) {
    return 'Suv · $drunk l';
  }

  @override
  String get nutritionWaterWorkout => 'Bugungi mashg‘ulot uchun +0,5 l';

  @override
  String nutritionAddMl(String ml) {
    return '+$ml ml';
  }

  @override
  String get nutritionMeals => 'Ovqatlar';

  @override
  String nutritionMealsLogged(String n) {
    return '$n / 4 yozilgan';
  }

  @override
  String get nutritionAdd => 'Qo‘shish';

  @override
  String get nutritionLowToday => 'Bugun kam';

  @override
  String nutritionAllMicros(String n) {
    return 'Hammasi $n ›';
  }

  @override
  String get nutritionDinnerIdea => 'Kechki ovqat g‘oyasi';

  @override
  String nutritionIdeaMessage(
      String gap, String food, String portion, String protein) {
    return 'Oqsil $gap g yetmayapti. $food ($portion) taxminan $protein g beradi.';
  }

  @override
  String get nutritionAddToDinner => 'Kechki ovqatga qo‘shish';

  @override
  String get nutritionOtherIdea => 'Boshqa g‘oya';

  @override
  String get nutritionRemove => 'O‘chirish';

  @override
  String get nutritionSearch => 'Mahsulot qidirish';

  @override
  String get nutritionFood => 'Mahsulot';

  @override
  String nutritionGrams(String grams) {
    return '$grams g';
  }

  @override
  String nutritionAddToSlot(String slot) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Nonushtaga qo‘shish',
        'lunch': 'Tushlikka qo‘shish',
        'dinner': 'Kechki ovqatga qo‘shish',
        'snack': 'Yengil ovqatga qo‘shish',
        'other': 'Kechki ovqatga qo‘shish',
      },
    );
    return '$_temp0';
  }

  @override
  String nutritionAddToSlotKcal(String slot, String kcal) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Nonushtaga qo‘shish · $kcal kkal',
        'lunch': 'Tushlikka qo‘shish · $kcal kkal',
        'dinner': 'Kechki ovqatga qo‘shish · $kcal kkal',
        'snack': 'Yengil ovqatga qo‘shish · $kcal kkal',
        'other': 'Kechki ovqatga qo‘shish · $kcal kkal',
      },
    );
    return '$_temp0';
  }

  @override
  String nutritionAddedTo(String name, String slot) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': '$name nonushtaga qo‘shildi',
        'lunch': '$name tushlikka qo‘shildi',
        'dinner': '$name kechki ovqatga qo‘shildi',
        'snack': '$name yengil ovqatga qo‘shildi',
        'other': '$name qo‘shildi',
      },
    );
    return '$_temp0';
  }

  @override
  String get nutritionResults => 'Natijalar';

  @override
  String nutritionResultsCount(String n) {
    return '$n ta mahsulot · bir porsiya uchun';
  }

  @override
  String get nutritionNoResults =>
      'Hech narsa topilmadi. Boshqa nom bilan urinib ko‘ring.';

  @override
  String get nutritionRecent => 'So‘nggilar';

  @override
  String get nutritionRecentNote => 'bu hafta yegansiz';

  @override
  String nutritionPortionLine(String portion, String kcal, String protein) {
    return '$portion · $kcal kkal · O $protein g';
  }

  @override
  String get nutritionCantFind => 'Topa olmadingizmi?';

  @override
  String get nutritionCantFindBody => 'Felixdan baholashni so‘rang';

  @override
  String get foodBaseError => 'Mahsulotlar bazasini yuklab bo‘lmadi.';

  @override
  String get foodNotFound => 'Bu mahsulot bazada yo‘q.';

  @override
  String get foodCatAll => 'Hammasi';

  @override
  String get foodCatUzbek => 'O‘zbek taomlari';

  @override
  String get foodCatMeatFish => 'Go‘sht va baliq';

  @override
  String get foodCatDairy => 'Sut mahsulotlari';

  @override
  String get foodCatFruit => 'Mevalar';

  @override
  String get foodCatVeg => 'Sabzavotlar';

  @override
  String get foodCatGrains => 'Don va makaron';

  @override
  String get foodCatBread => 'Non';

  @override
  String get foodCatDrinks => 'Ichimliklar';

  @override
  String get foodCatOther => 'Boshqa';

  @override
  String get foodRecipeEstimate => 'Retsept bo‘yicha baho';

  @override
  String foodPer100(String kcal) {
    return '$kcal kkal / 100 g';
  }

  @override
  String get foodPortion => 'Porsiya';

  @override
  String get foodKcal => 'kkal';

  @override
  String get foodFitsDay => 'Kuningizga mosmi?';

  @override
  String foodKcalLeftAfter(String kcal) {
    return 'keyin $kcal kkal qoladi';
  }

  @override
  String foodKcalOver(String kcal) {
    return '$kcal kkal ortiq';
  }

  @override
  String foodEaten(String kcal) {
    return 'Yeyilgan $kcal';
  }

  @override
  String foodPlus(String name, String kcal) {
    return '+ $name $kcal';
  }

  @override
  String foodTarget(String kcal) {
    return 'Maqsad $kcal';
  }

  @override
  String foodFatWould(String fat, String target) {
    return 'Yog‘ $target g dan $fat g ga yetadi.';
  }

  @override
  String foodProteinBehind(String g) {
    return 'Oqsil hali ham $g g yetmaydi.';
  }

  @override
  String get foodRichIn => 'Boy';

  @override
  String get foodPctOfTarget => 'kunlik me’yoringizning %';

  @override
  String get micrTitle => 'Mikronutriyentlar';

  @override
  String micrTargetsFor(String who, String age) {
    return '$who uchun me’yorlar, $age · NASEM';
  }

  @override
  String get micrMen => 'erkaklar';

  @override
  String get micrWomen => 'ayollar';

  @override
  String get micrToday => 'Bugun';

  @override
  String get micr7Days => '7 kun';

  @override
  String get micr30Days => '30 kun';

  @override
  String get micrAthlete => 'Sportchi uchun asosiylar';

  @override
  String get micrVitamins => 'Vitaminlar';

  @override
  String get micrMinerals => 'Minerallar';

  @override
  String micrAll(String n) {
    return 'Hammasi $n';
  }

  @override
  String get micrEmpty => 'Mikronutriyentlarni ko‘rish uchun ovqat yozing.';

  @override
  String micrAverage(String n) {
    return 'Yozuvi bor $n kun o‘rtachasi';
  }

  @override
  String get micrLow => 'Kam';

  @override
  String get micrOk => 'Me’yorda';

  @override
  String get micrHigh => 'Ko‘p';

  @override
  String get micrVitDTitle => 'D vitamini butun hafta kam';

  @override
  String get micrVitDBody =>
      'Yog‘li baliq, tuxum va boyitilgan sut mahsulotlari biroz yordam beradi. D3 qo‘shimchasi haqida shifokoringizdan so‘rang.';

  @override
  String get micrInSeason => 'Hozir mavsumda';

  @override
  String micrUzbekistanMonth(String month) {
    return 'O‘zbekiston · $month';
  }

  @override
  String get microVitD => 'D vitamini';

  @override
  String get microCalcium => 'Kaltsiy';

  @override
  String get microMagnesium => 'Magniy';

  @override
  String get microIron => 'Temir';

  @override
  String get microZinc => 'Rux';

  @override
  String get microPotassium => 'Kaliy';

  @override
  String get microSodium => 'Natriy';

  @override
  String get microB12 => 'B12 vitamini';

  @override
  String get microSelenium => 'Selen';

  @override
  String get microVitE => 'E vitamini';

  @override
  String get microVitC => 'C vitamini';

  @override
  String get microVitA => 'A vitamini';

  @override
  String get microHintVitD => 'Yog‘li baliq, tuxum, quyosh';

  @override
  String get microHintCalcium => 'Sut mahsulotlari, kunjut, ko‘katlar';

  @override
  String get microHintMagnesium => 'Yong‘oq, grechka, dukkaklilar';

  @override
  String get microHintIron => 'Go‘sht, jigar, yasmiq';

  @override
  String get microHintZinc => 'Mol va qo‘y go‘shti, qovoq urug‘i';

  @override
  String get microHintPotassium => 'Kartoshka, banan, dukkaklilar';

  @override
  String get microHintSodium => 'Non, sho‘r pishloq, sho‘rvalar';

  @override
  String get microHintB12 => 'Mol go‘shti, tuxum, sut mahsulotlari';

  @override
  String get microHintSelenium => 'Baliq, tuxum, go‘sht';

  @override
  String get microHintVitE => 'Yong‘oq, urug‘lar, o‘simlik moyi';

  @override
  String get microHintVitC => 'Qalampir, sitrus, anor';

  @override
  String get microHintVitA => 'Sabzi, qovoq, ismaloq';

  @override
  String get targetsTitle => 'Sizning me’yorlaringiz';

  @override
  String get targetsSubtitle =>
      'Profilingiz va so‘nggi 4 hafta mashg‘ulotlari asosida';

  @override
  String get targetsGoal => 'Maqsad';

  @override
  String get targetsLoseFat => 'Yog‘ yo‘qotish';

  @override
  String get targetsMaintain => 'Saqlash';

  @override
  String get targetsLeanBulk => 'Sifatli massa';

  @override
  String get targetsBmr => 'Bazal metabolizm';

  @override
  String targetsBmrFormula(String weight, String height, String age) {
    return 'Mifflin-St Jeor · $weight kg, $height sm, $age yosh';
  }

  @override
  String targetsActivity(String factor) {
    return '× $factor faollik';
  }

  @override
  String targetsHours(String hours) {
    return 'FITRIX’da haftasiga $hours soat mashg‘ulot';
  }

  @override
  String targetsHoursEstimated(String hours) {
    return 'Taxminan haftasiga $hours soat: 4 hafta ichida mashg‘ulot yo‘q';
  }

  @override
  String get targetsAdjLose => 'Yog‘ yo‘qotish uchun −15%';

  @override
  String get targetsAdjMaintain => 'Vaznni saqlash';

  @override
  String get targetsAdjBulk => '+10% sifatli massa';

  @override
  String get targetsDaily => 'Kunlik me’yor';

  @override
  String targetsProteinG(String g) {
    return 'Oqsil · $g g';
  }

  @override
  String targetsFatG(String g) {
    return 'Yog‘ · $g g';
  }

  @override
  String targetsCarbsG(String g) {
    return 'Uglevodlar · $g g';
  }

  @override
  String targetsPerKg(String value) {
    return 'Tana vazni kg ga $value g';
  }

  @override
  String targetsFatPerKg(String value, String pct) {
    return 'kg ga $value g, kaloriyaning taxminan $pct%';
  }

  @override
  String get targetsCarbsNote => 'Qolgan kaloriyalar';

  @override
  String get targetsAuto => 'avto';

  @override
  String get targetsSave => 'Me’yorlarni saqlash';

  @override
  String get progressOverall => 'Umumiy';

  @override
  String get progressEmpty => 'Yuklamani ko‘rish uchun mashg‘ulotni yozing';

  @override
  String get progressLoadThisWeek => 'Shu haftadagi yuklama';

  @override
  String get progressLoadNote => 'seans RPE × daq';

  @override
  String get progressAu => 'shartli birlik';

  @override
  String progressPercentOfUsual(int percent) {
    return 'odatdagidan $percent%';
  }

  @override
  String get progressFitness => 'Tayyorgarlik';

  @override
  String get progressFatigue => 'Charchoq';

  @override
  String get progressForm => 'Holat';

  @override
  String get progress42Day => '42 kunlik yuklama';

  @override
  String get progress7Day => '7 kunlik yuklama';

  @override
  String get progressEstimated =>
      'Taxminiy: ba’zi mashg‘ulotlar uchun zo‘riqish 6 deb olingan';

  @override
  String get progressFormFresh => 'Tetik';

  @override
  String get progressFormNeutral => 'O‘rtacha';

  @override
  String get progressFormTired => 'Charchagan';

  @override
  String get progressRecords => 'Rekordlar';

  @override
  String get progressRecordsThisWeek => 'shu hafta';

  @override
  String get progressBalance => 'Yuklama balansi';

  @override
  String get progressBandLow => 'Past';

  @override
  String get progressBandSweet => 'Optimal';

  @override
  String get progressBandRisky => 'Xavfli';

  @override
  String get progressBalanceLow => 'Juda kam';

  @override
  String get progressBalanceSweet => 'Optimal 0,8–1,3';

  @override
  String get progressBalanceRisky => 'Xavfli';

  @override
  String get progressFelixInsight => 'Felix fikri';

  @override
  String get progressInsightLow =>
      'So‘nggi yuklamangiz odatdagidan past. 0,8 dan oshish uchun shu hafta yana bitta mashg‘ulot qo‘shing.';

  @override
  String get progressInsightSweet =>
      'Yuklamangiz optimal oraliqda. Ritmni saqlang va yengil bo‘lgan joyda og‘irlikni oshiring.';

  @override
  String get progressInsightRisky =>
      'Yuklamangiz odatdagidan oshib ketdi. Keyingi mashg‘ulotlarni yengilroq qiling va yaxshi uxlang.';

  @override
  String get progressLiftsE1rm => 'Mashqlar · e1RM';

  @override
  String get progressBodyWeight => 'Tana vazni';

  @override
  String get loadTitle => 'Mashg‘ulot yuklamasi';

  @override
  String loadSubtitle(String sport) {
    return '$sport · seans RPE × daqiqa';
  }

  @override
  String get loadAllSports => 'Barcha sport turlari';

  @override
  String loadWeeks(int count) {
    return '$count hafta';
  }

  @override
  String get loadFitnessExplain =>
      '42 kunlik o‘rtacha yuklamangiz. Muntazam mashq qilsangiz sekin o‘sadi.';

  @override
  String get loadFatigueExplain =>
      '7 kunlik yuklamangiz. Og‘ir haftalardan keyin ko‘tariladi, dam olsangiz tez tushadi.';

  @override
  String get loadFormExplain =>
      'Tayyorgarlik minus charchoq. Musbat bo‘lsa tetiksiz: musobaqa, sinov yoki rekord vaqti.';

  @override
  String get loadByWeek => 'Haftalar bo‘yicha';

  @override
  String loadAvg(String value) {
    return 'shartli birlik · o‘rtacha $value';
  }

  @override
  String get loadThisWeek => 'Shu';

  @override
  String get loadNextWeek => 'Keyingi hafta';

  @override
  String loadAim(String value) {
    return 'Taxminan $value shartli birlikni maqsad qiling, so‘nggi o‘rtacha haftangizga yaqin.';
  }

  @override
  String get loadChartEmpty => 'Yuklama haqida ma’lumot hali kam';

  @override
  String get recordsTitle => 'Rekordlar';

  @override
  String recordsSummary(int count, int sports) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta shaxsiy rekord',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sports,
      locale: localeName,
      other: '$sports ta sport turi',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get recordsAll => 'Hammasi';

  @override
  String get recordsThisMonth => 'Shu oy';

  @override
  String get recordsBestStreak => 'Eng yaxshi seriya';

  @override
  String recordsWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hafta',
    );
    return '$_temp0';
  }

  @override
  String recordsMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ta rekord',
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
      other: '$count takror',
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
      other: '+$count takror',
    );
    return '$_temp0';
  }

  @override
  String get recordsToday => 'bugun';

  @override
  String get recordsYesterday => 'kecha';

  @override
  String recordsDaysAgo(int count) {
    return '$count kun oldin';
  }

  @override
  String get recordsEmpty =>
      'Rekordlar hali yo‘q. Mashg‘ulotda avvalgi natijani yangilang, u shu yerda paydo bo‘ladi.';

  @override
  String get liftTitle => 'Mashqlar';

  @override
  String get liftEstimated => 'Taxminiy 1TM · Epley';

  @override
  String liftSince(String date, String kg, String reps, String since) {
    return '$since dan beri · eng yaxshi yondashuv $kg × $reps, $date';
  }

  @override
  String liftBestSet(String date, String kg, String reps) {
    return 'eng yaxshi yondashuv $kg × $reps, $date';
  }

  @override
  String get liftChartE1rm => 'e1RM';

  @override
  String get liftChartTop => 'Eng yaxshi yondashuv vazni';

  @override
  String get liftStrengthLevel => 'Kuch darajasi';

  @override
  String get liftLevelBeginner => 'Boshlang‘ich';

  @override
  String get liftLevelNovice => 'Yangi boshlovchi';

  @override
  String get liftLevelIntermediate => 'O‘rta';

  @override
  String get liftLevelAdvanced => 'Ilg‘or';

  @override
  String get liftLevelElite => 'Elita';

  @override
  String liftRatio(String ratio) {
    return '$ratio × tana vazni';
  }

  @override
  String liftNextBand(String kg, String level, String ratio) {
    return '$level — $ratio × · $kg';
  }

  @override
  String get liftTopBand => 'Eng yuqori daraja egallangan';

  @override
  String get liftNeedWeight =>
      'Kuch darajasini ko‘rish uchun tana vazningizni yozing.';

  @override
  String get liftNextSession => 'Keyingi mashg‘ulot';

  @override
  String get liftReserve => '2 takror zaxirada';

  @override
  String get liftColSet => 'Yondashuv';

  @override
  String get liftCol1rm => '%1TM';

  @override
  String get liftColLoad => 'Og‘irlik';

  @override
  String get liftColReps => 'Takror';

  @override
  String get liftTopSet => 'Asosiy';

  @override
  String get liftBackOff => 'Yengil';

  @override
  String get liftVolume => 'Hajm';

  @override
  String get liftFelix => 'Felix';

  @override
  String liftPaceUp(String kg) {
    return 'Barqaror: haftasiga $kg.';
  }

  @override
  String liftPaceTo(String date, String kg, String ratio) {
    return 'Barqaror: haftasiga $kg. Shu sur’atda $ratio × tana vazniga taxminan $date da yetasiz.';
  }

  @override
  String get liftPaceFlat =>
      'So‘nggi paytda e1RM o‘smayapti. Bir yengil hafta, keyin yana oldinga.';

  @override
  String get liftNone =>
      'Og‘irlikli mashq bilan mashg‘ulotni tugating, mashqlar shu yerda ko‘rinadi.';

  @override
  String bodyPerWeek(String value) {
    return '$value / hafta';
  }

  @override
  String bodyTrendLine(String goal, int weeks) {
    return '$weeks haftalik trend · maqsad: $goal';
  }

  @override
  String bodyTrendNone(String goal) {
    return 'Trend uchun o‘lchovlar hali kam · maqsad: $goal';
  }

  @override
  String bodyGoalLoseFat(String unit) {
    return 'yog‘ni kamaytirish −0,3…−0,7 $unit / hafta';
  }

  @override
  String bodyGoalMaintain(String unit) {
    return 'vaznni saqlash ±0,2 $unit / hafta';
  }

  @override
  String bodyGoalLeanBulk(String unit) {
    return 'sof massa +0,2…+0,4 $unit / hafta';
  }

  @override
  String get bodyGoalNameLoseFat => 'yog‘ni kamaytirish';

  @override
  String get bodyGoalNameMaintain => 'saqlash';

  @override
  String get bodyGoalNameLeanBulk => 'sof massa';

  @override
  String bodyOffTrack(String goal) {
    return 'Maqsaddan chetda: $goal';
  }

  @override
  String bodyAdd(int kcal) {
    return 'Trend maqsaddan past. Kuniga taxminan $kcal kkal qo‘shing, asosan mashg‘ulot atrofida uglevodlar.';
  }

  @override
  String bodyCut(int kcal) {
    return 'Trend maqsaddan yuqori. Kuniga taxminan $kcal kkal kamaytiring, asosan yog‘ va shirin ichimliklardan.';
  }

  @override
  String get bodyUpdateTargets => 'Normalarimni yangilash';

  @override
  String get bodyRange8 => '8 hafta';

  @override
  String get bodyRange26 => '6 oy';

  @override
  String get bodyRange52 => 'Yil';

  @override
  String get bodyLegendTrend => 'Trend';

  @override
  String get bodyLegendWeighIns => 'O‘lchovlar';

  @override
  String get bodyLegendGoal => 'Maqsad oralig‘i';

  @override
  String get bodyToday => 'Bugun';

  @override
  String get bodyWeighIns => 'O‘lchovlar';

  @override
  String get bodyWeighInsNote => 'ertalab, hojatxonadan keyin';

  @override
  String get bodyLog => 'Bugungi vaznni yozish';

  @override
  String get bodySheetTitle => 'Bugungi vazn';

  @override
  String get bodySave => 'Saqlash';

  @override
  String get bodyWeightRange => '20 dan 400 kg gacha vazn kiriting.';

  @override
  String get bodyEmpty => 'Trendni ko‘rish uchun vazningizni yozing.';

  @override
  String get programsTitle => 'Dasturlar';

  @override
  String get programsEntrySub => 'Kelgusi haftalar uchun tayyor rejalar';

  @override
  String get programsActiveEyebrow => 'Faol dastur';

  @override
  String programsWeekOf(int w, int n) {
    return '$w-hafta / $n';
  }

  @override
  String programsNext(String session, String day, String duration) {
    return 'Keyingisi: $session · $day · $duration';
  }

  @override
  String get programsNoneLeft => 'Dasturda mashg‘ulot qolmadi';

  @override
  String programsDoneOf(int done, int total) {
    return 'Bajarildi: $done / $total mashg‘ulot';
  }

  @override
  String get programsOpen => 'Ochish';

  @override
  String get programsPickedEyebrow => 'Siz uchun tanlandi';

  @override
  String programsPickedText(String name, int perWeek, String level) {
    return '$name · haftada $perWeek kun · $level. Maqsad va tajribangizga mos.';
  }

  @override
  String get programsFelixPick => 'Felix tanlovi';

  @override
  String get programsFilterAll => 'Hammasi';

  @override
  String get programsGoalMuscle => 'Mushak';

  @override
  String get programsGoalStrength => 'Kuch';

  @override
  String get programsGoalFatLoss => 'Yog‘ yo‘qotish';

  @override
  String get programsLevelBeginner => 'Boshlovchi';

  @override
  String get programsLevelIntermediate => 'O‘rta';

  @override
  String get programsLevelAdvanced => 'Ilg‘or';

  @override
  String get programsAtHome => 'Uyda';

  @override
  String get programsDaysAWeek => 'Haftada kunlar';

  @override
  String get programsAny => 'Istalgan';

  @override
  String programsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dastur',
      one: '$n dastur',
    );
    return '$_temp0';
  }

  @override
  String programsPerWeek(int n) {
    return '$n× / hafta';
  }

  @override
  String programsWeeksMin(int weeks, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks hafta',
      one: '$weeks hafta',
    );
    return '$_temp0 · $min daq';
  }

  @override
  String get programsDetails => 'Batafsil';

  @override
  String get programsEmptyFilter => 'Bu filtrlarga mos dastur yo‘q.';

  @override
  String get programTitle => 'Dastur';

  @override
  String get programNotFound => 'Bu dastur mavjud emas.';

  @override
  String get programLength => 'Davomiyligi';

  @override
  String get programPerWeekLabel => 'Haftada';

  @override
  String get programSessionLabel => 'Mashg‘ulot';

  @override
  String programWeeksShort(int n) {
    return '$n hafta';
  }

  @override
  String get programYourWeek => 'Sizning haftangiz';

  @override
  String programClashes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n to‘qnashuv',
      one: '$n to‘qnashuv',
    );
    return '$_temp0';
  }

  @override
  String get programRest => 'Dam';

  @override
  String programWorkoutsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mashg‘ulot',
      one: '$n mashg‘ulot',
    );
    return '$_temp0';
  }

  @override
  String programRir(int n) {
    return 'RIR $n';
  }

  @override
  String get programHowYouProgress => 'Qanday rivojlanasiz';

  @override
  String get programFelixEyebrow => 'Felix buni siz uchun moslashtirdi';

  @override
  String programFelixText(String days, String what) {
    return 'Mashg‘ulot kunlari $days va undan oldingi hamda keyingi kunlardan chetlab o‘tadi: $what. Boshlashda kunlarni o‘zgartirishingiz mumkin.';
  }

  @override
  String get programAskFelix => 'Felixdan so‘rash';

  @override
  String programAskFelixDraft(String name) {
    return '$name dasturi menga mosmi? Uni haftam bilan solishtiring.';
  }

  @override
  String get programStart => 'Dasturni boshlash';

  @override
  String programStartTitle(String name) {
    return 'Boshlash: $name';
  }

  @override
  String programStartSub(int weeks, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks hafta',
      one: '$weeks hafta',
    );
    return '$_temp0 · tugaydi: $date';
  }

  @override
  String get programStartDate => 'Boshlanish';

  @override
  String get programToday => 'Bugun';

  @override
  String get programPickDate => 'Sanani tanlash';

  @override
  String get programTrainingDays => 'Mashg‘ulot kunlari';

  @override
  String programDaysPicked(int n, int total) {
    return 'Tanlandi: $n / $total';
  }

  @override
  String programClashTitle(String day, String title) {
    return '$day: $title';
  }

  @override
  String get programClashHit =>
      'Bu kuni ikkita og‘ir mashg‘ulot to‘planadi. Boshqa kunni tanlang.';

  @override
  String get programClashNear =>
      'Dastur kuni unga yonma-yon. Oldin va keyin oyoqlaringizni asrang.';

  @override
  String get programClashAvoid =>
      'Dastur kunlari undan chetda, shuning uchun oldin va keyin tiklanasiz.';

  @override
  String get programStartWeights => 'Boshlang‘ich vaznlar';

  @override
  String get programFromRecords => 'rekordlaringizdan';

  @override
  String get programReplacePlan => 'Haftalik rejamni almashtirish';

  @override
  String get programReplaceSub =>
      'Yugurish va futbol qoladi, zal kunlari almashadi';

  @override
  String programStartOn(String date) {
    return '$date boshlash';
  }

  @override
  String get programReplacesActive => 'Bu faol dasturingizni almashtiradi.';

  @override
  String programProgressSub(int w, int n, String date) {
    return '$w-hafta / $n · boshlangan: $date';
  }

  @override
  String programDeloadNote(int w) {
    return '$w-hafta — yengillashtirilgan hafta: odatdagi yondashuvlarning taxminan yarmini bajaring.';
  }

  @override
  String get programTileSessions => 'Mashg‘ulotlar';

  @override
  String get programTileOnTime => 'O‘z vaqtida';

  @override
  String get programTileRecords => 'Rekordlar';

  @override
  String get programThisWeek => 'Shu hafta';

  @override
  String programWeekDone(int done, int total) {
    return '$done / $total bajarildi';
  }

  @override
  String get programNoSessionsWeek => 'Bu hafta dastur mashg‘ulotlari yo‘q.';

  @override
  String get programPlanned => 'rejalashtirilgan';

  @override
  String get programMainLifts => 'Asosiy mashqlar';

  @override
  String get programTopSetKg => 'eng yaxshi to‘plam, kg';

  @override
  String get programColLift => 'Mashq';

  @override
  String get programColStart => 'Boshi';

  @override
  String get programColNow => 'Hozir';

  @override
  String get programColGoal => 'Maqsad';

  @override
  String get programNextIncrease => 'Keyingi oshirish';

  @override
  String programNextIncreaseText(int sets, int reps, String lift, String kg) {
    return '$lift mashqida $sets × $reps ni ketma-ket ikki marta bajardingiz. Keyingi safar: $kg kg.';
  }

  @override
  String get programNoActive => 'Faol dastur yo‘q';

  @override
  String get programNoActiveBody =>
      'Kelgusi haftalar rejasini olish uchun dasturni tanlang.';

  @override
  String get programBrowse => 'Dasturlarni ko‘rish';

  @override
  String get programEnd => 'Dasturni tugatish';

  @override
  String get programEndTitle => 'Bu dasturni tugatamizmi?';

  @override
  String get programEndBody =>
      'Mashg‘ulotlar va rekordlar qoladi. Qolgan mashg‘ulotlar rejadan o‘chadi.';

  @override
  String programKgReps(String kg, int reps) {
    return '$kg kg × $reps';
  }

  @override
  String get coachAskFelix => 'Felixdan so‘rash';

  @override
  String gymAskFirstDraft(String sport) {
    return 'Birinchi mashg‘ulotim ($sport) oldidaman. Nimaga e‘tibor beray?';
  }

  @override
  String gymAskBackDraft(int days) {
    return 'Oxirgi mashg‘ulotim $days kun oldin bo‘lgan. Mashg‘ulotlarga qanday qaytsam bo‘ladi?';
  }

  @override
  String recoveryAskDraft(
      int score, String label, String sleep, String soreness) {
    return 'Bugungi tayyorligim $score% ($label). Uyqu $sleep, mushak og‘rig‘i: $soreness. Bugun qanchalik og‘ir mashq qilsam bo‘ladi?';
  }

  @override
  String planAskDraft(String a, String aDay, String b, String bDay) {
    return '$a ($aDay) va $b ($bDay) ikkalasi ham og‘ir. Haftamni qanday tuzsam bo‘ladi?';
  }

  @override
  String progressAskDraft(String week, String balance, String band) {
    return 'Bu haftadagi yuklamam $week, yuklama balansi $balance ($band). Keyingi haftada nima qilay?';
  }

  @override
  String liftAskDraft(String lift, String e1rm) {
    return '$lift bo‘yicha e1RM — $e1rm. O‘sishni qanday davom ettiray?';
  }

  @override
  String bodyAskDraft(String weight, String trend, String goal) {
    return 'Vaznim $weight, haftasiga $trend o‘zgaryapti. Maqsadim: $goal. Ovqatlanishimni qanday o‘zgartiray?';
  }

  @override
  String nutritionAskDraft(String kcal, String protein) {
    return 'Bugunga $kcal kkal va $protein g oqsil qoldi. Kechki ovqatga nima yeyay?';
  }

  @override
  String get nutritionCantFindDraft => 'Bu taomning kaloriyasini baholang: ';

  @override
  String get planEmptyBodyNextWeek =>
      'Keyingi hafta uchun zal mashqlarini bir bosishda rejalashtiring.';

  @override
  String programsPickedGoalText(String name, int perWeek, String level) {
    return '$name · haftada $perWeek kun · $level. Maqsadingizga mos.';
  }

  @override
  String programsPickedLevelText(String name, int perWeek, String level) {
    return '$name · haftada $perWeek kun · $level. Tajribangizga mos.';
  }

  @override
  String get programsStartEyebrow => 'Boshlash uchun';

  @override
  String programsStartText(String name, int perWeek, String level) {
    return '$name · haftada $perWeek kun · $level. Aniqroq tanlov uchun «Men haqimda» bo‘limida maqsad va tajribangizni kiriting.';
  }

  @override
  String get programDetailsTooltip => 'Dastur haqida';

  @override
  String nutritionKcalOver(String kcal) {
    return '$kcal kkal ortiqcha';
  }

  @override
  String get homeDoneForToday => 'Bugun uchun tayyor';

  @override
  String homeNextSession(String day, String title) {
    return 'Keyingisi: $day · $title';
  }

  @override
  String get homeNothingNext => 'Hozircha boshqa reja yo‘q';

  @override
  String chatFoodLogTo(String slot) {
    return 'Yozish: $slot';
  }

  @override
  String chatFoodItemMeta(String grams, String kcal) {
    return '$grams g · $kcal kkal';
  }

  @override
  String chatFoodEstimateName(String name) {
    return '≈ $name';
  }

  @override
  String get chatFoodEstimateNote => '≈ Feliks bahosi';

  @override
  String chatFoodTotal(String kcal, String protein) {
    return '$kcal kkal · $protein g oqsil';
  }

  @override
  String chatFoodAdd(String kcal) {
    return 'Mening ovqatlanishimga qo‘shish · $kcal kkal';
  }

  @override
  String chatFoodAdded(String slot) {
    return 'Qo‘shildi: $slot';
  }

  @override
  String get chatActionWeightSetFirst => 'Avval vazningizni kiriting';

  @override
  String get chatActionSetWeight => 'Vaznni kiritish';

  @override
  String get gymDiscardAndStart => 'Bekor qilib boshlash';
}
