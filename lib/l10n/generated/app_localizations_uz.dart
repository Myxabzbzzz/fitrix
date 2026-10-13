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
    return 'Savat, mahsulotlar: $n';
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
}
