import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/strapi_auth_service.dart';

class UserProvider extends ChangeNotifier {
  static User? _user;
  static final AuthService _authService = AuthService();

  static User? get user => _user;

  static set user(User? value) {
    _user = value;
  }

  static Future<bool> initialize() async {
    try {
      if (_user == null) {
        _user = await _authService.getCurrentUser();
      }
      return _user != null;
    } catch (e) {
      print('Error initializing user: $e');
      return false;
    }
  }

  static bool get isAuthenticated => _user != null;
}
