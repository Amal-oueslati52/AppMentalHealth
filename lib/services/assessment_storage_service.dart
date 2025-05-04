import 'dart:convert';
import '../models/assessment_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssessmentStorageService {
  static const String _storageKey = 'assessment_sessions';

  Future<void> saveSession(AssessmentSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessions = await getSessions();
      sessions.add(session);

      final jsonList = sessions.map((s) => s.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));

      print('✅ Session sauvegardée avec succès');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde: $e');
      throw Exception('Erreur de sauvegarde: $e');
    }
  }

  Future<List<AssessmentSession>> getSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => AssessmentSession.fromJson(json)).toList();
    } catch (e) {
      print('❌ Erreur lors de la lecture: $e');
      return [];
    }
  }
}
