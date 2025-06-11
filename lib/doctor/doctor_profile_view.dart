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
    final TextEditingController passwordController = TextEditingController();

    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Supprimer le compte'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Êtes-vous sûr de vouloir supprimer votre compte ? '
                  'Cette action supprimera également votre cabinet et toutes vos réservations. '
                  'Cette action est irréversible.',
                ),
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
        title: const Text(
          'Mon Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _authService.logout(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Color(0xFFE8E9F3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.person,
                              size: 50, color: Color(0xFF8B94CD)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nom complet',
                        icon: Icons.person,
                        gradient: true,
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email,
                        enabled: false,
                        gradient: true,
                      ),
                      _buildTextField(
                        controller: _specialityController,
                        label: 'Spécialité',
                        icon: Icons.psychology,
                        gradient: true,
                      ),
                      _buildTextField(
                        controller: _ageController,
                        label: 'Âge',
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        gradient: true,
                      ),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Téléphone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        gradient: true,
                      ),
                      const SizedBox(height: 20),
                      _buildGradientButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: Icons.save,
                        label: 'Enregistrer les modifications',
                        gradient: const [Color(0xFFCA88CD), Color(0xFF8B94CD)],
                      ),
                      const SizedBox(height: 40),
                      _buildGradientButton(
                        onPressed: _isLoading ? null : _deleteAccount,
                        icon: Icons.delete_forever,
                        label: 'Supprimer mon compte',
                        gradient: const [Colors.redAccent, Colors.red],
                      ),
                    ],
                  ),
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
    bool gradient = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon,
              color: gradient ? const Color(0xFF8B94CD) : Colors.grey[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
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

  Widget _buildGradientButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required List<Color> gradient,
  }) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
      ),
    );
  }
}
