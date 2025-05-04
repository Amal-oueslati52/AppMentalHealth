import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/message.dart';
import '../services/assessment_storage_service.dart';
import '../models/assessment_session.dart';

// Service de chat qui gère l'envoi des messages à l'API et la réception des réponses
class ChatService {
  // URL de base de l'API Groq pour les requêtes de complétion de chat
  final String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  // Instance de Dio pour effectuer les requêtes HTTP
  final _dio = Dio();

  // Instance du service de stockage des évaluations
  final AssessmentStorageService _storageService = AssessmentStorageService();

  final Map<String, List<Map<String, String>>> _psychAssessment = {
    'fr': [
      {
        'question': "Décrivez votre humeur aujourd'hui en quelques mots.",
        'context': "Évaluation rapide de l'état émotionnel"
      },
      {
        'question': "Comment dormez-vous la nuit?",
        'context': "Qualité du sommeil"
      },
      {
        'question': "Qu'est-ce qui vous stresse le plus actuellement?",
        'context': "Sources de stress"
      },
      {
        'question': "Avez-vous des pensées négatives répétitives?",
        'context': "Patterns de pensée"
      },
      {
        'question': "Sur 10, quel est votre niveau d'énergie?",
        'context': "Niveau de vitalité"
      }
    ],
    'en': [
      {
        'question': "Describe your mood today in a few words.",
        'context': "Quick emotional assessment"
      },
      {'question': "How do you sleep at night?", 'context': "Sleep quality"},
      {
        'question': "What stresses you the most right now?",
        'context': "Stress sources"
      },
      {
        'question': "Do you have recurring negative thoughts?",
        'context': "Thought patterns"
      },
      {
        'question': "Out of 10, what's your energy level?",
        'context': "Vitality level"
      }
    ],
    'ar': [
      {
        'question': "صف مزاجك اليوم بكلمات قليلة.",
        'context': "تقييم سريع للحالة العاطفية"
      },
      {'question': "كيف تنام في الليل؟", 'context': "جودة النوم"},
      {'question': "ما الذي يسبب لك التوتر حالياً؟", 'context': "مصادر التوتر"},
      {'question': "هل لديك أفكار سلبية متكررة؟", 'context': "أنماط التفكير"},
      {'question': "من 10، ما هو مستوى طاقتك؟", 'context': "مستوى النشاط"}
    ]
  };

  // Méthode pour formater les messages avant de les envoyer à l'API
  List<Map<String, String>> _prepareMessages(List<Message> messages,
      {bool isAssessment = false,
      int questionCount = 0,
      String selectedLanguage = 'fr'}) {
    final List<Map<String, String>> formattedMessages = [];

    if (!isAssessment) {
      formattedMessages.add({
        "role": "system",
        "content":
            "Vous êtes un assistant de l'application de suivi de la santé mentale. Répondez toujours de manière empathique et professionnelle. Commencez toujours vos réponses par 'En tant qu'assistant de suivi de la santé mentale, ...' quand c'est approprié."
      });
    }

    if (isAssessment) {
      final assessment = _psychAssessment[selectedLanguage]!;
      final currentQuestion =
          questionCount < assessment.length ? assessment[questionCount] : null;

      String systemPrompt = """
      Psychologue professionnel effectuant une évaluation rapide.
      Question ${questionCount + 1}/5

      DIRECTIVES:
      1. Posez uniquement la question suivante: "${currentQuestion?['question'] ?? ''}"
      2. Après la réponse: bref feedback (1 ligne) et question suivante
      3. Au 5ème message: générez un rapport concis:

      [SYNTHÈSE]
      - Points clés observés
      - Niveau de stress/fatigue mentale identifié
      
      [EXERCICES DE RELAXATION]
      Si stress ou fatigue mentale détectés :
      - 2-3 exercices de respiration ou méditation
      - Une technique de relaxation musculaire progressive
      - Un exercice de visualisation positive

      [RECOMMANDATIONS]
      - 2-3 conseils pratiques quotidiens
      - Suggestions d'habitudes apaisantes
      - Techniques de gestion du stress immédiate

      Style: professionnel mais bref et direct
      Langue: ${_getLanguagePrompt(selectedLanguage)}
      """;

      formattedMessages.add({"role": "system", "content": systemPrompt});
    }

    // Ajouter l'historique des messages
    formattedMessages.addAll(messages.map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.content,
        }));

    return formattedMessages;
  }

  String _getLanguagePrompt(String lang) {
    switch (lang) {
      case 'fr':
        return 'Communiquer en français uniquement';
      case 'ar':
        return 'التواصل باللغة العربية فقط';
      case 'en':
        return 'Communicate in English only';
      default:
        return 'Communiquer en français uniquement';
    }
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

  // Méthode pour démarrer une auto-évaluation
  Future<Map<String, dynamic>> startAssessment(String language) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
        }),
        data: {
          'messages': _prepareMessages([],
              isAssessment: true, selectedLanguage: language),
          'model': 'llama-3.3-70b-versatile',
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return {
        'message': content,
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'start',
        'questionCount': 1,
      };
    } catch (e) {
      print('❌ Error starting assessment: $e');
      throw Exception('Failed to start assessment: $e');
    }
  }

  // Méthode pour continuer une auto-évaluation
  Future<Map<String, dynamic>> continueAssessment(
      List<Message> conversation, String userId, String language) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${dotenv.env['GROQ_API_KEY']}',
        }),
        data: {
          'messages': _prepareMessages(conversation,
              isAssessment: true, selectedLanguage: language),
          'model': 'llama-3.3-70b-versatile',
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      final isReport =
          content.contains('Résumé') || content.contains('Recommandations');

      if (isReport) {
        // Sauvegarder la session complète
        final session = AssessmentSession(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: userId,
          timestamp: DateTime.now(),
          conversation: conversation,
          report: content,
          isComplete: true,
        );
        await _storageService.saveSession(session);
      }

      return {
        'message': content,
        'timestamp': DateTime.now().toIso8601String(),
        'type': isReport ? 'report' : 'question',
        'isComplete': isReport,
      };
    } catch (e) {
      print('❌ Error: $e');
      return {'error': e.toString()};
    }
  }
}
