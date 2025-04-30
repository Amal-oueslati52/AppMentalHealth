import 'dart:convert';
import 'dart:io';
import 'package:app/models/user.dart';
import 'package:app/patient/login.dart';
import 'package:app/patient/HomeScreen.dart';
import 'package:app/doctor/doctorHome.dart';
import 'package:app/doctor/pending_approval_screen.dart';
import 'package:app/services/http_service.dart';
import 'package:app/toast/toast.dart';
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

  // Utiliser la bonne URL selon la plateforme
  static const String _iosBaseUrl = 'http://127.0.0.1:1337/api';
  static const String _androidBaseUrl = 'http://192.168.1.11:1337/api';
  static final String baseUrl = Platform.isIOS ? _iosBaseUrl : _androidBaseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _logger.i('Attempting login for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/local'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': email,
          'password': password,
        }),
      );

      _logger.d('Login response: ${response.body}');
      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['jwt'] != null) {
        Map<String, dynamic> userData =
            Map<String, dynamic>.from(responseData['user']);
        final jwt = responseData['jwt'];

        try {
          final doctorResponse = await http.get(
            Uri.parse(
                '$baseUrl/doctors?filters[users_permissions_user]=${userData['id']}&populate=*'),
            headers: {'Authorization': 'Bearer $jwt'},
          );

          final doctorData = json.decode(doctorResponse.body);
          _logger.d('Doctor data: $doctorData');

          if (doctorData['data'] != null && doctorData['data'].isNotEmpty) {
            final doctorInfo = doctorData['data'][0];
            final doctorAttributes = doctorInfo['attributes'];
            _logger
                .i('Found doctor profile with attributes: $doctorAttributes');

            userData.addAll({
              'roleType': 'DOCTOR',
              'isApproved': doctorAttributes['isApproved'] ?? false,
              'speciality': doctorAttributes['speciality'] ?? '',
              'doctor': doctorInfo,
            });
            await _storage.saveUserRole('DOCTOR');
          } else {
            userData.addAll({
              'roleType': 'PATIENT',
              'isApproved': true,
            });
            await _storage.saveUserRole('PATIENT');
          }
        } catch (e) {
          _logger.e('Error checking doctor profile: $e');
          userData.addAll({
            'roleType': 'PATIENT',
            'isApproved': true,
          });
          await _storage.saveUserRole('PATIENT');
        }

        await _saveUserData({
          'jwt': jwt,
          'user': userData,
        });

        UserProvider.user = User.fromJson(userData);
        return {'jwt': jwt, 'user': userData};
      } else {
        final errorMessage =
            responseData['error']?['message'] ?? 'Invalid credentials';
        _logger.e('Login failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      _logger.e('Login error details: $e');
      if (e is FormatException) {
        throw Exception('Server response was not in the expected format');
      }
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> navigateBasedOnRole(BuildContext context) async {
    try {
      final user = await getCurrentUser();
      if (!context.mounted) return;

      _logger.i(
          'Navigating for user - Role: ${user.roleType}, isApproved: ${user.isApproved}');

      if (user.roleType.toUpperCase() == 'DOCTOR') {
        // For doctors, check approval status from the doctor profile
        final isApproved = user.isApproved;
        _logger.i('Doctor approval status: $isApproved');

        if (isApproved) {
          _logger.i('Doctor is approved -> DoctorHome');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DoctorHome()),
          );
        } else {
          _logger.i('Doctor not approved -> PendingApprovalScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
          );
        }
      } else {
        // For patients, always go to HomeScreen
        _logger.i('User is patient -> HomeScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _logger.e('Navigation error: $e');
      showToast(message: "Navigation failed");
      await logout(context);
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String genre,
    required String objectif,
    required String role,
    String? age,
  }) async {
    try {
      _logger.i('Attempting to register user with role: $role');

      // Initial registration without role
      final response = await http.post(
        Uri.parse('$baseUrl/auth/local/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': email,
          'email': email,
          'password': password,
          'name': name,
          'genre': genre,
          'objectif': objectif,
          'age': age != null ? int.tryParse(age) ?? 0 : 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userId = data['user']['id'];
        final jwt = data['jwt'];

        // Update user with role
        await http.put(
          Uri.parse('$baseUrl/users/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $jwt',
          },
          body: json.encode({
            'roleType': role.toUpperCase(),
          }),
        );

        if (role.toUpperCase() == 'DOCTOR') {
          // Create doctor profile with isApproved set to false
          final doctorProfileResponse = await http.post(
            Uri.parse('$baseUrl/doctors'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: json.encode({
              'data': {
                'users_permissions_user': userId,
                'speciality': '',
                'isApproved': false,
              }
            }),
          );

          final doctorProfileData = json.decode(doctorProfileResponse.body);
          final userData = {
            'jwt': jwt,
            'user': {
              ...data['user'],
              'roleType': 'DOCTOR',
              'isApproved': false,
              'doctor': doctorProfileData['data'],
            },
          };
          await _saveUserData(userData);
          return userData;
        } else {
          // Create patient profile
          await http.post(
            Uri.parse('$baseUrl/patients'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwt',
            },
            body: json.encode({
              'data': {
                'users_permissions_user': userId,
                'birthdate': DateTime.now().toIso8601String(),
              }
            }),
          );

          final userData = {
            'jwt': jwt,
            'user': {
              ...data['user'],
              'roleType': 'PATIENT',
              'isApproved': true,
            },
          };
          await _saveUserData(userData);
          return userData;
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error']['message']);
      }
    } catch (e) {
      _logger.e('Registration error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> createDoctorProfile({
    required int userId,
    required String speciality,
    String? jwt,
  }) async {
    try {
      final token = jwt ?? await getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.post(
        Uri.parse('$baseUrl/doctors'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {
            'users_permissions_user': userId,
            'speciality': speciality,
            'isApproved': false, // Set to false by default for new doctors
          }
        }),
      );

      _logger.i('Doctor profile creation response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create doctor profile');
      }

      final responseData = json.decode(response.body);
      return responseData['data'];
    } catch (e) {
      _logger.e('Error creating doctor profile: $e');
      throw Exception('Failed to create doctor profile');
    }
  }

  Future<void> createPatientProfile({
    required int userId,
    required DateTime birthdate,
    String? jwt,
  }) async {
    try {
      final token = jwt ?? await _storage.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      print(
          'Creating patient profile with birthdate: ${birthdate.toIso8601String()}');
      print('Using token: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {
            'users_permissions_user': userId,
            'birthdate': birthdate.toIso8601String(),
          }
        }),
      );

      print('Patient profile creation response: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create patient profile: ${response.body}');
      }
    } catch (e) {
      print('Error creating patient profile: $e');
      throw Exception('Failed to create patient profile');
    }
  }

  Future<void> logout(BuildContext context) async {
    _logger.i('Logging out current user');

    try {
      await _storage.clearAll();
      UserProvider.user = null;

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (Route<dynamic> route) => false,
      );

      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error during logout process: ${e.toString()}');
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final jwt = await getAuthToken();
      if (jwt == null) throw Exception('No authentication token found');

      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      if (userResponse.statusCode != 200) {
        throw Exception('Failed to fetch user data');
      }

      final userData = json.decode(userResponse.body);
      final Map<String, dynamic> finalUserData =
          Map<String, dynamic>.from(userData);

      final roleType =
          (finalUserData['roleType'] ?? 'PATIENT').toString().toUpperCase();
      _logger.d('User roleType: $roleType');

      if (roleType == 'DOCTOR') {
        try {
          final doctorResponse = await http.get(
            Uri.parse(
                '$baseUrl/doctors?filters[users_permissions_user]=${finalUserData['id']}&populate=*'),
            headers: {'Authorization': 'Bearer $jwt'},
          );

          final doctorData = json.decode(doctorResponse.body);
          _logger.d('Doctor data response: $doctorData');

          if (doctorData['data'] != null && doctorData['data'].isNotEmpty) {
            final doctorInfo = doctorData['data'][0];
            // Store the entire doctor object
            finalUserData['doctor'] = doctorInfo;

            // Also store top-level properties for backward compatibility
            finalUserData.addAll({
              'roleType': roleType,
              'isApproved': doctorInfo['isApproved'] ?? false,
              'speciality': doctorInfo['speciality'] ?? '',
            });
          } else {
            finalUserData.addAll({
              'roleType': roleType,
              'isApproved': false,
              'speciality': '',
            });
          }
        } catch (e) {
          _logger.e('Error fetching doctor profile: $e');
          finalUserData.addAll({
            'roleType': roleType,
            'isApproved': false,
            'speciality': '',
          });
        }
      } else {
        finalUserData.addAll({
          'roleType': 'PATIENT',
          'isApproved': true,
          'isProfileComplete': true,
        });
      }

      _logger.i('Creating user with final data: $finalUserData');
      final user = User.fromJson(finalUserData);
      UserProvider.user = user;
      return user;
    } catch (e) {
      _logger.e('Error getting current user: $e');
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<String?> getAuthToken() async {
    _logger.d('Retrieving auth token');
    return _storage.getAuthToken();
  }

  Future<void> _saveUserData(Map<String, dynamic> data) async {
    _logger.d('Saving authentication data');
    if (data['jwt'] != null) {
      await _storage.saveAuthToken(data['jwt']);
    }

    if (data['user'] != null && data['user']['id'] != null) {
      await _storage.saveUserId(data['user']['id'].toString());
    }
  }

  Future<bool> isAuthenticated() async {
    _logger.d('Checking authentication status');
    return await _storage.hasValidSession();
  }

  Future<User> updateProfile(Map<String, dynamic> userData) async {
    if (UserProvider.user == null) {
      _logger.e('Cannot update profile: No user is logged in');
      throw Exception('No authenticated user found');
    }

    _logger.i('Updating profile for user ID: ${UserProvider.user!.id}');

    try {
      if (userData['age'] != null) {
        userData['age'] = userData['age'].toString();
      }

      final response = await _httpClient.put(
        '$baseUrl/users/${UserProvider.user!.id}',
        body: userData,
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
        roleType:
            attributes['roletype']?.toString() ?? UserProvider.user!.roleType,
        genre: attributes['genre']?.toString() ?? UserProvider.user!.genre,
        age: attributes['age']?.toString() ?? UserProvider.user!.age,
        objectif:
            attributes['objectif']?.toString() ?? UserProvider.user!.objectif,
        speciality: attributes['speciality']?.toString() ??
            UserProvider.user!.speciality,
        birthdate:
            attributes['birthdate']?.toString() ?? UserProvider.user!.birthdate,
      );

      UserProvider.user = updatedUser;
      _logger.i('Profile updated successfully');
      return updatedUser;
    } catch (e) {
      _logger.e('Error updating user profile: ${e.toString()}');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  Future<User> getCompleteUserData() async {
    try {
      final jwt = await getAuthToken();
      if (jwt == null) throw Exception('No authentication token found');

      // Récupérer les données utilisateur avec les profils
      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      final userData = json.decode(userResponse.body);
      final Map<String, dynamic> finalUserData =
          Map<String, dynamic>.from(userData);

      // Vérifier le type d'utilisateur
      final roleType =
          (finalUserData['roleType'] ?? 'PATIENT').toString().toUpperCase();

      if (roleType == 'DOCTOR') {
        // Récupérer le profil docteur
        final doctorResponse = await http.get(
          Uri.parse(
              '$baseUrl/doctors?filters[users_permissions_user]=${finalUserData['id']}&populate=*'),
          headers: {'Authorization': 'Bearer $jwt'},
        );

        final doctorData = json.decode(doctorResponse.body);
        if (doctorData['data']?.isNotEmpty ?? false) {
          finalUserData['doctor'] = doctorData['data'][0]['attributes'];
        }
      } else {
        // Récupérer le profil patient
        final patientResponse = await http.get(
          Uri.parse(
              '$baseUrl/patients?filters[users_permissions_user]=${finalUserData['id']}'),
          headers: {'Authorization': 'Bearer $jwt'},
        );

        final patientData = json.decode(patientResponse.body);
        if (patientData['data']?.isNotEmpty ?? false) {
          finalUserData['patient'] = patientData['data'][0]['attributes'];
        }
      }

      return User.fromJson(finalUserData);
    } catch (e) {
      _logger.e('Error fetching user data: $e');
      throw Exception('Failed to fetch user data');
    }
  }

  void dispose() {
    _logger.d('Disposing AuthService resources');
  }
}
