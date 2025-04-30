import 'package:flutter/material.dart';
import 'package:app/patient/login.dart';
import 'package:app/patient/HomeScreen.dart';
import 'package:app/doctor/doctorHome.dart';
import 'package:app/doctor/pending_approval_screen.dart';
import 'package:app/doctor/completeProfileDoctor.dart';
import 'package:app/patient/completePatientProfile.dart';
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
    _checkAuthAndProfile();
  }

  Future<void> _checkAuthAndProfile() async {
    try {
      await Future.delayed(const Duration(seconds: 3));

      final bool isAuthenticated = await _authService.isAuthenticated();
      if (!isAuthenticated) {
        _navigateToLogin();
        return;
      }

      final user = await _authService.getCompleteUserData();
      if (!mounted) return;

      if (user.roleType == 'DOCTOR') {
        if (!user.isProfileComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CompleteDoctorProfile(
                userData: {'user': user.toString()},
              ),
            ),
          );
        } else if (!user.isApproved) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PendingApprovalScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DoctorHome()),
          );
        }
      } else {
        if (!user.isProfileComplete) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CompletePatientProfile(
                userData: {'user': user.toString()},
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
    );
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
