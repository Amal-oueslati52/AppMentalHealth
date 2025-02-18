import 'package:app/HomeScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Ajout de Firestore pour gérer les données utilisateur
import 'package:app/toast/toast.dart'; // Importation de la fonction toast pour afficher des messages à l'utilisateur

class SignUp extends StatefulWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  // Initialisation des objets Firebase et des contrôleurs de texte pour les champs du formulaire
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _objectifController = TextEditingController();

  bool _isLoading =
      false; // Variable pour afficher ou non le chargement lors de l'inscription

  // Fonction pour gérer l'inscription
  Future<void> _signUp() async {
    print("➡️ Bouton Sign Up pressé");
    setState(() => _isLoading = true); // Démarre l'indicateur de chargement

    // Récupération des valeurs saisies dans les champs de texte
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();
    String name = _nameController.text.trim();
    String genre = _genreController.text.trim();
    String age = _ageController.text.trim();
    String objectif = _objectifController.text.trim();

    print(" Email: $email");
    print(" Password: $password");
    print(" Name: $name");
    print(" Genre: $genre");
    print(" Age: $age");
    print(" Objectif: $objectif");

    // Validation des champs de saisie
    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        name.isEmpty ||
        genre.isEmpty ||
        age.isEmpty ||
        objectif.isEmpty) {
      print("⚠️ Un champ est vide");
      showToast(
          message:
              "All fields are required"); // Affiche un message si un champ est vide
      setState(() => _isLoading = false); // Arrête l'indicateur de chargement
      return;
    }

    // Vérification que le mot de passe et la confirmation correspondent
    if (password != confirmPassword) {
      print("⚠️ Les mots de passe ne correspondent pas");
      showToast(
          message:
              "Passwords do not match"); // Affiche un message si les mots de passe ne correspondent pas
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Tentative de création de l'utilisateur dans Firebase
      print("🚀 Tentative de création de l'utilisateur Firebase");
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("✅ Utilisateur créé avec UID: ${userCredential.user?.uid}");

      // Sauvegarde des informations de l'utilisateur dans Firestore
      print("📂 Sauvegarde des infos utilisateur dans Firestore");
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'genre': genre,
        'age': age,
        'objectif': objectif,
        'createdAt': Timestamp.now(), // Date de création du compte
      });
      print("✅ Infos utilisateur enregistrées");

      showToast(message: "Account created successfully!"); // Message de succès

      // Navigation vers l'écran d'accueil une fois l'inscription terminée
      print("➡️ Navigation vers HomeScreen");
      if (!mounted)
        return; // Vérifie que le widget est toujours présent avant de naviguer
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                const HomeScreen()), // Navigation vers l'écran principal
      );
    } on FirebaseAuthException catch (e) {
      // Gestion des erreurs liées à Firebase
      print("❌ Erreur Firebase: ${e.code}");
      showToast(
          message: _getFirebaseErrorMessage(
              e.code)); // Affiche un message d'erreur spécifique
    } catch (e) {
      // Gestion des erreurs inattendues
      print("❌ Erreur inattendue: $e");
      showToast(message: "An error occurred. Please try again.");
    } finally {
      // Arrête l'indicateur de chargement après l'exécution du processus
      print("⏳ Fin du processus d'inscription");
      setState(() => _isLoading = false);
    }
  }

  // Fonction pour récupérer un message d'erreur spécifique basé sur le code d'erreur Firebase
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case "email-already-in-use":
        return "This email is already registered.";
      case "invalid-email":
        return "Invalid email format.";
      case "weak-password":
        return "Password should be at least 6 characters.";
      default:
        return "An error occurred. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Fond avec un gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8E44AD),
                    Color(0xFF3498DB),
                    Color(0xFF1ABC9C),
                  ],
                ),
              ),
            ),
            // Formulaire d'inscription
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
                  // Champs pour le nom
                  TextField(
                    controller: _nameController,
                    decoration: _inputDecoration("Name", Icons.person),
                  ),
                  const SizedBox(height: 20),
                  // Champs pour l'email
                  TextField(
                    controller: _emailController,
                    decoration: _inputDecoration("Email", Icons.email),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  // Champs pour le mot de passe
                  TextField(
                    controller: _passwordController,
                    decoration: _inputDecoration("Password", Icons.lock),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  // Champs pour la confirmation du mot de passe
                  TextField(
                    controller: _confirmPasswordController,
                    decoration:
                        _inputDecoration("Confirm Password", Icons.lock),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  // Champs pour le genre
                  TextField(
                    controller: _genreController,
                    decoration: _inputDecoration("Genre", Icons.person),
                    obscureText: false,
                  ),
                  const SizedBox(height: 20),
                  // Champs pour l'âge
                  TextField(
                    controller: _ageController,
                    decoration: _inputDecoration("Age", Icons.person),
                    obscureText: false,
                  ),
                  const SizedBox(height: 20),
                  // Champs pour l'objectif
                  TextField(
                    controller: _objectifController,
                    decoration: _inputDecoration("Objectif", Icons.star),
                    obscureText: false,
                  ),

                  const SizedBox(height: 30),

                  // Bouton pour soumettre l'inscription
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 50, vertical: 15)),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Sign Up',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fonction pour styliser les champs de saisie
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
}
