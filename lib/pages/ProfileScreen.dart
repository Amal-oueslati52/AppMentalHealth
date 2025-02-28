import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'login.dart';
import 'chat_screen.dart';
import 'HomeScreen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _tabIndex = 1;

  void _navigateToScreen(int index) {
    Widget screen;

    switch (index) {
      case 0:
        screen = const HomeScreen(); // Page d'accueil
        break;
      case 1:
        screen = const ProfileScreen(); // Page de profil
        break;
      case 2:
        screen = const ChatScreen(); // Page du chatbot
        break;
      default:
        screen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

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

  // Navigation

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _pageController = PageController(initialPage: _tabIndex);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genreController.dispose();
    _ageController.dispose();
    _objectifController.dispose();
    _pageController.dispose();
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

  // Fonction pour enregistrer les modifications
  Future<void> _saveChanges() async {
    if (_user == null) return;
    setState(() => _isLoading = true);

    try {
      await _firestore.collection('users').doc(_user!.uid).update({
        'name': _nameController.text.trim(),
        'genre': _genreController.text.trim(),
        'age': _ageController.text.trim(),
        'objectif': _objectifController.text.trim(),
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
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Login()));
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
      appBar: AppBar(
        leading: IconButton(
          icon: ImageIcon(AssetImage('assets/icones/image 25.png')),
          onPressed: () {},
        ),
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: ImageIcon(AssetImage('assets/icones/image 28.png')),
            onPressed: () {},
          ),
        ],
      ),
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
                        ? FileImage(_imageFile!)
                        : (_userData?['photoUrl'] != null
                                ? NetworkImage(_userData!['photoUrl'])
                                : const AssetImage('assets/default_avatar.png'))
                            as ImageProvider,
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
                  onPressed: _logout,
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
      bottomNavigationBar: CircleNavBar(
        activeIcons: const [
          Icon(Icons.home, color: Colors.deepPurple),
          Icon(Icons.person, color: Colors.deepPurple),
          Icon(Icons.assessment, color: Colors.deepPurple),
          Icon(Icons.book, color: Colors.deepPurple),
          Icon(Icons.message, color: Colors.deepPurple),
        ],
        inactiveIcons: const [
          Text("Home"),
          Text("Profile"),
          Text("Chatbot"),
          Text("Auto"),
          Text("Journal"),
        ],
        color: Colors.white,
        height: 60,
        circleWidth: 60,
        activeIndex: _tabIndex,
        onTap: (index) => _navigateToScreen(index),
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        cornerRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(24),
        ),
        shadowColor: Colors.deepPurple,
        elevation: 10,
      ),
    );
  }
}
