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
  String shopOrderRejected(String message) {
    return 'Pedido rechazado: $message';
  }

  @override
  String get shopRetry => 'Reintentar';

  @override
  String get shopNoProducts => 'Aún no hay productos';
}
