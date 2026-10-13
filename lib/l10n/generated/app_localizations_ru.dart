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
  String get homeToday => 'Сегодня';

  @override
  String homeTodayMeta(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упражнения',
      many: '$count упражнений',
      few: '$count упражнения',
      one: '$count упражнение',
    );
    return '$_temp0 · около $minutes мин';
  }

  @override
  String get homeStart => 'Начать';

  @override
  String get homeContinue => 'Продолжить';

  @override
  String get progressTitle => 'Мой прогресс';

  @override
  String get progressStrength => 'Сила';

  @override
  String progressNoWorkouts(String sport) {
    return 'Тренировок ($sport) пока нет. Завершите одну, отметив хотя бы один подход, и здесь появится ваш прогресс.';
  }

  @override
  String get progressRecentWorkouts => 'Последние тренировки';

  @override
  String get progressBody => 'Тело';

  @override
  String get progressSampleNote =>
      'Пример данных — отслеживание скоро появится.';

  @override
  String progressFirst(String value) {
    return 'Первое: $value';
  }

  @override
  String progressLatest(String value) {
    return 'Последнее: $value';
  }

  @override
  String progressCurrent(String value) {
    return 'Сейчас: $value';
  }

  @override
  String progressMonthAgo(String value) {
    return 'Месяц назад: $value';
  }

  @override
  String get progressIntake => 'Потреблено, в среднем';

  @override
  String get progressBurn => 'Сожжено, в среднем';

  @override
  String get progressKcalPerDay => 'ккал / день';

  @override
  String progressSets(String count) {
    return '$count подх.';
  }

  @override
  String get nutritionTitle => 'Моё питание';

  @override
  String nutritionOfGoal(String goal) {
    return 'из $goal ккал';
  }

  @override
  String nutritionLeft(String kcal) {
    return 'Осталось $kcal ккал на сегодня';
  }

  @override
  String get nutritionGoalReached => 'Цель на сегодня достигнута';

  @override
  String get nutritionProtein => 'Белки';

  @override
  String get nutritionCarbs => 'Углеводы';

  @override
  String get nutritionFat => 'Жиры';

  @override
  String get nutritionBreakfast => 'Завтрак';

  @override
  String get nutritionBreakfastItems => 'Овсянка, банан, кофе';

  @override
  String get nutritionLunch => 'Обед';

  @override
  String get nutritionLunchItems => 'Курица, рис, салат';

  @override
  String get nutritionSnack => 'Перекус';

  @override
  String get nutritionSnackItems => 'Йогурт и орехи';

  @override
  String get nutritionDinner => 'Ужин';

  @override
  String get nutritionNotLogged => 'Пока не записано';

  @override
  String nutritionKcal(String kcal) {
    return '$kcal ккал';
  }

  @override
  String get nutritionTipEyebrow => 'Совет Феликса';

  @override
  String get nutritionTipTitle => 'Белок на ужин';

  @override
  String get nutritionTipMessage =>
      'На ужин возьмите около 40 г белка. Курица, рис и зелень подойдут вашему плану.';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get profileWorkouts => 'тренировок';

  @override
  String get profileDayStreak => 'дней подряд';

  @override
  String get profileKgNow => 'кг сейчас';

  @override
  String get profileLanguage => 'Язык';

  @override
  String get profileTheme => 'Тема';

  @override
  String get profileThemeAuto => 'Авто';

  @override
  String get profileThemeLight => 'Светлая';

  @override
  String get profileThemeDark => 'Тёмная';

  @override
  String get chatQuickPlanWeek => 'Составь план на неделю';

  @override
  String get chatQuickEatToday => 'Что мне съесть сегодня?';

  @override
  String get chatQuickTired => 'Сегодня я устал';

  @override
  String get gymToday => 'Сегодня';

  @override
  String get gymStart => 'Начать';

  @override
  String get gymDone => 'Готово';

  @override
  String get gymAskFelix => 'Спросить';

  @override
  String gymCoachEyebrow(String sport) {
    return 'ИИ-ТРЕНЕР: $sport';
  }

  @override
  String gymTileCaption(int plans, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      plans,
      locale: localeName,
      other: '$plans плана',
      many: '$plans планов',
      few: '$plans плана',
      one: '$plans план',
    );
    return '$_temp0 · на этой неделе: $week';
  }
}
