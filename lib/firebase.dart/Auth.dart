import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final SharedPreferences _prefs;

  FirebaseAuthService() {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Sauvegarder le token
  Future<void> _saveToken(String token) async {
    await _prefs.setString('authToken', token);
  }

  // Récupérer le token
  Future<String?> _getToken() async {
    return _prefs.getString('authToken');
  }

  // Supprimer le token
  Future<void> _removeToken() async {
    await _prefs.remove('authToken');
  }

  // Inscription
  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      if (e is FirebaseAuthException) {
        print("Erreur Firebase : ${e.code}");
      } else {
        print("Erreur inattendue : $e");
      }
      return null;
    }
  }

  // Connexion
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        String? token = await credential.user?.getIdToken();
        await _saveToken(token!);
      }
      return credential.user;
    } catch (e) {
      if (e is FirebaseAuthException) {
        print("Erreur Firebase : ${e.code}");
      } else {
        print("Erreur inattendue : $e");
      }
      return null;
    }
  }

  // Déconnexion
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
    String? token = await _getToken();
    return token != null;
  }
}
