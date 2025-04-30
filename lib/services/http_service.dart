import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage.dart';

class HttpClient {
  final StorageService _storage = StorageService();

  // Ajouter cette méthode pour gérer les en-têtes
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> get(String url) async {
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
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to make POST request: $e');
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
}
