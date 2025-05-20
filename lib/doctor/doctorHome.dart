import 'package:flutter/material.dart';
import '../user_provider.dart';
import 'doctor_cabinets_screen.dart';
import 'doctor_profile_view.dart';
import '../services/messagerieService.dart';
import '../screens/chat.dart';

class DoctorHome extends StatelessWidget {
  final MessagerieService _messagerieService = MessagerieService();

  @override
  Widget build(BuildContext context) {
    final userName = UserProvider.user?.name ?? 'Docteur';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Espace Psychologue',
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
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DoctorProfileView()),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8E9F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $userName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B94CD),
                  ),
                ),
                const SizedBox(height: 20),
                _buildMenuCard(
                  icon: Icons.people,
                  title: 'Mes Patients',
                  subtitle: 'Liste de vos patients et leurs messages',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _PatientsListScreen(
                          messagerieService: _messagerieService,
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuCard(
                  icon: Icons.business,
                  title: 'Mes Cabinets',
                  subtitle: 'Gérer vos cabinets et réservations',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorCabinetsScreen()),
                  ),
                ),
                _buildMenuCard(
                  icon: Icons.calendar_today,
                  title: 'Réservations du Jour',
                  subtitle: 'Voir les rendez-vous à venir',
                  onTap: () {/* TODO */},
                ),
                _buildMenuCard(
                  icon: Icons.schedule,
                  title: 'Horaires de Travail',
                  subtitle: 'Gérer vos disponibilités',
                  onTap: () {/* TODO */},
                ),
                _buildMenuCard(
                  icon: Icons.person,
                  title: 'Mon Profil',
                  subtitle: 'Gérer mes informations',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorProfileView()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA88CD).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B94CD),
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Color(0xFF8B94CD),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

// Nouvel écran pour la liste des patients
class _PatientsListScreen extends StatelessWidget {
  final MessagerieService messagerieService;

  const _PatientsListScreen({
    Key? key,
    required this.messagerieService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Patients'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8E9F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: messagerieService.getUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            final patients = snapshot.data ?? [];

            if (patients.isEmpty) {
              return const Center(
                child: Text('Aucun patient trouvé'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF0E6FF),
                      child: Text(
                        patient['name']?[0] ?? '?',
                        style: const TextStyle(
                          color: Color(0xFF8B94CD),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      patient['name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(patient['email'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.message_rounded,
                        color: Color(0xFF8B94CD),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              userId: patient['id'].toString(),
                              userName: patient['name'] ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DoctorHome(),
  ));
}
