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
  String get mapTitle => 'Карта Fitrix';

  @override
  String get mapFilterAll => 'Все';

  @override
  String get mapFilterGyms => 'Залы';

  @override
  String get mapFilterParks => 'Парки';

  @override
  String get mapFilterTracks => 'Трассы';

  @override
  String get mapFilterPools => 'Бассейны';

  @override
  String get mapLocationOff => 'Геолокация выключена: показан центр Ташкента';

  @override
  String get mapHoursUnknown => 'Часы работы не указаны';

  @override
  String mapAway(String distance) {
    return '$distance от вас';
  }

  @override
  String get mapShowRoute => 'Показать маршрут';

  @override
  String get mapHideRoute => 'Скрыть маршрут';

  @override
  String get mapModesLabel => 'Как добраться';

  @override
  String get mapModeWalk => 'Пешком';

  @override
  String get mapModeBike => 'Велосипед';

  @override
  String get mapModeCar => 'Авто';

  @override
  String get mapModeMetro => 'Метро';

  @override
  String get mapComputing => 'Считаем маршруты…';

  @override
  String get mapCoverage => 'Маршруты есть только для центра Ташкента';

  @override
  String get mapNoRoute => 'Для этого способа маршрута нет';

  @override
  String get mapMetroNoHelp =>
      'Метро не поможет в этой поездке: нет пары станций, которая экономит время.';

  @override
  String get mapPlanFailed =>
      'Не удалось построить маршруты. Выберите другое место.';

  @override
  String mapMinutes(int n) {
    return '$n мин';
  }

  @override
  String mapHoursMinutes(int h, int m) {
    return '$h ч $m мин';
  }

  @override
  String mapArrive(String duration, String time) {
    return '$duration · прибытие в $time';
  }

  @override
  String mapRide(String from, String to, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count остановки',
      many: '$count остановок',
      few: '$count остановки',
      one: '$count остановка',
    );
    return '$from → $to, $_temp0';
  }

  @override
  String mapWalkTotal(String distance) {
    return 'Всего пешком: $distance';
  }

  @override
  String get mapWalkingFaster => 'пешком здесь быстрее';

  @override
  String mapNoteWalk(String distance) {
    return '$distance пешком';
  }

  @override
  String mapNoteBike(String distance) {
    return '$distance на велосипеде, включая дорожки';
  }

  @override
  String mapNoteCar(String distance) {
    return '$distance на авто, без учёта пробок, 2 мин на парковку';
  }

  @override
  String mapMeters(int n) {
    return '$n м';
  }

  @override
  String mapKilometers(String n) {
    return '$n км';
  }
}
