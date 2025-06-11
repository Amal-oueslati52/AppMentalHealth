import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:rahti/patient/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase first
    await Firebase.initializeApp();

    // Initialize notifications after Firebase
    await _initializeNotifications();    // Enable Firebase services after initialization only in debug mode
    if (kDebugMode) {
      await _initializeFirebaseServices();
    }

    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      print("Environment variables loaded");
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ Error during initialization: $e");
    }
  }

  runApp(const MyApp());
}

Future<void> _initializeFirebaseServices() async {
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.deviceCheck,
    );
    if (kDebugMode) {
      print("✅ Firebase services initialized");
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ Error initializing Firebase services: $e");
    }
  }
}

Future<void> _initializeNotifications() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (kDebugMode) {
      print("📱 FCM Token: $token");
    }
  } catch (e) {
    if (kDebugMode) {
      print("❌ Error initializing notifications: $e");
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mental Health App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}
