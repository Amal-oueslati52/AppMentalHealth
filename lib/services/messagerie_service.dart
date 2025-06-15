import 'package:rahti/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'strapi_auth_service.dart';
import 'http_service.dart';

/// Service de messagerie gérant les conversations entre utilisateurs
/// Utilise Firebase Firestore pour le stockage en temps réel des messages
/// et Strapi pour la gestion des utilisateurs et des blocages
class MessagerieService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore
      .instance; // Instance Firestore pour le stockage des messages
  final HttpClient _httpClient =
      HttpClient(); // Client HTTP pour les requêtes API

  /// Vérifie que l'utilisateur est authentifié avant d'effectuer des opérations
  /// Tente une initialisation si nécessaire
  /// @returns true si l'authentification est valide
  Future<bool> _ensureAuthenticated() async {
    if (!UserProvider.isAuthenticated) {
      return await UserProvider.initialize();
    }
    return true;
  }

  /// Envoie un message à un utilisateur spécifique
  /// Le message est stocké dans une "salle de chat" unique pour les deux utilisateurs
  /// @param receiverId ID de l'utilisateur destinataire
  /// @param message Contenu du message à envoyer
  /// @throws Exception si l'authentification échoue ou si l'envoi est impossible
  Future<void> sendMessage(String receiverId, String message) async {
    if (!await _ensureAuthenticated()) {
      throw Exception('Authentification requise');
    }

    try {
      final currentUser = UserProvider.user!;

      // Prevent sending messages to self
      if (currentUser.id.toString() == receiverId) {
        throw Exception('You cannot send messages to yourself');
      }

      final timestamp = Timestamp.now();

      // Validate IDs
      final senderId = currentUser.id.toString();

      Map<String, dynamic> newMessage = {
        'senderId': senderId, // Store Strapi user ID as string
        'receiverId': receiverId,
        'content': message,
        'createdAt': timestamp,
        'updatedAt': timestamp,
        'status': 'SENT'
      };

      // Create chat room ID using Strapi IDs
      List<String> ids = [senderId, receiverId];
      ids.sort();
      String chatRoomID = ids.join("_");

      // Reference to the chat document
      final chatDocRef = _firestore.collection("chats").doc(chatRoomID);

      // Create batch to ensure atomic operations
      final batch = _firestore.batch();

      // Set chat room data
      batch.set(
          chatDocRef,
          {
            'participants': [senderId, receiverId],
            'lastMessage': message,
            'lastMessageTime': timestamp,
            'updatedAt': timestamp,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      // Add message to subcollection
      final messageRef = chatDocRef.collection("messages").doc();
      batch.set(messageRef, newMessage);

      // Commit the batch
      await batch.commit();

      print('Successfully sent message to chat room: $chatRoomID');
      print('Message data: $newMessage');

      notifyListeners();
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userId, otherUserId) async* {
    try {
      if (!await _ensureAuthenticated()) {
        print('❌ Authentication required');
        yield* Stream.empty();
        return;
      }

      // Create unique chat room ID
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomID = ids.join("_");

      print('📥 Getting messages from room: $chatRoomID');

      // Verify the chat room exists
      final chatDoc =
          await _firestore.collection("chats").doc(chatRoomID).get();

      if (!chatDoc.exists) {
        // Create chat room if it doesn't exist
        await _firestore.collection("chats").doc(chatRoomID).set({
          'participants': ids,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      yield* _firestore
          .collection("chats")
          .doc(chatRoomID)
          .collection("messages")
          .orderBy("createdAt", descending: true)
          .snapshots();
    } catch (e) {
      print('❌ Error getting messages: $e');
      yield* Stream.empty();
    }
  }

  // Get user stream
  Future<List<Map<String, dynamic>>> getUsers() async {
    if (!await _ensureAuthenticated()) {
      throw Exception('Authentication required');
    }

    try {
      // Force refresh current user
      final authService = AuthService();
      final freshUser = await authService.getCurrentUser();
      final currentRole = freshUser.roleType.toUpperCase();

      print('🔍 Fresh user role from getCurrentUser: $currentRole');

      // Construction de l'URL en fonction du rôle
      String url = '';
      if (currentRole == 'PATIENT') {
        // Pour les patients, obtenir les docteurs approuvés
        url =
            '${AuthService.baseUrl}/users?populate[doctor][populate]=*&filters[roleType]=DOCTOR';
      } else if (currentRole == 'DOCTOR') {
        // Pour les docteurs, obtenir tous les patients
        url =
            '${AuthService.baseUrl}/users?filters[roleType]=PATIENT&populate=*';
      }

      final response = await _httpClient.get(url);
      print('📥 Raw API Response: $response');

      final List<Map<String, dynamic>> filteredUsers = [];

      if (response is List) {
        // Traitement direct si c'est une liste
        for (var user in response) {
          if (user is! Map) continue;

          if (currentRole == 'PATIENT') {
            // Vérifier si le docteur est approuvé
            final doctor = user['doctor'];
            final isApproved = doctor?['isApproved'] ?? false;

            if (isApproved) {
              filteredUsers.add({
                'id': user['id'].toString(),
                'name': user['name'] ?? user['username'] ?? 'Unknown',
                'email': user['email'] ?? '',
                'roleType': 'DOCTOR',
                'speciality': doctor?['speciality'] ?? '',
              });
            }
          } else if (currentRole == 'DOCTOR' &&
              user['roleType']?.toString().toUpperCase() == 'PATIENT') {
            filteredUsers.add({
              'id': user['id'].toString(),
              'name': user['name'] ?? user['username'] ?? 'Unknown',
              'email': user['email'] ?? '',
              'roleType': 'PATIENT',
            });
          }
        }
      }

      print('✅ Filtered users: ${filteredUsers.length}');
      return filteredUsers;
    } catch (e) {
      print('❌ Error fetching users: $e');
      return [];
    }
  }

  // Get all users except blocked users
  Future<List<Map<String, dynamic>>> getUsersExceptBlocked() async {
    if (UserProvider.user == null) return [];

    final currentUserId = UserProvider.user!.id;
    // final blockedUsers = await getBlockedUsers();
    // final blockedUserIds = blockedUsers.map((u) => u['id'].toString()).toList();
    final blockedUserIds = [];

    final users = await getUsers();
    return users
        .where((user) =>
            user['id'].toString() != currentUserId.toString() &&
            !blockedUserIds.contains(user['id'].toString()))
        .toList();
  }

  // Report User
  Future<void> reportUser(String messageId, String userId) async {
    if (UserProvider.user == null) return;

    await _httpClient.post('${AuthService.baseUrl}/reports', body: {
      'reportedBy': UserProvider.user!.id,
      'messageId': messageId,
      'messageOwnerId': userId,
    });
  }

  // Block User
  Future<void> blockUser(String userId) async {
    if (UserProvider.user == null) return;

    await _httpClient.post('${AuthService.baseUrl}/blocked-users', body: {
      'blockedUserId': userId,
      'userId': UserProvider.user!.id,
    });
    notifyListeners();
  }

  // Unblock User
  Future<void> unblockUser(String blockedUserId) async {
    if (UserProvider.user == null) return;

    await _httpClient
        .delete('${AuthService.baseUrl}/blocked-users/$blockedUserId');
    notifyListeners();
  }

  // Get Blocked Users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    if (UserProvider.user == null) return [];

    final response =
        await _httpClient.get('${AuthService.baseUrl}/blocked-users');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> clearMessagingCache() async {
    try {
      // Clear Firebase cache
      await _firestore.terminate();
      await _firestore.clearPersistence();
      print('🗑️ Firebase messaging cache cleared');
    } catch (e) {
      print('❌ Error clearing Firebase cache: $e');
    }
  }
}
