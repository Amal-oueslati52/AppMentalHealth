import 'package:firebase_messaging/firebase_messaging.dart';

/// Service de gestion des notifications push
/// Utilise Firebase Cloud Messaging (FCM) pour :
/// - Gérer les notifications en premier plan et en arrière-plan
/// - Gérer les permissions de notifications
/// - Traiter les actions utilisateur sur les notifications
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Initialise le service de notifications
  /// - Demande les permissions nécessaires
  /// - Récupère le token FCM
  /// - Configure les handlers de messages
  Future<void> initialize() async {
    try {
      // Demande des permissions de notification à l'utilisateur
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $token');

      // Configure message handling
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    } catch (e) {
      print('❌ Error initializing notifications: $e');
    }
  }

  /// Gestion des messages reçus lorsque l'application est au premier plan
  /// Affiche les notifications et traite les données associées
  /// @param message Le message FCM reçu
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📬 Réception d\'un message en premier plan !');
    print('Données du message : ${message.data}');

    if (message.notification != null) {
      print('Titre de la notification : ${message.notification!.title}');
      print('Contenu de la notification : ${message.notification!.body}');
    }
  }

  /// Gestion des actions utilisateur sur les notifications
  /// Appelé quand l'utilisateur tape sur une notification pour ouvrir l'app
  /// @param message Le message FCM qui a déclenché l'ouverture
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('📱 Ouverture de l\'app via notification : ${message.data}');
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📥 Handling background message: ${message.messageId}');
}
