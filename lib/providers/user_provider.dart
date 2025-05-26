import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/strapi_auth_service.dart';

class UserProvider extends ChangeNotifier {
  static User? _user;
  static final AuthService _authService = AuthService();

  static User? get user => _user;

  static set user(User? value) {
    if (_user?.roleType != value?.roleType) {
      print(
          '🔄 User role changed from ${_user?.roleType} to ${value?.roleType}');
    }
    _user = value;
  }

  static Future<void> clearUser() async {
    _user = null;
    print('🗑️ UserProvider cleared');
  }

  static Future<bool> initialize() async {
    try {
      await clearUser(); // Clear current user before initialization
      _user = await _authService.getCurrentUser();
      print('✅ UserProvider initialized with role: ${_user?.roleType}');
      return _user != null;
    } catch (e) {
      print('❌ Error initializing user: $e');
      return false;
    }
  }

  static bool get isAuthenticated => _user != null;
}
