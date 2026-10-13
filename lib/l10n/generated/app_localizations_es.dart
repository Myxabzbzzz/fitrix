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
}
