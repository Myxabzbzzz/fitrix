import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';

/// Limits shared with the `profiles` table checks
/// (supabase/migrations/..._initial_schema.sql).
class ProfileLimits {
  ProfileLimits._();

  static const int nameMaxLength = 100;
  static const int ageMin = 5;
  static const int ageMax = 120;
  static const double weightMin = 20;
  static const double weightMax = 400;
  static const double heightMin = 80;
  static const double heightMax = 260;
}

/// Parses "72", "72.5" or "72,5". Null for anything else.
double? parseProfileNumber(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  if (value == null || !value.isFinite) return null;
  return value;
}

/// numeric(5,1): one decimal place.
double _oneDecimal(double value) => (value * 10).roundToDouble() / 10;

/// "72" for whole numbers, "72.5" otherwise; '' for null.
String formatProfileNumber(num? value) {
  if (value == null) return '';
  final rounded = _oneDecimal(value.toDouble());
  return rounded == rounded.truncateToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

/// Profile form validation. Each check returns an error message or null.
class ProfileValidator {
  ProfileValidator._();

  static String? name(String value) {
    final name = value.trim();
    if (name.isEmpty) return 'Enter your name';
    if (name.length > ProfileLimits.nameMaxLength) return 'Name is too long';
    return null;
  }

  static String? surname(String value) =>
      value.trim().length > ProfileLimits.nameMaxLength
          ? 'Surname is too long'
          : null;

  static String? age(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Enter your age';
    final age = int.tryParse(text);
    if (age == null) return 'Age must be a whole number';
    if (age < ProfileLimits.ageMin || age > ProfileLimits.ageMax) {
      return 'Age must be between ${ProfileLimits.ageMin} and ${ProfileLimits.ageMax}';
    }
    return null;
  }

  static String? weight(String value) => _measure(
        value,
        what: 'weight',
        min: ProfileLimits.weightMin,
        max: ProfileLimits.weightMax,
        unit: 'kg',
      );

  static String? height(String value) => _measure(
        value,
        what: 'height',
        min: ProfileLimits.heightMin,
        max: ProfileLimits.heightMax,
        unit: 'cm',
      );

  static String? _measure(
    String value, {
    required String what,
    required double min,
    required double max,
    required String unit,
  }) {
    final text = value.trim();
    if (text.isEmpty) return 'Enter your $what';
    final number = parseProfileNumber(text);
    if (number == null) return 'Enter your $what as a number';
    final rounded = _oneDecimal(number);
    if (rounded < min || rounded > max) {
      return '${what[0].toUpperCase()}${what.substring(1)} must be between '
          '${formatProfileNumber(min)} and ${formatProfileNumber(max)} $unit';
    }
    return null;
  }

  /// Field name ('name', 'surname', 'age', 'weight', 'height') → error.
  /// Empty when the profile is valid.
  static Map<String, String> validate(UserProfile profile) {
    final errors = <String, String?>{
      'name': name(profile.name),
      'surname': surname(profile.surname),
      'age': age(profile.age),
      'weight': weight(profile.weight),
      'height': height(profile.height),
    };
    errors.removeWhere((_, error) => error == null);
    return errors.cast<String, String>();
  }

  /// Trimmed, with numbers in a canonical form ("72,50" → "72.5").
  static UserProfile normalize(UserProfile profile) => UserProfile(
        name: profile.name.trim(),
        surname: profile.surname.trim(),
        age: profile.age.trim(),
        weight: _normalizeNumber(profile.weight),
        height: _normalizeNumber(profile.height),
      );

  static String _normalizeNumber(String text) {
    final number = parseProfileNumber(text);
    return number == null ? text.trim() : formatProfileNumber(number);
  }
}

/// One row of the `profiles` table.
class ProfileRow {
  const ProfileRow({
    required this.id,
    this.name = '',
    this.surname = '',
    this.age,
    this.weightKg,
    this.heightCm,
    this.language = 'en',
    this.onboardingComplete = false,
  });

  final String id;
  final String name;
  final String surname;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String language;
  final bool onboardingComplete;

  static const table = 'profiles';
  static const columns =
      'id, name, surname, age, weight_kg, height_cm, language, onboarding_complete';

  factory ProfileRow.fromJson(Map<String, dynamic> json) => ProfileRow(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        surname: (json['surname'] as String?) ?? '',
        age: (json['age'] as num?)?.toInt(),
        weightKg: _toDouble(json['weight_kg']),
        heightCm: _toDouble(json['height_cm']),
        language: (json['language'] as String?) ?? 'en',
        onboardingComplete: (json['onboarding_complete'] as bool?) ?? false,
      );

  /// Builds a row from what's stored on the device. Values the database
  /// would reject (e.g. typed before validation existed) become null rather
  /// than failing the whole upload.
  factory ProfileRow.fromLocal({
    required String id,
    required UserProfile profile,
    String? language,
    bool onboardingComplete = false,
  }) {
    final age = int.tryParse(profile.age.trim());
    final weight = parseProfileNumber(profile.weight);
    final height = parseProfileNumber(profile.height);
    return ProfileRow(
      id: id,
      name: _clip(profile.name.trim()),
      surname: _clip(profile.surname.trim()),
      age: age != null &&
              age >= ProfileLimits.ageMin &&
              age <= ProfileLimits.ageMax
          ? age
          : null,
      weightKg: _inRange(
          weight, ProfileLimits.weightMin, ProfileLimits.weightMax),
      heightCm: _inRange(
          height, ProfileLimits.heightMin, ProfileLimits.heightMax),
      language: normalizeLanguage(language),
      onboardingComplete: onboardingComplete,
    );
  }

  /// The language code if the app supports it, else 'en'.
  static String normalizeLanguage(String? code) =>
      code != null && AppConstants.languages.containsKey(code) ? code : 'en';

  /// Payload for an upsert. `onboarding_complete` is only ever sent as true,
  /// so an older upload that lands late can't undo a finished onboarding.
  /// Without [includeProfile] only the language (and onboarding flag) are
  /// sent and the stored profile fields stay as they are.
  Map<String, dynamic> toUpsert({bool includeProfile = true}) => {
        'id': id,
        if (includeProfile) ...{
          'name': name,
          'surname': surname,
          'age': age,
          'weight_kg': weightKg,
          'height_cm': heightCm,
        },
        'language': normalizeLanguage(language),
        if (onboardingComplete) 'onboarding_complete': true,
      };

  /// The profile as the app stores it locally (all strings).
  UserProfile toUserProfile() => UserProfile(
        name: name,
        surname: surname,
        age: age?.toString() ?? '',
        weight: formatProfileNumber(weightKg),
        height: formatProfileNumber(heightCm),
      );

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _clip(String text) => text.length > ProfileLimits.nameMaxLength
      ? text.substring(0, ProfileLimits.nameMaxLength)
      : text;

  static double? _inRange(double? value, double min, double max) {
    if (value == null) return null;
    final rounded = _oneDecimal(value);
    return rounded >= min && rounded <= max ? rounded : null;
  }
}
