import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/constants/app_constants.dart';
import 'package:fitrix/features/profile/data/models/user_profile.dart';

class ProfileRepository {
  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserName, profile.name);
    await prefs.setString(AppConstants.keyUserSurname, profile.surname);
    await prefs.setString(AppConstants.keyUserAge, profile.age);
    await prefs.setString(AppConstants.keyUserWeight, profile.weight);
    await prefs.setString(AppConstants.keyUserHeight, profile.height);
    await prefs.setString(AppConstants.keyUserGoal, profile.goal);
    await prefs.setString(AppConstants.keyUserExperience, profile.experience);
    await prefs.setStringList(AppConstants.keyUserSports, profile.sports);
  }

  Future<UserProfile?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(AppConstants.keyUserName);

    if (name == null) return null;

    return UserProfile(
      name: name,
      surname: prefs.getString(AppConstants.keyUserSurname) ?? '',
      age: prefs.getString(AppConstants.keyUserAge) ?? '',
      weight: prefs.getString(AppConstants.keyUserWeight) ?? '',
      height: prefs.getString(AppConstants.keyUserHeight) ?? '',
      goal: prefs.getString(AppConstants.keyUserGoal) ?? '',
      experience: prefs.getString(AppConstants.keyUserExperience) ?? '',
      sports: prefs.getStringList(AppConstants.keyUserSports) ?? const [],
    );
  }
}
