import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthService {
  FirebaseAuth _auth = FirebaseAuth.instance;

  // Méthode pour sauvegarder le token
  Future<void> _saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
  }

  // Méthode pour récupérer le token
  Future<String?> _getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // Méthode pour supprimer le token (déconnexion)
  Future<void> _removeToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
  }

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      print("Some error occurred");
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (credential.user != null) {
        // Sauvegarder le token après une connexion réussie
        await _saveToken(credential.user!.uid);
      }
      return credential.user;
    } catch (e) {
      print("Some error occurred");
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Supprimer le token lors de la déconnexion
      await _removeToken();
      print("Déconnexion réussie !");
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
    }
  }
}
