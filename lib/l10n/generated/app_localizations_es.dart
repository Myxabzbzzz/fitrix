// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get continueButton => 'Continuar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get introStart => 'Empieza tu camino';

  @override
  String get aboutMeTitle => 'Sobre mí';

  @override
  String get age => 'Edad';

  @override
  String get weight => 'Peso';

  @override
  String get height => 'Altura';

  @override
  String get unitKg => 'kg';

  @override
  String get unitCm => 'cm';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutTitle => '¿Cerrar sesión?';

  @override
  String get signOutLocalBody =>
      'Tu perfil, chats y entrenamientos se guardan solo en este dispositivo y se eliminarán.';

  @override
  String get signOutAccountBody =>
      'Tu perfil, entrenamientos y chats están guardados en tu cuenta y se eliminarán de este dispositivo. Inicia sesión con el mismo correo para recuperarlos.';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => '¿Eliminar la cuenta?';

  @override
  String get deleteAccountBody =>
      'Se eliminará para siempre tu cuenta de FITRIX y todo su contenido: tu perfil, planes de entrenamiento, historial de entrenamientos y chats con Felix, en todos tus dispositivos.';

  @override
  String get deleteAccountAppleNote => 'Apple te pedirá que lo confirmes.';

  @override
  String get deleteForGoodTitle => '¿Eliminar para siempre?';

  @override
  String get deleteForGoodBody => 'Una cuenta eliminada no se puede recuperar.';

  @override
  String get deletingAccount => 'Eliminando tu cuenta…';

  @override
  String deleteAccountFailed(String reason) {
    return 'No se pudo eliminar tu cuenta. $reason';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String workoutDeleted(String name) {
    return '«$name» eliminado';
  }

  @override
  String get syncFailed =>
      'No se pudo sincronizar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get homeToday => 'Hoy';

  @override
  String homeTodayMeta(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '1 ejercicio',
    );
    return '$_temp0 · unos $minutes min';
  }

  @override
  String get homeStart => 'Empezar';

  @override
  String get homeContinue => 'Continuar';

  @override
  String get progressTitle => 'Mi progreso';

  @override
  String get progressStrength => 'Fuerza';

  @override
  String progressNoWorkouts(String sport) {
    return 'Aún no hay entrenamientos de $sport. Termina uno con al menos una serie marcada y tu progreso aparecerá aquí.';
  }

  @override
  String get progressRecentWorkouts => 'Entrenamientos recientes';

  @override
  String get progressBody => 'Cuerpo';

  @override
  String get progressSampleNote =>
      'Datos de ejemplo: el seguimiento llegará pronto.';

  @override
  String progressFirst(String value) {
    return 'Primero: $value';
  }

  @override
  String progressLatest(String value) {
    return 'Último: $value';
  }

  @override
  String progressCurrent(String value) {
    return 'Actual: $value';
  }

  @override
  String progressMonthAgo(String value) {
    return 'Hace un mes: $value';
  }

  @override
  String get progressIntake => 'Ingesta, media';

  @override
  String get progressBurn => 'Gasto, media';

  @override
  String get progressKcalPerDay => 'kcal / día';

  @override
  String progressSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '$count serie',
    );
    return '$_temp0';
  }

  @override
  String get nutritionTitle => 'Mi nutrición';

  @override
  String nutritionOfGoal(String goal) {
    return 'de $goal kcal';
  }

  @override
  String nutritionLeft(String kcal) {
    return 'Quedan $kcal kcal hoy';
  }

  @override
  String get nutritionGoalReached => 'Objetivo de hoy cumplido';

  @override
  String get nutritionProtein => 'Proteína';

  @override
  String get nutritionCarbs => 'Carbohidratos';

  @override
  String get nutritionFat => 'Grasas';

  @override
  String get nutritionBreakfast => 'Desayuno';

  @override
  String get nutritionBreakfastItems => 'Avena, plátano, café';

  @override
  String get nutritionLunch => 'Almuerzo';

  @override
  String get nutritionLunchItems => 'Pollo, arroz, ensalada';

  @override
  String get nutritionSnack => 'Merienda';

  @override
  String get nutritionSnackItems => 'Yogur y frutos secos';

  @override
  String get nutritionDinner => 'Cena';

  @override
  String get nutritionNotLogged => 'Aún sin registrar';

  @override
  String nutritionKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String get nutritionTipEyebrow => 'Consejo de Felix';

  @override
  String get nutritionTipTitle => 'Proteína en la cena';

  @override
  String get nutritionTipMessage =>
      'En la cena apunta a unos 40 g de proteína. Pollo, arroz y verduras encajan en tu plan.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileWorkouts => 'entrenamientos';

  @override
  String get profileDayStreak => 'días seguidos';

  @override
  String get profileKgNow => 'kg ahora';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get profileTheme => 'Tema';

  @override
  String get profileThemeAuto => 'Auto';

  @override
  String get profileThemeLight => 'Claro';

  @override
  String get profileThemeDark => 'Oscuro';

  @override
  String get chatQuickPlanWeek => 'Planifica mi semana';

  @override
  String get chatQuickEatToday => '¿Qué debería comer hoy?';

  @override
  String get chatQuickTired => 'Hoy estoy sin energía';

  @override
  String get gymToday => 'Hoy';

  @override
  String get gymStart => 'Empezar';

  @override
  String get gymDone => 'Hecho';

  @override
  String get gymAskFelix => 'Preguntar';

  @override
  String gymCoachEyebrow(String sport) {
    return 'ENTRENADOR IA: $sport';
  }

  @override
  String gymTileCaption(int plans, int week) {
    String _temp0 = intl.Intl.pluralLogic(
      plans,
      locale: localeName,
      other: '$plans planes',
      one: '$plans plan',
    );
    return '$_temp0 · $week esta semana';
  }

  @override
  String get discoverTitle => 'Descubrir';

  @override
  String get discoverNotifications => 'Notificaciones';

  @override
  String get discoverNoNotifications => 'No hay notificaciones nuevas';

  @override
  String get discoverForYou => 'Para ti';

  @override
  String get discoverChallenges => 'Retos';

  @override
  String get discoverPrograms => 'Programas';

  @override
  String get discoverArticles => 'Artículos';

  @override
  String get discoverThisWeek => 'Esta semana';

  @override
  String get discoverJoin => 'Unirme al reto';

  @override
  String get discoverJoined => 'Te has unido';

  @override
  String get discoverSignInToJoin => 'Inicia sesión para unirte a los retos';

  @override
  String get discoverSignIn => 'Iniciar sesión';

  @override
  String get discoverJoinFailed => 'No se pudo unir. Inténtalo de nuevo.';

  @override
  String get discoverProgramsForYou => 'Programas para ti';

  @override
  String get discoverAll => 'Todo';

  @override
  String discoverProgramSoon(String title) {
    return '$title: vista previa próximamente';
  }

  @override
  String get discoverFelixEyebrow => 'Consejo de Felix';

  @override
  String get discoverFelixTitle => 'El descanso te hace más fuerte';

  @override
  String get discoverFelixMessage =>
      'Dos días suaves a la semana reducen el riesgo de lesión y mantienen tus marcas en alza.';

  @override
  String get discoverAskFelix => 'Preguntar a Felix';

  @override
  String get discoverRead => 'Leer';

  @override
  String discoverMinRead(int n) {
    return '$n min de lectura';
  }

  @override
  String get discoverArticleMissing => 'Este artículo no está disponible.';

  @override
  String get shopTitle => 'Tienda';

  @override
  String shopCartLabel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Carrito, $n artículos',
      one: 'Carrito, 1 artículo',
      zero: 'Carrito vacío',
    );
    return '$_temp0';
  }

  @override
  String get shopSearchHint => 'Buscar productos';

  @override
  String get shopAll => 'Todo';

  @override
  String get shopCatSupplements => 'Suplementos';

  @override
  String get shopCatEquipment => 'Equipamiento';

  @override
  String get shopCatApparel => 'Ropa';

  @override
  String get shopProBlurb =>
      'Chats ilimitados con Felix, planes a medida y revisión de técnica.';

  @override
  String get shopProButton => 'Saber más';

  @override
  String get shopProSoonTitle => 'FITRIX Pro llega pronto';

  @override
  String get shopProSoonBody => 'Te avisaremos en cuanto esté listo.';

  @override
  String get shopGotIt => 'Entendido';

  @override
  String shopNothingFound(String query) {
    return 'No se encontró nada para «$query».';
  }

  @override
  String shopAdd(String name) {
    return 'Añadir $name';
  }

  @override
  String get shopCartTitle => 'Carrito';

  @override
  String get shopClose => 'Cerrar';

  @override
  String get shopRemoveOne => 'Quitar uno';

  @override
  String get shopAddOne => 'Añadir uno';

  @override
  String get shopTotal => 'Total';

  @override
  String get shopPlaceOrder => 'Hacer pedido';

  @override
  String get shopCartEmpty =>
      'Tu carrito está vacío. Toca + en cualquier producto para añadirlo.';

  @override
  String get shopOrderPlaced => 'Pedido realizado';

  @override
  String get shopSignInToOrder => 'Inicia sesión para hacer el pedido';

  @override
  String get shopOrderFailed =>
      'No se pudo hacer el pedido. Revisa tu conexión.';

  @override
  String get shopRetry => 'Reintentar';

  @override
  String get shopNoProducts => 'Aún no hay productos';

  @override
  String get mapTitle => 'Mapa Fitrix';

  @override
  String get mapFilterAll => 'Todo';

  @override
  String get mapFilterGyms => 'Gimnasios';

  @override
  String get mapFilterParks => 'Parques';

  @override
  String get mapFilterTracks => 'Pistas';

  @override
  String get mapFilterPools => 'Piscinas';

  @override
  String get mapLocationOff =>
      'Ubicación desactivada: mostrando el centro de Taskent';

  @override
  String get mapHoursUnknown => 'Horario no indicado';

  @override
  String mapAway(String distance) {
    return 'a $distance';
  }

  @override
  String get mapShowRoute => 'Mostrar ruta';

  @override
  String get mapHideRoute => 'Ocultar ruta';

  @override
  String get mapModesLabel => 'Cómo llegar';

  @override
  String get mapModeWalk => 'A pie';

  @override
  String get mapModeBike => 'Bici';

  @override
  String get mapModeCar => 'Coche';

  @override
  String get mapModeMetro => 'Metro';

  @override
  String get mapComputing => 'Calculando rutas…';

  @override
  String get mapCoverage => 'Las rutas cubren el centro de Taskent';

  @override
  String get mapNoRoute => 'No hay ruta para este modo';

  @override
  String get mapMetroNoHelp =>
      'El metro no ayuda en este trayecto: ningún par de estaciones ahorra tiempo.';

  @override
  String get mapPlanFailed =>
      'No se pudieron calcular las rutas. Prueba con otro lugar.';

  @override
  String mapMinutes(int n) {
    return '$n min';
  }

  @override
  String mapHoursMinutes(int h, int m) {
    return '$h h $m min';
  }

  @override
  String mapArrive(String duration, String time) {
    return '$duration · llegada $time';
  }

  @override
  String mapRide(String from, String to, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paradas',
      one: '$count parada',
    );
    return '$from → $to, $_temp0';
  }

  @override
  String mapWalkTotal(String distance) {
    return '$distance a pie en total';
  }

  @override
  String get mapWalkingFaster => 'aquí es más rápido ir a pie';

  @override
  String mapNoteWalk(String distance) {
    return '$distance a pie';
  }

  @override
  String mapNoteBike(String distance) {
    return '$distance en bici, con ciclovías';
  }

  @override
  String mapNoteCar(String distance) {
    return '$distance en coche, sin datos de tráfico, 2 min para aparcar';
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
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done de $total series',
      one: '$done de $total serie',
    );
    return '$_temp0';
  }

  @override
  String workoutSetCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n series',
      one: '$n serie',
    );
    return '$_temp0';
  }

  @override
  String workoutSetDone(int n) {
    return 'Serie $n hecha';
  }

  @override
  String get workoutFinishTitle => '¿Terminar el entrenamiento?';

  @override
  String get workoutFinishNoSets =>
      'No hay ninguna serie marcada, así que este entrenamiento no se guardará.';

  @override
  String workoutFinishSummary(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done de $total series completadas.',
      one: '$done de $total serie completada.',
    );
    return '$_temp0 El entrenamiento se guardará en tu historial.';
  }

  @override
  String get workoutKeepGoing => 'Seguir';

  @override
  String get workoutFinish => 'Terminar';

  @override
  String get workoutSaved => 'Entrenamiento guardado en Mi progreso';

  @override
  String get workoutNoExercises =>
      'Aún no hay ejercicios. Mantén pulsada la tarjeta del entrenamiento para añadir.';

  @override
  String get workoutAddSet => 'Añadir serie';

  @override
  String get workoutFinishButton => 'Terminar entrenamiento';

  @override
  String get workoutColSet => '#';

  @override
  String get workoutColPrevious => 'Anterior';

  @override
  String get workoutColKg => 'Kg';

  @override
  String get workoutColReps => 'Reps';

  @override
  String get gymCoachFirstTitle => '¿Todo listo para tu primer entrenamiento?';

  @override
  String gymCoachFirstMessage(String workout) {
    return 'Empieza con $workout. Felix ajustará el plan después.';
  }

  @override
  String get gymCoachBackTitle => '¡Hola de nuevo!';

  @override
  String gymCoachBackMessage(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '$days día',
    );
    return 'Tu último entrenamiento fue hace $_temp0. Una sesión más ligera hoy te devuelve al ritmo.';
  }

  @override
  String get gymFinishCurrentTitle => '¿Terminar el entrenamiento actual?';

  @override
  String gymFinishCurrentBody(String current, String next) {
    return '«$current» sigue en curso. ¿Empezar «$next» en su lugar?';
  }

  @override
  String get gymMyWorkouts => 'Mis entrenamientos';

  @override
  String get gymNewWorkout => 'Nuevo entrenamiento';

  @override
  String get gymNewWorkoutHint => 'p. ej., Hombros';

  @override
  String get gymAdd => 'Añadir';

  @override
  String get gymEditNameHint => 'Nombre del entrenamiento';

  @override
  String get gymEditDelete => 'Eliminar entrenamiento';

  @override
  String get gymEditAddExerciseHint => 'Añadir ejercicio';

  @override
  String get gymEditSave => 'Guardar';

  @override
  String get sportGym => 'Gimnasio';

  @override
  String get sportFitness => 'Fitness';

  @override
  String get sportCycling => 'Ciclismo';

  @override
  String get sportRunning => 'Running';

  @override
  String get sportFootball => 'Fútbol';

  @override
  String get sportWinterSports => 'Deportes de invierno';

  @override
  String get sportWinterSportsTile => 'DEPORTES\nDE INVIERNO';

  @override
  String get tabDiscover => 'Descubrir';

  @override
  String get tabShop => 'Tienda';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabFelix => 'Felix';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get homeTileProgress => 'MI\nPROGRESO';

  @override
  String get homeTileNutrition => 'MI\nNUTRICIÓN';

  @override
  String get homeTileWorkouts => 'MIS\nENTRENOS';

  @override
  String get homeTileShop => 'TIENDA';

  @override
  String get homeTileMap => 'MAPA\nFITRIX';

  @override
  String get homeMenuMap => 'Mapa Fitrix';

  @override
  String get chatTyping => 'Felix está escribiendo';

  @override
  String chatError(String error) {
    return 'Error: $error';
  }

  @override
  String get chatStart => 'Empezar';

  @override
  String get chatMessageHint => 'Mensaje...';

  @override
  String get chatAllChats => 'Todos los chats';

  @override
  String get chatTapToRetry => 'Toca para reintentar';

  @override
  String get progressWeightTitle => 'Mi peso (kg)';

  @override
  String get progressCaloriesTitle => 'Calorías: ingesta y gasto';

  @override
  String signInCodeResent(String email) {
    return 'Hemos enviado un nuevo código a $email';
  }

  @override
  String get signInChangeEmail => 'Cambiar correo';

  @override
  String get profileFieldName => 'Nombre';

  @override
  String get profileFieldSurname => 'Apellido';

  @override
  String get profileFieldWeightKg => 'Peso, kg';

  @override
  String get profileFieldHeightCm => 'Altura, cm';

  @override
  String get signInAgainTitle => 'Inicia sesión de nuevo';

  @override
  String get signInAgainSubtitle =>
      'Tu sesión ha terminado. Introduce tu correo para continuar.';

  @override
  String get signInCreateTitle => 'Crea una cuenta';

  @override
  String get signInCreateSubtitle =>
      'Introduce tu correo para registrarte en la app';

  @override
  String get signInGetCode => 'Obtener código';

  @override
  String get signInTryAgain => 'Reintentar';

  @override
  String get signInOr => 'o';

  @override
  String get signInTermsPrefix => 'Al continuar, aceptas los ';

  @override
  String get signInTerms => 'Términos del servicio';

  @override
  String get signInTermsAnd => ' y la ';

  @override
  String get signInPrivacy => 'Política de privacidad';

  @override
  String get signInTermsSuffix => '.';

  @override
  String signInContinueWith(String provider) {
    return 'Continuar con $provider';
  }

  @override
  String get signInCheckEmailTitle => 'Revisa tu correo';

  @override
  String signInCodePrompt(String length, String email) {
    return 'Introduce el código de $length dígitos que enviamos a\n$email';
  }

  @override
  String get signInResend => 'Reenviar código';

  @override
  String signInResendIn(String time) {
    return 'Reenviar código en $time';
  }

  @override
  String get signInSpamNote => '¿No lo encuentras? Revisa la carpeta de spam.';

  @override
  String signInComingSoon(String provider) {
    return 'Iniciar sesión con $provider llegará pronto. Por ahora usa tu correo.';
  }

  @override
  String get signInProfileLoadOffline =>
      'Has iniciado sesión, pero no se pudo cargar tu perfil. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get signInProfileLoadFailed =>
      'Has iniciado sesión, pero no se pudo cargar tu perfil. Inténtalo de nuevo.';

  @override
  String get signInErrInvalidCode =>
      'El código es incorrecto o ha caducado. Revisa el último correo o pide un código nuevo.';

  @override
  String get signInErrRateLimited =>
      'Demasiados intentos. Espera un minuto e inténtalo de nuevo.';

  @override
  String get signInErrNetwork =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo.';

  @override
  String get signInErrInvalidEmail => 'Introduce un correo válido.';

  @override
  String get signInErrUnknown => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String signInErrProviderDisabled(String provider) {
    return 'Iniciar sesión con $provider aún no está configurado en el servidor. Por ahora usa tu correo.';
  }

  @override
  String signInErrProviderUnavailable(String provider) {
    return 'Iniciar sesión con $provider no está disponible en este dispositivo. Usa tu correo.';
  }

  @override
  String signInErrSocialFailed(String provider) {
    return 'No se pudo iniciar sesión con $provider. Inténtalo de nuevo o usa tu correo.';
  }

  @override
  String get profileErrNameRequired => 'Introduce tu nombre';

  @override
  String get profileErrNameTooLong => 'El nombre es demasiado largo';

  @override
  String get profileErrSurnameTooLong => 'El apellido es demasiado largo';

  @override
  String get profileErrAgeRequired => 'Introduce tu edad';

  @override
  String get profileErrAgeWhole => 'La edad debe ser un número entero';

  @override
  String profileErrAgeRange(String min, String max) {
    return 'La edad debe estar entre $min y $max';
  }

  @override
  String get profileErrWeightRequired => 'Introduce tu peso';

  @override
  String get profileErrWeightNumber => 'Introduce tu peso como número';

  @override
  String profileErrWeightRange(String min, String max) {
    return 'El peso debe estar entre $min y $max kg';
  }

  @override
  String get profileErrHeightRequired => 'Introduce tu altura';

  @override
  String get profileErrHeightNumber => 'Introduce tu altura como número';

  @override
  String profileErrHeightRange(String min, String max) {
    return 'La altura debe estar entre $min y $max cm';
  }

  @override
  String get signInUnavailable =>
      'Las cuentas no están disponibles ahora. Inténtalo más tarde.';

  @override
  String get programLevelBeginner => 'Principiante';

  @override
  String get programLevelMedium => 'Intermedio';

  @override
  String get programLevelAdvanced => 'Avanzado';

  @override
  String get shopOrderUnavailable =>
      'Algunos artículos ya no están disponibles. Actualiza tu carrito e inténtalo de nuevo.';
}
