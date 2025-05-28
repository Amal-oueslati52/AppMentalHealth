import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      // Request notification permissions
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

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📬 Got a message in foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message notification: ${message.notification!.title}');
      print('Message notification: ${message.notification!.body}');
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('📱 Message opened app: ${message.data}');
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📥 Handling background message: ${message.messageId}');
}
