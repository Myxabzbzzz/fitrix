class UserProfile {
  final String name;
  final String surname;
  final String age;
  final String weight;
  final String height;

  /// Onboarding answers Felix needs. Stable English values (the quick-reply
  /// text, or what the user typed), empty when not answered yet.
  final String goal;
  final String experience;
  final List<String> sports;

  UserProfile({
    required this.name,
    required this.surname,
    required this.age,
    required this.weight,
    required this.height,
    this.goal = '',
    this.experience = '',
    this.sports = const [],
  });

  UserProfile copyWith({
    String? name,
    String? surname,
    String? age,
    String? weight,
    String? height,
    String? goal,
    String? experience,
    List<String>? sports,
  }) {
    return UserProfile(
      name: name ?? this.name,
      surname: surname ?? this.surname,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      sports: sports ?? this.sports,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'age': age,
      'weight': weight,
      'height': height,
      'goal': goal,
      'experience': experience,
      'sports': sports,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      age: json['age'] ?? '',
      weight: json['weight'] ?? '',
      height: json['height'] ?? '',
      goal: json['goal'] ?? '',
      experience: json['experience'] ?? '',
      sports: [
        for (final s in (json['sports'] as List?) ?? const [])
          if (s is String) s,
      ],
    );
  }
}
