import 'package:flutter/material.dart';
import '../services/strapi_auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isEditing = false;
  bool _isLoading = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _objectifController = TextEditingController();

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

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _nameController.text = user.name;
        _genreController.text = user.genre;
        _ageController.text = user.age;
        _objectifController.text = user.objectif;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement du profil: $e")),
      );
    }
  }

  Future<void> _saveChanges() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty ||
        _genreController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _objectifController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All fields must be filled")),
      );
      return;
    }

    // Validate age is a number
    if (int.tryParse(_ageController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Age must be a valid number")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.updateProfile({
        'name': _nameController.text.trim(),
        'genre': _genreController.text.trim(),
        'age': _ageController.text.trim(),
        'objectif': _objectifController.text.trim(),
      });

      setState(() => _isEditing = false);
      await _loadUserData(); // Reload the data after update

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès !")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
        await _authService.logout(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de la déconnexion: $e")),
        );
      }
    }
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType:
            label == "Âge" ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white.withAlpha((0.8 * 255).toInt()),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.account_circle,
                  size: 100,
                  color: Colors.white,
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
    );
  }
}
