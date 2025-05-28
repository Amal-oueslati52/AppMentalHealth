import 'package:app/services/strapi_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:app/toast/toast.dart';
import 'package:logger/logger.dart';
import 'package:app/patient/completePatientProfile.dart';
import 'package:app/doctor/complete_profile_doctor.dart';
import 'package:app/models/user_role.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();
  UserRole? selectedRole;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _objectifController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _genreController.dispose();
    _ageController.dispose();
    _objectifController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _signUp() async {
    // Validation
    if (selectedRole == null) {
      showToast(message: "Please select a role (PATIENT or DOCTOR)");
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final genre = _genreController.text.trim();
    final age = _ageController.text.trim();
    final objectif = _objectifController.text.trim();

    // Validation des champs
    if ([email, password, name, genre, age, objectif]
        .any((field) => field.isEmpty)) {
      showToast(message: "All fields must be filled");
      return;
    }

    if (!_isValidEmail(email)) {
      showToast(message: "Invalid email format");
      return;
    }

    if (int.tryParse(age) == null) {
      showToast(message: "Age must be a valid number");
      return;
    }

    _setLoading(true);

    try {
      _logger
          .i('Attempting to register user with role: ${selectedRole!.value}');

      // Enregistrement de l'utilisateur
      final userData = await _authService.register(
        email: email,
        password: password,
        name: name,
        genre: genre,
        objectif: objectif,
        role: selectedRole!.value,
        age: age,
      );

      if (!mounted) return;

      _logger
          .i('User registered successfully, proceeding to profile completion');

      // Redirection basée sur le rôle
      if (selectedRole == UserRole.doctor) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompleteDoctorProfile(
              userData: {
                ...userData,
                'password': password,
                'role': selectedRole!.value,
              },
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CompletePatientProfile(
              userData: {
                ...userData,
                'password': password,
                'role': selectedRole!.value,
              },
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Registration error: $e');
      showToast(
          message:
              "Registration failed: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      _setLoading(false);
    }
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<UserRole>(
          value: selectedRole,
          dropdownColor: const Color(0xFF8B94CD),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(Icons.work, color: Colors.white70),
          ),
          items: UserRole.values.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Text(
                role.toString().split('.').last.toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => selectedRole = value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.3)
                      ],
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_add,
                      size: 50,
                      color: Color(0xFF8B94CD),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Créer un compte',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildTextField(
                  controller: _nameController,
                  label: 'Nom complet',
                  icon: Icons.person,
                ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                _buildRoleDropdown(),
                _buildTextField(
                  controller: _genreController,
                  label: 'Genre',
                  icon: Icons.person_outline,
                ),
                _buildTextField(
                  controller: _ageController,
                  label: 'Âge',
                  icon: Icons.cake,
                  keyboardType: TextInputType.number,
                ),
                _buildTextField(
                  controller: _objectifController,
                  label: 'Objectif',
                  icon: Icons.stars,
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.3)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'S\'inscrire',
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
