import 'package:flutter/material.dart';
import '../services/strapi_auth_service.dart';
import '../models/user.dart';
import '../toast/toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

/// État de l'écran de profil utilisateur
/// Gère l'affichage et la modification des informations du profil
class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService(); // Service d'authentification
  bool _isEditing = false; // Mode édition activé/désactivé
  bool _isLoading = false; // Indicateur de chargement pour les opérations
  bool _isInitialLoading = true; // Chargement initial des données
  User? _currentUser; // Données de l'utilisateur courant

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
      if (!mounted) return;

      setState(() {
        _currentUser = user;
        _nameController.text = user.name;
        _genreController.text = user.genre ?? '';
        _ageController.text = user.age ?? '';
        _objectifController.text = user.objectif ?? '';
        _isInitialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      showToast(message: "Error loading profile: $e");
      setState(() => _isInitialLoading = false);
    }
  }

  bool _validateFields() {
    if (_nameController.text.trim().isEmpty ||
        _genreController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _objectifController.text.trim().isEmpty) {
      showToast(message: "All fields must be filled");
      return false;
    }

    if (int.tryParse(_ageController.text.trim()) == null) {
      showToast(message: "Age must be a valid number");
      return false;
    }

    return true;
  }

  Future<void> _saveChanges() async {
    if (!_validateFields()) return;

    setState(() => _isLoading = true);

    try {
      final updatedUser = await _authService.updateProfile({
        'name': _nameController.text.trim(),
        'genre': _genreController.text.trim(),
        'age': _ageController.text.trim(),
        'objectif': _objectifController.text.trim(),
      });

      setState(() {
        _currentUser = updatedUser;
        _isEditing = false;
      });

      if (!mounted) return;
      showToast(message: "Profile updated successfully!");
    } catch (e) {
      if (!mounted) return;
      showToast(message: "Error updating profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Logout"),
            content: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("Logout"),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && mounted) {
      try {
        await _authService.logout(context);
      } catch (e) {
        if (!mounted) return;
        showToast(message: "Error during logout: $e");
      }
    }
  }

  Future<void> _deleteAccount() async {
    final TextEditingController passwordController = TextEditingController();

    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Supprimer le compte"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    "Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible."),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: "Mot de passe",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Annuler"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                    foregroundColor: const Color.fromARGB(135, 226, 155, 150)),
                child: const Text("Supprimer"),
              ),
            ],
          ),
        ) ??
        false;
    if (confirm && mounted) {
      setState(() => _isLoading = true);
      try {
        // Vérifier le mot de passe avant de supprimer le compte
        if (passwordController.text.isEmpty) {
          throw Exception('Veuillez entrer votre mot de passe');
        }

        // Valider le mot de passe avec le serveur avant de supprimer le compte
        final passwordValid =
            await _authService.validatePassword(passwordController.text);
        if (!passwordValid) {
          throw Exception('Mot de passe incorrect');
        }

        final success = await _authService.deleteAccount();
        if (success && mounted) {
          await _authService.logout(context);
        } else {
          throw Exception('Failed to delete account');
        }
      } catch (e) {
        if (!mounted) return;
        showToast(message: "Erreur lors de la suppression du compte : $e");
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white.withAlpha(204),
          suffixIcon: _isEditing
              ? Icon(
                  isNumeric ? Icons.numbers : Icons.edit,
                  color: Colors.grey,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFFCA88CD),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 50, color: Color(0xFFCA88CD)),
                ),
                const SizedBox(height: 20),
                Text(
                  _currentUser?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildEditableField("Name", _nameController),
                _buildEditableField("Genre", _genreController),
                _buildEditableField("Age", _ageController, isNumeric: true),
                _buildEditableField("Objective", _objectifController),
                const SizedBox(height: 30),
                if (_isEditing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() => _isEditing = false);
                                _loadUserData();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Enregistrer'),
                      ),
                    ],
                  )
                else
                  ElevatedButton(
                    onPressed: () => setState(() => _isEditing = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(166, 144, 192, 231),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                    ),
                    child: const Text('modifier Profile'),
                  ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _deleteAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 248, 86, 75),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Supprimer mon compte'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
