import 'dart:convert';
import 'dart:io';
import 'package:rahti/models/user.dart';
import 'package:rahti/patient/login.dart';
import 'package:rahti/patient/home_screen.dart';
import 'package:rahti/doctor/doctor_home.dart';
import 'package:rahti/doctor/pending_approval_screen.dart';
import 'package:rahti/services/http_service.dart';
import 'package:rahti/toast/toast.dart';
import 'package:rahti/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'storage.dart';
import 'package:rahti/patient/complete_patient_profile.dart';
import 'messagerie_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Service gérant l'authentification et la gestion des utilisateurs
/// Utilise le pattern Singleton pour assurer une seule instance dans l'application
class AuthService {
  // Implémentation du pattern Singleton pour garantir une instance unique
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Services et dépendances nécessaires
  final Logger _logger =
      Logger(); // Service de logging pour le debug et monitoring
  final StorageService _storage =
      StorageService(); // Gestion du stockage local (tokens, préférences)
  final HttpClient _httpClient =
      HttpClient(); // Client HTTP personnalisé pour les requêtes API

  // Utiliser la bonne URL selon la plateforme
  static final String baseUrl = Platform.isAndroid
      ? dotenv.env['API_URL_ANDROID']!
      : dotenv.env['API_URL_IOS']!;

  /// Fonction de connexion d'un utilisateur
  /// @param email: adresse email de l'utilisateur
  /// @param password: mot de passe de l'utilisateur
  /// @returns Map contenant le token JWT et les données utilisateur
  /// Processus:
  /// 1. Nettoie les anciennes données
  /// 2. Réinitialise les tokens Firebase
  /// 3. Authentifie auprès de Strapi
  /// 4. Sauvegarde les nouvelles données
  /// 5. Met à jour le token FCM  /// Authentification d'un utilisateur avec email et mot de passe
  ///
  /// Processus complet :
  /// 1. Nettoyage des données existantes (session, cache)
  /// 2. Réinitialisation des tokens Firebase
  /// 3. Authentification auprès de Strapi
  /// 4. Récupération et sauvegarde du nouveau token
  /// 5. Mise à jour des données utilisateur
  ///
  /// @param email Email de l'utilisateur
  /// @param password Mot de passe
  /// @returns Map contenant le token JWT et les données utilisateur
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      _logger.i('Tentative de connexion pour: $email');

      // 1. Nettoyage complet des données existantes
      await _storage.clearAll();
      await _storage.clearAuthData();
      UserProvider.user = null;

      // Clear Firebase messaging cache and reset FCM token
      final messagingService = MessagerieService();
      await messagingService.clearMessagingCache();

      // Force generate a new FCM token by deleting the old one first
      await FirebaseMessaging.instance.deleteToken();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      _logger.i('Got new FCM token: $fcmToken');

      // 2. Proceed with login
      final response = await http.post(
        Uri.parse('$baseUrl/auth/local'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': email,
          'password': password,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['jwt'] != null) {
        final userData = {
          'jwt': responseData['jwt'],
          'user': responseData['user']
        };

        // 3. Save new user data
        await _storage.saveUserData(userData);
        _logger.i('✅ Auth data saved for: $email');

        // 4. Update FCM token on server
        if (fcmToken != null) {
          try {
            final tokenUpdateResponse = await http.put(
              Uri.parse('$baseUrl/notifications/update-token'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ${responseData['jwt']}',
              },
              body: json.encode({
                'fcmToken': fcmToken,
              }),
            );

            if (tokenUpdateResponse.statusCode == 200) {
              _logger.i('✅ FCM token updated on server');
            } else {
              _logger.w(
                  '⚠️ Failed to update FCM token: ${tokenUpdateResponse.body}');
            }
          } catch (e) {
            _logger.e('❌ Error updating FCM token: $e');
            // Don't throw here - we want the login to succeed even if token update fails
          }
        }

        // 5. Update UserProvider with fresh data
        UserProvider.user = User.fromJson(responseData['user']);
        return userData;
      } else {
        throw Exception(responseData['error']?['message'] ?? 'Login failed');
      }
    } catch (e) {
      _logger.e('❌ Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  /// Gère la navigation après la connexion selon le rôle de l'utilisateur
  /// Pour les médecins:
  /// - Vérifie si le compte est approuvé
  /// - Redirige vers l'écran d'attente ou l'accueil docteur
  /// Pour les patients:
  /// - Vérifie si le profil est complet
  /// - Redirige vers la complétion du profil ou l'accueil patient
  Future<void> navigateBasedOnRole(BuildContext context) async {
    try {
      final user = await getCurrentUser();
      if (!context.mounted) return;

      _logger.i('Navigating for user - Role: ${user.roleType}');

      if (user.roleType.toUpperCase() == 'DOCTOR') {
        final isApproved = user.doctor?['isApproved'] ?? false;
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
        // Modification ici pour vérifier si le profil patient est complet
        final bool isProfileComplete = await _isPatientProfileComplete(user.id);
        _logger.i('Patient profile complete status: $isProfileComplete');

        if (isProfileComplete) {
          _logger.i('Patient profile complete -> HomeScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (context.mounted) {
          // Ne rediriger vers CompletePatientProfile que lors de l'inscription
          final bool isNewRegistration = await _storage.getIsNewRegistration();
          if (isNewRegistration) {
            _logger.i('New patient registration -> CompletePatientProfile');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CompletePatientProfile(
                  userData: {'user': user.toString()},
                ),
              ),
            );
            // Réinitialiser le flag après la redirection
            await _storage.setIsNewRegistration(false);
          } else {
            _logger.i('Existing patient -> HomeScreen');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      _logger.e('Navigation error: $e');
      if (context.mounted) {
        showToast(message: "Navigation failed");
        await logout(context);
      }
    }
  }

  Future<bool> _isPatientProfileComplete(int userId) async {
    try {
      final response = await _httpClient
          .get('$baseUrl/patients?filters[users_permissions_user][id]=$userId');

      return response != null &&
          response['data'] != null &&
          response['data'].isNotEmpty;
    } catch (e) {
      _logger.e('Error checking patient profile: $e');
      return false;
    }
  }

  /// Inscription d'un nouvel utilisateur
  /// @param email: email de l'utilisateur
  /// @param password: mot de passe
  /// @param name: nom complet
  /// @param genre: genre de l'utilisateur
  /// @param objectif: objectif de l'utilisateur
  /// @param role: rôle (DOCTOR ou PATIENT)
  /// @param age: âge (optionnel)
  /// Crée le compte utilisateur et le profil associé selon le rôle
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
      // 1. Delete FCM token from server
      final token = await getAuthToken();
      if (token != null) {
        try {
          // Get current FCM token
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            // Delete token from server
            await http.delete(
              Uri.parse('$baseUrl/notifications/delete-token'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode({
                'fcmToken': fcmToken,
              }),
            );
            _logger.i('✅ FCM token deleted from server');
          }
        } catch (e) {
          _logger.e('❌ Error deleting FCM token: $e');
          // Continue with logout even if token deletion fails
        }
      }

      // 2. Clear Strapi data
      await _storage.clearAll();
      await _storage.clearAuthData();
      UserProvider.user = null;

      // 3. Clear Firebase cache
      final messagingService = MessagerieService();
      await messagingService.clearMessagingCache();

      if (!context.mounted) return;

      // 4. Navigate to login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
        (Route<dynamic> route) => false,
      );

      _logger.i('✅ Logout successful, all caches cleared');
    } catch (e) {
      _logger.e('❌ Error during logout: $e');
      throw Exception('Logout failed: $e');
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
            _logger.d('Doctor info stored: $doctorInfo');
          } else {
            _logger.w('No doctor profile found');
            finalUserData.addAll({'roleType': roleType, 'doctor': null});
          }
        } catch (e) {
          _logger.e('Error fetching doctor profile: $e');
          finalUserData.addAll({'roleType': roleType, 'doctor': null});
        }
      } else {
        finalUserData.addAll({
          'roleType': 'PATIENT',
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
    try {
      _logger.d('Retrieving auth token');
      final token = await _storage.getAuthToken();

      if (token == null) {
        _logger.w('No token found in storage');
        return null;
      }

      // Validation du token
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          _logger.w('Invalid token format');
          await _storage.clearAll();
          return null;
        }

        final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));

        final expiry =
            DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
        if (expiry.isBefore(DateTime.now())) {
          _logger.w('Token expired');
          await _storage.clearAll();
          return null;
        }

        _logger.i('Valid token found');
        return token;
      } catch (e) {
        _logger.e('Error validating token: $e');
        await _storage.clearAll();
        return null;
      }
    } catch (e) {
      _logger.e('Error retrieving token: $e');
      return null;
    }
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

  Future<bool> updateDoctorProfile(
      int userId, Map<String, dynamic> data) async {
    try {
      final token = await getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      // 1. Get doctor profile
      final findDoctorResponse = await http.get(
        Uri.parse(
            '$baseUrl/doctors?filters[users_permissions_user][id]=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      _logger.d('Find doctor response: ${findDoctorResponse.body}');

      final doctorData = json.decode(findDoctorResponse.body);
      if (doctorData['data']?.isEmpty ?? true) {
        throw Exception('Doctor profile not found');
      }

      final doctor = doctorData['data'][0];
      final documentId = doctor['documentId'];
      _logger.d('Found doctor documentId: $documentId');

      // 2. Update doctor profile using documentId
      final updateResponse = await http.put(
        Uri.parse('$baseUrl/doctors/$documentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {'speciality': data['speciality'], 'phone': data['phone']}
        }),
      );

      _logger.d('Update URL: $baseUrl/doctors/$documentId');
      _logger.d('Update request body: ${json.encode({
            'data': {'speciality': data['speciality'], 'phone': data['phone']}
          })}');
      _logger.d('Update response: ${updateResponse.body}');

      return updateResponse.statusCode >= 200 &&
          updateResponse.statusCode < 300;
    } catch (e) {
      _logger.e('Error updating doctor profile: $e');
      return false;
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

      _logger.d('Fetching complete user data...');
      // First check if we already have a user in UserProvider
      if (UserProvider.user != null) {
        _logger.d('Using cached user from UserProvider');
        return UserProvider.user!;
      }

      final userResponse = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $jwt'},
      );

      final userData = json.decode(userResponse.body);
      final Map<String, dynamic> finalUserData =
          Map<String, dynamic>.from(userData);

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
        _logger.d('Doctor data received: $doctorData');

        if (doctorData['data']?.isNotEmpty ?? false) {
          // Stocker l'objet docteur complet, pas seulement ses attributs
          finalUserData['doctor'] = doctorData['data'][0];
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
      _logger.d('Final user data: $finalUserData');
      final user = User.fromJson(finalUserData);
      UserProvider.user = user; // Set the user in UserProvider
      return user;
    } catch (e) {
      _logger.e('Error fetching user data: $e');
      throw Exception('Failed to fetch user data');
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final token = await getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final userId = UserProvider.user?.id;
      if (userId == null) throw Exception('User ID not found');

      final roleType = UserProvider.user?.roleType.toUpperCase();

      if (roleType == 'DOCTOR') {
        // 1. First find all doctor data
        final findDoctorResponse = await http.get(
          Uri.parse(
              '$baseUrl/doctors?filters[users_permissions_user][id]=$userId&populate=*'),
          headers: {'Authorization': 'Bearer $token'},
        );

        final doctorData = json.decode(findDoctorResponse.body);
        if (doctorData['data']?.isNotEmpty ?? false) {
          final doctor = doctorData['data'][0];
          final doctorDocumentId = doctor['documentId'];

          // 2. Delete all reservations linked to this doctor
          final findReservationsResponse = await http.get(
            Uri.parse(
                '$baseUrl/reservations?filters[doctor][id]=${doctor['id']}'),
            headers: {'Authorization': 'Bearer $token'},
          );

          final reservationsData = json.decode(findReservationsResponse.body);
          for (var reservation in reservationsData['data'] ?? []) {
            await http.delete(
              Uri.parse('$baseUrl/reservations/${reservation['id']}'),
              headers: {'Authorization': 'Bearer $token'},
            );
          }

          // 3. Delete cabinet if exists
          if (doctor['cabinet'] != null) {
            final cabinetId = doctor['cabinet']['id'];
            await http.delete(
              Uri.parse('$baseUrl/cabinets/$cabinetId'),
              headers: {'Authorization': 'Bearer $token'},
            );
          }

          // 4. Delete doctor profile
          final deleteDoctorResponse = await http.delete(
            Uri.parse('$baseUrl/doctors/$doctorDocumentId'),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (deleteDoctorResponse.statusCode >= 300) {
            throw Exception('Failed to delete doctor profile');
          }
        }
      } else {
        // Handle patient deletion (existing code)
        final findPatientResponse = await http.get(
          Uri.parse(
              '$baseUrl/patients?filters[users_permissions_user][id]=$userId'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (findPatientResponse.statusCode >= 300) {
          throw Exception('Failed to find patient profile');
        }

        final patientData = json.decode(findPatientResponse.body);
        if (patientData['data']?.isNotEmpty ?? false) {
          final patient = patientData['data'][0];
          final documentId = patient['documentId'];

          // Delete patient profile using documentId
          final deletePatientResponse = await http.delete(
            Uri.parse('$baseUrl/patients/$documentId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );

          _logger.d(
              'Delete patient response: ${deletePatientResponse.statusCode}');
          if (deletePatientResponse.statusCode >= 300) {
            throw Exception('Failed to delete patient profile');
          }
        }
      }

      // Finally delete user account
      final deleteUserResponse = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      await _storage.clearAll();
      UserProvider.user = null;

      return deleteUserResponse.statusCode >= 200 &&
          deleteUserResponse.statusCode < 300;
    } catch (e) {
      _logger.e('Error deleting account: $e');
      return false;
    }
  }

  Future<bool> validatePassword(String password) async {
    try {
      _logger.i('Validating password');

      final user = UserProvider.user;
      if (user == null) throw Exception('No user found');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/local'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'identifier': user.email,
          'password': password,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Error validating password: $e');
      return false;
    }
  }

  /// Demande de réinitialisation de mot de passe
  /// @param email: adresse email de l'utilisateur
  /// @returns true si l'email a été envoyé avec succès
  /// Envoie un email avec un lien de réinitialisation via Strapi
  Future<bool> forgotPassword(String email) async {
    try {
      _logger.i('Requesting password reset for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        _logger.i('Password reset email sent successfully');
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['error']?['message'] ?? 'Failed to send reset email');
      }
    } catch (e) {
      _logger.e('Error requesting password reset: $e');
      throw Exception('Failed to send reset email: $e');
    }
  }

  void dispose() {
    _logger.d('Disposing AuthService resources');
  }
}
