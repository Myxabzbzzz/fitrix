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
  String get signOut => 'Cerrar sesión';

  @override
  String get signOutTitle => '¿Cerrar sesión?';

  @override
  String get signOutLocalBody =>
      'Todo lo que registraste está guardado solo en este dispositivo y se eliminará: perfil, entrenamientos, chats, chequeos, planes, comidas y peso.';

  @override
  String get signOutAccountBody =>
      'Todo lo que registraste está guardado en tu cuenta y se eliminará de este dispositivo. Inicia sesión con el mismo correo para recuperar tus datos.';

  @override
  String signOutPendingBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count cambios aún no han llegado a tu cuenta (¿sin conexión?). Si cierras sesión ahora, se eliminarán.',
      one:
          '$count cambio aún no ha llegado a tu cuenta (¿sin conexión?). Si cierras sesión ahora, se eliminará.',
    );
    return '$_temp0';
  }

  @override
  String get signOutAnyway => 'Cerrar sesión de todos modos';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => '¿Eliminar la cuenta?';

  @override
  String get deleteAccountBody =>
      'Se eliminará para siempre tu cuenta de FITRIX y todo su contenido: tu perfil, planes de entrenamiento, historial de entrenamientos, chats con Felix, check-ins, comidas y peso corporal, en todos tus dispositivos.';

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
  String get nutritionTitle => 'Mi nutrición';

  @override
  String nutritionOfGoal(String goal) {
    return 'de $goal kcal';
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
  String get nutritionLunch => 'Almuerzo';

  @override
  String get nutritionSnack => 'Merienda';

  @override
  String get nutritionDinner => 'Cena';

  @override
  String get nutritionNotLogged => 'Aún sin registrar';

  @override
  String nutritionKcal(String kcal) {
    return '$kcal kcal';
  }

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileWorkouts => 'entrenamientos';

  @override
  String get profileDayStreak => 'días seguidos';

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
  String get shopProSoonBody =>
      'Aún no está disponible. Aparecerá aquí en una próxima actualización.';

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
    return 'Empieza con $workout. La próxima vez Felix te sugerirá pesos según lo que registres.';
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
  String get gymFinishCurrentTitle => '¿Descartar el entrenamiento actual?';

  @override
  String gymFinishCurrentBody(String current, String next) {
    return '«$current» sigue en curso y no se guardará. ¿Empezar «$next» en su lugar?';
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

  @override
  String get workoutKeyboardDone => 'Listo';

  @override
  String get workoutEditLabel => 'Editar entrenamiento';

  @override
  String get aboutMeSave => 'Guardar';

  @override
  String get aboutMeSaved => 'Guardado';

  @override
  String get aboutMeDiscardTitle => '¿Descartar cambios?';

  @override
  String get aboutMeDiscardBody => 'Tus cambios en el perfil no se guardarán.';

  @override
  String get aboutMeDiscard => 'Descartar';

  @override
  String get aboutMeKeepEditing => 'Seguir editando';

  @override
  String get aboutMeEmail => 'Correo';

  @override
  String get aboutMeGoal => 'Objetivo';

  @override
  String get aboutMeGoalOther => 'Otro…';

  @override
  String get aboutMeGoalOtherHint => 'Describe tu objetivo';

  @override
  String get aboutMeLevel => 'Nivel';

  @override
  String get aboutMeSports => 'Deportes';

  @override
  String get aboutMeSportsLimit => 'Puedes elegir hasta 6 deportes.';

  @override
  String get aboutGoalBuild => 'Ganar músculo y fuerza';

  @override
  String get aboutGoalEndurance => 'Mejorar la resistencia';

  @override
  String get aboutGoalLose => 'Perder peso y tonificar';

  @override
  String get aboutGoalHealthy => 'Sentirme más sano y equilibrado';

  @override
  String get aboutGoalTrack => 'Solo seguir mi progreso';

  @override
  String get chatAddPhoto => 'Añadir foto';

  @override
  String get chatTakePhoto => 'Hacer foto';

  @override
  String get chatChooseFromLibrary => 'Elegir de la galería';

  @override
  String get chatRemovePhoto => 'Quitar foto';

  @override
  String get chatPhotoTooLarge =>
      'La foto es demasiado grande. Prueba con otra.';

  @override
  String get chatPhotoFailed =>
      'No se pudo obtener la foto. Revisa los permisos de cámara y fotos en Ajustes.';

  @override
  String get chatPhotoPrompt => '¿Qué opinas de esta foto?';

  @override
  String get chatMicStart => 'Dictar un mensaje';

  @override
  String get chatMicStop => 'Detener dictado';

  @override
  String get chatMicDenied =>
      'Felix aún no te oye. Abre Ajustes y permite a FITRIX el micrófono y el reconocimiento de voz.';

  @override
  String get chatPhotoViewer => 'Foto';

  @override
  String get chatPhotoUnavailable =>
      'La foto no está disponible o es demasiado grande para enviarla.';

  @override
  String get chatMicListening => 'Escuchando';

  @override
  String get chatMicStopped => 'Escucha detenida';

  @override
  String get chatActionConfirm => 'Confirmar';

  @override
  String get chatActionApplied => 'Añadido ✓';

  @override
  String chatActionWeightChange(String from, String to) {
    return 'Actualizar peso: $from → $to kg';
  }

  @override
  String chatActionWorkoutExercises(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '$count ejercicio',
    );
    return '$_temp0';
  }

  @override
  String get chatActionMealTitle => 'Añadir a la nutrición de hoy';

  @override
  String chatActionMealTotal(String kcal) {
    return '$kcal kcal en total';
  }

  @override
  String get chatActionOpen => 'Abrir';

  @override
  String chatActionWeightDone(String from, String to) {
    return 'Peso actualizado: $from → $to kg';
  }

  @override
  String chatActionWeightDoneSet(String to) {
    return 'Peso actualizado a $to kg';
  }

  @override
  String get chatActionNoProfile =>
      'Primero completa tu perfil y entonces podré actualizar tu peso.';

  @override
  String get chatActionError => 'No se pudo aplicar. Inténtalo de nuevo.';

  @override
  String get chatActionUndoError => 'No se pudo deshacer. Inténtalo de nuevo.';

  @override
  String get chatActionWeightChangedSince =>
      'El peso cambió desde entonces: no se deshizo nada';

  @override
  String get unitTonnes => 't';

  @override
  String workoutLiveCaption(int x, int y, String t) {
    return 'Serie $x de $y · $t levantadas';
  }

  @override
  String get workoutColRpe => 'RPE';

  @override
  String workoutRestShort(String time) {
    return 'descanso $time';
  }

  @override
  String workoutBestShort(String value) {
    return 'mejor $value';
  }

  @override
  String get workoutPr => 'PR';

  @override
  String get workoutE1rm => 'e1RM';

  @override
  String get workoutBodyweight => 'PC';

  @override
  String workoutFelixLine(String last, String next) {
    return 'La última vez $last. Hoy prueba $next kg.';
  }

  @override
  String get workoutRestLabel => 'Descanso';

  @override
  String workoutRestNext(String label) {
    return 'Siguiente: $label';
  }

  @override
  String workoutNextSet(int n, String kg, int reps) {
    return 'Serie $n · $kg × $reps';
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
  String get workoutRestSkip => 'Omitir';

  @override
  String get workoutMenuSwap => 'Cambiar ejercicio';

  @override
  String workoutMenuSimilar(String names) {
    return 'Similares: $names';
  }

  @override
  String get workoutMenuWarmup => 'Añadir series de calentamiento';

  @override
  String workoutMenuWarmupSub(String plan) {
    return '2 series: $plan';
  }

  @override
  String get workoutMenuRest => 'Temporizador de descanso';

  @override
  String get workoutMenuRestSub => 'Para este ejercicio';

  @override
  String get workoutMenuNote => 'Nota';

  @override
  String get workoutMenuNoteEmpty => 'Añadir una nota';

  @override
  String get workoutMenuNoteHint => 'Por ejemplo: correas en la última serie';

  @override
  String get workoutNoteSave => 'Guardar';

  @override
  String get workoutMenuReorder => 'Reordenar';

  @override
  String get workoutMenuReorderSub => 'Subir o bajar en el entrenamiento';

  @override
  String get workoutMenuRemove => 'Quitar ejercicio';

  @override
  String get workoutRemoveTitle => '¿Quitar este ejercicio?';

  @override
  String get workoutRemoveBody => 'Se perderán las series registradas.';

  @override
  String get workoutRemoveConfirm => 'Quitar';

  @override
  String workoutRpeTitle(int n) {
    return 'RPE de la serie $n · ¿qué tan duro fue?';
  }

  @override
  String workoutRpeCaption(int n, int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left repeticiones',
      one: '$left repetición',
    );
    return 'RPE $n · unas $_temp0 en reserva';
  }

  @override
  String get workoutCompleteTitle => 'Entrenamiento completado';

  @override
  String workoutCompleteSubtitle(String name, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n récords nuevos',
      one: '$n récord nuevo',
      zero: 'sin récords nuevos',
    );
    return '$name · $_temp0';
  }

  @override
  String get workoutTileDuration => 'Duración';

  @override
  String get workoutTileVolume => 'Volumen';

  @override
  String get workoutTileSets => 'Series';

  @override
  String get workoutTileRecords => 'Récords';

  @override
  String get workoutTileLoad => 'Carga';

  @override
  String get workoutOverallTitle => '¿Qué tan dura fue en general?';

  @override
  String get workoutOverallHint =>
      'Opcional. Cuenta para tu carga de entrenamiento y tu puntuación de recuperación.';

  @override
  String workoutOverallCaption(int n, String label) {
    return 'RPE $n · $label. Cuenta para tu carga de entrenamiento.';
  }

  @override
  String get workoutRpeVeryEasy => 'Muy fácil';

  @override
  String get workoutRpeEasy => 'Fácil';

  @override
  String get workoutRpeModerate => 'Moderado';

  @override
  String get workoutRpeHard => 'Duro';

  @override
  String get workoutRpeVeryHard => 'Muy duro';

  @override
  String get workoutRpeMax => 'Esfuerzo máximo';

  @override
  String get workoutExercisesTitle => 'Ejercicios';

  @override
  String get workoutBestSetE1rm => 'mejor serie · e1RM';

  @override
  String workoutBestSet(String value) {
    return 'Mejor serie $value';
  }

  @override
  String get workoutNextTimeTitle => 'La próxima vez';

  @override
  String workoutNextTimeBody(String exercise, String kg) {
    return '$exercise: todas las series hechas. La próxima vez prueba $kg kg.';
  }

  @override
  String get workoutSave => 'Guardar entrenamiento';

  @override
  String get workoutDiscard => 'Descartar';

  @override
  String get workoutDiscardTitle => '¿Descartar este entrenamiento?';

  @override
  String get workoutDiscardBody => 'No se guardará en tu historial.';

  @override
  String get workoutAddExercise => 'Ejercicio';

  @override
  String homeGreetingMorning(String name) {
    return 'Buenos días, $name';
  }

  @override
  String get homeGreetingMorningNoName => 'Buenos días';

  @override
  String homeGreetingAfternoon(String name) {
    return 'Buenas tardes, $name';
  }

  @override
  String get homeGreetingAfternoonNoName => 'Buenas tardes';

  @override
  String homeGreetingEvening(String name) {
    return 'Buenas noches, $name';
  }

  @override
  String get homeGreetingEveningNoName => 'Buenas noches';

  @override
  String get checkinCardPrompt =>
      '¿Cómo te sientes hoy? 20 segundos para saber qué tan listo estás para entrenar.';

  @override
  String get checkinCardAction => 'Registrar';

  @override
  String checkinCardRecovered(int score) {
    return '$score% recuperado';
  }

  @override
  String get checkinCardSeeMore => 'Ver qué influyó';

  @override
  String get checkinTitle => 'Chequeo matutino';

  @override
  String get checkinSleep => 'Sueño';

  @override
  String checkinSleepDuration(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get checkinSleepLess => 'Dormir 15 minutos menos';

  @override
  String get checkinSleepMore => 'Dormir 15 minutos más';

  @override
  String get sleepQualityPoor => 'Mala';

  @override
  String get sleepQualityOk => 'Normal';

  @override
  String get sleepQualityGood => 'Buena';

  @override
  String get checkinSoreness => 'Dolor muscular';

  @override
  String get sorenessNone => 'Ninguno';

  @override
  String get sorenessLight => 'Leve';

  @override
  String get sorenessMedium => 'Media';

  @override
  String get sorenessStrong => 'Fuerte';

  @override
  String get bodyLegs => 'Piernas';

  @override
  String get bodyBack => 'Espalda';

  @override
  String get bodyChest => 'Pecho';

  @override
  String get bodyArms => 'Brazos';

  @override
  String get bodyShoulders => 'Hombros';

  @override
  String get checkinEnergy => 'Energía';

  @override
  String get checkinStress => 'Estrés';

  @override
  String get levelLow => 'Baja';

  @override
  String get levelOk => 'Normal';

  @override
  String get levelHigh => 'Alta';

  @override
  String get stressLow => 'Bajo';

  @override
  String get stressMedium => 'Medio';

  @override
  String get stressHigh => 'Alto';

  @override
  String get checkinSave => 'Guardar chequeo';

  @override
  String get readinessReady => 'Listo para entrenar';

  @override
  String get readinessTrainLight => 'Entrena suave';

  @override
  String get readinessRest => 'Descansa hoy';

  @override
  String get checkinHintReady => 'Una sesión dura está bien.';

  @override
  String checkinHintReadySore(String areas) {
    return 'Una sesión dura está bien. $areas necesitan un día más.';
  }

  @override
  String get checkinHintLight => 'Hoy ve más suave.';

  @override
  String get checkinHintRest =>
      'Tómatelo con calma. Recuperarse también es entrenar.';

  @override
  String get recoveryTitle => 'Recuperación';

  @override
  String recoverySubtitle(String time) {
    return 'Hoy · chequeo a las $time';
  }

  @override
  String get recoveryRecovered => 'recuperado';

  @override
  String recoveryHintReadySore(String areas) {
    return 'Una sesión dura está bien. Hoy $areas suave.';
  }

  @override
  String get recoveryShaped => 'Qué influyó';

  @override
  String factorSleep(String duration) {
    return 'Sueño $duration';
  }

  @override
  String factorSleepQuality(String quality) {
    return 'Calidad: $quality';
  }

  @override
  String factorSoreness(String level) {
    return 'Dolor: $level';
  }

  @override
  String factorEnergy(String level) {
    return 'Energía: $level';
  }

  @override
  String factorStress(String level) {
    return 'Estrés: $level';
  }

  @override
  String get factorLoad => 'Carga de entrenamiento';

  @override
  String factorLoadSub(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días duros',
      one: '1 día duro',
    );
    return '$_temp0 en los últimos 7';
  }

  @override
  String get recoveryPlanTitle => 'Plan de hoy, ajustado';

  @override
  String recoveryPlanApplied(String plan, String swaps, String areas) {
    return '$plan se queda. Cambios: $swaps. Así cuidas: $areas.';
  }

  @override
  String recoveryPlanSuggested(String plan, String swaps, String areas) {
    return '$plan puede quedarse. Cambios sugeridos: $swaps, para cuidar: $areas.';
  }

  @override
  String get recoveryStartWorkout => 'Empezar entrenamiento';

  @override
  String get recoveryUndo => 'Deshacer';

  @override
  String get recoveryApplySwaps => 'Aplicar cambios';

  @override
  String get recoveryLast7 => 'Últimos 7 días';

  @override
  String recoveryAvg(int score) {
    return 'media $score%';
  }

  @override
  String get recoveryNoCheckin => 'Aún no hay chequeo';

  @override
  String get recoveryNoCheckinBody =>
      'Registra cómo estás para ver tu recuperación y qué influyó.';

  @override
  String get planTitle => 'Esta semana';

  @override
  String planSummary(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sesiones',
      one: '$n sesión',
    );
    return '$_temp0 · $m hechas';
  }

  @override
  String get planLoadTitle => 'Carga de entrenamiento';

  @override
  String get planLoadEasy => 'Baja';

  @override
  String get planLoadNormal => 'Normal';

  @override
  String get planLoadHigh => 'Alta';

  @override
  String planLoadCaption(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n sesiones duras en los próximos 3 días.',
      one: '$n sesión dura en los próximos 3 días.',
    );
    return '$_temp0';
  }

  @override
  String planRecoveryToday(int score) {
    return 'Recuperación hoy: $score%.';
  }

  @override
  String get planFelixLabel => 'FELIX SUGIERE';

  @override
  String planFelixText(
      String a, String aDay, String b, String bDay, String target) {
    return '$a ($aDay) y $b ($bDay) son duras. Mueve $b a $target para que tus piernas se recuperen.';
  }

  @override
  String get planOptimize => 'Optimizar plan';

  @override
  String get planKeep => 'Mantener';

  @override
  String planTodayDay(String day) {
    return 'Hoy · $day';
  }

  @override
  String planDoneCount(int n) {
    return '$n hechas';
  }

  @override
  String planPlannedCount(int n) {
    return '$n planificadas';
  }

  @override
  String get planMissedHeader => 'perdida';

  @override
  String get planMissed => 'Perdida';

  @override
  String get planRestDay => 'Día de descanso';

  @override
  String planExercisesMeta(int count, String duration) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ejercicios',
      one: '$count ejercicio',
    );
    return '$_temp0 · $duration';
  }

  @override
  String planDurationHM(int h, int m) {
    return '$h h $m min';
  }

  @override
  String planDurationH(int h) {
    return '$h h';
  }

  @override
  String planDurationM(int m) {
    return '$m min';
  }

  @override
  String get planIntensityEasy => 'Suave';

  @override
  String get planIntensityNormal => 'Normal';

  @override
  String get planIntensityHard => 'Dura';

  @override
  String planDoneMeta(String duration, int rpe) {
    return '$duration · RPE $rpe';
  }

  @override
  String get planAddSession => 'Añadir sesión';

  @override
  String get planAddTitle => 'Añadir una sesión';

  @override
  String get planWorkoutLabel => 'ENTRENAMIENTO';

  @override
  String get planDayLabel => 'DÍA';

  @override
  String planAddButton(String title, String day) {
    return 'Añadir $title · $day';
  }

  @override
  String planWarnThird(String day) {
    return '$day sería tu 3.er día duro seguido';
  }

  @override
  String planWarnAuto(String day) {
    return '$day te da más tiempo para recuperarte. Felix lo eligió por ti.';
  }

  @override
  String get planWarnPick => 'Elige otro día para cuidar tu recuperación.';

  @override
  String get planGenericFootball => 'Fútbol 7×7';

  @override
  String get planSkiing => 'Esquí';

  @override
  String get planEmptyTitle => 'Aún no hay plan';

  @override
  String get planEmptyBody =>
      'Organiza tus entrenamientos de gimnasio para el resto de la semana con un toque.';

  @override
  String get planPlanWeek => 'Planificar mi semana';

  @override
  String get planEntryEmpty => 'Planifica tu semana de entrenamiento';

  @override
  String get planNextWeek => 'Próxima semana';

  @override
  String get planPlanNextWeek => 'Planificar la próxima semana';

  @override
  String get exercisesTitle => 'Ejercicios';

  @override
  String exercisesSearch(int n) {
    return 'Buscar entre $n ejercicios';
  }

  @override
  String get exercisesSearchShort => 'Buscar ejercicios';

  @override
  String get exercisesAll => 'Todos';

  @override
  String get exercisesAnyEquipment => 'Cualquier equipo';

  @override
  String get exercisesRecent => 'Recientes';

  @override
  String get exercisesFromWorkouts => 'de tus entrenos';

  @override
  String get exercisesBest => 'mejor';

  @override
  String get exercisesAZ => 'Todos · A–Z';

  @override
  String exercisesCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ejercicios',
      one: '$n ejercicio',
    );
    return '$_temp0';
  }

  @override
  String get exercisesNoMatch => 'No hay ejercicios. Prueba otro filtro.';

  @override
  String get muscleChest => 'Pecho';

  @override
  String get muscleBack => 'Espalda';

  @override
  String get muscleShoulders => 'Hombros';

  @override
  String get muscleArms => 'Brazos';

  @override
  String get muscleLegs => 'Piernas';

  @override
  String get muscleGlutes => 'Glúteos';

  @override
  String get muscleCore => 'Core';

  @override
  String get equipBarbell => 'Barra';

  @override
  String get equipDumbbell => 'Mancuernas';

  @override
  String get equipCable => 'Polea';

  @override
  String get equipMachine => 'Máquina';

  @override
  String get equipBodyweight => 'Peso corporal';

  @override
  String get equipKettlebell => 'Pesa rusa';

  @override
  String get levelBeginner => 'Principiante';

  @override
  String get levelIntermediate => 'Intermedio';

  @override
  String get levelAdvanced => 'Avanzado';

  @override
  String get exerciseCompound => 'Compuesto';

  @override
  String get exerciseDetailTitle => 'Ejercicio';

  @override
  String get exercisePrimary => 'Principales';

  @override
  String get exerciseSecondary => 'Secundarios';

  @override
  String get exerciseYourNumbers => 'Tus números';

  @override
  String get exerciseBestSet => 'Mejor serie';

  @override
  String get exerciseE1rm => 'e1RM';

  @override
  String get exerciseSessions => 'Sesiones';

  @override
  String exerciseChangeSince(String pct, String month) {
    return '$pct desde $month';
  }

  @override
  String get exerciseNoHistory => 'Hazlo una vez para ver tus números';

  @override
  String get exerciseHowTo => 'Cómo hacerlo';

  @override
  String get exerciseMistakes => 'Errores comunes';

  @override
  String get exerciseSimilar => 'Similares';

  @override
  String get exerciseAskFelix => 'Preguntar a Felix';

  @override
  String exerciseAskFelixDraft(String name) {
    return '¿Cómo mejoro mi $name?';
  }

  @override
  String get exerciseAddToWorkout => 'Añadir al entrenamiento';

  @override
  String get exerciseAdded => 'Añadido al entrenamiento';

  @override
  String get exerciseQuickWorkout => 'Entrenamiento rápido';

  @override
  String addExerciseTitle(String workout) {
    return 'Añadir a $workout';
  }

  @override
  String addExerciseSwapTitle(String workout) {
    return 'Cambiar en $workout';
  }

  @override
  String addExerciseHint(String group, int n, int target) {
    return '$group: $n series esta semana, el objetivo es $target.';
  }

  @override
  String get addExerciseSuggested => 'Sugeridos';

  @override
  String addExerciseSelected(int n) {
    return '$n seleccionados';
  }

  @override
  String get addExerciseLibrary => 'Biblioteca';

  @override
  String get addExerciseInWorkout => 'En este entrenamiento';

  @override
  String addExerciseButton(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Añadir $n ejercicios',
      one: 'Añadir $n ejercicio',
    );
    return '$_temp0';
  }

  @override
  String get addExerciseSwap => 'Cambiar';

  @override
  String get workoutMenuSwapSub => 'Elige de la biblioteca';

  @override
  String get gymExercises => 'Ejercicios';

  @override
  String gymExercisesSub(int n) {
    return '$n con técnica y tus mejores series';
  }

  @override
  String get profileEditTooltip => 'Editar perfil';

  @override
  String get profileMySports => 'Mis deportes';

  @override
  String profileSportsSelected(int n) {
    return '$n seleccionados';
  }

  @override
  String get profileWeightLabel => 'kg · peso';

  @override
  String get profileHeightLabel => 'cm · altura';

  @override
  String get profileAgeLabel => 'años · edad';

  @override
  String get profileSettings => 'Ajustes';

  @override
  String get hrZonesTitle => 'Zonas de frecuencia cardíaca';

  @override
  String profileHrZonesSummary(int rest, int max) {
    return 'Reposo $rest · máx $max lpm';
  }

  @override
  String get profileHrZonesSetUp => 'Configurar';

  @override
  String get profileConnectedApps => 'Apps conectadas';

  @override
  String profileConnectedAppsCount(int connected, int total) {
    return '$connected de $total conectadas';
  }

  @override
  String get hrZonesMax => 'FC máx';

  @override
  String get hrZonesRest => 'FC en reposo';

  @override
  String get hrZonesLthr => 'LTHR';

  @override
  String get hrZonesEdit => 'Editar frecuencias';

  @override
  String get hrZonesKarvonen => 'Karvonen';

  @override
  String get hrZonesFriel => 'LTHR (Friel)';

  @override
  String get hrZonesKarvonenTitle => 'Zonas Karvonen';

  @override
  String get hrZonesKarvonenSub => '% de reserva';

  @override
  String get hrZonesFrielTitle => 'Zonas LTHR';

  @override
  String get hrZonesColZone => 'ZONA';

  @override
  String get hrZonesColBpm => 'LPM';

  @override
  String get hrZonesColHrr => '50–100% reserva';

  @override
  String get hrZonesColLthr => '% DE LTHR';

  @override
  String hrZonesLthrValue(int lthr) {
    return 'LTHR $lthr lpm';
  }

  @override
  String hrZonesFormula(int reserve) {
    return 'FC = reposo + % × (máx − reposo). Tu reserva es $reserve lpm.';
  }

  @override
  String hrZonesZ2Tip(int low, int high) {
    return 'La mayor parte de tu carrera debe estar en Z2, $low–$high lpm. Z4 solo para intervalos cortos.';
  }

  @override
  String get hrZonesHowTitle => 'Cómo medir la FC máxima';

  @override
  String get hrZonesHowBody =>
      'Calienta 15 min y haz dos esfuerzos duros de 3–4 min cuesta arriba. La FC más alta que veas es tu máxima.';

  @override
  String hrZonesTanaka(int age, int max) {
    return '¿Sin prueba aún? Estimación de Tanaka: 208 − 0,7 × $age = $max lpm (±10).';
  }

  @override
  String get hrZonesRestingTip => 'FC en reposo: mídela al despertar, tumbado.';

  @override
  String get hrZonesFrielNote =>
      'Zonas Friel para correr. Prueba LTHR: corre 30 min en solitario a tope; la FC media de los últimos 20 min es tu LTHR.';

  @override
  String get hrZonesNeedAge =>
      'Añade tu edad al perfil para estimar tu FC máxima.';

  @override
  String get hrZonesCompleteProfile => 'Completa tu perfil';

  @override
  String get hrZonesNeedRates =>
      'Añade tu FC en reposo y máxima para ver tus zonas.';

  @override
  String get hrZonesNeedLthr => 'Añade tu LTHR para ver las zonas Friel.';

  @override
  String get hrZoneRecovery => 'Recuperación';

  @override
  String get hrZoneAerobic => 'Aeróbica';

  @override
  String get hrZoneTempo => 'Tempo';

  @override
  String get hrZoneThreshold => 'Umbral';

  @override
  String get hrZoneVo2max => 'VO2máx';

  @override
  String get hrZoneSubThr => 'Sub-umbral';

  @override
  String get hrZoneThreshPlus => 'Umbral+';

  @override
  String get hrZoneCapacity => 'Capacidad';

  @override
  String get hrZoneAnaerobic => 'Anaerób.';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get editProfileBody => 'Cuerpo';

  @override
  String get editProfilePerformance => 'Rendimiento';

  @override
  String get editProfileSex => 'Sexo';

  @override
  String get sexMale => 'Hombre';

  @override
  String get sexFemale => 'Mujer';

  @override
  String get editProfileRestingHr => 'FC en reposo';

  @override
  String get editProfileMaxHr => 'FC máx';

  @override
  String get editProfileLthr => 'LTHR (opcional)';

  @override
  String get editProfileFtp => 'FTP en ciclismo';

  @override
  String get editProfileFiveK => 'Mejor marca en 5 km';

  @override
  String get unitBpm => 'lpm';

  @override
  String get unitWatts => 'W';

  @override
  String get unitMinSec => 'min:seg';

  @override
  String get unitYears => 'años';

  @override
  String get editProfileSave => 'Guardar';

  @override
  String editProfileErrHr(int min, int max) {
    return 'Introduce $min–$max lpm';
  }

  @override
  String get editProfileErrRestMax =>
      'La FC en reposo debe ser menor que la máxima';

  @override
  String editProfileErrFtp(int min, int max) {
    return 'Introduce $min–$max W';
  }

  @override
  String get editProfileErrFiveK => 'Introduce un tiempo de 12:00 a 60:00';

  @override
  String get connectedAppsTitle => 'Apps conectadas';

  @override
  String get connectedAppsWhyHeader => 'POR QUÉ CONECTAR';

  @override
  String connectedAppsWhyBody(String health) {
    return '$health rellena el sueño de anoche en tu chequeo y aporta la FC en reposo y la VFC para la recuperación, los pasos y el peso de básculas inteligentes. Los entrenamientos del reloj se tienen en cuenta en tu historial y en la carga de entrenamiento. Los datos de Apple Watch, Garmin, WHOOP y Mi Band (Zepp / Mi Fitness) llegan a través de $health cuando la sincronización de esa app con $health está activada.';
  }

  @override
  String connectedAppsWhyBodyAndroid(String health) {
    return '$health rellena el sueño de anoche en tu chequeo y aporta la FC en reposo y la VFC para la recuperación, los pasos y el peso de básculas inteligentes. Los entrenamientos del reloj se tienen en cuenta en tu historial y en la carga de entrenamiento. Los datos de Garmin, WHOOP y Mi Band (Zepp / Mi Fitness) llegan a través de $health cuando la sincronización de esa app con $health está activada.';
  }

  @override
  String get connectedAppsHealthDesc =>
      'Sueño, FC, VFC, pasos, peso, entrenamientos';

  @override
  String get connectedAppsGarminDesc => 'Actividades, FC, sueño, VFC';

  @override
  String get connectedAppsStravaDesc => 'Carreras, rutas en bici y esquí';

  @override
  String get connectedAppsWhoopDesc => 'Recuperación, esfuerzo, sueño, VFC';

  @override
  String get connectedAppsNotConnected => 'No conectada';

  @override
  String get connectedAppsConnect => 'Conectar';

  @override
  String get connectedAppsFooter => 'Puedes desconectar en cualquier momento.';

  @override
  String connectedAppsSheetTitle(String app) {
    return 'Conectar $app';
  }

  @override
  String get connectedAppsSheetSubtitle => 'Qué podría leer FITRIX';

  @override
  String get connectedAppsSheetPrivacy =>
      'Cuando llegue, FITRIX solo leerá datos y nunca publicará.';

  @override
  String connectedAppsSheetSoon(String app, String health) {
    return 'Conectar $app directamente aún no está disponible. Mientras tanto, envía sus datos a $health y FITRIX los leerá desde ahí.';
  }

  @override
  String get connectedAppsComingSoon => 'Llegará en una próxima actualización';

  @override
  String get connectedAppsClose => 'Cerrar';

  @override
  String get connectedAppsConnected => 'Conectada';

  @override
  String connectedAppsLastRead(String time) {
    return 'Última lectura: $time';
  }

  @override
  String get connectedAppsReading => 'Leyendo tus datos…';

  @override
  String connectedAppsWriteWorkouts(String health) {
    return 'Guardar mis entrenamientos de FITRIX en $health';
  }

  @override
  String get connectedAppsDisconnect => 'Desconectar';

  @override
  String get connectedAppsDisconnectedIos =>
      'Para quitar el acceso, abre Ajustes › Salud › Acceso a datos y dispositivos › FITRIX.';

  @override
  String get connectedAppsDisconnectedAndroid =>
      'Para quitar el acceso, abre Health Connect › Permisos de aplicaciones › FITRIX.';

  @override
  String get connectedAppsDeniedIos =>
      'No se concedió el acceso. Puedes cambiarlo en la app Salud.';

  @override
  String get connectedAppsDeniedAndroid =>
      'No se concedió el acceso. Puedes cambiarlo en Health Connect.';

  @override
  String get connectedAppsInstall => 'Instalar';

  @override
  String get connectedAppsUpdate => 'Actualizar';

  @override
  String get connectedAppsNotInstalled =>
      'Health Connect no está instalado en este teléfono.';

  @override
  String get connectedAppsNeedsUpdate =>
      'Health Connect necesita una actualización.';

  @override
  String get connectedAppsUnavailable => 'No disponible en este dispositivo.';

  @override
  String get connectedAppsPrivacy =>
      'Los datos de salud se quedan en este teléfono; en tu cuenta solo se guardan los entrenamientos que importas y tu chequeo.';

  @override
  String connectedAppsDeleteHelp(String health) {
    return 'Borrar un entrenamiento en FITRIX no lo borra de $health.';
  }

  @override
  String get nutritionToday => 'Hoy';

  @override
  String nutritionDateTraining(String date) {
    return '$date · día de entrenamiento';
  }

  @override
  String get nutritionCompleteTitle => 'Completa tu perfil';

  @override
  String get nutritionCompleteBody =>
      'Añade tu sexo, edad, peso y altura para ver tus objetivos diarios.';

  @override
  String get nutritionLeftToday => 'Te queda hoy';

  @override
  String get nutritionBurned => 'Quemadas entrenando';

  @override
  String nutritionBurnedValue(String kcal) {
    return '≈ +$kcal kcal';
  }

  @override
  String get nutritionHowSet => 'Cómo se calcula ›';

  @override
  String get nutritionMacros => 'Macros';

  @override
  String nutritionProteinPerKg(String value) {
    return 'proteína $value g/kg';
  }

  @override
  String nutritionGramsOf(String eaten, String target) {
    return '$eaten / $target g';
  }

  @override
  String nutritionWaterTitle(String drunk, String target) {
    return 'Agua · $drunk de $target L';
  }

  @override
  String nutritionWaterNoTarget(String drunk) {
    return 'Agua · $drunk L';
  }

  @override
  String get nutritionWaterWorkout => '+0,5 L por el entrenamiento de hoy';

  @override
  String nutritionStepsBonus(String kcal, String steps) {
    return '+$kcal kcal por los pasos de hoy (pasos: $steps)';
  }

  @override
  String nutritionAddMl(String ml) {
    return '+$ml ml';
  }

  @override
  String get nutritionMeals => 'Comidas';

  @override
  String nutritionMealsLogged(String n) {
    return '$n de 4 registradas';
  }

  @override
  String get nutritionAdd => 'Añadir';

  @override
  String get nutritionLowToday => 'Bajo hoy';

  @override
  String nutritionAllMicros(String n) {
    return 'Todos $n ›';
  }

  @override
  String get nutritionDinnerIdea => 'Idea para la cena';

  @override
  String nutritionIdeaMessage(
      String gap, String food, String portion, String protein) {
    return 'Te faltan $gap g de proteína. $food ($portion) aporta unos $protein g.';
  }

  @override
  String get nutritionAddToDinner => 'Añadir a la cena';

  @override
  String get nutritionOtherIdea => 'Otra idea';

  @override
  String get nutritionRemove => 'Quitar';

  @override
  String get nutritionSearch => 'Buscar alimentos';

  @override
  String get nutritionFood => 'Alimento';

  @override
  String nutritionGrams(String grams) {
    return '$grams g';
  }

  @override
  String nutritionAddToSlot(String slot) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Añadir al desayuno',
        'lunch': 'Añadir al almuerzo',
        'dinner': 'Añadir a la cena',
        'snack': 'Añadir a la merienda',
        'other': 'Añadir a la cena',
      },
    );
    return '$_temp0';
  }

  @override
  String nutritionAddToSlotKcal(String slot, String kcal) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': 'Añadir al desayuno · $kcal kcal',
        'lunch': 'Añadir al almuerzo · $kcal kcal',
        'dinner': 'Añadir a la cena · $kcal kcal',
        'snack': 'Añadir a la merienda · $kcal kcal',
        'other': 'Añadir a la cena · $kcal kcal',
      },
    );
    return '$_temp0';
  }

  @override
  String nutritionAddedTo(String name, String slot) {
    String _temp0 = intl.Intl.selectLogic(
      slot,
      {
        'breakfast': '$name añadido al desayuno',
        'lunch': '$name añadido al almuerzo',
        'dinner': '$name añadido a la cena',
        'snack': '$name añadido a la merienda',
        'other': '$name añadido',
      },
    );
    return '$_temp0';
  }

  @override
  String get nutritionResults => 'Resultados';

  @override
  String nutritionResultsCount(String n) {
    return '$n alimentos · por porción';
  }

  @override
  String get nutritionNoResults =>
      'No se encontró nada. Prueba con otro nombre.';

  @override
  String get nutritionRecent => 'Recientes';

  @override
  String get nutritionRecentNote => 'lo comiste esta semana';

  @override
  String nutritionPortionLine(String portion, String kcal, String protein) {
    return '$portion · $kcal kcal · P $protein g';
  }

  @override
  String get nutritionCantFind => '¿No lo encuentras?';

  @override
  String get nutritionCantFindBody => 'Pídele a Felix que lo estime';

  @override
  String get foodBaseError => 'No se pudo cargar la base de alimentos.';

  @override
  String get foodNotFound => 'Este alimento no está en la base.';

  @override
  String get foodCatAll => 'Todos';

  @override
  String get foodCatUzbek => 'Platos uzbekos';

  @override
  String get foodCatMeatFish => 'Carne y pescado';

  @override
  String get foodCatDairy => 'Lácteos';

  @override
  String get foodCatFruit => 'Fruta';

  @override
  String get foodCatVeg => 'Verduras';

  @override
  String get foodCatGrains => 'Cereales';

  @override
  String get foodCatBread => 'Pan';

  @override
  String get foodCatDrinks => 'Bebidas';

  @override
  String get foodCatOther => 'Otros';

  @override
  String get foodRecipeEstimate => 'Estimación por receta';

  @override
  String foodPer100(String kcal) {
    return '$kcal kcal / 100 g';
  }

  @override
  String get foodPortion => 'Porción';

  @override
  String get foodKcal => 'kcal';

  @override
  String get foodFitsDay => '¿Encaja en tu día?';

  @override
  String foodKcalLeftAfter(String kcal) {
    return 'después te quedan $kcal kcal';
  }

  @override
  String foodKcalOver(String kcal) {
    return '$kcal kcal de más';
  }

  @override
  String foodEaten(String kcal) {
    return 'Comido $kcal';
  }

  @override
  String foodPlus(String name, String kcal) {
    return '+ $name $kcal';
  }

  @override
  String foodTarget(String kcal) {
    return 'Objetivo $kcal';
  }

  @override
  String foodFatWould(String fat, String target) {
    return 'La grasa llegaría a $fat de $target g.';
  }

  @override
  String foodProteinBehind(String g) {
    return 'Aún te faltarán $g g de proteína.';
  }

  @override
  String get foodRichIn => 'Rico en';

  @override
  String get foodPctOfTarget => '% de tu objetivo diario';

  @override
  String get micrTitle => 'Micronutrientes';

  @override
  String micrTargetsFor(String who, String age) {
    return 'Objetivos para $who, $age · NASEM';
  }

  @override
  String get micrMen => 'hombres';

  @override
  String get micrWomen => 'mujeres';

  @override
  String get micrToday => 'Hoy';

  @override
  String get micr7Days => '7 días';

  @override
  String get micr30Days => '30 días';

  @override
  String get micrAthlete => 'Esenciales del deportista';

  @override
  String get micrVitamins => 'Vitaminas';

  @override
  String get micrMinerals => 'Minerales';

  @override
  String micrAll(String n) {
    return 'Todos $n';
  }

  @override
  String get micrEmpty => 'Registra comidas para ver tus micronutrientes.';

  @override
  String micrAverage(String n) {
    return 'Media de $n días con registros';
  }

  @override
  String get micrLow => 'Bajo';

  @override
  String get micrOk => 'OK';

  @override
  String get micrHigh => 'Alto';

  @override
  String get micrVitDTitle => 'La vitamina D está baja toda la semana';

  @override
  String get micrVitDBody =>
      'El pescado azul, los huevos y los lácteos enriquecidos ayudan un poco. Pregunta a tu médico por un suplemento de D3.';

  @override
  String get micrInSeason => 'De temporada ahora';

  @override
  String micrUzbekistanMonth(String month) {
    return 'Uzbekistán · $month';
  }

  @override
  String get microVitD => 'Vitamina D';

  @override
  String get microCalcium => 'Calcio';

  @override
  String get microMagnesium => 'Magnesio';

  @override
  String get microIron => 'Hierro';

  @override
  String get microZinc => 'Zinc';

  @override
  String get microPotassium => 'Potasio';

  @override
  String get microSodium => 'Sodio';

  @override
  String get microB12 => 'Vitamina B12';

  @override
  String get microSelenium => 'Selenio';

  @override
  String get microVitE => 'Vitamina E';

  @override
  String get microVitC => 'Vitamina C';

  @override
  String get microVitA => 'Vitamina A';

  @override
  String get microHintVitD => 'Pescado azul, huevos, sol';

  @override
  String get microHintCalcium => 'Lácteos, sésamo, verduras de hoja';

  @override
  String get microHintMagnesium => 'Frutos secos, trigo sarraceno, legumbres';

  @override
  String get microHintIron => 'Carne, hígado, lentejas';

  @override
  String get microHintZinc => 'Ternera, cordero, pipas de calabaza';

  @override
  String get microHintPotassium => 'Patatas, plátanos, legumbres';

  @override
  String get microHintSodium => 'Pan, queso salado, caldos';

  @override
  String get microHintB12 => 'Ternera, huevos, lácteos';

  @override
  String get microHintSelenium => 'Pescado, huevos, carne';

  @override
  String get microHintVitE => 'Frutos secos, semillas, aceite vegetal';

  @override
  String get microHintVitC => 'Pimientos, cítricos, granada';

  @override
  String get microHintVitA => 'Zanahoria, calabaza, espinacas';

  @override
  String get targetsTitle => 'Tus objetivos';

  @override
  String get targetsSubtitle =>
      'Según tu perfil y las últimas 4 semanas de entrenamiento';

  @override
  String get targetsGoal => 'Objetivo';

  @override
  String get targetsLoseFat => 'Perder grasa';

  @override
  String get targetsMaintain => 'Mantener';

  @override
  String get targetsLeanBulk => 'Volumen limpio';

  @override
  String get targetsBmr => 'Metabolismo basal';

  @override
  String targetsBmrFormula(String weight, String height, String age) {
    return 'Mifflin-St Jeor · $weight kg, $height cm, $age años';
  }

  @override
  String targetsActivity(String factor) {
    return '× $factor actividad';
  }

  @override
  String targetsHours(String hours) {
    return '$hours h de entrenamiento a la semana en FITRIX';
  }

  @override
  String targetsHoursEstimated(String hours) {
    return 'Estimado $hours h a la semana: sin entrenos en 4 semanas';
  }

  @override
  String get targetsAdjLose => '−15% para perder grasa';

  @override
  String get targetsAdjMaintain => 'Mantener el peso';

  @override
  String get targetsAdjBulk => '+10% volumen limpio';

  @override
  String get targetsDaily => 'Objetivo diario';

  @override
  String targetsProteinG(String g) {
    return 'Proteína · $g g';
  }

  @override
  String targetsFatG(String g) {
    return 'Grasa · $g g';
  }

  @override
  String targetsCarbsG(String g) {
    return 'Carbohidratos · $g g';
  }

  @override
  String targetsPerKg(String value) {
    return '$value g por kg de peso';
  }

  @override
  String targetsFatPerKg(String value, String pct) {
    return '$value g por kg, cerca del $pct% de las kcal';
  }

  @override
  String get targetsCarbsNote => 'El resto de las calorías';

  @override
  String get targetsAuto => 'auto';

  @override
  String get targetsSave => 'Guardar objetivos';

  @override
  String get progressOverall => 'General';

  @override
  String get progressEmpty => 'Registra un entrenamiento para ver tu carga';

  @override
  String get progressLoadThisWeek => 'Carga de esta semana';

  @override
  String get progressLoadNote => 'RPE de sesión × min';

  @override
  String get progressAu => 'UA';

  @override
  String progressPercentOfUsual(int percent) {
    return '$percent% de lo habitual';
  }

  @override
  String get progressFitness => 'Forma física';

  @override
  String get progressFatigue => 'Fatiga';

  @override
  String get progressForm => 'Frescura';

  @override
  String get progress42Day => 'carga de 42 días';

  @override
  String get progress7Day => 'carga de 7 días';

  @override
  String get progressEstimated =>
      'Estimado: algunas sesiones usan un esfuerzo de 6 por defecto';

  @override
  String get progressFormFresh => 'Fresco';

  @override
  String get progressFormNeutral => 'Neutral';

  @override
  String get progressFormTired => 'Cansado';

  @override
  String get progressRecords => 'Récords';

  @override
  String get progressRecordsThisWeek => 'esta semana';

  @override
  String get progressBalance => 'Equilibrio de carga';

  @override
  String get progressBandLow => 'Baja';

  @override
  String get progressBandSweet => 'Punto ideal';

  @override
  String get progressBandRisky => 'Riesgo';

  @override
  String get progressBalanceLow => 'Muy poca';

  @override
  String get progressBalanceSweet => 'Punto ideal 0,8–1,3';

  @override
  String get progressBalanceRisky => 'Riesgo';

  @override
  String get progressFelixInsight => 'Consejo de Felix';

  @override
  String get progressInsightLow =>
      'Tu carga reciente está por debajo de lo habitual. Añade una sesión esta semana para volver por encima de 0,8.';

  @override
  String get progressInsightSweet =>
      'Tu carga está en el punto ideal. Mantén el ritmo y sube peso donde las series sean fáciles.';

  @override
  String get progressInsightRisky =>
      'Tu carga subió por encima de lo habitual. Haz las próximas sesiones más suaves y duerme bien.';

  @override
  String get progressLiftsE1rm => 'Levantamientos · e1RM';

  @override
  String get progressBodyWeight => 'Peso corporal';

  @override
  String get loadTitle => 'Carga de entrenamiento';

  @override
  String loadSubtitle(String sport) {
    return '$sport · RPE de sesión × minutos';
  }

  @override
  String get loadAllSports => 'Todos los deportes';

  @override
  String loadWeeks(int count) {
    return '$count semanas';
  }

  @override
  String get loadFitnessExplain =>
      'Tu carga media de 42 días. Sube despacio cuando entrenas con constancia.';

  @override
  String get loadFatigueExplain =>
      'Tu carga de 7 días. Salta tras semanas duras y baja rápido con descanso.';

  @override
  String get loadFormExplain =>
      'Forma menos fatiga. Positivo significa fresco: carrera, prueba o récord.';

  @override
  String get loadByWeek => 'Por semana';

  @override
  String loadAvg(String value) {
    return 'UA · media $value';
  }

  @override
  String get loadThisWeek => 'Esta';

  @override
  String get loadNextWeek => 'Próxima semana';

  @override
  String loadAim(String value) {
    return 'Apunta a unas $value UA, cerca de tu media semanal reciente.';
  }

  @override
  String get loadChartEmpty => 'Aún hay poca carga';

  @override
  String get recordsTitle => 'Récords';

  @override
  String recordsSummary(int count, int sports) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count récords personales',
      one: '$count récord personal',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sports,
      locale: localeName,
      other: '$sports deportes',
      one: '$sports deporte',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get recordsAll => 'Todos';

  @override
  String get recordsThisMonth => 'Este mes';

  @override
  String get recordsBestStreak => 'Mejor racha';

  @override
  String recordsWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '$count semana',
    );
    return '$_temp0';
  }

  @override
  String recordsMonthCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count récords',
      one: '$count récord',
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
      other: '$count repeticiones',
      one: '$count repetición',
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
      other: '+$count repeticiones',
      one: '+$count repetición',
    );
    return '$_temp0';
  }

  @override
  String get recordsToday => 'hoy';

  @override
  String get recordsYesterday => 'ayer';

  @override
  String recordsDaysAgo(int count) {
    return 'hace $count días';
  }

  @override
  String get recordsEmpty =>
      'Aún no hay récords. Supera tu mejor marca en un entrenamiento y aparecerá aquí.';

  @override
  String get liftTitle => 'Levantamientos';

  @override
  String get liftEstimated => '1RM estimado · Epley';

  @override
  String liftSince(String date, String kg, String reps, String since) {
    return 'desde $since · mejor serie $kg × $reps el $date';
  }

  @override
  String liftBestSet(String date, String kg, String reps) {
    return 'mejor serie $kg × $reps el $date';
  }

  @override
  String get liftChartE1rm => 'e1RM';

  @override
  String get liftChartTop => 'Carga de la mejor serie';

  @override
  String get liftStrengthLevel => 'Nivel de fuerza';

  @override
  String get liftLevelBeginner => 'Principiante';

  @override
  String get liftLevelNovice => 'Novato';

  @override
  String get liftLevelIntermediate => 'Intermedio';

  @override
  String get liftLevelAdvanced => 'Avanzado';

  @override
  String get liftLevelElite => 'Élite';

  @override
  String liftRatio(String ratio) {
    return '$ratio × peso corporal';
  }

  @override
  String liftNextBand(String kg, String level, String ratio) {
    return '$level a $ratio × · $kg';
  }

  @override
  String get liftTopBand => 'Nivel máximo alcanzado';

  @override
  String get liftNeedWeight =>
      'Registra tu peso corporal para ver tu nivel de fuerza.';

  @override
  String get liftNextSession => 'Próxima sesión';

  @override
  String get liftReserve => '2 repeticiones en reserva';

  @override
  String get liftColSet => 'Serie';

  @override
  String get liftCol1rm => '%1RM';

  @override
  String get liftColLoad => 'Carga';

  @override
  String get liftColReps => 'Reps';

  @override
  String get liftTopSet => 'Serie top';

  @override
  String get liftBackOff => 'Descarga';

  @override
  String get liftVolume => 'Volumen';

  @override
  String get liftFelix => 'Felix';

  @override
  String liftPaceUp(String kg) {
    return 'Constante: $kg a la semana.';
  }

  @override
  String liftPaceTo(String date, String kg, String ratio) {
    return 'Constante: $kg a la semana. A este ritmo llegas a $ratio × tu peso corporal hacia $date.';
  }

  @override
  String get liftPaceFlat =>
      'Tu e1RM lleva un tiempo estancado. Una semana ligera y vuelve a apretar.';

  @override
  String get liftNone =>
      'Termina un entrenamiento con un ejercicio con peso para ver tus levantamientos aquí.';

  @override
  String bodyPerWeek(String value) {
    return '$value / sem.';
  }

  @override
  String bodyTrendLine(String goal, int weeks) {
    return 'Tendencia de $weeks semanas · objetivo: $goal';
  }

  @override
  String bodyTrendNone(String goal) {
    return 'Aún hay pocos pesajes para una tendencia · objetivo: $goal';
  }

  @override
  String bodyGoalLoseFat(String unit) {
    return 'perder grasa −0,3 a −0,7 $unit / sem.';
  }

  @override
  String bodyGoalMaintain(String unit) {
    return 'mantener ±0,2 $unit / sem.';
  }

  @override
  String bodyGoalLeanBulk(String unit) {
    return 'volumen limpio +0,2 a +0,4 $unit / sem.';
  }

  @override
  String get bodyGoalNameLoseFat => 'pérdida de grasa';

  @override
  String get bodyGoalNameMaintain => 'mantenimiento';

  @override
  String get bodyGoalNameLeanBulk => 'volumen limpio';

  @override
  String bodyOffTrack(String goal) {
    return 'Fuera de rumbo: $goal';
  }

  @override
  String bodyAdd(int kcal) {
    return 'Tu tendencia está por debajo del objetivo. Añade unas $kcal kcal al día, sobre todo carbohidratos alrededor del entrenamiento.';
  }

  @override
  String bodyCut(int kcal) {
    return 'Tu tendencia está por encima del objetivo. Quita unas $kcal kcal al día, sobre todo de grasas y bebidas azucaradas.';
  }

  @override
  String get bodyUpdateTargets => 'Actualizar mis objetivos';

  @override
  String get bodyRange8 => '8 semanas';

  @override
  String get bodyRange26 => '6 meses';

  @override
  String get bodyRange52 => 'Año';

  @override
  String get bodyLegendTrend => 'Tendencia';

  @override
  String get bodyLegendWeighIns => 'Pesajes';

  @override
  String get bodyLegendGoal => 'Rango objetivo';

  @override
  String get bodyToday => 'Hoy';

  @override
  String get bodyWeighIns => 'Pesajes';

  @override
  String get bodyWeighInsNote => 'por la mañana, tras ir al baño';

  @override
  String get bodyLog => 'Registrar el peso de hoy';

  @override
  String get bodySheetTitle => 'Peso de hoy';

  @override
  String get bodySave => 'Guardar';

  @override
  String get bodyWeightRange => 'Introduce un peso entre 20 y 400 kg.';

  @override
  String get bodyEmpty => 'Registra tu peso para ver tu tendencia.';

  @override
  String get programsTitle => 'Programas';

  @override
  String get programsEntrySub => 'Planes listos para las próximas semanas';

  @override
  String get programsActiveEyebrow => 'Programa activo';

  @override
  String programsWeekOf(int w, int n) {
    return 'Semana $w de $n';
  }

  @override
  String programsNext(String session, String day, String duration) {
    return 'Siguiente: $session · $day · $duration';
  }

  @override
  String get programsNoneLeft => 'No quedan sesiones en este programa';

  @override
  String programsDoneOf(int done, int total) {
    return '$done de $total sesiones hechas';
  }

  @override
  String get programsOpen => 'Abrir';

  @override
  String get programsPickedEyebrow => 'Elegido para ti';

  @override
  String programsPickedText(String name, int perWeek, String level) {
    return '$name · $perWeek días a la semana · $level. Encaja con tu objetivo y experiencia.';
  }

  @override
  String get programsFelixPick => 'Elección de Felix';

  @override
  String get programsFilterAll => 'Todos';

  @override
  String get programsGoalMuscle => 'Músculo';

  @override
  String get programsGoalStrength => 'Fuerza';

  @override
  String get programsGoalFatLoss => 'Perder grasa';

  @override
  String get programsLevelBeginner => 'Principiante';

  @override
  String get programsLevelIntermediate => 'Intermedio';

  @override
  String get programsLevelAdvanced => 'Avanzado';

  @override
  String get programsAtHome => 'En casa';

  @override
  String get programsDaysAWeek => 'Días a la semana';

  @override
  String get programsAny => 'Cualquiera';

  @override
  String programsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n programas',
      one: '$n programa',
    );
    return '$_temp0';
  }

  @override
  String programsPerWeek(int n) {
    return '$n× / semana';
  }

  @override
  String programsWeeksMin(int weeks, int min) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas',
      one: '$weeks semana',
    );
    return '$_temp0 · $min min';
  }

  @override
  String get programsDetails => 'Detalles';

  @override
  String get programsEmptyFilter =>
      'Ningún programa coincide con estos filtros.';

  @override
  String get programTitle => 'Programa';

  @override
  String get programNotFound => 'Este programa no está disponible.';

  @override
  String get programLength => 'Duración';

  @override
  String get programPerWeekLabel => 'Por semana';

  @override
  String get programSessionLabel => 'Sesión';

  @override
  String programWeeksShort(int n) {
    return '$n sem';
  }

  @override
  String get programYourWeek => 'Tu semana';

  @override
  String programClashes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n choques',
      one: '$n choque',
    );
    return '$_temp0';
  }

  @override
  String get programRest => 'Descanso';

  @override
  String programWorkoutsCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n entrenamientos',
      one: '$n entrenamiento',
    );
    return '$_temp0';
  }

  @override
  String programRir(int n) {
    return 'RIR $n';
  }

  @override
  String get programHowYouProgress => 'Cómo progresas';

  @override
  String get programFelixEyebrow => 'Felix lo ajustó para ti';

  @override
  String programFelixText(String days, String what) {
    return 'Los días de entreno evitan $days y los días justo antes y después por: $what. Puedes cambiar los días al empezar.';
  }

  @override
  String get programAskFelix => 'Preguntar a Felix';

  @override
  String programAskFelixDraft(String name) {
    return '¿Es $name un buen programa para mí? Compáralo con mi semana.';
  }

  @override
  String get programStart => 'Empezar programa';

  @override
  String programStartTitle(String name) {
    return 'Empezar $name';
  }

  @override
  String programStartSub(int weeks, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other: '$weeks semanas',
      one: '$weeks semana',
    );
    return '$_temp0 · termina el $date';
  }

  @override
  String get programStartDate => 'Inicio';

  @override
  String get programToday => 'Hoy';

  @override
  String get programPickDate => 'Elegir fecha';

  @override
  String get programTrainingDays => 'Días de entreno';

  @override
  String programDaysPicked(int n, int total) {
    return '$n de $total elegidos';
  }

  @override
  String programClashTitle(String day, String title) {
    return '$day: $title';
  }

  @override
  String get programClashHit =>
      'Entrenar ese día suma dos sesiones duras. Elige otro día.';

  @override
  String get programClashNear =>
      'Un día del programa está justo al lado. Cuida las piernas antes y después.';

  @override
  String get programClashAvoid =>
      'Los días del programa lo evitan para que te recuperes antes y después.';

  @override
  String get programStartWeights => 'Pesos iniciales';

  @override
  String get programFromRecords => 'de tus récords';

  @override
  String get programReplacePlan => 'Reemplazar mi plan semanal';

  @override
  String get programReplaceSub =>
      'Correr y fútbol se quedan, los días de gimnasio cambian';

  @override
  String programStartOn(String date) {
    return 'Empezar el $date';
  }

  @override
  String get programReplacesActive => 'Esto reemplaza tu programa activo.';

  @override
  String programProgressSub(int w, int n, String date) {
    return 'Semana $w de $n · empezó el $date';
  }

  @override
  String programDeloadNote(int w) {
    return 'La semana $w es de descarga: haz más o menos la mitad de tus series habituales.';
  }

  @override
  String get programTileSessions => 'Sesiones';

  @override
  String get programTileOnTime => 'A tiempo';

  @override
  String get programTileRecords => 'Récords';

  @override
  String get programThisWeek => 'Esta semana';

  @override
  String programWeekDone(int done, int total) {
    return '$done de $total hechas';
  }

  @override
  String get programNoSessionsWeek =>
      'No hay sesiones del programa esta semana.';

  @override
  String get programPlanned => 'planificada';

  @override
  String get programMainLifts => 'Levantamientos principales';

  @override
  String get programTopSetKg => 'serie top, kg';

  @override
  String get programColLift => 'Ejercicio';

  @override
  String get programColStart => 'Inicio';

  @override
  String get programColNow => 'Ahora';

  @override
  String get programColGoal => 'Meta';

  @override
  String get programNextIncrease => 'Próximo aumento';

  @override
  String programNextIncreaseText(int sets, int reps, String lift, String kg) {
    return 'Hiciste $sets × $reps en $lift dos veces seguidas. Próxima sesión: $kg kg.';
  }

  @override
  String get programNoActive => 'Sin programa activo';

  @override
  String get programNoActiveBody =>
      'Elige un programa para tener un plan de las próximas semanas.';

  @override
  String get programBrowse => 'Ver programas';

  @override
  String get programEnd => 'Terminar programa';

  @override
  String get programEndTitle => '¿Terminar este programa?';

  @override
  String get programEndBody =>
      'Tus entrenamientos y récords se quedan. Las sesiones restantes salen de tu plan.';

  @override
  String programKgReps(String kg, int reps) {
    return '$kg kg × $reps';
  }

  @override
  String get coachAskFelix => 'Preguntar a Felix';

  @override
  String gymAskFirstDraft(String sport) {
    return 'Voy a hacer mi primer entrenamiento de $sport. ¿En qué debo fijarme?';
  }

  @override
  String gymAskBackDraft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días',
      one: '$days día',
    );
    return 'Mi último entrenamiento fue hace $_temp0. ¿Cómo vuelvo a entrenar?';
  }

  @override
  String recoveryAskDraft(
      int score, String label, String sleep, String soreness) {
    return 'Mi preparación hoy es $score% ($label). Sueño $sleep, agujetas: $soreness. ¿Qué tan duro debería entrenar hoy?';
  }

  @override
  String planAskDraft(String a, String aDay, String b, String bDay) {
    return '$a ($aDay) y $b ($bDay) son duras. ¿Cómo organizo mi semana?';
  }

  @override
  String progressAskDraft(String week, String balance, String band) {
    return 'Mi carga de entrenamiento esta semana es $week y mi equilibrio de carga es $balance ($band). ¿Qué hago la próxima semana?';
  }

  @override
  String liftAskDraft(String lift, String e1rm) {
    return 'Mi e1RM en $lift es $e1rm. ¿Cómo sigo progresando?';
  }

  @override
  String bodyAskDraft(String weight, String trend, String goal) {
    return 'Mi peso es $weight y cambia $trend por semana. Mi objetivo: $goal. ¿Cómo cambio lo que como?';
  }

  @override
  String nutritionAskDraft(String kcal, String protein) {
    return 'Me quedan $kcal kcal y $protein g de proteína hoy. ¿Qué ceno?';
  }

  @override
  String get nutritionCantFindDraft => 'Estima las calorías de: ';

  @override
  String get planEmptyBodyNextWeek =>
      'Organiza tus entrenamientos de gimnasio de la próxima semana con un toque.';

  @override
  String programsPickedGoalText(String name, int perWeek, String level) {
    return '$name · $perWeek días a la semana · $level. Encaja con tu objetivo.';
  }

  @override
  String programsPickedLevelText(String name, int perWeek, String level) {
    return '$name · $perWeek días a la semana · $level. Encaja con tu experiencia.';
  }

  @override
  String get programsStartEyebrow => 'Para empezar';

  @override
  String programsStartText(String name, int perWeek, String level) {
    return '$name · $perWeek días a la semana · $level. Añade tu objetivo y experiencia en Sobre mí para una elección más precisa.';
  }

  @override
  String get programDetailsTooltip => 'Detalles del programa';

  @override
  String nutritionKcalOver(String kcal) {
    return '$kcal kcal de más';
  }

  @override
  String get homeDoneForToday => 'Listo por hoy';

  @override
  String homeNextSession(String day, String title) {
    return 'Siguiente: $day · $title';
  }

  @override
  String get homeNothingNext => 'No hay nada más planificado';

  @override
  String chatFoodLogTo(String slot) {
    return 'Registrar en: $slot';
  }

  @override
  String chatFoodItemMeta(String grams, String kcal) {
    return '$grams g · $kcal kcal';
  }

  @override
  String chatFoodEstimateName(String name) {
    return '≈ $name';
  }

  @override
  String get chatFoodEstimateNote => '≈ estimación de Felix';

  @override
  String chatFoodTotal(String kcal, String protein) {
    return '$kcal kcal · $protein g de proteína';
  }

  @override
  String chatFoodAdd(String kcal) {
    return 'Añadir a Mi nutrición · $kcal kcal';
  }

  @override
  String chatFoodAdded(String slot) {
    return 'Añadido a: $slot';
  }

  @override
  String get chatActionWeightSetFirst => 'Primero indica tu peso';

  @override
  String get chatActionSetWeight => 'Indicar peso';

  @override
  String get gymDiscardAndStart => 'Descartar y empezar';

  @override
  String chatActionWeightSet(String to) {
    return 'Actualizar peso a $to kg';
  }

  @override
  String get felixPlanBadge => 'Plan de Felix';

  @override
  String felixPlanTitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrenamientos',
      one: '$count entrenamiento',
    );
    return '$_temp0';
  }

  @override
  String get felixPlanAddToWorkouts => 'Añadir a Mis entrenamientos';

  @override
  String get felixPlanAddToToday => 'Añadir al plan de hoy';

  @override
  String get felixPlansSection => 'De Felix';

  @override
  String felixChatTitle(String topic) {
    return 'Felix · $topic';
  }

  @override
  String get felixTopicNutrition => 'Nutrición';

  @override
  String get felixTopicRecovery => 'Recuperación';

  @override
  String get felixTopicApp => 'Asistente de la app';

  @override
  String get felixTopicSubGym => 'Fuerza, músculo, programas, técnica';

  @override
  String get felixTopicSubFitness => 'HIIT, peso corporal, movilidad, pruebas';

  @override
  String get felixTopicSubRunning => 'Ritmos, planes, carreras';

  @override
  String get felixTopicSubCycling => 'Potencia, FTP, subidas, rutas';

  @override
  String get felixTopicSubFootball =>
      'Forma para el partido, ejercicios, lesiones';

  @override
  String get felixTopicSubWinterSports =>
      'Esquí en Amirsoy y Chimgan, seguridad';

  @override
  String get felixTopicSubNutrition =>
      'Registro de comidas, macros, platos uzbekos';

  @override
  String get felixTopicSubRecovery => 'Sueño, agujetas, preparación, descargas';

  @override
  String get felixTopicSubApp => 'Cómo funciona FITRIX, planes, hábitos';

  @override
  String felixTopicGreeting(String topic) {
    return '¡Hola! Soy Felix. Hablemos de $topic.';
  }

  @override
  String get felixTopicGreetingHint =>
      'Pregunta lo que quieras o elige una pregunta abajo.';

  @override
  String get felixHubAiCoach => 'Entrenador de IA';

  @override
  String get felixHubIntro =>
      'Entrenamiento, recuperación y comida en un solo lugar. Escribe en English, Русский, O‘zbekcha o Español.';

  @override
  String felixHubToday(String title) {
    return 'Hoy: $title';
  }

  @override
  String get felixHubRest => 'Hoy es día de descanso';

  @override
  String get felixHubDone => 'La sesión de hoy está hecha';

  @override
  String felixHubNext(String sport, String weekday) {
    return '$sport el $weekday';
  }

  @override
  String get felixHubTopicsHeader => 'Habla con Felix sobre';

  @override
  String felixHubTopicsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count temas',
      one: '$count tema',
    );
    return '$_temp0';
  }

  @override
  String get felixHubRecent => 'Chats recientes';

  @override
  String get felixHubSeeAll => 'Ver todo';

  @override
  String get felixAllTopics => 'Todos los temas';

  @override
  String get felixSeesPlan => 'Ve tu plan, tu check-in y tus entrenamientos';

  @override
  String get felixSeesNutrition =>
      'Ve la comida de hoy, tus objetivos y tu peso';

  @override
  String get felixSeesRecovery =>
      'Ve tu check-in, tu sueño y tu carga de entrenamiento';

  @override
  String felixChipReadiness(int score) {
    return 'Recuperación $score%';
  }

  @override
  String felixChipToday(String title) {
    return 'Hoy: $title';
  }

  @override
  String get felixChipRest => 'Día de descanso';

  @override
  String felixChipLast(String name) {
    return 'Última: $name';
  }

  @override
  String felixChipKcal(String eaten, String target) {
    return '$eaten de $target kcal';
  }

  @override
  String felixChipProtein(String eaten) {
    return 'Proteína $eaten g';
  }

  @override
  String felixAskAbout(String topic) {
    return 'Pregunta a Felix sobre $topic';
  }

  @override
  String get felixAskAboutApp => 'Pregunta a Felix sobre FITRIX';

  @override
  String get felixPromptGym1 =>
      '¿Cómo rompo mi estancamiento en press de banca?';

  @override
  String get felixPromptGym2 => 'Hazme una rutina dividida de 3 días';

  @override
  String get felixPromptGym3 => 'Revisa las claves de mi técnica de sentadilla';

  @override
  String get felixPromptFitness1 => 'Un HIIT de 20 minutos para hoy';

  @override
  String get felixPromptFitness2 => 'Entrenamiento con peso corporal en casa';

  @override
  String get felixPromptFitness3 => 'Rutina de movilidad para caderas tensas';

  @override
  String get felixPromptRunning1 => '¿Cuál debería ser mi ritmo suave?';

  @override
  String get felixPromptRunning2 => 'Plan para mis primeros 10K';

  @override
  String get felixPromptRunning3 => 'Cómo evitar la periostitis tibial';

  @override
  String get felixPromptCycling1 => '¿Cómo mido mi FTP?';

  @override
  String get felixPromptCycling2 => 'Intervalos para subidas';

  @override
  String get felixPromptCycling3 => 'Qué comer en una salida de 3 horas';

  @override
  String get felixPromptFootball1 => 'Calentamiento antes de un partido';

  @override
  String get felixPromptFootball2 => 'Ejercicios de velocidad para esta semana';

  @override
  String get felixPromptFootball3 => '¿Piernas el día después de un partido?';

  @override
  String get felixPromptWinter1 =>
      'Preparar las piernas para la temporada de esquí';

  @override
  String get felixPromptWinter2 => 'Ejercicios para proteger las rodillas';

  @override
  String get felixPromptWinter3 => 'Cómo mantenerse caliente en la pista';

  @override
  String get felixPromptNutrition1 => '¿Qué debería comer hoy?';

  @override
  String get felixPromptNutrition2 => '¿Cuánta proteína necesito?';

  @override
  String get felixPromptNutrition3 => '¿Está bien el plov después de entrenar?';

  @override
  String get felixPromptRecovery1 => '¿Debería entrenar fuerte hoy?';

  @override
  String get felixPromptRecovery2 => 'Cómo dormir mejor';

  @override
  String get felixPromptRecovery3 => '¿Dónde encajan las piernas esta semana?';

  @override
  String get felixPromptApp1 => '¿Cómo uso el plan semanal?';

  @override
  String get felixPromptApp2 => '¿Cómo funciona el check-in?';

  @override
  String get runNameMorning => 'Carrera matutina';

  @override
  String get runNameAfternoon => 'Carrera de la tarde';

  @override
  String get runNameEvening => 'Carrera al anochecer';

  @override
  String get runNameNight => 'Carrera nocturna';

  @override
  String get runNotificationTitle => 'Grabando tu carrera';

  @override
  String get runNotificationText =>
      'FITRIX registra la distancia y el tiempo aunque la pantalla esté bloqueada.';

  @override
  String get runNotificationChannel => 'Grabación de carreras';

  @override
  String get rideNameMorning => 'Salida en bici matutina';

  @override
  String get rideNameAfternoon => 'Salida en bici de la tarde';

  @override
  String get rideNameEvening => 'Salida en bici al anochecer';

  @override
  String get rideNameNight => 'Salida en bici nocturna';

  @override
  String get skiDayName => 'Día de esquí';

  @override
  String get indoorRideName => 'Salida en interior';

  @override
  String get rideNotificationTitle => 'Grabando tu salida en bici';

  @override
  String get rideNotificationText =>
      'FITRIX registra la distancia y el tiempo aunque la pantalla esté bloqueada.';

  @override
  String get rideNotificationChannel => 'Grabación de salidas en bici';

  @override
  String get skiNotificationTitle => 'Grabando tu día de esquí';

  @override
  String get skiNotificationText =>
      'FITRIX registra la distancia y el tiempo aunque la pantalla esté bloqueada.';

  @override
  String get skiNotificationChannel => 'Grabación de días de esquí';

  @override
  String runVoiceHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count horas',
      one: '1 hora',
    );
    return '$_temp0';
  }

  @override
  String runVoiceMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutos',
      one: '1 minuto',
    );
    return '$_temp0';
  }

  @override
  String runVoiceSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count segundos',
      one: '1 segundo',
    );
    return '$_temp0';
  }

  @override
  String runVoicePace(String time) {
    return '$time por kilómetro';
  }

  @override
  String get runVoiceStart => 'Carrera iniciada.';

  @override
  String get runVoicePause => 'En pausa.';

  @override
  String get runVoiceResume => 'Seguimos.';

  @override
  String runVoiceKm(int km, String time, String lastPace, String avgPace) {
    return 'Kilómetro $km. Tiempo $time. Último kilómetro $lastPace. Ritmo medio $avgPace.';
  }

  @override
  String runVoiceFinish(String distance, String time, String avgPace) {
    return 'Carrera terminada. $distance kilómetros en $time. Ritmo medio $avgPace.';
  }

  @override
  String runVoiceFinishShort(String distance, String time) {
    return 'Carrera terminada. $distance kilómetros en $time.';
  }

  @override
  String get runUnfinishedTitle => 'Tienes una carrera sin terminar';

  @override
  String runUnfinishedBody(String next) {
    return 'Reanúdala o descártala y empieza «$next».';
  }

  @override
  String get runResume => 'Reanudar';

  @override
  String get runPause => 'Pausa';

  @override
  String get runDiscardTitle => '¿Descartar esta carrera?';

  @override
  String get runDiscardBody => 'Se perderán la distancia y la ruta.';

  @override
  String get runDiscardAction => 'Descartar';

  @override
  String get runDiscardRun => 'Descartar carrera';

  @override
  String get runHoldToFinish => 'Mantén para terminar';

  @override
  String get runLocationOff =>
      'La ubicación está desactivada para FITRIX. Permítela en Ajustes para registrar una carrera.';

  @override
  String get runLocationServiceOff =>
      'Los servicios de ubicación están desactivados. Actívalos en Ajustes para registrar una carrera.';

  @override
  String get runOpenSettings => 'Ajustes';

  @override
  String get runTime => 'Tiempo';

  @override
  String get runDistance => 'Distancia';

  @override
  String get runPace => 'Ritmo';

  @override
  String get runAvgPace => 'Ritmo medio';

  @override
  String get runUnitKm => 'km';

  @override
  String get runUnitPerKm => '/km';

  @override
  String get runPausedLabel => 'En pausa';

  @override
  String get runMovingTime => 'Tiempo en movimiento';

  @override
  String get runElevation => 'Desnivel positivo';

  @override
  String runElevationValue(String meters) {
    return '$meters m';
  }

  @override
  String runElapsedLine(String elapsed, String pauses) {
    return '$elapsed en total, $pauses';
  }

  @override
  String runPausesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pausas',
      one: '1 pausa',
      zero: 'sin pausas',
    );
    return '$_temp0';
  }

  @override
  String get runSplits => 'Parciales';

  @override
  String get runRpeTitle => '¿Qué tan duro se sintió?';

  @override
  String get runSave => 'Guardar';

  @override
  String get runDeleteRun => 'Eliminar carrera';

  @override
  String get runDeleteTitle => '¿Eliminar esta carrera?';

  @override
  String get runDeleteBody => 'Se quitará de tu historial.';

  @override
  String get runDeleteAction => 'Eliminar';

  @override
  String get runNoRoute => 'No se registró la ruta';

  @override
  String get runNotFound => 'Esta carrera ya no está aquí.';

  @override
  String get runStartRun => 'Empezar a correr';

  @override
  String get runThisWeek => 'Esta semana';

  @override
  String runWeekRuns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count carreras',
      one: '1 carrera',
    );
    return '$_temp0';
  }

  @override
  String get runHistory => 'Historial';

  @override
  String get runHistoryEmpty =>
      'Aún no hay carreras. Las que registres aparecerán aquí.';

  @override
  String get runWorkouts => 'Entrenamientos';

  @override
  String get runBarTitle => 'Carrera en curso';

  @override
  String get runBarReturn => 'Volver';

  @override
  String runUnfinishedLaunchTitle(String distance) {
    return 'Carrera sin terminar · $distance km';
  }

  @override
  String get runUnfinishedLaunchBody =>
      'Continúa donde lo dejaste, guarda lo registrado o descártala.';

  @override
  String get runFinishFailed =>
      'No se pudo terminar la carrera. Inténtalo de nuevo.';

  @override
  String get runGpsWaiting => 'Esperando GPS…';

  @override
  String get runGpsWeak => 'Señal GPS débil';

  @override
  String get runGpsReduced =>
      'Activa la Ubicación exacta para medir bien la distancia';

  @override
  String get footballLog => 'Registrar';

  @override
  String get footballLogTitle => 'Registrar fútbol';

  @override
  String get footballEditTitle => 'Editar registro';

  @override
  String get footballTypeMatch => 'Partido';

  @override
  String get footballTypeTraining => 'Entrenamiento';

  @override
  String get footballDate => 'Fecha';

  @override
  String get footballFormat => 'Formato';

  @override
  String get footballMinutes => 'Minutos';

  @override
  String get footballMinShort => 'min';

  @override
  String get footballPosition => 'Posición';

  @override
  String get footballPosGK => 'POR';

  @override
  String get footballPosCB => 'DFC';

  @override
  String get footballPosFB => 'LAT';

  @override
  String get footballPosCM => 'MC';

  @override
  String get footballPosWM => 'EXT';

  @override
  String get footballPosST => 'DEL';

  @override
  String get footballResult => 'Resultado';

  @override
  String get footballScoreFor => 'Nosotros';

  @override
  String get footballScoreAgainst => 'Rival';

  @override
  String get footballGoals => 'Tus goles';

  @override
  String get footballAssists => 'Tus asistencias';

  @override
  String get footballNote => 'Nota';

  @override
  String get footballSave => 'Guardar';

  @override
  String get footballDelete => 'Eliminar registro';

  @override
  String get footballDeleteTitle => '¿Eliminar este registro?';

  @override
  String get footballDeleteBody => 'Se quitará de tu historial.';

  @override
  String get footballDeleteAction => 'Eliminar';

  @override
  String get footballHistory => 'Historial';

  @override
  String get footballHistoryEmpty =>
      'Aún no hay registros. Registra uno después de jugar.';

  @override
  String get footballWorkouts => 'Entrenamientos';

  @override
  String healthFromSource(String source) {
    return 'de $source';
  }

  @override
  String healthInBedFromSource(String source) {
    return 'en la cama, de $source';
  }

  @override
  String get healthSectionTitle => 'Datos de salud';

  @override
  String get healthRestingHr => 'Frecuencia cardíaca en reposo';

  @override
  String get healthHrv => 'Variabilidad de la frecuencia cardíaca';

  @override
  String get healthSteps => 'Pasos';

  @override
  String healthRestingHrValue(int bpm) {
    return '$bpm lpm';
  }

  @override
  String healthRestingHrNormal(int bpm, int normal) {
    return '$bpm lpm · tu habitual $normal';
  }

  @override
  String healthHrvValue(int value, String kind) {
    return '$value ms $kind';
  }

  @override
  String healthHrvNormal(int value, String kind, int normal) {
    return '$value ms $kind · tu habitual $normal';
  }

  @override
  String healthStepsDailyAvg(int avg) {
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String avgString = avgNumberFormat.format(avg);

    return 'Media diaria: $avgString';
  }

  @override
  String healthStepsToday(int steps) {
    final intl.NumberFormat stepsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);

    return 'Pasos hoy: $stepsString';
  }

  @override
  String healthStepsTodayAvg(int steps, int avg) {
    final intl.NumberFormat stepsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String stepsString = stepsNumberFormat.format(steps);
    final intl.NumberFormat avgNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String avgString = avgNumberFormat.format(avg);

    return 'Pasos hoy: $stepsString · media de 7 días $avgString';
  }

  @override
  String get factorRestingHrHigh =>
      'Frecuencia en reposo por encima de lo normal';

  @override
  String get factorRestingHrNormal => 'Frecuencia en reposo normal';

  @override
  String get factorHrvLow => 'VFC por debajo de lo normal';

  @override
  String get factorHrvNormal => 'VFC normal';

  @override
  String get factorHrvHigh => 'VFC por encima de lo normal';

  @override
  String importedFromHealth(String health) {
    return 'De $health';
  }

  @override
  String importedAvgHr(int bpm) {
    return '$bpm lpm de media';
  }

  @override
  String get importedDeleteTitle => '¿Eliminar este entrenamiento?';

  @override
  String get importedDelete => 'Eliminar entrenamiento';

  @override
  String connectedAppsSummaryTitle(String health) {
    return 'De $health · últimos 7 días';
  }

  @override
  String get connectedAppsSummarySteps => 'Días con pasos';

  @override
  String get connectedAppsSummarySleep => 'Noches con sueño';

  @override
  String get connectedAppsSummaryRhr => 'Días con FC en reposo';

  @override
  String get connectedAppsSummaryHrv => 'Días con VFC';

  @override
  String connectedAppsSummaryWeight(String health) {
    return 'Pesajes de $health';
  }

  @override
  String connectedAppsSummaryImported(String health) {
    return 'Entrenamientos de $health';
  }

  @override
  String connectedAppsSummaryWritten(String health) {
    return 'Entrenamientos guardados en $health';
  }

  @override
  String get connectedAppsSummaryHintIos =>
      'Aún no hay datos de reloj: un reloj (Apple Watch, Garmin, WHOOP, Mi Band) añade sueño, pulso y entrenamientos.';

  @override
  String get connectedAppsSummaryHintAndroid =>
      'Aún no hay datos de reloj: un reloj (Garmin, WHOOP, Mi Band) añade sueño, pulso y entrenamientos.';

  @override
  String get rideVoiceStart => 'Recorrido en bici iniciado.';

  @override
  String rideVoiceDistance(
      String km, String time, String lastSpeed, String avgSpeed) {
    return '$km kilómetros. Tiempo $time. Últimos 5 kilómetros a $lastSpeed kilómetros por hora. Media $avgSpeed.';
  }

  @override
  String rideVoiceFinish(String distance, String time) {
    return 'Recorrido en bici terminado. $distance kilómetros en $time.';
  }

  @override
  String get skiVoiceStart => 'Día de esquí iniciado.';

  @override
  String skiVoiceDescent(
      int index, String distance, int vertical, String topSpeed) {
    return 'Descenso $index. Distancia $distance km, desnivel $vertical metros, velocidad máxima $topSpeed kilómetros por hora.';
  }

  @override
  String skiVoiceFinish(String distance, String time) {
    return 'Día de esquí terminado. $distance kilómetros de descensos en $time.';
  }

  @override
  String get activitySettingsTitle => 'Ajustes del entrenamiento';

  @override
  String get activitySettingsVoice => 'Voz';

  @override
  String get activitySettingsVoiceRun =>
      'Anuncia el inicio, cada kilómetro y el final.';

  @override
  String get activitySettingsVoiceRide =>
      'Anuncia el inicio, cada 5 km y el final.';

  @override
  String get activitySettingsVoiceSki =>
      'Anuncia el inicio, cada descenso y el final.';

  @override
  String get unitKmh => 'km/h';

  @override
  String get rideSpeed => 'Velocidad';

  @override
  String get rideAvgSpeed => 'Velocidad media';

  @override
  String get rideMaxSpeed => 'Velocidad máx.';

  @override
  String get rideAvgPower => 'Potencia media, W';

  @override
  String get skiStateDescending => 'Descenso';

  @override
  String get skiStateLift => 'En remonte';

  @override
  String get skiStateStopped => 'Parado';

  @override
  String get skiDescents => 'Descensos';

  @override
  String get skiVerticalDown => 'Desnivel bajado, m';

  @override
  String get skiTimeOnSlopes => 'Tiempo en pista';

  @override
  String get skiDistance => 'Distancia esquiada, km';

  @override
  String get skiAvgDescentSpeed => 'Velocidad media de descenso';

  @override
  String get skiLifts => 'Remontes';

  @override
  String skiDescentN(int n) {
    return 'Descenso $n';
  }

  @override
  String get skiDescentDuration => 'Duración';

  @override
  String get skiDescentVertical => 'Desnivel, m';

  @override
  String get rideElevationLoss => 'Desnivel negativo';

  @override
  String get cyclingStart => 'Empezar a pedalear';

  @override
  String get cyclingLog => 'Registrar salida en interior';

  @override
  String get cyclingUnitRides => 'Salidas';

  @override
  String get cyclingHistory => 'Historial';

  @override
  String get cyclingHistoryEmpty =>
      'Aún no hay salidas. Las que registres aparecerán aquí.';

  @override
  String get cyclingWorkouts => 'Entrenamientos';

  @override
  String get cyclingChoiceTitle => '¿Dónde pedaleas?';

  @override
  String get cyclingOutdoor => 'Al aire libre (GPS)';

  @override
  String get cyclingIndoor => 'En interior (registro)';

  @override
  String get cyclingIndoorTag => 'Interior';

  @override
  String get rideLogTitle => 'Registrar salida en interior';

  @override
  String get rideEditTitle => 'Editar registro';

  @override
  String get rideLogDistance => 'Distancia, km (opcional)';

  @override
  String get rideLogPower => 'Potencia media, W (opcional)';

  @override
  String get rideNote => 'Nota';

  @override
  String get skiStart => 'Empezar día de esquí';

  @override
  String get skiUnitDays => 'Días de esquí';

  @override
  String get skiHistory => 'Historial';

  @override
  String get skiHistoryEmpty =>
      'Aún no hay días de esquí. Los que registres aparecerán aquí.';

  @override
  String get skiWorkouts => 'Entrenamientos';

  @override
  String get skiUnitM => 'm';

  @override
  String get rideUnfinishedTitle => 'Tienes una salida sin terminar';

  @override
  String get skiUnfinishedTitle => 'Tienes un día de esquí sin terminar';

  @override
  String skiUnfinishedBody(String next) {
    return 'Reanúdalo o descártalo y empieza «$next».';
  }

  @override
  String get rideDiscardTitle => '¿Descartar esta salida?';

  @override
  String get skiDiscardTitle => '¿Descartar este día de esquí?';

  @override
  String get rideDeleteTitle => '¿Eliminar esta salida?';

  @override
  String get skiDeleteTitle => '¿Eliminar este día de esquí?';

  @override
  String get skiDeleteBody => 'Se quitará de tu historial.';

  @override
  String get rideBarTitle => 'Salida en curso';

  @override
  String get skiBarTitle => 'Día de esquí en curso';

  @override
  String get rideDiscardRun => 'Descartar salida';

  @override
  String get skiDiscardRun => 'Descartar día de esquí';

  @override
  String get rideDeleteRun => 'Eliminar salida';

  @override
  String get skiDeleteRun => 'Eliminar día de esquí';

  @override
  String rideUnfinishedLaunchTitle(String distance) {
    return 'Salida sin terminar · $distance km';
  }

  @override
  String skiUnfinishedLaunchTitle(String distance) {
    return 'Día de esquí sin terminar · $distance km';
  }

  @override
  String get rideLocationOff =>
      'La ubicación está desactivada para FITRIX. Permítela en Ajustes para registrar una salida.';

  @override
  String get skiLocationOff =>
      'La ubicación está desactivada para FITRIX. Permítela en Ajustes para registrar un día de esquí.';

  @override
  String get rideLocationServiceOff =>
      'Los servicios de ubicación están desactivados. Actívalos en Ajustes para registrar una salida.';

  @override
  String get skiLocationServiceOff =>
      'Los servicios de ubicación están desactivados. Actívalos en Ajustes para registrar un día de esquí.';

  @override
  String get rideFinishFailed =>
      'No se pudo terminar la salida. Inténtalo de nuevo.';

  @override
  String get skiFinishFailed =>
      'No se pudo terminar el día de esquí. Inténtalo de nuevo.';

  @override
  String get rideNotFound => 'Esta salida ya no está aquí.';

  @override
  String get skiNotFound => 'Este día de esquí ya no está aquí.';

  @override
  String get skiUnfinishedLaunchBody =>
      'Continúa donde lo dejaste, guarda lo registrado o descártalo.';
}
