import 'package:flutter/material.dart';
import 'package:rahti/patient/login.dart';
import 'package:rahti/patient/home_screen.dart';
import 'package:rahti/doctor/doctor_home.dart';
import 'package:rahti/doctor/pending_approval_screen.dart';
import 'package:rahti/doctor/complete_profile_doctor.dart';
import 'package:rahti/patient/complete_patient_profile.dart';
import 'package:rahti/services/strapi_auth_service.dart';

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo container with gradient border
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withAlpha(128),
                      Colors.white.withAlpha(51)
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // App name with modern style
              const Text(
                'rahti',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Tagline with subtle styling
              Text(
                'Votre compagnon de bien-être mental',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withAlpha(204),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 40),
              // Loading indicator
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withAlpha(204),
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
