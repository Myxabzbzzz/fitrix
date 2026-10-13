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
  static const int answerMaxLength = 120;
  static const int sportsMax = 6;
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

enum ProfileErrorKind {
  nameRequired,
  nameTooLong,
  surnameTooLong,
  ageRequired,
  ageWhole,
  ageRange,
  weightRequired,
  weightNumber,
  weightRange,
  heightRequired,
  heightNumber,
  heightRange,
}

/// A profile form error: [kind] (plus [min] / [max] for range errors) is
/// mapped to localized text by the UI; [message] is the English fallback.
class ProfileError {
  const ProfileError(this.kind, this.message, {this.min = '', this.max = ''});

  final ProfileErrorKind kind;
  final String message;
  final String min;
  final String max;

  @override
  String toString() => message;
}

/// Profile form validation. Each check returns an error or null.
class ProfileValidator {
  ProfileValidator._();

  static ProfileError? name(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return const ProfileError(
          ProfileErrorKind.nameRequired, 'Enter your name');
    }
    if (name.length > ProfileLimits.nameMaxLength) {
      return const ProfileError(
          ProfileErrorKind.nameTooLong, 'Name is too long');
    }
    return null;
  }

  static ProfileError? surname(String value) =>
      value.trim().length > ProfileLimits.nameMaxLength
          ? const ProfileError(
              ProfileErrorKind.surnameTooLong, 'Surname is too long')
          : null;

  static ProfileError? age(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return const ProfileError(ProfileErrorKind.ageRequired, 'Enter your age');
    }
    final age = int.tryParse(text);
    if (age == null) {
      return const ProfileError(
          ProfileErrorKind.ageWhole, 'Age must be a whole number');
    }
    if (age < ProfileLimits.ageMin || age > ProfileLimits.ageMax) {
      return const ProfileError(
        ProfileErrorKind.ageRange,
        'Age must be between ${ProfileLimits.ageMin} and ${ProfileLimits.ageMax}',
        min: '${ProfileLimits.ageMin}',
        max: '${ProfileLimits.ageMax}',
      );
    }
    return null;
  }

  static ProfileError? weight(String value) => _measure(
        value,
        what: 'weight',
        min: ProfileLimits.weightMin,
        max: ProfileLimits.weightMax,
        unit: 'kg',
        required: ProfileErrorKind.weightRequired,
        number: ProfileErrorKind.weightNumber,
        range: ProfileErrorKind.weightRange,
      );

  static ProfileError? height(String value) => _measure(
        value,
        what: 'height',
        min: ProfileLimits.heightMin,
        max: ProfileLimits.heightMax,
        unit: 'cm',
        required: ProfileErrorKind.heightRequired,
        number: ProfileErrorKind.heightNumber,
        range: ProfileErrorKind.heightRange,
      );

  static ProfileError? _measure(
    String value, {
    required String what,
    required double min,
    required double max,
    required String unit,
    required ProfileErrorKind required,
    required ProfileErrorKind number,
    required ProfileErrorKind range,
  }) {
    final text = value.trim();
    if (text.isEmpty) return ProfileError(required, 'Enter your $what');
    final parsed = parseProfileNumber(text);
    if (parsed == null) {
      return ProfileError(number, 'Enter your $what as a number');
    }
    final rounded = _oneDecimal(parsed);
    if (rounded < min || rounded > max) {
      final lo = formatProfileNumber(min);
      final hi = formatProfileNumber(max);
      return ProfileError(
        range,
        '${what[0].toUpperCase()}${what.substring(1)} must be between '
        '$lo and $hi $unit',
        min: lo,
        max: hi,
      );
    }
    return null;
  }

  /// Field name ('name', 'surname', 'age', 'weight', 'height') → error.
  /// Empty when the profile is valid.
  static Map<String, ProfileError> validate(UserProfile profile) {
    final errors = <String, ProfileError?>{
      'name': name(profile.name),
      'surname': surname(profile.surname),
      'age': age(profile.age),
      'weight': weight(profile.weight),
      'height': height(profile.height),
    };
    errors.removeWhere((_, error) => error == null);
    return errors.cast<String, ProfileError>();
  }

  /// Trimmed, with numbers in a canonical form ("72,50" → "72.5").
  static UserProfile normalize(UserProfile profile) => UserProfile(
        name: profile.name.trim(),
        surname: profile.surname.trim(),
        age: profile.age.trim(),
        weight: _normalizeNumber(profile.weight),
        height: _normalizeNumber(profile.height),
        goal: profile.goal,
        experience: profile.experience,
        sports: profile.sports,
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
    this.goal,
    this.experience,
    this.sports = const [],
  });

  final String id;
  final String name;
  final String surname;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final String language;
  final bool onboardingComplete;
  final String? goal;
  final String? experience;
  final List<String> sports;

  static const table = 'profiles';
  static const columns =
      'id, name, surname, age, weight_kg, height_cm, language, onboarding_complete, goal, experience, sports';

  factory ProfileRow.fromJson(Map<String, dynamic> json) => ProfileRow(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        surname: (json['surname'] as String?) ?? '',
        age: (json['age'] as num?)?.toInt(),
        weightKg: _toDouble(json['weight_kg']),
        heightCm: _toDouble(json['height_cm']),
        language: (json['language'] as String?) ?? 'en',
        onboardingComplete: (json['onboarding_complete'] as bool?) ?? false,
        goal: json['goal'] as String?,
        experience: json['experience'] as String?,
        sports: [
          for (final s in (json['sports'] as List?) ?? const [])
            if (s is String) s,
        ],
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
      weightKg:
          _inRange(weight, ProfileLimits.weightMin, ProfileLimits.weightMax),
      heightCm:
          _inRange(height, ProfileLimits.heightMin, ProfileLimits.heightMax),
      language: normalizeLanguage(language),
      onboardingComplete: onboardingComplete,
      goal: _answer(profile.goal),
      experience: _answer(profile.experience),
      sports: [
        for (final s in profile.sports)
          if (_answer(s) != null) _answer(s)!,
      ].take(ProfileLimits.sportsMax).toList(),
    );
  }

  /// The language code if the app supports it, else 'en'.
  static String normalizeLanguage(String? code) =>
      code != null && AppConstants.languages.containsKey(code) ? code : 'en';

  /// Payload for an upsert. `onboarding_complete` is only ever sent as true,
  /// so an older upload that lands late can't undo a finished onboarding.
  /// Without [includeProfile] only the language (and onboarding flag) are
  /// sent and the stored profile fields stay as they are.
  Map<String, dynamic> toUpsert({
    bool includeProfile = true,
    bool clearBlankAnswers = false,
  }) =>
      {
        'id': id,
        if (includeProfile) ...{
          'name': name,
          'surname': surname,
          'age': age,
          'weight_kg': weightKg,
          'height_cm': heightCm,
          // Left out when blank so a device that never answered doesn't
          // wipe answers given on another device.
          // After an edit on About me they are sent even when blank, so the
          // server clears them too.
          if (goal != null || clearBlankAnswers) 'goal': goal,
          if (experience != null || clearBlankAnswers)
            'experience': experience,
          if (sports.isNotEmpty || clearBlankAnswers) 'sports': sports,
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
        goal: goal ?? '',
        experience: experience ?? '',
        sports: sports,
      );

  /// Trimmed and clipped to the column limit; null when empty.
  static String? _answer(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return t.length > ProfileLimits.answerMaxLength
        ? t.substring(0, ProfileLimits.answerMaxLength)
        : t;
  }

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
