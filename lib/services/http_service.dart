import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage.dart';

class HttpClient {
  final StorageService _storage = StorageService();

  Future<dynamic> get(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to make request: $e');
    }
  }

  Future<dynamic> post(String url, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      print('📤 Making POST request to: $url');
      print('📤 Request body: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }

      throw Exception(
          'Request failed with status: ${response.statusCode}\nResponse: ${response.body}');
    } catch (e) {
      print('❌ POST request failed: $e');
      rethrow;
    }
  }

  Future<dynamic> put(String url, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to make PUT request: $e');
    }
  }

  Future<dynamic> delete(String url) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return response.statusCode == 200 ? json.decode(response.body) : null;
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to make DELETE request: $e');
    }
  }

  Future<void> clearCache() async {
    // Clear any cached headers or responses
    print('🗑️ HTTP client cache cleared');
  }

  Future<Map<String, String>> _getHeaders() async {
    // Always get fresh token
    final token = await _storage.getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
