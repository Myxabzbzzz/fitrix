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
    );
  }
}
