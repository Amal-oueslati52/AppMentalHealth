import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:app/patient/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with your configurations
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyD6McMzcCR-PIHgHw-YN-ctpopOJjbCvLI",
        appId: "1:709467509181:android:4adbf5132d733552b882d4",
        messagingSenderId: "709467509181",
        projectId: "app1-40a70",
        storageBucket: "app1-40a70.firebasestorage.app",
      ),
    );

    // Enable anonymous auth
    await FirebaseAuth.instance.signInAnonymously();

    // Initialize App Check after Firebase
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          AndroidProvider.debug, // Change to playIntegrity for production
      appleProvider: AppleProvider.deviceCheck,
    );

    print("Firebase initialized successfully with anonymous auth");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  await dotenv.load(fileName: ".env");
  print("Environment variables loaded");
  runApp(const MyApp());
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
