import 'package:app/toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:app/services/strapi_auth_service.dart';
import 'package:app/doctor/pending_approval_screen.dart';

class CompleteDoctorProfile extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CompleteDoctorProfile({Key? key, required this.userData})
      : super(key: key);

  @override
  _CompleteDoctorProfileState createState() => _CompleteDoctorProfileState();
}

class _CompleteDoctorProfileState extends State<CompleteDoctorProfile> {
  final _formKey = GlobalKey<FormState>();
  final _specialityController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleComplete() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final jwt = await _authService.getAuthToken();
      if (jwt == null) {
        throw Exception('No authentication token found');
      }

      await _authService.createDoctorProfile(
        userId: widget.userData['user']['id'],
        speciality: _specialityController.text,
        jwt: jwt,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PendingApprovalScreen()),
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
              TextFormField(
                controller: _specialityController,
                decoration: const InputDecoration(labelText: 'Speciality'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
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
