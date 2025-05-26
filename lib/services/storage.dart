import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/providers/user_provider.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _lastLoginKey = 'last_login';
  static const String _userRoleKey = 'user_role';
  static const String _isNewRegistrationKey = 'is_new_registration';

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }

  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role.toUpperCase());
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey)?.toUpperCase();
  }

  Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final lastLoginStr = prefs.getString(_lastLoginKey);

    if (token == null || lastLoginStr == null) {
      return false;
    }

    final lastLogin = DateTime.parse(lastLoginStr);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    return difference.inDays < 30; // Session expire après 30 jours
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_lastLoginKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove('user_data');
    await prefs.remove('current_role');

    // Force clear user provider
    await UserProvider.clearUser();

    print('🗑️ Auth data and user provider cleared');
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Force clear user provider
    await UserProvider.clearUser();

    print('🗑️ All storage data and user provider cleared');
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    if (userData['jwt'] != null) {
      await prefs.setString(_tokenKey, userData['jwt']);
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    }

    if (userData['user'] != null) {
      final user = userData['user'];
      await prefs.setString(_userIdKey, user['id'].toString());
      await prefs.setString(
          _userRoleKey, user['roleType'].toString().toUpperCase());

      // Sauvegarder les données complètes de l'utilisateur
      await prefs.setString('user_data', json.encode(userData['user']));
      print('✅ User data saved to storage: ${userData['user']}');
    }
  }

  Future<Map<String, dynamic>?> getCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }

  Future<void> setIsNewRegistration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isNewRegistrationKey, value);
  }

  Future<bool> getIsNewRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isNewRegistrationKey) ?? false;
  }
}
