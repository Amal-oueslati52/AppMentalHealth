import 'package:rahti/toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:rahti/services/strapi_auth_service.dart';
import 'package:rahti/patient/home_screen.dart';

class CompletePatientProfile extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CompletePatientProfile({super.key, required this.userData});

  @override
  State<CompletePatientProfile> createState() => _CompletePatientProfileState();
}

class _CompletePatientProfileState extends State<CompletePatientProfile> {
  static const Color kPrimaryColor = Color(0xFFCA88CD);
  static const Color kSecondaryColor = Color(0xFF8B94CD);
  static const double kButtonHeight = 50.0;
  static const double kBorderRadius = 25.0;
  static const double kSpacing = 16.0;
  static const String kDatePlaceholder = 'Sélectionner votre date de naissance';

  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  DateTime? _birthdate;
  bool _isLoading = false;

  String _formatDate(DateTime date) => date.toString().split(' ')[0];

  Future<void> _selectBirthdate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: kPrimaryColor),
        ),
        child: child!,
      ),
    );

    if (date != null && mounted) {
      setState(() => _birthdate = date);
    }
  }

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthdate == null) {
      showToast(message: "Veuillez sélectionner votre date de naissance");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(
        widget.userData['user']['email'],
        widget.userData['password'],
      );

      await _authService.createPatientProfile(
        userId: widget.userData['user']['id'],
        birthdate: _birthdate!,
      );

      await _authService.updateProfile({
        'birthdate': _birthdate!.toIso8601String(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      showToast(message: e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDatePicker() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: kSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kBorderRadius / 2),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: _selectBirthdate,
        icon: const Icon(Icons.calendar_today, color: kSecondaryColor),
        label: Text(
          _birthdate == null
              ? kDatePlaceholder
              : 'Date de naissance: ${_formatDate(_birthdate!)}',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: kButtonHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading
              ? [Colors.grey, Colors.grey]
              : [kPrimaryColor, kSecondaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withAlpha(76),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleComplete,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Compléter le profil',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Compléter votre profil',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryColor, kSecondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8E9F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kSpacing),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDatePicker(),
                  const SizedBox(height: kSpacing * 1.5),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
