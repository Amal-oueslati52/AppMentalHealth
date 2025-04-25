import 'package:app/services/strapi_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:app/pages/HomeScreen.dart';
import 'package:app/toast/toast.dart';
import 'package:logger/logger.dart';

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final AuthService _authService = AuthService();
  final Logger _logger = Logger();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _objectifController = TextEditingController();

  bool _isLoading = false;

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
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final genre = _genreController.text.trim();
    final age = _ageController.text.trim();
    final objectif = _objectifController.text.trim();

    // Validate required fields
    if (email.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        genre.isEmpty ||
        age.isEmpty ||
        objectif.isEmpty) {
      showToast(message: "All fields must be filled");
      return;
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      showToast(message: "Invalid email format");
      return;
    }

  

    // Validate age is a number
    if (int.tryParse(age) == null) {
      showToast(message: "Age must be a valid number");
      return;
    }

    _setLoading(true);
    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
        genre: genre,
        objectif: objectif,
      );
      showToast(message: "Account created successfully");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } catch (e) {
      _logger.e('Sign up error: $e');
      showToast(message: "Registration failed");
    } finally {
      _setLoading(false);
    }
  }

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

  InputDecoration _inputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white),
      border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white)),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white)),
      suffixIcon: Icon(icon, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _nameController,
                      decoration: _inputDecoration("Name", Icons.person)),
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
                  
                  TextField(
                      controller: _genreController,
                      decoration: _inputDecoration("Genre", Icons.person)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _ageController,
                      decoration: _inputDecoration("Age", Icons.cake)),
                  const SizedBox(height: 20),
                  TextField(
                      controller: _objectifController,
                      decoration: _inputDecoration("Objectif", Icons.star)),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign Up',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
