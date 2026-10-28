import 'dart:ui';

import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/l10n/generated/app_localizations.dart';

/// The language the walk picks on the language screen (E2E_LANG, default ru,
/// the owner's language; long Russian strings also shake out overflow).
const lang = String.fromEnvironment('E2E_LANG', defaultValue: 'ru');
final AppLocalizations L = lookupAppLocalizations(const Locale(lang));
final String langLabel = AppConstants.languages[lang]!;
