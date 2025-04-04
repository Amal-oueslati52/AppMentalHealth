import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/pages/HomeScreen.dart';
import 'package:app/pages/sign_up.dart';
import 'package:app/toast/toast.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn(); // Vérifier si l'utilisateur est déjà connecté
  }

  Future<void> _checkIfLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken'); // Récupérer le token

    if (token != null && _auth.currentUser != null) {
      try {
        // Rafraîchir le token pour s'assurer qu'il est valide
        String? refreshedToken = await _auth.currentUser?.getIdToken(true);
        if (refreshedToken != null) {
          await saveToken(refreshedToken);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } catch (e) {
        print("Erreur lors du rafraîchissement du token : $e");
      }
    }
  }

  Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token); // Sauvegarder le token
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showToast(message: "Veuillez entrer votre email et mot de passe.");
      setState(() => _isLoading = false);
      return;
    }

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = userCredential.user;

      if (user != null) {
        if (user.emailVerified) {
          showToast(message: "Connexion réussie !");

          // Sauvegarder le token JWT Firebase
          String? token = await user.getIdToken();
          await saveToken(token!);

          // Rediriger vers l'écran principal
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          showToast(
              message:
                  "Veuillez vérifier votre email. Un email de vérification a été envoyé.");
          await user.sendEmailVerification(); // Envoyer un email de vérification
          await _auth.signOut(); // Déconnexion de l'utilisateur
        }
      }
    } on FirebaseAuthException catch (e) {
      showToast(message: _getFirebaseErrorMessage(e.code));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        showToast(message: "Connexion Google annulée.");
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        showToast(message: "Connexion Google réussie !");

        // Sauvegarder le token JWT Firebase
        String? token = await user.getIdToken();
        await saveToken(token!);

        // Rediriger vers l'écran principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      showToast(message: _getFirebaseErrorMessage(e.code));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case "invalid-email":
        return "Format d'email invalide.";
      case "user-not-found":
        return "Aucun utilisateur trouvé avec cet email.";
      case "wrong-password":
        return "Mot de passe incorrect.";
      case "user-disabled":
        return "Ce compte a été désactivé.";
      case "too-many-requests":
        return "Trop de tentatives. Réessayez plus tard.";
      case "operation-not-allowed":
        return "Méthode de connexion non autorisée.";
      case "network-request-failed":
        return "Erreur réseau. Vérifiez votre connexion.";
      default:
        return "Une erreur s'est produite. Veuillez réessayer.";
    }
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      showToast(
          message:
              "Veuillez entrer votre email pour réinitialiser le mot de passe.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      showToast(message: "Lien de réinitialisation envoyé à votre email.");
    } on FirebaseAuthException catch (e) {
      showToast(message: _getFirebaseErrorMessage(e.code));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
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
                const SizedBox(height: 60),
                const Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Champ Email
                TextField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  decoration: _inputDecoration('Email', Icons.email),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                ),

                const SizedBox(height: 20),

                // Champ Password
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  decoration: _inputDecoration('Mot de passe', Icons.lock),
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 30),

                // Bouton Login
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Connexion',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Bouton Google Sign-In
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon: Image.asset('assets/icones/logoGoogle.png', height: 20),
                  label: const Text(
                    'Connexion avec Google',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                  ),
                ),

                const SizedBox(height: 20),

                // Créer un compte & Mot de passe oublié
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUp()),
                          );
                        },
                        child: const Text(
                          'Créer un compte',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: _resetPassword,
                        child: const Text(
                          'Mot de passe oublié ?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
}