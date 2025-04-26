import 'dart:convert';
import 'package:app/models/user.dart';
import 'package:app/pages/login.dart';
import 'package:app/services/http_service.dart';
import 'package:app/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'storage.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Logger _logger = Logger();
  final StorageService _storage = StorageService();
  final HttpClient _httpClient = HttpClient();

  static const String baseUrl = 'http://192.168.1.17:1337/api';

  /// Makes a POST request to the Strapi auth endpoint
  /// On success, stores the JWT token and updates the UserProvider
  /// Returns the full response data from the server
  /// Throws an exception if authentication fails
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/local'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'identifier': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) {
          throw Exception('Invalid response format: empty response');
        }

        final userData = data['user'];
        if (userData == null) {
          throw Exception('Invalid response format: missing user data');
        }

        // Create user with proper type conversion
        final user = User(
          id: userData['id'] is String
              ? int.parse(userData['id'])
              : userData['id'],
          name: userData['name']?.toString() ?? '',
          email: userData['email']?.toString() ?? '',
          genre: userData['genre']?.toString() ?? '',
          age: userData['age']?.toString() ?? '',
          objectif: userData['objectif']?.toString() ?? '',
        );

        UserProvider.user = user;
        _logger.i('Login successful for user: $email');
        await _saveUserData(data);
        return data;
      } else {
        final error = json.decode(response.body);
        final errorMessage =
            error['error']?['message'] ?? error['message'] ?? 'Unknown error';
        _logger.e('Login failed: $errorMessage');
        throw Exception('Failed to login: $errorMessage');
      }
    } catch (e) {
      _logger.e('Error during login process: ${e.toString()}');
      throw Exception('Authentication failed: ${e.toString()}');
    }
  }

  /// Makes a POST request to the Strapi registration endpoint
  /// On success, stores the JWT token and returns the response data
  /// Throws an exception if registration fails
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String genre,
    required String objectif,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/local/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'username': email,
          'email': email,
          'name': name,
          'password': password,
          'genre': genre,
          'objectif': objectif,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logger.i('Registration successful for user: $email');
        await _saveUserData(data);
        return data;
      } else {
        final error = json.decode(response.body);
        final errorMessage = error['error']?['message'] ??
            error['message'] ??
            'Registration failed';
        _logger.e('Registration failed: $errorMessage');
        throw Exception('Failed to register: $errorMessage');
      }
    } catch (e) {
      _logger.e('Error during registration process: ${e.toString()}');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  /// Clears all stored user data and authentication tokens
  /// Resets the UserProvider state
  /// Navigates back to the Welcome screen, removing all previous routes
  Future<void> logout(BuildContext context) async {
    _logger.i('Logging out current user');

    try {
      await _storage.clearAll();
      UserProvider.user = null;

      _logger.i('User logged out successfully');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => Login()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _logger.e('Error during logout process: ${e.toString()}');
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  /// Retrieves the currently authenticated user's information
  /// Returns the cached user if available, otherwise fetches from API
  /// Updates UserProvider with latest user data
  /// Throws an exception if user data cannot be fetched
  Future<User> getCurrentUser() async {
    _logger.d('Getting current user information');

    if (UserProvider.user != null) {
      _logger.i('Returning cached user data');
      return UserProvider.user!;
    }

    try {
      final response = await _httpClient.get('$baseUrl/users/me');
      final user = User.fromJson(response);
      UserProvider.user = user;

      return user;
    } catch (e) {
      _logger.e('Error getting current user: ${e.toString()}');
      throw Exception('Failed to fetch user data: ${e.toString()}');
    }
  }

  /// Returns the JWT token if it exists, otherwise null
  Future<String?> getAuthToken() async {
    _logger.d('Retrieving auth token');
    return _storage.getAuthToken();
  }

  /// Stores the JWT token from the API response for future authenticated requests
  Future<void> _saveUserData(Map<String, dynamic> data) async {
    _logger.d('Saving authentication data');
    await _storage.saveAuthToken(data['jwt']);
    if (data['user'] != null && data['user']['id'] != null) {
      await _storage.saveUserId(data['user']['id'].toString());
    }
  }

  /// Returns true if a valid token exists, otherwise false
  Future<bool> isAuthenticated() async {
    return await _storage.hasValidSession();
  }

  /// Makes a PUT request to the Strapi users endpoint
  /// Updates the UserProvider with the updated user information
  /// Returns the updated User object
  Future<User> updateProfile(Map<String, dynamic> userData) async {
    if (UserProvider.user == null) {
      _logger.e('Cannot update profile: No user is logged in');
      throw Exception('No authenticated user found');
    }

    _logger.i('Updating profile for user ID: ${UserProvider.user!.id}');

    try {
      // Convert age to string to ensure consistent type
      if (userData['age'] != null) {
        userData['age'] = userData['age'].toString();
      }

      final response = await _httpClient.put(
        '$baseUrl/users/${UserProvider.user!.id}',
        body: userData, // Remove the 'data' wrapper as it's not needed
      );

      if (response == null) {
        throw Exception('Server returned null response');
      }

      final data = response['data'] ?? response;
      final attributes = data['attributes'] ?? data;

      if (attributes == null) {
        throw Exception('Invalid response format: missing user attributes');
      }

      final updatedUser = User(
        id: UserProvider.user!.id,
        email: attributes['email']?.toString() ?? UserProvider.user!.email,
        name: attributes['name']?.toString() ?? UserProvider.user!.name,
        genre: attributes['genre']?.toString() ?? UserProvider.user!.genre,
        age: attributes['age']?.toString() ?? UserProvider.user!.age,
        objectif:
            attributes['objectif']?.toString() ?? UserProvider.user!.objectif,
      );

      _logger.i('Profile updated successfully with age: ${updatedUser.age}');
      UserProvider.user = updatedUser;
      return updatedUser;
    } catch (e) {
      _logger.e('Error updating user profile: ${e.toString()}');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Disposes resources used by the service
  void dispose() {
    _logger.d('Disposing AuthService resources');
    // Clean up any resources that need to be released
  }
}