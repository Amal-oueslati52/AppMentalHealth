import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Configuration Firebase pour l'application de santé mentale
/// Cette classe gère les options de configuration Firebase pour différentes plateformes :
/// - Android : Configuration native pour les appareils Android
/// - iOS : Configuration pour les appareils Apple
/// - Web : Configuration pour la version web de l'application
///
/// Fonctionnalités Firebase utilisées :
/// - Authentication : Gestion des connexions et inscriptions
/// - Cloud Firestore : Base de données pour les messages en temps réel
/// - Cloud Messaging : Notifications push
/// - Storage : Stockage des fichiers (images, documents)
/// - App Check : Sécurité supplémentaire
class DefaultFirebaseOptions {
  /// Retourne la configuration appropriée selon la plateforme d'exécution
  /// Cette méthode est appelée automatiquement lors de l'initialisation de Firebase
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_AUTH_DOMAIN',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD6McMzcCR-PIHgHw-YN-ctpopOJjbCvLI',
    appId: '1:709467509181:android:4adbf5132d733552b882d4',
    messagingSenderId: '709467509181',
    projectId: 'app1-40a70',
    storageBucket: 'app1-40a70.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'YOUR_IOS_BUNDLE_ID',
  );
}
