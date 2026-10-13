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
  String progressSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подхода',
      many: '$count подходов',
      few: '$count подхода',
      one: '$count подход',
    );
    return '$_temp0';
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
  String get chatQuickTired => 'Сегодня нет сил';

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
  String get discoverFelixEyebrow => 'Совет от Felix';

  @override
  String get discoverFelixTitle => 'Отдых делает сильнее';

  @override
  String get discoverFelixMessage =>
      'Два лёгких дня в неделю снижают риск травм и помогают расти в весах.';

  @override
  String get discoverAskFelix => 'Спросить Felix';

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
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Корзина, $n товара',
      many: 'Корзина, $n товаров',
      few: 'Корзина, $n товара',
      one: 'Корзина, $n товар',
      zero: 'Корзина пуста',
    );
    return '$_temp0';
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
      'Безлимитные чаты с Felix, индивидуальные планы и разбор техники.';

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
  String get shopRetry => 'Повторить';

  @override
  String get shopNoProducts => 'Товаров пока нет';

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

  @override
  String workoutSetsProgress(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done из $total подхода',
      many: '$done из $total подходов',
      few: '$done из $total подходов',
      one: '$done из $total подхода',
    );
    return '$_temp0';
  }

  @override
  String workoutSetCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n подхода',
      many: '$n подходов',
      few: '$n подхода',
      one: '$n подход',
    );
    return '$_temp0';
  }

  @override
  String workoutSetDone(int n) {
    return 'Подход $n выполнен';
  }

  @override
  String get workoutFinishTitle => 'Завершить тренировку?';

  @override
  String get workoutFinishNoSets =>
      'Ни один подход не отмечен, поэтому тренировка не будет сохранена.';

  @override
  String workoutFinishSummary(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: 'Выполнено $done из $total подхода.',
      many: 'Выполнено $done из $total подходов.',
      few: 'Выполнено $done из $total подходов.',
      one: 'Выполнено $done из $total подхода.',
    );
    return '$_temp0 Тренировка будет сохранена в вашей истории.';
  }

  @override
  String get workoutKeepGoing => 'Продолжить';

  @override
  String get workoutFinish => 'Завершить';

  @override
  String get workoutSaved => 'Тренировка сохранена в «Мой прогресс»';

  @override
  String get workoutNoExercises =>
      'Упражнений пока нет. Нажмите и удерживайте карточку тренировки, чтобы добавить.';

  @override
  String get workoutAddSet => 'Добавить подход';

  @override
  String get workoutFinishButton => 'Завершить тренировку';

  @override
  String get workoutColSet => '#';

  @override
  String get workoutColPrevious => 'Ранее';

  @override
  String get workoutColKg => 'Кг';

  @override
  String get workoutColReps => 'Повт.';

  @override
  String get gymCoachFirstTitle => 'Готовы к первой тренировке?';

  @override
  String gymCoachFirstMessage(String workout) {
    return 'Начните сегодня ($workout). После этого Felix скорректирует план.';
  }

  @override
  String get gymCoachBackTitle => 'С возвращением';

  @override
  String gymCoachBackMessage(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Ваша последняя тренировка была $_temp0 назад. Лёгкое занятие сегодня поможет вернуться в ритм.';
  }

  @override
  String get gymFinishCurrentTitle => 'Завершить текущую тренировку?';

  @override
  String gymFinishCurrentBody(String current, String next) {
    return '«$current» ещё не завершена. Начать «$next» вместо неё?';
  }

  @override
  String get gymMyWorkouts => 'Мои тренировки';

  @override
  String get gymNewWorkout => 'Новая тренировка';

  @override
  String get gymNewWorkoutHint => 'например, Плечи';

  @override
  String get gymAdd => 'Добавить';

  @override
  String get gymEditNameHint => 'Название тренировки';

  @override
  String get gymEditDelete => 'Удалить тренировку';

  @override
  String get gymEditAddExerciseHint => 'Добавить упражнение';

  @override
  String get gymEditSave => 'Сохранить';

  @override
  String get sportGym => 'Спортзал';

  @override
  String get sportFitness => 'Фитнес';

  @override
  String get sportCycling => 'Велоспорт';

  @override
  String get sportRunning => 'Бег';

  @override
  String get sportFootball => 'Футбол';

  @override
  String get sportWinterSports => 'Зимние виды спорта';

  @override
  String get sportWinterSportsTile => 'ЗИМНИЕ\nВИДЫ СПОРТА';

  @override
  String get tabDiscover => 'Обзор';

  @override
  String get tabShop => 'Магазин';

  @override
  String get tabHome => 'Главная';

  @override
  String get tabFelix => 'Felix';

  @override
  String get tabProfile => 'Профиль';

  @override
  String get homeTileProgress => 'МОЙ\nПРОГРЕСС';

  @override
  String get homeTileNutrition => 'МОЁ\nПИТАНИЕ';

  @override
  String get homeTileWorkouts => 'МОИ\nТРЕНИРОВКИ';

  @override
  String get homeTileShop => 'МАГАЗИН';

  @override
  String get homeTileMap => 'КАРТА\nFITRIX';

  @override
  String get homeMenuMap => 'Карта Fitrix';

  @override
  String get chatTyping => 'Felix печатает';

  @override
  String chatError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get chatStart => 'Начать';

  @override
  String get chatMessageHint => 'Сообщение...';

  @override
  String get chatAllChats => 'Все чаты';

  @override
  String get chatTapToRetry => 'Нажмите, чтобы повторить';

  @override
  String get progressWeightTitle => 'Мой вес (кг)';

  @override
  String get progressCaloriesTitle => 'Калории: потреблено и сожжено';

  @override
  String signInCodeResent(String email) {
    return 'Мы отправили новый код на $email';
  }

  @override
  String get signInChangeEmail => 'Изменить email';

  @override
  String get profileFieldName => 'Имя';

  @override
  String get profileFieldSurname => 'Фамилия';

  @override
  String get profileFieldWeightKg => 'Вес, кг';

  @override
  String get profileFieldHeightCm => 'Рост, см';

  @override
  String get signInAgainTitle => 'Войдите снова';

  @override
  String get signInAgainSubtitle =>
      'Сеанс завершён. Введите email, чтобы продолжить.';

  @override
  String get signInCreateTitle => 'Создайте аккаунт';

  @override
  String get signInCreateSubtitle =>
      'Введите email, чтобы зарегистрироваться в приложении';

  @override
  String get signInGetCode => 'Получить код';

  @override
  String get signInTryAgain => 'Повторить';

  @override
  String get signInOr => 'или';

  @override
  String get signInTermsPrefix => 'Нажимая «Продолжить», вы принимаете ';

  @override
  String get signInTerms => 'Условия использования';

  @override
  String get signInTermsAnd => ' и ';

  @override
  String get signInPrivacy => 'Политику конфиденциальности';

  @override
  String get signInTermsSuffix => '.';

  @override
  String signInContinueWith(String provider) {
    return 'Продолжить через $provider';
  }

  @override
  String get signInCheckEmailTitle => 'Проверьте почту';

  @override
  String signInCodePrompt(String length, String email) {
    return 'Введите $length-значный код, который мы отправили на\n$email';
  }

  @override
  String get signInResend => 'Отправить код ещё раз';

  @override
  String signInResendIn(String time) {
    return 'Отправить код ещё раз через $time';
  }

  @override
  String get signInSpamNote => 'Не нашли письмо? Проверьте папку «Спам».';

  @override
  String signInComingSoon(String provider) {
    return 'Вход через $provider скоро появится. Пока используйте email.';
  }

  @override
  String get signInProfileLoadOffline =>
      'Вы вошли, но профиль не удалось загрузить. Проверьте подключение и повторите попытку.';

  @override
  String get signInProfileLoadFailed =>
      'Вы вошли, но профиль не удалось загрузить. Попробуйте ещё раз.';

  @override
  String get signInErrInvalidCode =>
      'Код неверный или устарел. Проверьте последнее письмо или запросите новый код.';

  @override
  String get signInErrRateLimited =>
      'Слишком много попыток. Подождите минуту и повторите.';

  @override
  String get signInErrNetwork =>
      'Нет соединения. Проверьте интернет и повторите попытку.';

  @override
  String get signInErrInvalidEmail => 'Введите корректный адрес email.';

  @override
  String get signInErrUnknown => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String signInErrProviderDisabled(String provider) {
    return 'Вход через $provider на сервере пока не настроен. Пока используйте email.';
  }

  @override
  String signInErrProviderUnavailable(String provider) {
    return 'Вход через $provider недоступен на этом устройстве. Используйте email.';
  }

  @override
  String signInErrSocialFailed(String provider) {
    return 'Не удалось войти через $provider. Повторите попытку или используйте email.';
  }

  @override
  String get profileErrNameRequired => 'Введите имя';

  @override
  String get profileErrNameTooLong => 'Имя слишком длинное';

  @override
  String get profileErrSurnameTooLong => 'Фамилия слишком длинная';

  @override
  String get profileErrAgeRequired => 'Введите возраст';

  @override
  String get profileErrAgeWhole => 'Возраст должен быть целым числом';

  @override
  String profileErrAgeRange(String min, String max) {
    return 'Возраст должен быть от $min до $max';
  }

  @override
  String get profileErrWeightRequired => 'Введите вес';

  @override
  String get profileErrWeightNumber => 'Введите вес числом';

  @override
  String profileErrWeightRange(String min, String max) {
    return 'Вес должен быть от $min до $max кг';
  }

  @override
  String get profileErrHeightRequired => 'Введите рост';

  @override
  String get profileErrHeightNumber => 'Введите рост числом';

  @override
  String profileErrHeightRange(String min, String max) {
    return 'Рост должен быть от $min до $max см';
  }

  @override
  String get signInUnavailable =>
      'Аккаунты сейчас недоступны. Попробуйте позже.';

  @override
  String get programLevelBeginner => 'Начинающий';

  @override
  String get programLevelMedium => 'Средний';

  @override
  String get programLevelAdvanced => 'Продвинутый';

  @override
  String get shopOrderUnavailable =>
      'Некоторые товары больше недоступны. Обновите корзину и попробуйте снова.';

  @override
  String get workoutKeyboardDone => 'Готово';

  @override
  String get workoutEditLabel => 'Редактировать тренировку';

  @override
  String get aboutMeSave => 'Сохранить';

  @override
  String get aboutMeSaved => 'Сохранено';

  @override
  String get aboutMeDiscardTitle => 'Отменить изменения?';

  @override
  String get aboutMeDiscardBody => 'Ваши правки в профиле не будут сохранены.';

  @override
  String get aboutMeDiscard => 'Отменить';

  @override
  String get aboutMeKeepEditing => 'Продолжить';

  @override
  String get aboutMeEmail => 'Эл. почта';

  @override
  String get aboutMeGoal => 'Цель';

  @override
  String get aboutMeGoalOther => 'Другое…';

  @override
  String get aboutMeGoalOtherHint => 'Опишите свою цель';

  @override
  String get aboutMeLevel => 'Уровень';

  @override
  String get aboutMeSports => 'Виды спорта';

  @override
  String get aboutMeSportsLimit => 'Можно выбрать до 6 видов спорта.';

  @override
  String get aboutGoalBuild => 'Набрать мышцы и силу';

  @override
  String get aboutGoalEndurance => 'Повысить выносливость';

  @override
  String get aboutGoalLose => 'Похудеть и подтянуться';

  @override
  String get aboutGoalHealthy => 'Стать здоровее и сбалансированнее';

  @override
  String get aboutGoalTrack => 'Просто следить за прогрессом';

  @override
  String get chatAddPhoto => 'Добавить фото';

  @override
  String get chatTakePhoto => 'Сделать фото';

  @override
  String get chatChooseFromLibrary => 'Выбрать из галереи';

  @override
  String get chatRemovePhoto => 'Убрать фото';

  @override
  String get chatPhotoTooLarge => 'Фото слишком большое. Попробуйте другое.';

  @override
  String get chatPhotoFailed =>
      'Не удалось получить фото. Проверьте доступ к камере и фото в настройках.';

  @override
  String get chatPhotoPrompt => 'Что скажешь об этом фото?';

  @override
  String get chatMicStart => 'Надиктовать сообщение';

  @override
  String get chatMicStop => 'Остановить диктовку';

  @override
  String get chatMicDenied =>
      'Felix пока вас не слышит. Откройте Настройки и разрешите FITRIX микрофон и распознавание речи.';

  @override
  String get chatPhotoViewer => 'Фото';

  @override
  String get chatPhotoUnavailable =>
      'Фото не найдено или слишком большое для отправки.';

  @override
  String get chatMicListening => 'Слушаю';

  @override
  String get chatMicStopped => 'Прослушивание остановлено';

  @override
  String get chatActionConfirm => 'Подтвердить';

  @override
  String get chatActionApplied => 'Добавлено ✓';

  @override
  String chatActionWeightChange(String from, String to) {
    return 'Обновить вес: $from → $to кг';
  }

  @override
  String chatActionWeightSet(String to) {
    return 'Обновить вес до $to кг';
  }

  @override
  String chatActionWeightUnknown(String delta) {
    return 'Изменение веса: $delta кг. Сначала укажите текущий вес в профиле.';
  }

  @override
  String chatActionWorkoutTitle(int count, String sport) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавить $count тренировки в «$sport»',
      many: 'Добавить $count тренировок в «$sport»',
      few: 'Добавить $count тренировки в «$sport»',
      one: 'Добавить $count тренировку в «$sport»',
    );
    return '$_temp0';
  }

  @override
  String chatActionWorkoutExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упражнения',
      many: '$count упражнений',
      few: '$count упражнения',
      one: '$count упражнение',
    );
    return '$_temp0';
  }

  @override
  String get chatActionMealTitle => 'Добавить в питание на сегодня';

  @override
  String chatActionMealTotal(String kcal) {
    return 'Всего $kcal ккал';
  }

  @override
  String chatActionWorkoutsAdded(String sport) {
    return 'Тренировки добавлены: $sport';
  }

  @override
  String get chatActionOpen => 'Открыть';

  @override
  String chatActionWeightDone(String from, String to) {
    return 'Вес обновлён: $from → $to кг';
  }

  @override
  String chatActionWeightDoneSet(String to) {
    return 'Вес обновлён: $to кг';
  }

  @override
  String get chatActionNoProfile =>
      'Сначала заполните профиль, тогда я смогу обновить вес.';

  @override
  String get chatActionError => 'Не удалось применить. Попробуйте ещё раз.';
}
