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
      appBar: AppBar(
        title: const Text(
          'Compléter votre profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8E9F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCA88CD).withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFCA88CD),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (date != null) {
                        setState(() => _birthdate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today,
                        color: Color(0xFF8B94CD)),
                    label: Text(
                      _birthdate == null
                          ? 'Sélectionner votre date de naissance'
                          : 'Date de naissance: ${_birthdate.toString().split(' ')[0]}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading
                          ? [Colors.grey, Colors.grey]
                          : [const Color(0xFFCA88CD), const Color(0xFF8B94CD)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCA88CD).withOpacity(0.3),
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
                        borderRadius: BorderRadius.circular(25),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
