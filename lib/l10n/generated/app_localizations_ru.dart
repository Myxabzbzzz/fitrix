// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get continueButton => 'Продолжить';

  @override
  String get cancel => 'Отмена';

  @override
  String get introStart => 'Начать путь';

  @override
  String get aboutMeTitle => 'Обо мне';

  @override
  String get age => 'Возраст';

  @override
  String get weight => 'Вес';

  @override
  String get height => 'Рост';

  @override
  String get unitKg => 'кг';

  @override
  String get unitCm => 'см';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutTitle => 'Выйти из аккаунта?';

  @override
  String get signOutLocalBody =>
      'Профиль, чаты и тренировки хранятся только на этом устройстве и будут удалены.';

  @override
  String get signOutAccountBody =>
      'Профиль, тренировки и чаты сохранены в аккаунте и будут удалены с этого устройства. Войдите с тем же email, чтобы вернуть их.';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountBody =>
      'Аккаунт FITRIX и всё, что в нём есть, будут удалены навсегда: профиль, планы тренировок, история тренировок и чаты с Felix — на всех ваших устройствах.';

  @override
  String get deleteAccountAppleNote => 'Apple попросит подтвердить действие.';

  @override
  String get deleteForGoodTitle => 'Удалить навсегда?';

  @override
  String get deleteForGoodBody => 'Удалённый аккаунт восстановить нельзя.';

  @override
  String get deletingAccount => 'Удаляем аккаунт…';

  @override
  String deleteAccountFailed(String reason) {
    return 'Не удалось удалить аккаунт. $reason';
  }

  @override
  String get undo => 'Отменить';

  @override
  String workoutDeleted(String name) {
    return '«$name» удалена';
  }

  @override
  String get syncFailed =>
      'Не удалось синхронизировать. Проверьте подключение и попробуйте ещё раз.';

  @override
  String get discoverTitle => 'Обзор';

  @override
  String get discoverNotifications => 'Уведомления';

  @override
  String get discoverNoNotifications => 'Новых уведомлений нет';

  @override
  String get discoverForYou => 'Для вас';

  @override
  String get discoverChallenges => 'Челленджи';

  @override
  String get discoverPrograms => 'Программы';

  @override
  String get discoverArticles => 'Статьи';

  @override
  String get discoverThisWeek => 'На этой неделе';

  @override
  String get discoverJoin => 'Участвовать';

  @override
  String get discoverJoined => 'Вы участвуете';

  @override
  String get discoverSignInToJoin => 'Войдите, чтобы участвовать в челленджах';

  @override
  String get discoverSignIn => 'Войти';

  @override
  String get discoverJoinFailed =>
      'Не удалось присоединиться. Попробуйте ещё раз.';

  @override
  String get discoverProgramsForYou => 'Программы для вас';

  @override
  String get discoverAll => 'Все';

  @override
  String discoverProgramSoon(String title) {
    return '$title: предпросмотр скоро появится';
  }

  @override
  String get discoverFelixEyebrow => 'Совет от Феликса';

  @override
  String get discoverFelixTitle => 'Отдых делает сильнее';

  @override
  String get discoverFelixMessage =>
      'Два лёгких дня в неделю снижают риск травм и помогают расти в весах.';

  @override
  String get discoverAskFelix => 'Спросить Феликса';

  @override
  String get discoverRead => 'Читать';

  @override
  String discoverMinRead(int n) {
    return '$n мин чтения';
  }

  @override
  String get discoverArticleMissing => 'Эта статья недоступна.';

  @override
  String get shopTitle => 'Магазин';

  @override
  String shopCartLabel(int n) {
    return 'Корзина, товаров: $n';
  }

  @override
  String get shopSearchHint => 'Поиск товаров';

  @override
  String get shopAll => 'Все';

  @override
  String get shopCatSupplements => 'Добавки';

  @override
  String get shopCatEquipment => 'Инвентарь';

  @override
  String get shopCatApparel => 'Одежда';

  @override
  String get shopProBlurb =>
      'Безлимитные чаты с Феликсом, индивидуальные планы и разбор техники.';

  @override
  String get shopProButton => 'Подробнее';

  @override
  String get shopProSoonTitle => 'FITRIX Pro скоро появится';

  @override
  String get shopProSoonBody => 'Мы сообщим, как только всё будет готово.';

  @override
  String get shopGotIt => 'Понятно';

  @override
  String shopNothingFound(String query) {
    return 'По запросу «$query» ничего не найдено.';
  }

  @override
  String shopAdd(String name) {
    return 'Добавить: $name';
  }

  @override
  String get shopCartTitle => 'Корзина';

  @override
  String get shopClose => 'Закрыть';

  @override
  String get shopRemoveOne => 'Убрать один';

  @override
  String get shopAddOne => 'Добавить один';

  @override
  String get shopTotal => 'Итого';

  @override
  String get shopPlaceOrder => 'Оформить заказ';

  @override
  String get shopCartEmpty =>
      'Корзина пуста. Нажмите + у любого товара, чтобы добавить его.';

  @override
  String get shopOrderPlaced => 'Заказ оформлен';

  @override
  String get shopSignInToOrder => 'Войдите, чтобы оформить заказ';

  @override
  String get shopOrderFailed =>
      'Не удалось оформить заказ. Проверьте подключение.';

  @override
  String shopOrderRejected(String message) {
    return 'Заказ отклонён: $message';
  }

  @override
  String get shopRetry => 'Повторить';
}
