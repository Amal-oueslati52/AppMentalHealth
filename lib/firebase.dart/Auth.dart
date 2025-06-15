import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPreferences? _prefs;

  // Constructeur qui initialise les préférences partagées
  FirebaseAuthService() {
    _initPrefs();
  }

  // Initialisation des préférences partagées pour stocker les tokens et données de session
  // Cette méthode est appelée automatiquement lors de la création du service
  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Sauvegarder le token dans les préférences partagées
  Future<void> _saveToken(String token) async {
    if (_prefs != null) {
      await _prefs!.setString('authToken', token);
    }
  }

  // Supprimer le token des préférences partagées
  Future<void> _removeToken() async {
    if (_prefs != null) {
      await _prefs!.remove('authToken');
    }
  }

  // Récupérer le token depuis les préférences partagées
  Future<String?> getSavedToken() async {
    if (_prefs != null) {
      return _prefs!.getString('authToken');
    }
    return null;
  }

  // Rafraîchir le token Firebase et le sauvegarder
  Future<String?> getFreshToken() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Force le rafraîchissement du token
        String token = (await user.getIdToken(true)) ?? '';
        await _saveToken(token);
        return token;
      }
    } catch (e) {
      print("Erreur lors du rafraîchissement du token : $e");
    }
    return null;
  }

  // Inscription avec email et mot de passe
  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      print(
          "Inscription réussie pour l'utilisateur : ${credential.user?.email}");
      return credential.user;
    } catch (e) {
      print("Erreur d'inscription : ${e.toString()}");
      return null;
    }
  }

  // Connexion avec email et mot de passe
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      print("Tentative de connexion avec l'email : $email");
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Vérifiez si l'email est vérifié
        if (!credential.user!.emailVerified) {
          print(
              "L'email n'est pas vérifié pour l'utilisateur : ${credential.user!.email}");
          await credential.user!.sendEmailVerification();
          print("Email de vérification envoyé.");
          return null; // Retournez null si l'email n'est pas vérifié
        }

        // Récupérer et sauvegarder le token
        String token = (await credential.user!.getIdToken()) ?? '';
        await _saveToken(token);
        print(
            "Connexion réussie pour l'utilisateur : ${credential.user!.email}");
      }
      return credential.user;
    } catch (e) {
      print("Erreur de connexion : ${e.toString()}");
      return null;
    }
  }

  // Déconnexion de l'utilisateur
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _removeToken();
      print("Déconnexion réussie !");
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
    }
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Récupérer l'utilisateur actuellement connecté
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Réinitialiser le mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      print("Email de réinitialisation envoyé à $email");
    } catch (e) {
      print("Erreur lors de la réinitialisation du mot de passe : $e");
    }
  }

  // Vérifier si l'email est vérifié
  Future<bool> isEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Recharge les informations utilisateur
      return user.emailVerified;
    }
    return false;
  }

  // Envoyer un email de vérification
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      print("Email de vérification envoyé à ${user.email}");
    }
  }
}
