import 'package:flutter/material.dart';
import '../services/strapi_auth_service.dart';
import '../user_provider.dart';

class DoctorProfileView extends StatefulWidget {
  @override
  _DoctorProfileViewState createState() => _DoctorProfileViewState();
}

class _DoctorProfileViewState extends State<DoctorProfileView> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _specialityController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = UserProvider.user;
    // Récupérer les données du docteur depuis la collection doctor
    final doctorData = user?.doctor?['attributes'] ?? {};

    // Initialiser les contrôleurs avec les données utilisateur et docteur
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _specialityController =
        TextEditingController(text: doctorData['speciality'] ?? '');
    _ageController = TextEditingController(text: user?.age ?? '');
    _phoneController = TextEditingController(text: doctorData['phone'] ?? '');
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = UserProvider.user;
      if (user == null) throw Exception('No user found');

      // 1. Mettre à jour le profil utilisateur de base
      await _authService.updateProfile({
        'name': _nameController.text,
        'age': _ageController.text,
      });

      // 2. Mettre à jour le profil docteur
      final success = await _authService.updateDoctorProfile(
        user.id,
        {
          'speciality': _specialityController.text,
          'phone': _phoneController.text,
        },
      );

      if (!success) {
        throw Exception('Failed to update doctor profile');
      }

      // Rafraîchir les données
      if (!mounted) return;
      await _authService.getCurrentUser();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer le compte'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer votre compte ? '
              'Cette action supprimera également votre cabinet et toutes vos réservations. '
              'Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && mounted) {
      setState(() => _isLoading = true);
      try {
        final success = await _authService.deleteAccount();
        if (success && mounted) {
          await _authService.logout(context);
        } else {
          throw Exception('Failed to delete account');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression du compte : $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.logout(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade100,
                      child: const Icon(Icons.person,
                          size: 50, color: Colors.teal),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom complet',
                      icon: Icons.person,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      enabled: false,
                    ),
                    _buildTextField(
                      controller: _specialityController,
                      label: 'Spécialité',
                      icon: Icons.psychology,
                    ),
                    _buildTextField(
                      controller: _ageController,
                      label: 'Âge',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer les modifications'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _deleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Supprimer mon compte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.teal),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est requis';
          }
          return null;
        },
      ),
    );
  }
}
