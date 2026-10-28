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
  String get unitMcg => 'мкг';

  @override
  String get unitMg => 'мг';

  @override
  String get unitGrams => 'г';

  @override
  String get signOut => 'Выйти';

  @override
  String get signOutTitle => 'Выйти из аккаунта?';

  @override
  String get signOutLocalBody =>
      'Всё, что вы записали, хранится только на этом устройстве и будет удалено: профиль, тренировки, чаты, чек-ины, планы, питание и вес.';

  @override
  String get signOutAccountBody =>
      'Всё, что вы записали, сохранено в аккаунте и будет удалено с этого устройства. Войдите с той же почтой, чтобы вернуть данные.';

  @override
  String signOutPendingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count изменения ещё не попали в аккаунт (нет связи?). Если выйти сейчас, они удалятся.',
      many:
          '$count изменений ещё не попали в аккаунт (нет связи?). Если выйти сейчас, они удалятся.',
      few:
          '$count изменения ещё не попали в аккаунт (нет связи?). Если выйти сейчас, они удалятся.',
      one:
          '$count изменение ещё не попало в аккаунт (нет связи?). Если выйти сейчас, оно удалится.',
    );
    return '$_temp0';
  }

  @override
  String get signOutAnyway => 'Всё равно выйти';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountBody =>
      'Аккаунт FITRIX и всё, что в нём есть, будут удалены навсегда: профиль, планы тренировок, история тренировок, чаты с Felix, чек-ины, питание и вес тела — на всех ваших устройствах.';

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
  String get nutritionTitle => 'Моё питание';

  @override
  String nutritionOfGoal(String goal) {
    return 'из $goal ккал';
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
  String get nutritionLunch => 'Обед';

  @override
  String get nutritionSnack => 'Перекус';

  @override
  String get nutritionDinner => 'Ужин';

  @override
  String get nutritionNotLogged => 'Пока не записано';

  @override
  String nutritionKcal(String kcal) {
    return '$kcal ккал';
  }

  @override
  String get profileTitle => 'Профиль';

  @override
  String profileWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'тренировки',
      many: 'тренировок',
      few: 'тренировки',
      one: 'тренировка',
    );
    return '$_temp0';
  }

  @override
  String profileDayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дня подряд',
      many: 'дней подряд',
      few: 'дня подряд',
      one: 'день подряд',
    );
    return '$_temp0';
  }

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
  String get shopProSoonBody =>
      'Пока недоступно. Появится здесь в одном из следующих обновлений.';

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
  String get workoutFinishButton => 'Завершить';

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
    return 'Начните сегодня ($workout). В следующий раз Felix подскажет веса по вашим записям.';
  }

  @override
  String coachFirstMessageSport(String workout) {
    return 'Начните сегодня: $workout. Дальше Felix будет советовать по вашим записям.';
  }

  @override
  String get coachFirstMessageNoPlan =>
      'Запишите первую тренировку, и дальше Felix будет советовать по вашим записям.';

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
  String get gymFinishCurrentTitle => 'Отбросить текущую тренировку?';

  @override
  String gymFinishCurrentBody(String current, String next) {
    return '«$current» ещё идёт и не будет сохранена. Начать «$next» вместо неё?';
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
    return 'Введите $length-значный код, который мы отправили на $email';
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
  String get programLevelBeginner => 'Новичок';

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

  @override
  String get chatActionUndoError => 'Не удалось отменить. Попробуйте ещё раз.';

  @override
  String get chatActionWeightChangedSince =>
      'Вес с тех пор изменился — ничего не отменено';

  @override
  String get unitTonnes => 'т';

  @override
  String workoutLiveCaption(int x, int y, String t) {
    return 'Подход $x из $y · поднято $t';
  }

  @override
  String get workoutColRpe => 'RPE';

  @override
  String workoutRestShort(String time) {
    return 'отдых $time';
  }

  @override
  String workoutBestShort(String value) {
    return 'лучший $value';
  }

  @override
  String get workoutPr => 'Рекорд';

  @override
  String get workoutE1rm => 'e1RM';

  @override
  String get workoutBodyweight => 'СВ';

  @override
  String workoutFelixLine(String last, String next) {
    return 'В прошлый раз $last. Сегодня попробуйте $next кг.';
  }

  @override
  String get workoutRestLabel => 'Отдых';

  @override
  String workoutRestNext(String label) {
    return 'Далее: $label';
  }

  @override
  String workoutNextSet(int n, String kg, int reps) {
    return 'Подход $n · $kg × $reps';
  }

  @override
  String workoutRestAdd(int n) {
    return '+$n с';
  }

  @override
  String workoutRestSub(int n) {
    return '−$n с';
  }

  @override
  String get workoutRestSkip => 'Пропустить';

  @override
  String get workoutMenuSwap => 'Заменить упражнение';

  @override
  String workoutMenuSimilar(String names) {
    return 'Похожие: $names';
  }

  @override
  String get workoutMenuWarmup => 'Добавить разминочные подходы';

  @override
  String workoutMenuWarmupSub(String plan) {
    return '2 подхода: $plan';
  }

  @override
  String get workoutMenuRest => 'Таймер отдыха';

  @override
  String get workoutMenuRestSub => 'Для этого упражнения';

  @override
  String get workoutMenuNote => 'Заметка';

  @override
  String get workoutMenuNoteEmpty => 'Добавить заметку';

  @override
  String get workoutMenuNoteHint => 'Например: лямки на последнем подходе';

  @override
  String get workoutNoteSave => 'Сохранить';

  @override
  String get workoutMenuReorder => 'Порядок';

  @override
  String get workoutMenuReorderSub => 'Переместить выше или ниже в тренировке';

  @override
  String get workoutMenuRemove => 'Удалить упражнение';

  @override
  String get workoutRemoveTitle => 'Удалить это упражнение?';

  @override
  String get workoutRemoveBody => 'Записанные подходы будут потеряны.';

  @override
  String get workoutRemoveConfirm => 'Удалить';

  @override
  String workoutRpeTitle(int n) {
    return 'RPE подхода $n · насколько было тяжело?';
  }

  @override
  String workoutRpeCaption(int n, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left повтора',
      many: '$left повторов',
      few: '$left повтора',
      one: '$left повтор',
    );
    return 'RPE $n · примерно $_temp0 в запасе';
  }

  @override
  String get workoutCompleteTitle => 'Тренировка завершена';

  @override
  String workoutCompleteSubtitle(String name, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n новых рекорда',
      many: '$n новых рекордов',
      few: '$n новых рекорда',
      one: '$n новый рекорд',
      zero: 'новых рекордов нет',
    );
    return '$name · $_temp0';
  }

  @override
  String get workoutTileDuration => 'Время';

  @override
  String get workoutTileVolume => 'Объём';

  @override
  String get workoutTileSets => 'Подходы';

  @override
  String get workoutTileRecords => 'Рекорды';

  @override
  String get workoutTileLoad => 'Нагрузка';

  @override
  String get workoutOverallTitle => 'Насколько тяжёлой была тренировка?';

  @override
  String get workoutOverallHint =>
      'Необязательно. Учитывается в тренировочной нагрузке и оценке восстановления.';

  @override
  String workoutOverallCaption(int n, String label) {
    return 'RPE $n · $label. Учитывается в тренировочной нагрузке.';
  }

  @override
  String get workoutRpeVeryEasy => 'Очень легко';

  @override
  String get workoutRpeEasy => 'Легко';

  @override
  String get workoutRpeModerate => 'Умеренно';

  @override
  String get workoutRpeHard => 'Тяжело';

  @override
  String get workoutRpeVeryHard => 'Очень тяжело';

  @override
  String get workoutRpeMax => 'Максимум';

  @override
  String get workoutExercisesTitle => 'Упражнения';

  @override
  String get workoutBestSetE1rm => 'лучший подход · e1RM';

  @override
  String workoutBestSet(String value) {
    return 'Лучший подход $value';
  }

  @override
  String get workoutNextTimeTitle => 'В следующий раз';

  @override
  String workoutNextTimeBody(String exercise, String kg) {
    return '$exercise: все подходы выполнены. В следующий раз попробуйте $kg кг.';
  }

  @override
  String get workoutSave => 'Сохранить';

  @override
  String get workoutDiscard => 'Не сохранять';

  @override
  String get workoutDiscardTitle => 'Не сохранять тренировку?';

  @override
  String get workoutDiscardBody => 'Она не попадёт в вашу историю.';

  @override
  String get workoutAddExercise => 'Упражнение';

  @override
  String homeGreetingMorning(String name) {
    return 'Доброе утро, $name';
  }

  @override
  String get homeGreetingMorningNoName => 'Доброе утро';

  @override
  String homeGreetingAfternoon(String name) {
    return 'Добрый день, $name';
  }

  @override
  String get homeGreetingAfternoonNoName => 'Добрый день';

  @override
  String homeGreetingEvening(String name) {
    return 'Добрый вечер, $name';
  }

  @override
  String get homeGreetingEveningNoName => 'Добрый вечер';

  @override
  String get checkinCardPrompt =>
      'Как самочувствие сегодня? 20 секунд — и вы узнаете, насколько готовы к тренировке.';

  @override
  String get checkinCardAction => 'Отметиться';

  @override
  String checkinCardRecovered(int score) {
    return 'Восстановление $score%';
  }

  @override
  String get checkinCardSeeMore => 'Что повлияло';

  @override
  String get checkinTitle => 'Утренний чек-ин';

  @override
  String get checkinSleep => 'Сон';

  @override
  String checkinSleepDuration(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String get checkinSleepLess => 'Сон на 15 минут меньше';

  @override
  String get checkinSleepMore => 'Сон на 15 минут больше';

  @override
  String get sleepQualityPoor => 'Плохо';

  @override
  String get sleepQualityOk => 'Нормально';

  @override
  String get sleepQualityGood => 'Хорошо';

  @override
  String get checkinSoreness => 'Мышечная боль';

  @override
  String get sorenessNone => 'Нет';

  @override
  String get sorenessLight => 'Лёгкая';

  @override
  String get sorenessMedium => 'Средняя';

  @override
  String get sorenessStrong => 'Сильная';

  @override
  String get bodyLegs => 'Ноги';

  @override
  String get bodyBack => 'Спина';

  @override
  String get bodyChest => 'Грудь';

  @override
  String get bodyArms => 'Руки';

  @override
  String get bodyShoulders => 'Плечи';

  @override
  String get checkinEnergy => 'Энергия';

  @override
  String get checkinStress => 'Стресс';

  @override
  String get levelLow => 'Низкая';

  @override
  String get levelOk => 'Нормальная';

  @override
  String get levelHigh => 'Высокая';

  @override
  String get stressLow => 'Низкий';

  @override
  String get stressMedium => 'Средний';

  @override
  String get stressHigh => 'Высокий';

  @override
  String get checkinSave => 'Сохранить чек-ин';

  @override
  String get readinessReady => 'Готовы к тренировке';

  @override
  String get readinessTrainLight => 'Тренируйтесь легче';

  @override
  String get readinessRest => 'Сегодня отдых';

  @override
  String get checkinHintReady => 'Тяжёлая тренировка подойдёт.';

  @override
  String checkinHintReadySore(String areas) {
    return 'Тяжёлая тренировка подойдёт. $areas: нужен ещё день.';
  }

  @override
  String get checkinHintLight => 'Сегодня потренируйтесь полегче.';

  @override
  String get checkinHintRest =>
      'Не торопитесь. Восстановление тоже часть тренировки.';

  @override
  String get recoveryTitle => 'Восстановление';

  @override
  String recoverySubtitle(String time) {
    return 'Сегодня · чек-ин в $time';
  }

  @override
  String get recoveryRecovered => 'восстановление';

  @override
  String recoveryHintReadySore(String areas) {
    return 'Тяжёлая тренировка подойдёт. Сегодня полегче: $areas.';
  }

  @override
  String get recoveryShaped => 'Что повлияло';

  @override
  String factorSleep(String duration) {
    return 'Сон $duration';
  }

  @override
  String factorSleepQuality(String quality) {
    return 'Качество: $quality';
  }

  @override
  String factorSoreness(String level) {
    return 'Боль: $level';
  }

  @override
  String factorEnergy(String level) {
    return 'Энергия: $level';
  }

  @override
  String factorStress(String level) {
    return 'Стресс: $level';
  }

  @override
  String get factorLoad => 'Тренировочная нагрузка';

  @override
  String factorLoadSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count тяжёлого дня',
      many: '$count тяжёлых дней',
      few: '$count тяжёлых дня',
      one: '$count тяжёлый день',
    );
    return '$_temp0 за последние 7';
  }

  @override
  String get recoveryPlanTitle => 'План на сегодня, с поправками';

  @override
  String recoveryPlanApplied(String plan, String swaps, String areas) {
    return '$plan остаётся. Замены: $swaps. Это бережёт: $areas.';
  }

  @override
  String recoveryPlanSuggested(String plan, String swaps, String areas) {
    return '$plan можно оставить. Предлагаемые замены: $swaps, чтобы поберечь: $areas.';
  }

  @override
  String get recoveryStartWorkout => 'Начать тренировку';

  @override
  String get recoveryUndo => 'Отменить';

  @override
  String get recoveryApplySwaps => 'Применить замены';

  @override
  String get recoveryLast7 => 'Последние 7 дней';

  @override
  String recoveryAvg(int score) {
    return 'в среднем $score%';
  }

  @override
  String get recoveryNoCheckin => 'Чек-ина пока нет';

  @override
  String get recoveryNoCheckinBody =>
      'Отметьтесь, чтобы увидеть уровень восстановления и что на него повлияло.';

  @override
  String get planTitle => 'Эта неделя';

  @override
  String planSummary(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n занятия',
      many: '$n занятий',
      few: '$n занятия',
      one: '$n занятие',
    );
    return '$_temp0 · выполнено: $m';
  }

  @override
  String get planLoadTitle => 'Нагрузка';

  @override
  String get planLoadEasy => 'Низкая';

  @override
  String get planLoadNormal => 'Средняя';

  @override
  String get planLoadHigh => 'Высокая';

  @override
  String planLoadCaption(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n тяжёлой тренировки в ближайшие 3 дня.',
      many: '$n тяжёлых тренировок в ближайшие 3 дня.',
      few: '$n тяжёлые тренировки в ближайшие 3 дня.',
      one: '$n тяжёлая тренировка в ближайшие 3 дня.',
    );
    return '$_temp0';
  }

  @override
  String planRecoveryToday(int score) {
    return 'Восстановление сегодня: $score%.';
  }

  @override
  String get planFelixLabel => 'FELIX ПРЕДЛАГАЕТ';

  @override
  String planFelixText(
      String a, String aDay, String b, String bDay, String target) {
    return '$a ($aDay) и $b ($bDay) — обе тяжёлые. Перенесите «$b» на $target, чтобы ноги восстановились.';
  }

  @override
  String get planOptimize => 'Оптимизировать';

  @override
  String get planKeep => 'Оставить';

  @override
  String planTodayDay(String day) {
    return 'Сегодня · $day';
  }

  @override
  String planDoneCount(int n) {
    return 'выполнено: $n';
  }

  @override
  String planPlannedCount(int n) {
    return 'запланировано: $n';
  }

  @override
  String get planMissedHeader => 'пропущено';

  @override
  String get planMissed => 'Пропущено';

  @override
  String get planRestDay => 'День отдыха';

  @override
  String planExercisesMeta(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упражнения',
      many: '$count упражнений',
      few: '$count упражнения',
      one: '$count упражнение',
    );
    return '$_temp0 · $duration';
  }

  @override
  String planDurationHM(int h, int m) {
    return '$h ч $m мин';
  }

  @override
  String planDurationH(int h) {
    return '$h ч';
  }

  @override
  String planDurationM(int m) {
    return '$m мин';
  }

  @override
  String get planIntensityEasy => 'Легко';

  @override
  String get planIntensityNormal => 'Средне';

  @override
  String get planIntensityHard => 'Тяжело';

  @override
  String planDoneMeta(String duration, int rpe) {
    return '$duration · RPE $rpe';
  }

  @override
  String get planAddSession => 'Добавить занятие';

  @override
  String get planAddTitle => 'Новое занятие';

  @override
  String get planWorkoutLabel => 'ТРЕНИРОВКА';

  @override
  String get planDayLabel => 'ДЕНЬ';

  @override
  String planAddButton(String title, String day) {
    return 'Добавить: $title · $day';
  }

  @override
  String planWarnThird(String day) {
    return '$day станет третьим тяжёлым днём подряд';
  }

  @override
  String planWarnAuto(String day) {
    return '$day даёт больше времени на восстановление. Felix выбрал его за вас.';
  }

  @override
  String get planWarnPick =>
      'Выберите другой день, чтобы сохранить восстановление.';

  @override
  String get planGenericFootball => 'Футбол 7×7';

  @override
  String get planSkiing => 'Лыжи';

  @override
  String get planEmptyTitle => 'Плана пока нет';

  @override
  String get planEmptyBody =>
      'Расставьте силовые тренировки на остаток недели одним нажатием.';

  @override
  String get planPlanWeek => 'Спланировать неделю';

  @override
  String get planEntryEmpty => 'Спланируйте неделю тренировок';

  @override
  String get planNextWeek => 'Следующая неделя';

  @override
  String get planPlanNextWeek => 'Спланировать следующую неделю';

  @override
  String get exercisesTitle => 'Упражнения';

  @override
  String exercisesSearch(int n) {
    return 'Поиск по $n упражнениям';
  }

  @override
  String get exercisesSearchShort => 'Поиск упражнений';

  @override
  String get exercisesAll => 'Все';

  @override
  String get exercisesAnyEquipment => 'Любой инвентарь';

  @override
  String get exercisesRecent => 'Недавние';

  @override
  String get exercisesFromWorkouts => 'из тренировок';

  @override
  String get exercisesBest => 'лучший';

  @override
  String get exercisesAZ => 'Все · А–Я';

  @override
  String exercisesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n упражнения',
      many: '$n упражнений',
      few: '$n упражнения',
      one: '$n упражнение',
    );
    return '$_temp0';
  }

  @override
  String get exercisesNoMatch => 'Ничего не найдено. Попробуйте другой фильтр.';

  @override
  String get muscleChest => 'Грудь';

  @override
  String get muscleBack => 'Спина';

  @override
  String get muscleShoulders => 'Плечи';

  @override
  String get muscleArms => 'Руки';

  @override
  String get muscleLegs => 'Ноги';

  @override
  String get muscleGlutes => 'Ягодицы';

  @override
  String get muscleCore => 'Кор';

  @override
  String get equipBarbell => 'Штанга';

  @override
  String get equipDumbbell => 'Гантели';

  @override
  String get equipCable => 'Блок';

  @override
  String get equipMachine => 'Тренажёр';

  @override
  String get equipBodyweight => 'Свой вес';

  @override
  String get equipKettlebell => 'Гиря';

  @override
  String get levelBeginner => 'Новичок';

  @override
  String get levelIntermediate => 'Средний';

  @override
  String get levelAdvanced => 'Продвинутый';

  @override
  String get exerciseCompound => 'Базовое';

  @override
  String get exerciseDetailTitle => 'Упражнение';

  @override
  String get exercisePrimary => 'Основные';

  @override
  String get exerciseSecondary => 'Вторичные';

  @override
  String get exerciseYourNumbers => 'Ваши цифры';

  @override
  String get exerciseBestSet => 'Лучший подход';

  @override
  String get exerciseE1rm => 'e1RM';

  @override
  String get exerciseSessions => 'Тренировки';

  @override
  String exerciseChangeSince(String pct, String month) {
    return '$pct с $month';
  }

  @override
  String get exerciseNoHistory =>
      'Выполните один раз, чтобы увидеть свои цифры';

  @override
  String get exerciseHowTo => 'Как выполнять';

  @override
  String get exerciseMistakes => 'Частые ошибки';

  @override
  String get exerciseSimilar => 'Похожие';

  @override
  String get exerciseAskFelix => 'Спросить Felix';

  @override
  String exerciseAskFelixDraft(String name) {
    return 'Как улучшить моё упражнение: $name?';
  }

  @override
  String get exerciseAddToWorkout => 'Добавить';

  @override
  String get exerciseAdded => 'Добавлено в тренировку';

  @override
  String get exerciseQuickWorkout => 'Быстрая тренировка';

  @override
  String addExerciseTitle(String workout) {
    return 'Добавить в «$workout»';
  }

  @override
  String addExerciseSwapTitle(String workout) {
    return 'Замена в «$workout»';
  }

  @override
  String addExerciseHint(String group, int n, int target) {
    return '$group: $n подходов на этой неделе, цель — $target.';
  }

  @override
  String get addExerciseSuggested => 'Рекомендуем';

  @override
  String addExerciseSelected(int n) {
    return 'Выбрано: $n';
  }

  @override
  String get addExerciseLibrary => 'Библиотека';

  @override
  String get addExerciseInWorkout => 'Уже в тренировке';

  @override
  String addExerciseButton(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Добавить $n упражнения',
      many: 'Добавить $n упражнений',
      few: 'Добавить $n упражнения',
      one: 'Добавить $n упражнение',
    );
    return '$_temp0';
  }

  @override
  String get addExerciseSwap => 'Заменить';

  @override
  String get workoutMenuSwapSub => 'Выбрать из библиотеки';

  @override
  String get gymExercises => 'Упражнения';

  @override
  String gymExercisesSub(int n) {
    return '$n с техникой и вашими рекордами';
  }

  @override
  String get profileEditTooltip => 'Редактировать профиль';

  @override
  String get profileMySports => 'Мои виды спорта';

  @override
  String profileSportsSelected(int n) {
    return 'Выбрано: $n';
  }

  @override
  String get profileWeightLabel => 'кг · вес';

  @override
  String get profileHeightLabel => 'см · рост';

  @override
  String get profileAgeLabel => 'лет · возраст';

  @override
  String get profileSettings => 'Настройки';

  @override
  String get hrZonesTitle => 'Пульсовые зоны';

  @override
  String profileHrZonesSummary(int rest, int max) {
    return 'Покой $rest · макс $max уд/мин';
  }

  @override
  String get profileHrZonesSetUp => 'Настроить';

  @override
  String get profileConnectedApps => 'Подключённые приложения';

  @override
  String profileConnectedAppsCount(int connected, int total) {
    return 'Подключено $connected из $total';
  }

  @override
  String get hrZonesMax => 'Макс. пульс';

  @override
  String get hrZonesRest => 'Пульс покоя';

  @override
  String get hrZonesLthr => 'ПАНО';

  @override
  String get hrZonesEdit => 'Изменить пульс';

  @override
  String get hrZonesKarvonen => 'Карвонен';

  @override
  String get hrZonesFriel => 'ПАНО (Фрил)';

  @override
  String get hrZonesKarvonenTitle => 'Зоны по Карвонену';

  @override
  String get hrZonesKarvonenSub => '% от резерва';

  @override
  String get hrZonesFrielTitle => 'Зоны по ПАНО';

  @override
  String get hrZonesColZone => 'ЗОНА';

  @override
  String get hrZonesColBpm => 'УД/МИН';

  @override
  String get hrZonesColHrr => '50–100%';

  @override
  String get hrZonesColLthr => '% ОТ ПАНО';

  @override
  String hrZonesLthrValue(int lthr) {
    return 'ПАНО $lthr уд/мин';
  }

  @override
  String hrZonesFormula(int reserve) {
    return 'Пульс = покой + % × (макс − покой). Ваш резерв: $reserve уд/мин.';
  }

  @override
  String hrZonesZ2Tip(int low, int high) {
    return 'Большую часть бега держите в Z2, $low–$high уд/мин. Z4 только для коротких интервалов.';
  }

  @override
  String get hrZonesHowTitle => 'Как измерить максимальный пульс';

  @override
  String get hrZonesHowBody =>
      'Разминайтесь 15 минут, затем дважды пробегите 3–4 минуты в горку изо всех сил. Наибольший пульс и есть ваш максимум.';

  @override
  String hrZonesTanaka(int age, int max) {
    return 'Ещё нет теста? Оценка Танаки: 208 − 0,7 × $age = $max уд/мин (±10).';
  }

  @override
  String get hrZonesRestingTip =>
      'Пульс покоя: измеряйте после пробуждения, лёжа.';

  @override
  String get hrZonesFrielNote =>
      'Зоны Фрила для бега. Тест ПАНО: 30 минут бега в одиночку на максимум, средний пульс последних 20 минут и есть ваш ПАНО.';

  @override
  String get hrZonesNeedAge =>
      'Добавьте возраст в профиль, чтобы получить оценку максимального пульса.';

  @override
  String get hrZonesCompleteProfile => 'Заполнить профиль';

  @override
  String get hrZonesNeedRates =>
      'Добавьте пульс покоя и максимальный пульс, чтобы увидеть зоны.';

  @override
  String get hrZonesNeedLthr => 'Добавьте ПАНО, чтобы увидеть зоны Фрила.';

  @override
  String get hrZoneRecovery => 'Восстановление';

  @override
  String get hrZoneAerobic => 'Аэробная';

  @override
  String get hrZoneTempo => 'Темповая';

  @override
  String get hrZoneThreshold => 'Пороговая';

  @override
  String get hrZoneVo2max => 'МПК';

  @override
  String get hrZoneSubThr => 'Суб-порог';

  @override
  String get hrZoneThreshPlus => 'Порог+';

  @override
  String get hrZoneCapacity => 'Ёмкость';

  @override
  String get hrZoneAnaerobic => 'Анаэроб.';

  @override
  String get editProfileTitle => 'Редактировать профиль';

  @override
  String get editProfileBody => 'Тело';

  @override
  String get editProfilePerformance => 'Результаты';

  @override
  String get editProfileSex => 'Пол';

  @override
  String get sexMale => 'Мужской';

  @override
  String get sexFemale => 'Женский';

  @override
  String get editProfileRestingHr => 'Пульс покоя';

  @override
  String get editProfileMaxHr => 'Макс. пульс';

  @override
  String get editProfileLthr => 'ПАНО (необязательно)';

  @override
  String get editProfileFtp => 'FTP в велоспорте';

  @override
  String get editProfileFiveK => 'Личный рекорд на 5 км';

  @override
  String get unitBpm => 'уд/мин';

  @override
  String get unitWatts => 'Вт';

  @override
  String get unitMinSec => 'мин:сек';

  @override
  String get unitYears => 'лет';

  @override
  String get editProfileSave => 'Сохранить';

  @override
  String editProfileErrHr(int min, int max) {
    return 'Введите $min–$max уд/мин';
  }

  @override
  String get editProfileErrRestMax =>
      'Пульс покоя должен быть ниже максимального';

  @override
  String editProfileErrFtp(int min, int max) {
    return 'Введите $min–$max Вт';
  }

  @override
  String get editProfileErrFiveK => 'Введите время от 12:00 до 60:00';

  @override
  String get connectedAppsTitle => 'Подключённые приложения';

  @override
  String get connectedAppsWhyHeader => 'ЗАЧЕМ ПОДКЛЮЧАТЬ';

  @override
  String connectedAppsWhyBody(String health) {
    return '$health заполняет в чек-ине сон прошлой ночи, а также даёт пульс покоя и ВСР для восстановления, шаги и вес с умных весов. Тренировки с часов учитываются в истории и тренировочной нагрузке. Данные Apple Watch, Garmin, WHOOP и Mi Band (Zepp / Mi Fitness) приходят через $health, когда в их приложении включена синхронизация с $health.';
  }

  @override
  String connectedAppsWhyBodyAndroid(String health) {
    return '$health заполняет в чек-ине сон прошлой ночи, а также даёт пульс покоя и ВСР для восстановления, шаги и вес с умных весов. Тренировки с часов учитываются в истории и тренировочной нагрузке. Данные Garmin, WHOOP и Mi Band (Zepp / Mi Fitness) приходят через $health, когда в их приложении включена синхронизация с $health.';
  }

  @override
  String get connectedAppsHealthDesc =>
      'Сон, пульс, ВСР, шаги, вес, тренировки';

  @override
  String get connectedAppsGarminDesc => 'Тренировки, пульс, сон, ВСР';

  @override
  String get connectedAppsStravaDesc => 'Бег, велозаезды и лыжи';

  @override
  String get connectedAppsWhoopDesc => 'Восстановление, нагрузка, сон, ВСР';

  @override
  String get connectedAppsNotConnected => 'Не подключено';

  @override
  String get connectedAppsConnect => 'Подключить';

  @override
  String get connectedAppsFooter => 'Отключить можно в любой момент.';

  @override
  String connectedAppsSheetTitle(String app) {
    return 'Подключить $app';
  }

  @override
  String get connectedAppsSheetSubtitle => 'Что FITRIX сможет читать';

  @override
  String get connectedAppsSheetPrivacy =>
      'Когда это появится, FITRIX будет только читать данные и ничего не публиковать.';

  @override
  String connectedAppsSheetSoon(String app, String health) {
    return 'Прямое подключение $app пока недоступно. Но уже сейчас можно передавать его данные в $health — FITRIX прочитает их оттуда.';
  }

  @override
  String get connectedAppsComingSoon => 'Появится в одном из обновлений';

  @override
  String get connectedAppsClose => 'Закрыть';

  @override
  String get connectedAppsConnected => 'Подключено';

  @override
  String connectedAppsLastRead(String time) {
    return 'Обновлено в $time';
  }

  @override
  String get connectedAppsReading => 'Читаем данные…';

  @override
  String connectedAppsWriteWorkouts(String health) {
    return 'Сохранять мои тренировки FITRIX в $health';
  }

  @override
  String get connectedAppsDisconnect => 'Отключить';

  @override
  String get connectedAppsDisconnectedIos =>
      'Чтобы убрать доступ, откройте Настройки › Здоровье › Доступ к данным и устройства › FITRIX.';

  @override
  String get connectedAppsDisconnectedAndroid =>
      'Чтобы убрать доступ, откройте Health Connect › Разрешения приложений › FITRIX.';

  @override
  String get connectedAppsDeniedIos =>
      'Доступ не предоставлен. Изменить это можно в приложении «Здоровье».';

  @override
  String get connectedAppsDeniedAndroid =>
      'Доступ не предоставлен. Изменить это можно в Health Connect.';

  @override
  String get connectedAppsInstall => 'Установить';

  @override
  String get connectedAppsUpdate => 'Обновить';

  @override
  String get connectedAppsNotInstalled =>
      'Health Connect не установлен на этом телефоне.';

  @override
  String get connectedAppsNeedsUpdate => 'Health Connect нужно обновить.';

  @override
  String get connectedAppsUnavailable => 'Недоступно на этом устройстве.';

  @override
  String get connectedAppsPrivacy =>
      'Данные о здоровье остаются на этом телефоне; в ваш аккаунт сохраняются только импортированные тренировки и чек-ин.';

  @override
  String connectedAppsDeleteHelp(String health) {
    return 'Удаление тренировки в FITRIX не удаляет её из $health.';
  }

  @override
  String get nutritionToday => 'Сегодня';

  @override
  String nutritionDateTraining(String date) {
    return '$date · день тренировки';
  }

  @override
  String get nutritionCompleteTitle => 'Заполните профиль';

  @override
  String get nutritionCompleteBody =>
      'Укажите пол, возраст, вес и рост, чтобы получить дневные нормы.';

  @override
  String get nutritionLeftToday => 'Осталось сегодня';

  @override
  String get nutritionBurned => 'Сожжено на тренировке';

  @override
  String nutritionBurnedValue(String kcal) {
    return '≈ +$kcal ккал';
  }

  @override
  String get nutritionHowSet => 'Как это считается ›';

  @override
  String get nutritionMacros => 'БЖУ';

  @override
  String nutritionProteinPerKg(String value) {
    return 'белок $value г/кг';
  }

  @override
  String nutritionGramsOf(String eaten, String target) {
    return '$eaten / $target г';
  }

  @override
  String nutritionWaterTitle(String drunk, String target) {
    return 'Вода · $drunk из $target л';
  }

  @override
  String nutritionWaterNoTarget(String drunk) {
    return 'Вода · $drunk л';
  }

  @override
  String get nutritionWaterWorkout => '+0,5 л за сегодняшнюю тренировку';

  @override
  String nutritionStepsBonus(String kcal, String steps) {
    return '+$kcal ккал за шаги сегодня (шагов: $steps)';
  }

  @override
  String nutritionAddMl(String ml) {
    return '+$ml мл';
  }

  @override
  String get nutritionMeals => 'Приёмы пищи';

  @override
  String nutritionMealsLogged(String n) {
    return '$n из 4 записано';
  }

  @override
  String get nutritionAdd => 'Добавить';

  @override
  String get nutritionLowToday => 'Мало сегодня';

  @override
  String nutritionAllMicros(String n) {
    return 'Все $n ›';
  }

  @override
  String get nutritionDinnerIdea => 'Идея для ужина';

  @override
  String nutritionIdeaMessage(
      String gap, String food, String portion, String protein) {
    return 'Белка не хватает $gap г. $food ($portion) даст около $protein г.';
  }

  @override
  String get nutritionAddToDinner => 'Добавить в ужин';

  @override
  String get nutritionOtherIdea => 'Другая идея';

  @override
  String get nutritionRemove => 'Удалить';

  @override
  String get nutritionSearch => 'Найти продукт';

  @override
  String get nutritionFood => 'Продукт';

  @override
  String nutritionGrams(String grams) {
    return '$grams г';
  }

  @override
  String nutritionAddToSlot(String slot) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Добавить в завтрак',
        'lunch': 'Добавить в обед',
        'dinner': 'Добавить в ужин',
        'snack': 'Добавить в перекус',
        'other': 'Добавить в ужин',
      },
    );
    return '$_temp0';
  }

  @override
  String nutritionAddToSlotKcal(String slot, String kcal) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Добавить в завтрак · $kcal ккал',
        'lunch': 'Добавить в обед · $kcal ккал',
        'dinner': 'Добавить в ужин · $kcal ккал',
        'snack': 'Добавить в перекус · $kcal ккал',
        'other': 'Добавить в ужин · $kcal ккал',
      },
    );
    return '$_temp0';
  }

  @override
  String nutritionAddedTo(String name, String slot) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': '$name добавлено в завтрак',
        'lunch': '$name добавлено в обед',
        'dinner': '$name добавлено в ужин',
        'snack': '$name добавлено в перекус',
        'other': '$name добавлено',
      },
    );
    return '$_temp0';
  }

  @override
  String get nutritionResults => 'Результаты';

  @override
  String nutritionResultsCount(String n) {
    return '$n продуктов · на порцию';
  }

  @override
  String get nutritionNoResults =>
      'Ничего не найдено. Попробуйте другое название.';

  @override
  String get nutritionRecent => 'Недавнее';

  @override
  String get nutritionRecentNote => 'вы ели это на этой неделе';

  @override
  String nutritionPortionLine(String portion, String kcal, String protein) {
    return '$portion · $kcal ккал · Б $protein г';
  }

  @override
  String get nutritionCantFind => 'Не нашли?';

  @override
  String get nutritionCantFindBody => 'Попросите Felix оценить';

  @override
  String get foodBaseError => 'Не удалось загрузить базу продуктов.';

  @override
  String get foodNotFound => 'Этого продукта нет в базе.';

  @override
  String get foodCatAll => 'Все';

  @override
  String get foodCatUzbek => 'Узбекские блюда';

  @override
  String get foodCatMeatFish => 'Мясо и рыба';

  @override
  String get foodCatDairy => 'Молочное';

  @override
  String get foodCatFruit => 'Фрукты';

  @override
  String get foodCatVeg => 'Овощи и бобовые';

  @override
  String get foodCatGrains => 'Крупы и паста';

  @override
  String get foodCatBread => 'Хлеб';

  @override
  String get foodCatDrinks => 'Напитки';

  @override
  String get foodCatOther => 'Другое';

  @override
  String get foodRecipeEstimate => 'Оценка по рецепту';

  @override
  String foodPer100(String kcal) {
    return '$kcal ккал / 100 г';
  }

  @override
  String get foodPortion => 'Порция';

  @override
  String get foodKcal => 'ккал';

  @override
  String get foodFitsDay => 'Вписывается в день?';

  @override
  String foodKcalLeftAfter(String kcal) {
    return 'потом останется $kcal ккал';
  }

  @override
  String foodKcalOver(String kcal) {
    return 'перебор $kcal ккал';
  }

  @override
  String foodEaten(String kcal) {
    return 'Съедено $kcal';
  }

  @override
  String foodPlus(String name, String kcal) {
    return '+ $name $kcal';
  }

  @override
  String foodTarget(String kcal) {
    return 'Цель $kcal';
  }

  @override
  String foodFatWould(String fat, String target) {
    return 'Жиров станет $fat из $target г.';
  }

  @override
  String foodProteinBehind(String g) {
    return 'Белка всё ещё не хватает $g г.';
  }

  @override
  String get foodRichIn => 'Богато';

  @override
  String get foodPctOfTarget => '% от вашей дневной нормы';

  @override
  String get micrTitle => 'Микронутриенты';

  @override
  String micrTargetsFor(String who, String age) {
    return 'Нормы для $who, $age · NASEM';
  }

  @override
  String get micrMen => 'мужчин';

  @override
  String get micrWomen => 'женщин';

  @override
  String get micrToday => 'Сегодня';

  @override
  String get micr7Days => '7 дней';

  @override
  String get micr30Days => '30 дней';

  @override
  String get micrAthlete => 'Для спортсмена';

  @override
  String get micrVitamins => 'Витамины';

  @override
  String get micrMinerals => 'Минералы';

  @override
  String micrAll(String n) {
    return 'Все $n';
  }

  @override
  String get micrEmpty => 'Запишите еду, чтобы увидеть микронутриенты.';

  @override
  String micrAverage(String n) {
    return 'В среднем за $n дн. с записями';
  }

  @override
  String get micrLow => 'Мало';

  @override
  String get micrOk => 'Норма';

  @override
  String get micrHigh => 'Много';

  @override
  String get micrVitDTitle => 'Витамин D низкий всю неделю';

  @override
  String get micrVitDBody =>
      'Немного помогают жирная рыба, яйца и обогащённые молочные продукты. Спросите врача о добавке D3.';

  @override
  String get micrInSeason => 'Сейчас в сезон';

  @override
  String micrUzbekistanMonth(String month) {
    return 'Узбекистан · $month';
  }

  @override
  String get microVitD => 'Витамин D';

  @override
  String get microCalcium => 'Кальций';

  @override
  String get microMagnesium => 'Магний';

  @override
  String get microIron => 'Железо';

  @override
  String get microZinc => 'Цинк';

  @override
  String get microPotassium => 'Калий';

  @override
  String get microSodium => 'Натрий';

  @override
  String get microB12 => 'Витамин B12';

  @override
  String get microSelenium => 'Селен';

  @override
  String get microVitE => 'Витамин E';

  @override
  String get microVitC => 'Витамин C';

  @override
  String get microVitA => 'Витамин A';

  @override
  String get microHintVitD => 'Жирная рыба, яйца, солнце';

  @override
  String get microHintCalcium => 'Молочное, кунжут, зелень';

  @override
  String get microHintMagnesium => 'Орехи, гречка, бобовые';

  @override
  String get microHintIron => 'Мясо, печень, чечевица';

  @override
  String get microHintZinc => 'Говядина, баранина, тыквенные семечки';

  @override
  String get microHintPotassium => 'Картофель, бананы, бобовые';

  @override
  String get microHintSodium => 'Хлеб, солёный сыр, бульоны';

  @override
  String get microHintB12 => 'Говядина, яйца, молочное';

  @override
  String get microHintSelenium => 'Рыба, яйца, мясо';

  @override
  String get microHintVitE => 'Орехи, семечки, растительное масло';

  @override
  String get microHintVitC => 'Перец, цитрусовые, гранат';

  @override
  String get microHintVitA => 'Морковь, тыква, шпинат';

  @override
  String get targetsTitle => 'Ваши нормы';

  @override
  String get targetsSubtitle =>
      'По вашему профилю и тренировкам за последние 4 недели';

  @override
  String get targetsGoal => 'Цель';

  @override
  String get targetsLoseFat => 'Похудение';

  @override
  String get targetsMaintain => 'Поддержание';

  @override
  String get targetsLeanBulk => 'Чистый набор';

  @override
  String get targetsBmr => 'Базовый обмен';

  @override
  String targetsBmrFormula(String weight, String height, String age) {
    return 'Миффлин — Сан-Жеор · $weight кг, $height см, $age л.';
  }

  @override
  String targetsActivity(String factor) {
    return '× $factor активность';
  }

  @override
  String targetsHours(String hours) {
    return '$hours ч тренировок в неделю в FITRIX';
  }

  @override
  String targetsHoursEstimated(String hours) {
    return 'Оценка $hours ч в неделю: за 4 недели нет тренировок';
  }

  @override
  String get targetsAdjLose => '−15% для похудения';

  @override
  String get targetsAdjMaintain => 'Поддержание веса';

  @override
  String get targetsAdjBulk => '+10% чистый набор';

  @override
  String get targetsDaily => 'Дневная норма';

  @override
  String targetsProteinG(String g) {
    return 'Белок · $g г';
  }

  @override
  String targetsFatG(String g) {
    return 'Жиры · $g г';
  }

  @override
  String targetsCarbsG(String g) {
    return 'Углеводы · $g г';
  }

  @override
  String targetsPerKg(String value) {
    return '$value г на кг веса';
  }

  @override
  String targetsFatPerKg(String value, String pct) {
    return '$value г на кг, около $pct% калорий';
  }

  @override
  String get targetsCarbsNote => 'Остальные калории';

  @override
  String get targetsAuto => 'авто';

  @override
  String get targetsSave => 'Сохранить нормы';

  @override
  String get progressOverall => 'Всего';

  @override
  String get progressEmpty => 'Запишите тренировку, чтобы увидеть нагрузку';

  @override
  String get progressLoadThisWeek => 'Нагрузка за неделю';

  @override
  String get progressLoadNote => 'RPE сессии × мин';

  @override
  String get progressAu => 'у.е.';

  @override
  String progressPercentOfUsual(int percent) {
    return '$percent% от вашей нормы';
  }

  @override
  String get progressFitness => 'Форма';

  @override
  String get progressFatigue => 'Усталость';

  @override
  String get progressForm => 'Свежесть';

  @override
  String get progress42Day => 'нагрузка за 42 дня';

  @override
  String get progress7Day => 'нагрузка за 7 дней';

  @override
  String get progressEstimated =>
      'Оценка: для части тренировок усилие принято равным 6';

  @override
  String get progressFormFresh => 'Свеж';

  @override
  String get progressFormNeutral => 'Нейтрально';

  @override
  String get progressFormTired => 'Устал';

  @override
  String get progressRecords => 'Рекорды';

  @override
  String get progressRecordsThisWeek => 'за неделю';

  @override
  String get progressBalance => 'Баланс нагрузки';

  @override
  String get progressBandLow => 'Низкая';

  @override
  String get progressBandSweet => 'Оптимум';

  @override
  String get progressBandRisky => 'Риск';

  @override
  String get progressBalanceLow => 'Мало';

  @override
  String get progressBalanceSweet => 'Оптимум 0,8–1,3';

  @override
  String get progressBalanceRisky => 'Риск';

  @override
  String get progressFelixInsight => 'Совет Felix';

  @override
  String get progressInsightLow =>
      'Последняя нагрузка ниже вашей обычной. Добавьте одну тренировку на этой неделе, чтобы вернуться выше 0,8.';

  @override
  String get progressInsightSweet =>
      'Нагрузка в оптимальной зоне. Держите ритм и добавляйте вес там, где подходы даются легко.';

  @override
  String get progressInsightRisky =>
      'Нагрузка выросла выше привычной. Сделайте ближайшие тренировки легче и хорошо спите.';

  @override
  String get progressLiftsE1rm => 'Упражнения · e1RM';

  @override
  String get progressBodyWeight => 'Вес тела';

  @override
  String get loadTitle => 'Тренировочная нагрузка';

  @override
  String loadSubtitle(String sport) {
    return '$sport · RPE сессии × минуты';
  }

  @override
  String get loadAllSports => 'Все виды спорта';

  @override
  String loadWeeks(int count) {
    return '$count нед.';
  }

  @override
  String get loadFitnessExplain =>
      'Ваша средняя нагрузка за 42 дня. Растёт медленно, если тренируетесь регулярно.';

  @override
  String get loadFatigueExplain =>
      'Ваша нагрузка за 7 дней. Скачет после тяжёлых недель и быстро падает с отдыхом.';

  @override
  String get loadFormExplain =>
      'Форма минус усталость. Плюс значит свежесть: время для старта, теста или рекорда.';

  @override
  String get loadByWeek => 'По неделям';

  @override
  String loadAvg(String value) {
    return 'у.е. · в среднем $value';
  }

  @override
  String get loadThisWeek => 'Эта';

  @override
  String get loadNextWeek => 'Следующая неделя';

  @override
  String loadAim(String value) {
    return 'Цельтесь примерно в $value у.е., рядом с вашей недавней средней неделей.';
  }

  @override
  String get loadChartEmpty => 'Пока мало данных о нагрузке';

  @override
  String get recordsTitle => 'Рекорды';

  @override
  String recordsSummary(int count, int sports) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count личных рекорда',
      many: '$count личных рекордов',
      few: '$count личных рекорда',
      one: '$count личный рекорд',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sports,
      locale: localeName,
      other: '$sports вида спорта',
      many: '$sports видов спорта',
      few: '$sports вида спорта',
      one: '$sports вид спорта',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get recordsAll => 'Все';

  @override
  String get recordsThisMonth => 'В этом месяце';

  @override
  String get recordsBestStreak => 'Лучшая серия';

  @override
  String recordsWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count недели',
      many: '$count недель',
      few: '$count недели',
      one: '$count неделя',
    );
    return '$_temp0';
  }

  @override
  String recordsMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count рекорда',
      many: '$count рекордов',
      few: '$count рекорда',
      one: '$count рекорд',
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
      other: '$count повторения',
      many: '$count повторений',
      few: '$count повторения',
      one: '$count повторение',
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
      other: '+$count повторения',
      many: '+$count повторений',
      few: '+$count повторения',
      one: '+$count повторение',
    );
    return '$_temp0';
  }

  @override
  String get recordsToday => 'сегодня';

  @override
  String get recordsYesterday => 'вчера';

  @override
  String recordsDaysAgo(int count) {
    return '$count дн. назад';
  }

  @override
  String get recordsEmpty =>
      'Рекордов пока нет. Побейте прошлый результат на тренировке, и он появится здесь.';

  @override
  String get liftTitle => 'Упражнения';

  @override
  String get liftEstimated => 'Расчётный 1ПМ · Эпли';

  @override
  String liftSince(String date, String kg, String reps, String since) {
    return 'с $since · лучший подход $kg × $reps, $date';
  }

  @override
  String liftBestSet(String date, String kg, String reps) {
    return 'лучший подход $kg × $reps, $date';
  }

  @override
  String get liftChartE1rm => 'e1RM';

  @override
  String get liftChartTop => 'Вес лучшего подхода';

  @override
  String get liftStrengthLevel => 'Уровень силы';

  @override
  String get liftLevelBeginner => 'Начальный';

  @override
  String get liftLevelNovice => 'Новичок';

  @override
  String get liftLevelIntermediate => 'Средний';

  @override
  String get liftLevelAdvanced => 'Продвинутый';

  @override
  String get liftLevelElite => 'Элита';

  @override
  String liftRatio(String ratio) {
    return '$ratio × вес тела';
  }

  @override
  String liftNextBand(String kg, String level, String ratio) {
    return '$level при $ratio × · $kg';
  }

  @override
  String get liftTopBand => 'Высший уровень достигнут';

  @override
  String get liftNeedWeight => 'Запишите вес тела, чтобы увидеть уровень силы.';

  @override
  String get liftNextSession => 'Следующая тренировка';

  @override
  String get liftReserve => '2 повторения в запасе';

  @override
  String get liftColSet => 'Подход';

  @override
  String get liftCol1rm => '%1ПМ';

  @override
  String get liftColLoad => 'Вес';

  @override
  String get liftColReps => 'Повт.';

  @override
  String get liftTopSet => 'Рабочий';

  @override
  String get liftBackOff => 'Облегчённый';

  @override
  String get liftVolume => 'Объём';

  @override
  String get liftFelix => 'Felix';

  @override
  String liftPaceUp(String kg) {
    return 'Стабильно $kg в неделю.';
  }

  @override
  String liftPaceTo(String date, String kg, String ratio) {
    return 'Стабильно $kg в неделю. В таком темпе вы достигнете $ratio × веса тела примерно к $date.';
  }

  @override
  String get liftPaceFlat =>
      'Ваш e1RM в последнее время не растёт. Лёгкая неделя, а затем снова вперёд.';

  @override
  String get liftNone =>
      'Завершите тренировку с упражнением с весом, и оно появится здесь.';

  @override
  String bodyPerWeek(String value) {
    return '$value / нед.';
  }

  @override
  String bodyTrendLine(String goal, int weeks) {
    return 'Тренд за $weeks нед. · цель: $goal';
  }

  @override
  String bodyTrendNone(String goal) {
    return 'Для тренда пока мало взвешиваний · цель: $goal';
  }

  @override
  String bodyGoalLoseFat(String unit) {
    return 'снижение жира −0,3…−0,7 $unit / нед.';
  }

  @override
  String bodyGoalMaintain(String unit) {
    return 'поддержание ±0,2 $unit / нед.';
  }

  @override
  String bodyGoalLeanBulk(String unit) {
    return 'чистый набор +0,2…+0,4 $unit / нед.';
  }

  @override
  String get bodyGoalNameLoseFat => 'снижение жира';

  @override
  String get bodyGoalNameMaintain => 'поддержание';

  @override
  String get bodyGoalNameLeanBulk => 'чистый набор';

  @override
  String bodyOffTrack(String goal) {
    return 'Мимо цели: $goal';
  }

  @override
  String bodyAdd(int kcal) {
    return 'Тренд ниже цели. Добавьте около $kcal ккал в день, в основном углеводы вокруг тренировок.';
  }

  @override
  String bodyCut(int kcal) {
    return 'Тренд выше цели. Уберите около $kcal ккал в день, в основном жиры и сладкие напитки.';
  }

  @override
  String get bodyUpdateTargets => 'Обновить мои нормы';

  @override
  String get bodyRange8 => '8 недель';

  @override
  String get bodyRange26 => '6 месяцев';

  @override
  String get bodyRange52 => 'Год';

  @override
  String get bodyLegendTrend => 'Тренд';

  @override
  String get bodyLegendWeighIns => 'Взвешивания';

  @override
  String get bodyLegendGoal => 'Целевой коридор';

  @override
  String get bodyToday => 'Сегодня';

  @override
  String get bodyWeighIns => 'Взвешивания';

  @override
  String get bodyWeighInsNote => 'утром, после туалета';

  @override
  String get bodyLog => 'Записать вес сегодня';

  @override
  String get bodySheetTitle => 'Вес сегодня';

  @override
  String get bodySave => 'Сохранить';

  @override
  String get bodyWeightRange => 'Введите вес от 20 до 400 кг.';

  @override
  String get bodyEmpty => 'Запишите вес, чтобы увидеть тренд.';

  @override
  String get programsTitle => 'Программы';

  @override
  String get programsEntrySub => 'Готовые планы на ближайшие недели';

  @override
  String get programsActiveEyebrow => 'Активная программа';

  @override
  String programsWeekOf(int w, int n) {
    return 'Неделя $w из $n';
  }

  @override
  String programsNext(String session, String day, String duration) {
    return 'Дальше: $session · $day · $duration';
  }

  @override
  String get programsNoneLeft => 'В программе не осталось занятий';

  @override
  String programsDoneOf(int done, int total) {
    return 'Выполнено $done из $total занятий';
  }

  @override
  String get programsOpen => 'Открыть';

  @override
  String get programsPickedEyebrow => 'Подобрано для вас';

  @override
  String programsPickedText(String name, int perWeek, String level) {
    return '$name · $perWeek дн. в неделю · $level. Подходит вашей цели и опыту.';
  }

  @override
  String get programsFelixPick => 'Выбор Felix';

  @override
  String get programsFilterAll => 'Все';

  @override
  String get programsGoalMuscle => 'Мышцы';

  @override
  String get programsGoalStrength => 'Сила';

  @override
  String get programsGoalFatLoss => 'Снижение жира';

  @override
  String get programsLevelBeginner => 'Новичок';

  @override
  String get programsLevelIntermediate => 'Средний';

  @override
  String get programsLevelAdvanced => 'Продвинутый';

  @override
  String get programsAtHome => 'Дома';

  @override
  String get programsDaysAWeek => 'Дней в неделю';

  @override
  String get programsAny => 'Любое';

  @override
  String programsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n программы',
      many: '$n программ',
      few: '$n программы',
      one: '$n программа',
    );
    return '$_temp0';
  }

  @override
  String programsPerWeek(int n) {
    return '$n× / нед.';
  }

  @override
  String programsWeeksMin(int weeks, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks недели',
      many: '$weeks недель',
      few: '$weeks недели',
      one: '$weeks неделя',
    );
    return '$_temp0 · $min мин';
  }

  @override
  String get programsDetails => 'Подробнее';

  @override
  String get programsEmptyFilter => 'Нет программ под эти фильтры.';

  @override
  String get programTitle => 'Программа';

  @override
  String get programNotFound => 'Эта программа недоступна.';

  @override
  String get programLength => 'Срок';

  @override
  String get programPerWeekLabel => 'В неделю';

  @override
  String get programSessionLabel => 'Занятие';

  @override
  String programWeeksShort(int n) {
    return '$n нед.';
  }

  @override
  String get programYourWeek => 'Ваша неделя';

  @override
  String programClashes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n конфликта',
      many: '$n конфликтов',
      few: '$n конфликта',
      one: '$n конфликт',
    );
    return '$_temp0';
  }

  @override
  String get programRest => 'Отдых';

  @override
  String programWorkoutsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n тренировки',
      many: '$n тренировок',
      few: '$n тренировки',
      one: '$n тренировка',
    );
    return '$_temp0';
  }

  @override
  String programRir(int n) {
    return 'RIR $n';
  }

  @override
  String get programHowYouProgress => 'Как вы прогрессируете';

  @override
  String get programFelixEyebrow => 'Felix подстроил это для вас';

  @override
  String programFelixText(String days, String what) {
    return 'Дни тренировок обходят $days и дни до и после него из-за: $what. Дни можно изменить при старте.';
  }

  @override
  String get programAskFelix => 'Спросить Felix';

  @override
  String programAskFelixDraft(String name) {
    return 'Подходит ли мне программа $name? Сверь её с моей неделей.';
  }

  @override
  String get programStart => 'Начать';

  @override
  String programStartTitle(String name) {
    return 'Начать: $name';
  }

  @override
  String programStartSub(int weeks, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks недели',
      many: '$weeks недель',
      few: '$weeks недели',
      one: '$weeks неделя',
    );
    return '$_temp0 · до $date';
  }

  @override
  String get programStartDate => 'Старт';

  @override
  String get programToday => 'Сегодня';

  @override
  String get programPickDate => 'Другая дата';

  @override
  String get programTrainingDays => 'Дни тренировок';

  @override
  String programDaysPicked(int n, int total) {
    return 'Выбрано $n из $total';
  }

  @override
  String programClashTitle(String day, String title) {
    return '$day: $title';
  }

  @override
  String get programClashHit =>
      'В этот день будут две тяжёлые тренировки. Выберите другой день.';

  @override
  String get programClashNear =>
      'День программы стоит вплотную к нему. Берегите ноги до и после.';

  @override
  String get programClashAvoid =>
      'Дни программы обходят его, чтобы вы успели восстановиться до и после.';

  @override
  String get programStartWeights => 'Стартовые веса';

  @override
  String get programFromRecords => 'из ваших рекордов';

  @override
  String get programReplacePlan => 'Заменить мой план недели';

  @override
  String get programReplaceSub => 'Бег и футбол остаются, дни зала меняются';

  @override
  String programStartOn(String date) {
    return 'Начать $date';
  }

  @override
  String get programReplacesActive => 'Это заменит вашу активную программу.';

  @override
  String programProgressSub(int w, int n, String date) {
    return 'Неделя $w из $n · старт $date';
  }

  @override
  String programDeloadNote(int w) {
    return 'Неделя $w — разгрузочная: делайте примерно половину обычных подходов.';
  }

  @override
  String get programTileSessions => 'Занятия';

  @override
  String get programTileOnTime => 'Вовремя';

  @override
  String get programTileRecords => 'Рекорды';

  @override
  String get programThisWeek => 'На этой неделе';

  @override
  String programWeekDone(int done, int total) {
    return '$done из $total выполнено';
  }

  @override
  String get programNoSessionsWeek => 'На этой неделе нет занятий программы.';

  @override
  String get programPlanned => 'запланировано';

  @override
  String get programMainLifts => 'Основные упражнения';

  @override
  String get programTopSetKg => 'лучший подход, кг';

  @override
  String get programColLift => 'Упражнение';

  @override
  String get programColStart => 'Старт';

  @override
  String get programColNow => 'Сейчас';

  @override
  String get programColGoal => 'Цель';

  @override
  String get programNextIncrease => 'Следующая прибавка';

  @override
  String programNextIncreaseText(int sets, int reps, String lift, String kg) {
    return 'Вы выполнили $sets × $reps в упражнении «$lift» два раза подряд. Следующий раз: $kg кг.';
  }

  @override
  String get programNoActive => 'Нет активной программы';

  @override
  String get programNoActiveBody =>
      'Выберите программу, чтобы получить план на ближайшие недели.';

  @override
  String get programBrowse => 'Смотреть программы';

  @override
  String get programEnd => 'Завершить программу';

  @override
  String get programEndTitle => 'Завершить эту программу?';

  @override
  String get programEndBody =>
      'Тренировки и рекорды сохранятся. Оставшиеся занятия уйдут из плана.';

  @override
  String programKgReps(String kg, int reps) {
    return '$kg кг × $reps';
  }

  @override
  String get coachAskFelix => 'Спросить Felix';

  @override
  String gymAskFirstDraft(String sport) {
    return 'Скоро моя первая тренировка ($sport). На что обратить внимание?';
  }

  @override
  String gymAskBackDraft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня',
      many: '$days дней',
      few: '$days дня',
      one: '$days день',
    );
    return 'Моя последняя тренировка была $_temp0 назад. Как лучше вернуться к тренировкам?';
  }

  @override
  String recoveryAskDraft(
      int score, String label, String sleep, String soreness) {
    return 'Моя готовность сегодня $score% ($label). Сон $sleep, болезненность мышц: $soreness. Насколько тяжело мне тренироваться сегодня?';
  }

  @override
  String planAskDraft(String a, String aDay, String b, String bDay) {
    return '$a ($aDay) и $b ($bDay) — обе тяжёлые. Как лучше расставить мою неделю?';
  }

  @override
  String progressAskDraft(String week, String balance, String band) {
    return 'Моя нагрузка на этой неделе $week, баланс нагрузки $balance ($band). Что делать на следующей неделе?';
  }

  @override
  String liftAskDraft(String lift, String e1rm) {
    return 'Мой e1RM в упражнении $lift — $e1rm. Как продолжить рост?';
  }

  @override
  String bodyAskDraft(String weight, String trend, String goal) {
    return 'Мой вес $weight, меняется на $trend в неделю. Моя цель: $goal. Как мне изменить питание?';
  }

  @override
  String nutritionAskDraft(String kcal, String protein) {
    return 'На сегодня у меня осталось $kcal ккал и $protein г белка. Что съесть на ужин?';
  }

  @override
  String get nutritionCantFindDraft => 'Оцени калорийность блюда: ';

  @override
  String get planEmptyBodyNextWeek =>
      'Расставьте силовые тренировки на следующую неделю одним нажатием.';

  @override
  String programsPickedGoalText(String name, int perWeek, String level) {
    return '$name · $perWeek дн. в неделю · $level. Подходит вашей цели.';
  }

  @override
  String programsPickedLevelText(String name, int perWeek, String level) {
    return '$name · $perWeek дн. в неделю · $level. Подходит вашему опыту.';
  }

  @override
  String get programsStartEyebrow => 'С чего начать';

  @override
  String programsStartText(String name, int perWeek, String level) {
    return '$name · $perWeek дн. в неделю · $level. Укажите цель и опыт в разделе «Обо мне», чтобы подбор был точнее.';
  }

  @override
  String get programDetailsTooltip => 'О программе';

  @override
  String nutritionKcalOver(String kcal) {
    return '$kcal ккал сверх цели';
  }

  @override
  String get homeDoneForToday => 'На сегодня всё';

  @override
  String homeNextSession(String day, String title) {
    return 'Далее: $day · $title';
  }

  @override
  String get homeNothingNext => 'Больше ничего не запланировано';

  @override
  String chatFoodLogTo(String slot) {
    return 'Записать в: $slot';
  }

  @override
  String chatFoodItemMeta(String grams, String kcal) {
    return '$grams г · $kcal ккал';
  }

  @override
  String chatFoodEstimateName(String name) {
    return '≈ $name';
  }

  @override
  String get chatFoodEstimateNote => '≈ оценка Felix';

  @override
  String chatFoodTotal(String kcal, String protein) {
    return '$kcal ккал · $protein г белка';
  }

  @override
  String chatFoodAdd(String kcal) {
    return 'Добавить · $kcal ккал';
  }

  @override
  String chatFoodAdded(String slot) {
    return 'Добавлено: $slot';
  }

  @override
  String get chatActionWeightSetFirst => 'Сначала укажите свой вес';

  @override
  String get chatActionSetWeight => 'Указать вес';

  @override
  String get gymDiscardAndStart => 'Сбросить и начать';

  @override
  String chatActionWeightSet(String to) {
    return 'Обновить вес до $to кг';
  }

  @override
  String get felixPlanBadge => 'План Felix';

  @override
  String felixPlanTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count тренировки',
      many: '$count тренировок',
      few: '$count тренировки',
      one: '$count тренировка',
    );
    return '$_temp0';
  }

  @override
  String get felixPlanAddToWorkouts => 'В мои тренировки';

  @override
  String get felixPlanAddToToday => 'Добавить на сегодня';

  @override
  String get felixPlansSection => 'От Felix';

  @override
  String felixChatTitle(String topic) {
    return 'Felix · $topic';
  }

  @override
  String get felixTopicNutrition => 'Питание';

  @override
  String get felixTopicRecovery => 'Восстановление';

  @override
  String get felixTopicApp => 'Помощник по приложению';

  @override
  String get felixTopicSubGym => 'Сила, мышцы, программы, техника';

  @override
  String get felixTopicSubFitness => 'HIIT, свой вес, мобильность, тесты';

  @override
  String get felixTopicSubRunning => 'Темп, планы, забеги';

  @override
  String get felixTopicSubCycling => 'Мощность, FTP, подъёмы, маршруты';

  @override
  String get felixTopicSubFootball => 'Форма к матчу, упражнения, травмы';

  @override
  String get felixTopicSubWinterSports =>
      'Лыжи в Амирсое и Чимгане, безопасность';

  @override
  String get felixTopicSubNutrition => 'Дневник питания, БЖУ, узбекские блюда';

  @override
  String get felixTopicSubRecovery =>
      'Сон, крепатура, готовность, разгрузочные недели';

  @override
  String get felixTopicSubApp => 'Как работает FITRIX, планы, привычки';

  @override
  String felixTopicGreeting(String topic) {
    return 'Привет! Я Felix. Давай поговорим: $topic.';
  }

  @override
  String get felixTopicGreetingHint =>
      'Спрашивай что угодно или выбери вопрос ниже.';

  @override
  String get felixHubAiCoach => 'ИИ-тренер';

  @override
  String get felixHubIntro =>
      'Тренировки, восстановление и питание в одном месте. Пиши на English, Русский, O‘zbekcha или Español.';

  @override
  String felixHubToday(String title) {
    return 'Сегодня: $title';
  }

  @override
  String get felixHubRest => 'Сегодня день отдыха';

  @override
  String get felixHubDone => 'Сегодняшняя тренировка выполнена';

  @override
  String felixHubNext(String sport, String weekday) {
    return '$sport: $weekday';
  }

  @override
  String get felixHubTopicsHeader => 'О чём поговорить с Felix';

  @override
  String felixHubTopicsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count темы',
      many: '$count тем',
      few: '$count темы',
      one: '$count тема',
    );
    return '$_temp0';
  }

  @override
  String get felixHubRecent => 'Недавние чаты';

  @override
  String get felixHubSeeAll => 'Все';

  @override
  String get felixAllTopics => 'Все темы';

  @override
  String get felixSeesPlan => 'Видит ваш план, чек-ин и тренировки';

  @override
  String get felixSeesNutrition => 'Видит еду за сегодня, цели и вес';

  @override
  String get felixSeesRecovery =>
      'Видит ваш чек-ин, сон и тренировочную нагрузку';

  @override
  String felixChipReadiness(int score) {
    return 'Восстановление $score%';
  }

  @override
  String felixChipToday(String title) {
    return 'Сегодня: $title';
  }

  @override
  String get felixChipRest => 'День отдыха';

  @override
  String felixChipLast(String name) {
    return 'Последняя: $name';
  }

  @override
  String felixChipKcal(String eaten, String target) {
    return '$eaten из $target ккал';
  }

  @override
  String felixChipProtein(String eaten) {
    return 'Белок $eaten г';
  }

  @override
  String felixAskAbout(String topic) {
    return 'Спросите Felix: $topic';
  }

  @override
  String get felixAskAboutApp => 'Спросите Felix про FITRIX';

  @override
  String get felixPromptGym1 => 'Как пробить плато в жиме лёжа?';

  @override
  String get felixPromptGym2 => 'Составь мне сплит на 3 дня';

  @override
  String get felixPromptGym3 => 'Подскажи, на что смотреть в технике приседа';

  @override
  String get felixPromptFitness1 => '20-минутный HIIT на сегодня';

  @override
  String get felixPromptFitness2 => 'Тренировка с собственным весом дома';

  @override
  String get felixPromptFitness3 => 'Мобильность для зажатых бёдер';

  @override
  String get felixPromptRunning1 => 'Какой у меня должен быть лёгкий темп?';

  @override
  String get felixPromptRunning2 => 'План к моим первым 10 км';

  @override
  String get felixPromptRunning3 => 'Как избежать болей в голенях';

  @override
  String get felixPromptCycling1 => 'Как проверить мой FTP?';

  @override
  String get felixPromptCycling2 => 'Интервалы для подъёмов';

  @override
  String get felixPromptCycling3 => 'Что есть в 3-часовой поездке';

  @override
  String get felixPromptFootball1 => 'Разминка перед матчем';

  @override
  String get felixPromptFootball2 => 'Упражнения на скорость на эту неделю';

  @override
  String get felixPromptFootball3 => 'Ноги на следующий день после матча?';

  @override
  String get felixPromptWinter1 => 'Подготовка ног к лыжному сезону';

  @override
  String get felixPromptWinter2 => 'Упражнения для защиты коленей';

  @override
  String get felixPromptWinter3 => 'Как не мёрзнуть на склоне';

  @override
  String get felixPromptNutrition1 => 'Что мне съесть сегодня?';

  @override
  String get felixPromptNutrition2 => 'Сколько белка мне нужно?';

  @override
  String get felixPromptNutrition3 => 'Можно ли плов после тренировки?';

  @override
  String get felixPromptRecovery1 =>
      'Стоит ли мне сегодня тренироваться в полную силу?';

  @override
  String get felixPromptRecovery2 => 'Как лучше спать';

  @override
  String get felixPromptRecovery3 => 'Куда вписать ноги на этой неделе?';

  @override
  String get felixPromptApp1 => 'Как пользоваться планом на неделю?';

  @override
  String get felixPromptApp2 => 'Как работает чек-ин?';

  @override
  String get runNameMorning => 'Утренняя пробежка';

  @override
  String get runNameAfternoon => 'Дневная пробежка';

  @override
  String get runNameEvening => 'Вечерняя пробежка';

  @override
  String get runNameNight => 'Ночная пробежка';

  @override
  String get runNotificationTitle => 'Идёт запись пробежки';

  @override
  String get runNotificationText =>
      'FITRIX записывает дистанцию и время, даже когда экран заблокирован.';

  @override
  String get runNotificationChannel => 'Запись пробежки';

  @override
  String get rideNameMorning => 'Утренняя поездка';

  @override
  String get rideNameAfternoon => 'Дневная поездка';

  @override
  String get rideNameEvening => 'Вечерняя поездка';

  @override
  String get rideNameNight => 'Ночная поездка';

  @override
  String get skiDayName => 'Лыжный день';

  @override
  String get indoorRideName => 'Тренировка на велотренажёре';

  @override
  String get rideNotificationTitle => 'Идёт запись поездки';

  @override
  String get rideNotificationText =>
      'FITRIX записывает дистанцию и время, даже когда экран заблокирован.';

  @override
  String get rideNotificationChannel => 'Запись поездки';

  @override
  String get skiNotificationTitle => 'Идёт запись лыжного дня';

  @override
  String get skiNotificationText =>
      'FITRIX записывает дистанцию и время, даже когда экран заблокирован.';

  @override
  String get skiNotificationChannel => 'Запись лыжного дня';

  @override
  String runVoiceHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа',
      many: '$count часов',
      few: '$count часа',
      one: '$count час',
    );
    return '$_temp0';
  }

  @override
  String runVoiceMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты',
      many: '$count минут',
      few: '$count минуты',
      one: '$count минута',
    );
    return '$_temp0';
  }

  @override
  String runVoiceSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунды',
      many: '$count секунд',
      few: '$count секунды',
      one: '$count секунда',
    );
    return '$_temp0';
  }

  @override
  String runVoicePace(String time) {
    return '$time на километр';
  }

  @override
  String get runVoiceStart => 'Пробежка началась.';

  @override
  String get runVoicePause => 'Пауза.';

  @override
  String get runVoiceResume => 'Продолжаем.';

  @override
  String runVoiceKm(int km, String time, String lastPace, String avgPace) {
    return 'Километр $km. Время $time. Последний километр $lastPace. Средний темп $avgPace.';
  }

  @override
  String runVoiceFinish(String distance, String time, String avgPace) {
    return 'Пробежка завершена. $distance километра. Время $time. Средний темп $avgPace.';
  }

  @override
  String runVoiceFinishShort(String distance, String time) {
    return 'Пробежка завершена. $distance километра. Время $time.';
  }

  @override
  String get runUnfinishedTitle => 'У вас есть незавершённая пробежка';

  @override
  String runUnfinishedBody(String next) {
    return 'Продолжите её или сбросьте и начните «$next».';
  }

  @override
  String get runResume => 'Продолжить';

  @override
  String get runPause => 'Пауза';

  @override
  String get runDiscardTitle => 'Сбросить эту пробежку?';

  @override
  String get runDiscardBody => 'Дистанция и маршрут будут потеряны.';

  @override
  String get runDiscardAction => 'Сбросить';

  @override
  String get runDiscardRun => 'Сбросить пробежку';

  @override
  String get runHoldToFinish => 'Удерживайте, чтобы завершить';

  @override
  String get runLocationOff =>
      'Геолокация для FITRIX выключена. Разрешите её в настройках, чтобы записать пробежку.';

  @override
  String get runLocationServiceOff =>
      'Службы геолокации выключены. Включите их в настройках, чтобы записать пробежку.';

  @override
  String get runOpenSettings => 'Настройки';

  @override
  String get runTime => 'Время';

  @override
  String get runDistance => 'Дистанция';

  @override
  String get runPace => 'Темп';

  @override
  String get runAvgPace => 'Средний темп';

  @override
  String get runUnitKm => 'км';

  @override
  String get runUnitPerKm => '/км';

  @override
  String get runPausedLabel => 'Пауза';

  @override
  String get runMovingTime => 'Время в движении';

  @override
  String get runElevation => 'Набор высоты';

  @override
  String runElevationValue(String meters) {
    return '$meters м';
  }

  @override
  String runElapsedLine(String elapsed, String pauses) {
    return '$elapsed всего, $pauses';
  }

  @override
  String runPausesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count паузы',
      many: '$count пауз',
      few: '$count паузы',
      one: '1 пауза',
      zero: 'без пауз',
    );
    return '$_temp0';
  }

  @override
  String get runSplits => 'Отрезки';

  @override
  String get runRpeTitle => 'Насколько тяжело было?';

  @override
  String get runSave => 'Сохранить';

  @override
  String get runDeleteRun => 'Удалить пробежку';

  @override
  String get runDeleteTitle => 'Удалить эту пробежку?';

  @override
  String get runDeleteBody => 'Она будет удалена из истории.';

  @override
  String get runDeleteAction => 'Удалить';

  @override
  String get runNoRoute => 'Маршрут не записан';

  @override
  String get runNotFound => 'Этой пробежки больше нет.';

  @override
  String get runStartRun => 'Начать пробежку';

  @override
  String get runThisWeek => 'На этой неделе';

  @override
  String runWeekRuns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пробежки',
      many: '$count пробежек',
      few: '$count пробежки',
      one: '$count пробежка',
    );
    return '$_temp0';
  }

  @override
  String get runHistory => 'История';

  @override
  String get runHistoryEmpty =>
      'Пробежек пока нет. Записанные пробежки появятся здесь.';

  @override
  String get runWorkouts => 'Тренировки';

  @override
  String get runBarTitle => 'Пробежка';

  @override
  String get runBarReturn => 'Вернуться';

  @override
  String runUnfinishedLaunchTitle(String distance) {
    return 'Незавершённая пробежка · $distance км';
  }

  @override
  String get runUnfinishedLaunchBody =>
      'Продолжите с того места, где остановились, сохраните записанное или сбросьте.';

  @override
  String get runFinishFailed =>
      'Не удалось завершить пробежку. Попробуйте ещё раз.';

  @override
  String get runGpsWaiting => 'Ждём GPS…';

  @override
  String get runGpsWeak => 'Слабый сигнал GPS';

  @override
  String get runGpsReduced =>
      'Включите «Точную геопозицию» для точной дистанции';

  @override
  String get footballLog => 'Записать';

  @override
  String get footballLogTitle => 'Записать футбол';

  @override
  String get footballEditTitle => 'Изменить запись';

  @override
  String get footballTypeMatch => 'Матч';

  @override
  String get footballTypeTraining => 'Тренировка';

  @override
  String get footballDate => 'Дата';

  @override
  String get footballFormat => 'Формат';

  @override
  String get footballMinutes => 'Минуты';

  @override
  String get footballMinShort => 'мин';

  @override
  String get footballPosition => 'Позиция';

  @override
  String get footballPosGK => 'ВР';

  @override
  String get footballPosCB => 'ЦЗ';

  @override
  String get footballPosFB => 'КЗ';

  @override
  String get footballPosCM => 'ЦП';

  @override
  String get footballPosWM => 'КП';

  @override
  String get footballPosST => 'НП';

  @override
  String get footballResult => 'Счёт';

  @override
  String get footballScoreFor => 'Мы';

  @override
  String get footballScoreAgainst => 'Соперник';

  @override
  String get footballGoals => 'Ваши голы';

  @override
  String get footballAssists => 'Ваши передачи';

  @override
  String get footballNote => 'Заметка';

  @override
  String get footballSave => 'Сохранить';

  @override
  String get footballDelete => 'Удалить запись';

  @override
  String get footballDeleteTitle => 'Удалить эту запись?';

  @override
  String get footballDeleteBody => 'Она исчезнет из вашей истории.';

  @override
  String get footballDeleteAction => 'Удалить';

  @override
  String get footballHistory => 'История';

  @override
  String get footballHistoryEmpty =>
      'Пока нет записей. Запишите игру после матча или тренировки.';

  @override
  String get footballWorkouts => 'Тренировки';

  @override
  String healthFromSource(String source) {
    return 'из $source';
  }

  @override
  String healthInBedFromSource(String source) {
    return 'в постели, из $source';
  }

  @override
  String get healthSectionTitle => 'Данные о здоровье';

  @override
  String get healthRestingHr => 'Пульс покоя';

  @override
  String get healthHrv => 'Вариабельность пульса';

  @override
  String get healthSteps => 'Шаги';

  @override
  String healthRestingHrValue(int bpm) {
    return '$bpm уд/мин';
  }

  @override
  String healthRestingHrNormal(int bpm, int normal) {
    return '$bpm уд/мин · ваша норма $normal';
  }

  @override
  String healthHrvValue(int value, String kind) {
    return '$value мс $kind';
  }

  @override
  String healthHrvNormal(int value, String kind, int normal) {
    return '$value мс $kind · ваша норма $normal';
  }

  @override
  String healthStepsDailyAvg(int avg) {
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String avgString = avgNumberFormat.format(avg);

    return 'В среднем за день: $avgString';
  }

  @override
  String healthStepsToday(int steps) {
    final intl.NumberFormat stepsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'Шаги сегодня: $stepsString';
  }

  @override
  String healthStepsTodayAvg(int steps, int avg) {
    final intl.NumberFormat stepsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String avgString = avgNumberFormat.format(avg);

    return 'Шаги сегодня: $stepsString\nВ среднем за 7 дней: $avgString';
  }

  @override
  String get factorRestingHrHigh => 'Пульс покоя выше нормы';

  @override
  String get factorRestingHrNormal => 'Пульс покоя в норме';

  @override
  String get factorHrvLow => 'ВСР ниже нормы';

  @override
  String get factorHrvNormal => 'ВСР в норме';

  @override
  String get factorHrvHigh => 'ВСР выше нормы';

  @override
  String importedFromHealth(String health) {
    return 'Из $health';
  }

  @override
  String importedAvgHr(int bpm) {
    return '$bpm уд/мин в среднем';
  }

  @override
  String get importedDeleteTitle => 'Удалить эту тренировку?';

  @override
  String get importedDelete => 'Удалить тренировку';

  @override
  String connectedAppsSummaryTitle(String health) {
    return 'Из $health · последние 7 дней';
  }

  @override
  String get connectedAppsSummarySteps => 'Дни с шагами';

  @override
  String get connectedAppsSummarySleep => 'Ночи со сном';

  @override
  String get connectedAppsSummaryRhr => 'Дни с пульсом покоя';

  @override
  String get connectedAppsSummaryHrv => 'Дни с ВСР';

  @override
  String connectedAppsSummaryWeight(String health) {
    return 'Дни со взвешиванием из $health';
  }

  @override
  String connectedAppsSummaryImported(String health) {
    return 'Тренировки из $health';
  }

  @override
  String connectedAppsSummaryWritten(String health) {
    return 'Тренировки, сохранённые в $health';
  }

  @override
  String get connectedAppsSummaryHintIos =>
      'Данных с часов пока нет — часы (Apple Watch, Garmin, WHOOP, Mi Band) добавят сон, пульс и тренировки.';

  @override
  String get connectedAppsSummaryHintAndroid =>
      'Данных с часов пока нет — часы (Garmin, WHOOP, Mi Band) добавят сон, пульс и тренировки.';

  @override
  String get rideVoiceStart => 'Заезд начался.';

  @override
  String rideVoiceDistance(
      String km, String time, String lastSpeed, String avgSpeed) {
    return '$km км. Время $time. Последние 5 км со скоростью $lastSpeed км/ч. Средняя $avgSpeed.';
  }

  @override
  String rideVoiceFinish(String distance, String time) {
    return 'Заезд завершён. $distance км. Время $time.';
  }

  @override
  String get skiVoiceStart => 'Лыжный день начался.';

  @override
  String skiVoiceDescent(
      int index, String distance, int vertical, String topSpeed) {
    return 'Спуск $index. Расстояние $distance км, перепад $vertical м, максимум $topSpeed км/ч.';
  }

  @override
  String skiVoiceFinish(String distance, String time) {
    return 'Лыжный день завершён. Спуски: $distance км. Время $time.';
  }

  @override
  String get activitySettingsTitle => 'Настройки тренировки';

  @override
  String get activitySettingsVoice => 'Голос';

  @override
  String get activitySettingsVoiceRun =>
      'Говорит о старте, каждом километре и финише.';

  @override
  String get activitySettingsVoiceRide =>
      'Говорит о старте, каждых 5 км и финише.';

  @override
  String get activitySettingsVoiceSki =>
      'Говорит о старте, каждом спуске и финише.';

  @override
  String get unitKmh => 'км/ч';

  @override
  String get rideSpeed => 'Скорость';

  @override
  String get rideAvgSpeed => 'Средняя скорость';

  @override
  String get rideMaxSpeed => 'Макс. скорость';

  @override
  String get rideAvgPower => 'Средняя мощность, Вт';

  @override
  String get skiStateDescending => 'Спуск';

  @override
  String get skiStateLift => 'На подъёмнике';

  @override
  String get skiStateStopped => 'Стоите';

  @override
  String get skiDescents => 'Спуски';

  @override
  String get skiVerticalDown => 'Перепад вниз, м';

  @override
  String get skiTimeOnSlopes => 'Время на склоне';

  @override
  String get skiDistance => 'Дистанция спусков, км';

  @override
  String get skiAvgDescentSpeed => 'Средняя скорость спуска';

  @override
  String get skiLifts => 'Подъёмы';

  @override
  String skiDescentN(int n) {
    return 'Спуск $n';
  }

  @override
  String get skiDescentDuration => 'Длительность';

  @override
  String get skiDescentVertical => 'Перепад высоты, м';

  @override
  String get rideElevationLoss => 'Спуск по высоте';

  @override
  String get cyclingStart => 'Начать поездку';

  @override
  String get cyclingLog => 'Записать тренировку на тренажёре';

  @override
  String cyclingUnitRides(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'поездки',
      many: 'поездок',
      few: 'поездки',
      one: 'поездка',
    );
    return '$_temp0';
  }

  @override
  String get cyclingHistory => 'История';

  @override
  String get cyclingHistoryEmpty =>
      'Поездок пока нет. Записанные поездки появятся здесь.';

  @override
  String get cyclingWorkouts => 'Тренировки';

  @override
  String get cyclingChoiceTitle => 'Где катаетесь?';

  @override
  String get cyclingOutdoor => 'На улице (GPS)';

  @override
  String get cyclingIndoor => 'В помещении (запись)';

  @override
  String get cyclingIndoorTag => 'Тренажёр';

  @override
  String get rideLogTitle => 'Записать тренировку на тренажёре';

  @override
  String get rideEditTitle => 'Изменить запись';

  @override
  String get rideLogDistance => 'Дистанция, км (необязательно)';

  @override
  String get rideLogPower => 'Средняя мощность, Вт (необязательно)';

  @override
  String get rideNote => 'Заметка';

  @override
  String get skiStart => 'Начать лыжный день';

  @override
  String skiUnitDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'лыжного дня',
      many: 'лыжных дней',
      few: 'лыжных дня',
      one: 'лыжный день',
    );
    return '$_temp0';
  }

  @override
  String skiUnitDescents(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'спуска',
      many: 'спусков',
      few: 'спуска',
      one: 'спуск',
    );
    return '$_temp0';
  }

  @override
  String get skiHistory => 'История';

  @override
  String get skiHistoryEmpty =>
      'Лыжных дней пока нет. Записанные дни появятся здесь.';

  @override
  String get skiWorkouts => 'Тренировки';

  @override
  String get skiUnitM => 'м';

  @override
  String get rideUnfinishedTitle => 'У вас есть незавершённая поездка';

  @override
  String get skiUnfinishedTitle => 'У вас есть незавершённый лыжный день';

  @override
  String skiUnfinishedBody(String next) {
    return 'Продолжите его или сбросьте и начните «$next».';
  }

  @override
  String get rideDiscardTitle => 'Сбросить эту поездку?';

  @override
  String get skiDiscardTitle => 'Сбросить этот лыжный день?';

  @override
  String get rideDeleteTitle => 'Удалить эту поездку?';

  @override
  String get skiDeleteTitle => 'Удалить этот лыжный день?';

  @override
  String get skiDeleteBody => 'Он будет удалён из истории.';

  @override
  String get rideBarTitle => 'Поездка';

  @override
  String get skiBarTitle => 'Лыжный день';

  @override
  String get rideDiscardRun => 'Сбросить поездку';

  @override
  String get skiDiscardRun => 'Сбросить лыжный день';

  @override
  String get rideDeleteRun => 'Удалить поездку';

  @override
  String get skiDeleteRun => 'Удалить лыжный день';

  @override
  String rideUnfinishedLaunchTitle(String distance) {
    return 'Незавершённая поездка · $distance км';
  }

  @override
  String skiUnfinishedLaunchTitle(String distance) {
    return 'Незавершённый лыжный день · $distance км';
  }

  @override
  String get rideLocationOff =>
      'Геолокация для FITRIX выключена. Разрешите её в настройках, чтобы записать поездку.';

  @override
  String get skiLocationOff =>
      'Геолокация для FITRIX выключена. Разрешите её в настройках, чтобы записать лыжный день.';

  @override
  String get rideLocationServiceOff =>
      'Службы геолокации выключены. Включите их в настройках, чтобы записать поездку.';

  @override
  String get skiLocationServiceOff =>
      'Службы геолокации выключены. Включите их в настройках, чтобы записать лыжный день.';

  @override
  String get rideFinishFailed =>
      'Не удалось завершить поездку. Попробуйте ещё раз.';

  @override
  String get skiFinishFailed =>
      'Не удалось завершить лыжный день. Попробуйте ещё раз.';

  @override
  String get rideNotFound => 'Этой поездки больше нет.';

  @override
  String get skiNotFound => 'Этого лыжного дня больше нет.';

  @override
  String get skiUnfinishedLaunchBody =>
      'Продолжите с того места, где остановились, сохраните записанное или сбросьте.';

  @override
  String get addExerciseNoWorkoutTitle => 'Нет активной тренировки';

  @override
  String get addExerciseNoWorkoutBody =>
      'Начните тренировку, чтобы добавлять в неё упражнения. А пока можно посмотреть библиотеку упражнений.';

  @override
  String get addExerciseOpenLibrary => 'Библиотека упражнений';

  @override
  String get assistantSubtitle => 'Ваш личный ассистент';

  @override
  String get assistantGreeting =>
      'Привет!\nЯ Felix, ваш персональный ИИ-тренер в FITRIX.';

  @override
  String get assistantIntro =>
      'Помогу тренироваться с умом, следить за прогрессом и не терять мотивацию.';

  @override
  String get assistantQuestion =>
      'Расскажите, какая у вас сейчас главная цель?';

  @override
  String get chatFailedUnavailable =>
      'Felix недоступен — проверьте подключение';

  @override
  String get chatFailedInterrupted => 'Felix не успел ответить';

  @override
  String get chatFailedUnreadable => 'Не удалось прочитать ответ Felix';

  @override
  String get chatFailedSignIn => 'Войдите снова, чтобы писать Felix';

  @override
  String get chatFailedTooFast =>
      'Слишком много сообщений — подождите и повторите';

  @override
  String get chatRetry => 'Повторить';

  @override
  String get onbSportSkiing => 'Лыжи';

  @override
  String get onbSportSnowboarding => 'Сноуборд';

  @override
  String get onbFreqWeekly => 'Раз в неделю или реже';

  @override
  String get onbFreqDaily => 'Почти каждый день';

  @override
  String get onbFreqFew => 'Несколько раз в неделю';

  @override
  String get onbFreqStarting => 'Только начинаю';

  @override
  String get transitionReady => 'Felix готов.\nА вы?';

  @override
  String get transitionGo => 'Начинаем';

  @override
  String progressCollecting(int days) {
    return 'Собираем данные — ещё $days дн.';
  }

  @override
  String get profileErrSexRequired =>
      'Выберите: от этого зависят нормы калорий';

  @override
  String nutritionMissingBody(String fields) {
    return 'Укажите $fields, чтобы получить дневные нормы.';
  }

  @override
  String get nutritionMissingSex => 'пол';

  @override
  String get nutritionMissingAge => 'возраст';

  @override
  String get nutritionMissingWeight => 'вес';

  @override
  String get nutritionMissingHeight => 'рост';

  @override
  String get nutritionMissingAnd => ' и ';

  @override
  String get checkinTitleAfternoon => 'Дневной чек-ин';

  @override
  String get checkinTitleEvening => 'Вечерний чек-ин';

  @override
  String get planDurationUnderMinute => '<1 мин';

  @override
  String durationSeconds(int s) {
    return '$s с';
  }

  @override
  String coachFirstRunning(String workout) {
    return 'Начните сегодня: $workout. Дальше Felix подскажет темп по вашим пробежкам.';
  }

  @override
  String get coachFirstRunningNoPlan =>
      'Запишите первую пробежку, и Felix подскажет темп по ней.';

  @override
  String coachFirstCycling(String workout) {
    return 'Начните сегодня: $workout. Дальше Felix подскажет нагрузку по вашим поездкам.';
  }

  @override
  String get coachFirstCyclingNoPlan =>
      'Запишите первую поездку, и Felix подскажет, с какой нагрузкой ехать дальше.';

  @override
  String coachFirstFootball(String workout) {
    return 'Начните сегодня: $workout. После каждой записанной игры Felix подскажет, как восстановиться.';
  }

  @override
  String get coachFirstFootballNoPlan =>
      'Запишите первую игру или тренировку, и Felix подскажет, как восстановиться.';

  @override
  String coachFirstSkiing(String workout) {
    return 'Начните сегодня: $workout. Дальше Felix будет следить за спусками и перепадом высот по вашим записям.';
  }

  @override
  String get coachFirstSkiingNoPlan =>
      'Запишите первый лыжный день, и Felix будет следить за спусками и перепадом высот.';

  @override
  String get skiStateMoving => 'В движении';
}
