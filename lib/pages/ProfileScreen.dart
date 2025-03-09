import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final GoogleSignIn _googleSignIn = GoogleSignIn(); // Ajoutez cette ligne

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isEditing = false;
  bool _isLoading = false;

  // Contrôleurs pour les champs de texte
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _objectifController = TextEditingController();

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genreController.dispose();
    _ageController.dispose();
    _objectifController.dispose();
    super.dispose();
  }

  // Fonction pour charger les données utilisateur depuis Firebase
  Future<void> _loadUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>?;
          _nameController.text = _userData?['name'] ?? '';
          _genreController.text = _userData?['genre'] ?? '';
          _ageController.text = _userData?['age'] ?? '';
          _objectifController.text = _userData?['objectif'] ?? '';
        });
      }
    }
  }

  // Fonction pour sélectionner une image depuis la galerie
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Fonction pour télécharger l'image dans Firebase Storage
  Future<String?> _uploadImage(File imageFile) async {
    try {
      // Générer un nom de fichier unique
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();

      // Référence vers Firebase Storage
      Reference storageReference =
          FirebaseStorage.instance.ref().child('profile_images/$fileName.jpg');

      // Télécharger l'image
      UploadTask uploadTask = storageReference.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;

      // Récupérer l'URL de l'image téléchargée
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print("Erreur lors du téléchargement de l'image : $e");
      return null;
    }
  }

  // Fonction pour enregistrer les modifications
  Future<void> _saveChanges() async {
    if (_user == null) return;
    setState(() => _isLoading = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        // Télécharger l'image et récupérer son URL
        imageUrl = await _uploadImage(_imageFile!);
      }

      // Mettre à jour les données du profil dans Firestore
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': _nameController.text.trim(),
        'genre': _genreController.text.trim(),
        'age': _ageController.text.trim(),
        'objectif': _objectifController.text.trim(),
        if (imageUrl != null)
          'photoUrl': imageUrl, // Ajouter l'URL de l'image si elle existe
      });

      setState(() => _isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès !")),
      );
    } catch (e) {
      print("Erreur mise à jour: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Fonction pour déconnecter l'utilisateur
  Future<void> _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Déconnexion"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _auth.signOut();
        await _googleSignIn.signOut(); // Déconnexion de Google Sign-In
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('authToken'); // Supprimer le token d'authentification

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Déconnexion réussie !")),
        );
      } catch (e) {
        print("Erreur lors de la déconnexion : $e");
      }
    }
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white.withOpacity(0.8),
        ),
      ),
    );
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(
                            _imageFile!) // Afficher l'image sélectionnée
                        : (_userData?['photoUrl'] != null
                            ? NetworkImage(_userData![
                                'photoUrl']) // Afficher l'image du profil
                            : const AssetImage('assets/default_avatar.png')
                                as ImageProvider), // Image par défaut
                  ),
                ),
                const SizedBox(height: 20),
                _buildEditableField("Nom", _nameController),
                _buildEditableField("Genre", _genreController),
                _buildEditableField("Âge", _ageController),
                _buildEditableField("Objectif", _objectifController),
                const SizedBox(height: 20),
                _isEditing
                    ? _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 15)),
                            child: const Text(
                              'Enregistrer',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                    : ElevatedButton(
                        onPressed: () {
                          setState(() => _isEditing = true);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 50, vertical: 15)),
                        child: const Text(
                          'Modifier',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _logout, // Appeler la méthode _logout
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(136, 203, 93, 207),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15)),
                  child: const Text(
                    'Déconnexion',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
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