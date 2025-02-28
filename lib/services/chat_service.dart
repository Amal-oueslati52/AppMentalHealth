import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message.dart';

// Service de chat qui gère l'envoi des messages à l'API et la réception des réponses
class ChatService {
  // URL de base de l'API Groq pour les requêtes de complétion de chat
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Instance de Dio pour effectuer les requêtes HTTP
  final _dio = Dio();

  // Méthode pour formater les messages avant de les envoyer à l'API
  List<Map<String, String>> _prepareMessages(List<Message> messages) {
    final List<Map<String, String>> formattedMessages = [];

    // Ajouter un message système
    formattedMessages.add({
      "role": "system",
      "content":
          "You are an assistant of a mental health application. Answer briefly and empathetically."
    });

    // Formater les messages de l'utilisateur et de l'assistant
    for (final message in messages) {
      String role = message.isUser ? 'user' : 'assistant';
      formattedMessages.add({
        'role': role,
        'content': message.content,
      });
    }

    return formattedMessages;
  }

  // Méthode pour envoyer un message et récupérer la réponse du chatbot
  Future<String> sendMessage(List<Message> messages) async {
    try {
      final formattedMessages = _prepareMessages(messages);

      // Envoi d'une requête POST à l'API
      final response = await _dio.post(
        _baseUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json', // Spécifie le format JSON
            'Authorization':
                'Bearer ${dotenv.env['GROQ_API_KEY']}', // Clé API stockée dans un fichier .env
          },
        ),
        data: {
          'messages': formattedMessages, // Envoie les messages formatés
          'model':
              'llama-3.3-70b-versatile', // Spécifie le modèle utilisé pour la génération de texte
        },
      );

      // Utiliser l'opérateur ternaire pour vérifier le statut de la réponse
      return response.statusCode == 200
          ? response.data['choices'][0]['message']
              ['content'] // Récupère la réponse du chatbot
          : throw Exception(
              'Failed to get response: ${response.statusCode}'); // Erreur si le statut est différent de 200
    } on DioException catch (e) {
      // Gestion des erreurs spécifiques à Dio (problèmes de connexion, timeout, etc.)
      throw Exception('Dio error: ${e.message}');
    } catch (e) {
      // Gestion des autres erreurs
      throw Exception('Error sending message: $e');
    }
  }
}
