import 'package:app/services/strapi_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:app/toast/toast.dart';
import 'package:logger/logger.dart';
import 'package:app/patient/completePatientProfile.dart';
import 'package:app/doctor/completeProfileDoctor.dart';
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
    if ([email, password, name, genre, age, objectif].any((field) => field.isEmpty)) {
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
      _logger.i('Attempting to register user with role: ${selectedRole!.value}');
      
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

      _logger.i('User registered successfully, proceeding to profile completion');

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
      showToast(message: "Registration failed: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      _setLoading(false);
    }
  }

  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      suffixIcon: Icon(icon, color: Colors.white),
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
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: _inputDecoration("Name", Icons.person),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: _inputDecoration("Email", Icons.email),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  decoration: _inputDecoration("Password", Icons.lock),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: _inputDecoration("Select Role", Icons.work),
                  dropdownColor: Colors.teal,
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(
                        role.toString().split('.').last.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _genreController,
                  decoration: _inputDecoration("Genre", Icons.person),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _ageController,
                  decoration: _inputDecoration("Age", Icons.cake),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _objectifController,
                  decoration: _inputDecoration("Objectif", Icons.star),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical: 15,
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
