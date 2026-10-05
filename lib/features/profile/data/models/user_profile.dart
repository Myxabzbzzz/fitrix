class UserProfile {
  final String name;
  final String surname;
  final String age;
  final String weight;
  final String height;

  UserProfile({
    required this.name,
    required this.surname,
    required this.age,
    required this.weight,
    required this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'surname': surname,
      'age': age,
      'weight': weight,
      'height': height,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] ?? '',
      surname: json['surname'] ?? '',
      age: json['age'] ?? '',
      weight: json['weight'] ?? '',
      height: json['height'] ?? '',
    );
  }
}
