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
<<<<<<< HEAD
<<<<<<< HEAD
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
  String progressSets(String count) {
    return '$count series';
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
=======
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
>>>>>>> t10
=======
  String get chatQuickPlanWeek => 'Planifica mi semana';

  @override
  String get chatQuickEatToday => '¿Qué debería comer hoy?';

  @override
  String get chatQuickTired => 'Hoy me siento cansado';
>>>>>>> t9
}
