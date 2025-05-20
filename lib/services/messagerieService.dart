import 'package:app/providers/user_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'strapi_auth_service.dart';
import 'http_service.dart';

class MessagerieService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HttpClient _httpClient = HttpClient();

  Future<bool> _ensureAuthenticated() async {
    if (!UserProvider.isAuthenticated) {
      return await UserProvider.initialize();
    }
    return true;
  }

  // Send message
  Future<void> sendMessage(String receiverId, String message) async {
    if (!await _ensureAuthenticated()) {
      throw Exception('Authentication required');
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
    if (!await _ensureAuthenticated()) {
      throw Exception('Authentication required');
    }

    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomID = ids.join("_");

      print('Fetching messages from chats/$chatRoomID/messages');

      yield* _firestore
          .collection("chats")
          .doc(chatRoomID)
          .collection("messages")
          .orderBy("createdAt", descending: true)
          .snapshots();
    } catch (e) {
      print('Error getting messages: $e');
      throw Exception('Failed to load messages: $e');
    }
  }

  // Get user stream
  Future<List<Map<String, dynamic>>> getUsers() async {
    if (!await _ensureAuthenticated()) {
      throw Exception('Authentication required');
    }

    final response = await _httpClient.get('${AuthService.baseUrl}/users');
    final currentUser = UserProvider.user;

    if (currentUser == null) return [];

    final List<Map<String, dynamic>> allUsers = _parseUsers(response);
    return _filterUsersByRole(allUsers, currentUser.roleType);
  }

  List<Map<String, dynamic>> _parseUsers(dynamic response) {
    if (response is List) {
      return response.map(_mapUser).toList();
    } else if (response is Map && response.containsKey('data')) {
      return (response['data'] as List).map(_mapUser).toList();
    }
    return [];
  }

  Map<String, dynamic> _mapUser(dynamic user) {
    final attrs = user is Map ? user['attributes'] ?? user : user;
    return {
      'id': user['id'].toString(),
      'name': attrs['name'] ?? attrs['username'] ?? '',
      'email': attrs['email'] ?? '',
      'roleType': attrs['roleType'] ?? 'PATIENT',
    };
  }

  List<Map<String, dynamic>> _filterUsersByRole(
      List<Map<String, dynamic>> users, String currentUserRole) {
    final upperRole = currentUserRole.toUpperCase();
    return users.where((user) {
      final userRole = (user['roleType'] ?? '').toString().toUpperCase();
      return (upperRole == 'PATIENT' && userRole == 'DOCTOR') ||
          (upperRole == 'DOCTOR' && userRole == 'PATIENT');
    }).toList();
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
}
