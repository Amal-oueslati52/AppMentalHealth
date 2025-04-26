import 'package:flutter/material.dart';
import 'package:app/pages/login.dart';
import 'package:app/pages/HomeScreen.dart';
import 'package:app/services/strapi_auth_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  _checkAuthAndNavigate() async {
    await Future.delayed(Duration(seconds: 3));

    bool isAuthenticated = await _authService.isAuthenticated();

    if (!mounted) return;

    if (isAuthenticated) {
      // Récupérer les données utilisateur si authentifié
      try {
        await _authService.getCurrentUser();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (e) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Login()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Image de fond qui couvre tout l'écran
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/backgrounds/background.jpg'),
                  fit: BoxFit.cover, // L'image couvre tout l'écran
                ),
              ),
            ),
          ),
          // Contenu centré
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
