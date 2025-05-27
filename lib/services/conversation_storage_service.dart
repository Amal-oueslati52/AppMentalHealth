import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ConversationStorageService {
  final String _baseUrl = Platform.isAndroid
      ? 'http://192.168.208.250:1337/api'
      : 'http://localhost:1337/api';

  Future<void> saveConversation({
    required List<Map<String, dynamic>> messages,
    required String userId,
  }) async {
    try {
      // First get patient document ID
      final patientResponse = await http.get(
        Uri.parse(
            '$_baseUrl/patients?filters[users_permissions_user][id]=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final patientData = json.decode(patientResponse.body);
      if ((patientData['data'] as List).isEmpty) {
        throw Exception('Patient not found');
      }

      final patientDocumentId = patientData['data'][0]['id'];

      final data = {
        'data': {
          'type': 'CHAT',
          'message': {
            'text': messages.last['content'],
            'conversation': messages,
          },
          'patient': patientDocumentId, // Use document ID directly
          'publishedAt': DateTime.now().toIso8601String()
        }
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(data),
      );

      print('✅ Response status: ${response.statusCode}');
      print('✅ Response body: ${response.body}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}
