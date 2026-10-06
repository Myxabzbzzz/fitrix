import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitrix/core/constants/app_constants.dart';

/// Local-only mode (no Supabase): the email typed on the sign-in screen is
/// just remembered on the device. With Supabase the account comes from
/// `AuthGateway` instead.
class AuthRepository {
  Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyUserEmail, email);
    await prefs.setBool(AppConstants.keyIsAuthenticated, true);
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyUserEmail);
  }
}
