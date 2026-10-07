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
}
