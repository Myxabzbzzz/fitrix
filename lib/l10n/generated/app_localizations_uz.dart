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
    return 'Bugun $workout bilan boshlang. Undan keyin Felix rejani moslashtiradi.';
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
  String chatActionWeightSet(String to) {
    return 'Vaznni $to kg ga yangilash';
  }

  @override
  String chatActionWeightUnknown(String delta) {
    return 'Vazn o‘zgarishi: $delta kg. Avval profilda joriy vazningizni kiriting.';
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
      'Majburiy emas. Felix keyingi mashg‘ulotlarni rejalashda foydalanadi.';

  @override
  String workoutOverallCaption(int n, String label) {
    return 'RPE $n · $label. Felix ertangi rejani tuzishda foydalanadi.';
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
      'Bugun o‘zingizni qanday his qilyapsiz? 20 soniya, va Felix rejangizni moslaydi.';

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
}
