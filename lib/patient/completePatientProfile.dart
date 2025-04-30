import 'package:app/toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:app/services/strapi_auth_service.dart';
import 'package:app/patient/HomeScreen.dart';

class CompletePatientProfile extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CompletePatientProfile({Key? key, required this.userData})
      : super(key: key);

  @override
  _CompletePatientProfileState createState() => _CompletePatientProfileState();
}

class _CompletePatientProfileState extends State<CompletePatientProfile> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  DateTime? _birthdate;
  bool _isLoading = false;

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      if (_birthdate == null) {
        showToast(message: "Please select birthdate");
        return;
      }

      // Se reconnecter avec les informations d'authentification
      await _authService.login(
        widget.userData['user']['email'],
        widget.userData['password'], // Maintenant disponible
      );

      // Créer le profil patient
      await _authService.createPatientProfile(
        userId: widget.userData['user']['id'],
        birthdate: _birthdate!,
      );

      // Mettre à jour le profil utilisateur
      await _authService.updateProfile({
        'birthdate': _birthdate!.toIso8601String(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      showToast(message: e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _birthdate = date);
                  }
                },
                child: Text(_birthdate == null
                    ? 'Select Birthdate'
                    : 'Birthdate: ${_birthdate.toString().split(' ')[0]}'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleComplete,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Complete Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
