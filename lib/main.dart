import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app/patient/splash_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD6McMzcCR-PIHgHw-YN-ctpopOJjbCvLI",
        appId: "1:709467509181:android:4adbf5132d733552b882d4",
        messagingSenderId: "709467509181",
        projectId: "app1-40a70",
        storageBucket: "app1-40a70.firebasestorage.app",
      ),
    );

    // Initialize notifications after Firebase
    await _initializeNotifications();

    // Then enable Firebase services
    await FirebaseAuth.instance.signInAnonymously();
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          AndroidProvider.debug, // Change to playIntegrity for production
      appleProvider: AppleProvider.deviceCheck,
    );

    print("✅ Firebase initialized with notifications");
  } catch (e) {
    print("❌ Error initializing Firebase: $e");
  }

  await dotenv.load(fileName: ".env");
  print("Environment variables loaded");
  runApp(const MyApp());
}

Future<void> _initializeNotifications() async {
  // Request permission
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // Get FCM token
  final token = await messaging.getToken();
  print("📱 FCM Token: $token");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(),
    );
  }
}
