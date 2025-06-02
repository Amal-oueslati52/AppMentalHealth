import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'ProfileScreen.dart';
import 'chat_screen.dart';
import 'map_screen.dart';
import '../screens/chat.dart';
import '../patient/assessment_screen.dart';
import '../services/messagerieService.dart';
import 'assessment_history_screen.dart';
import '../patient/patient_bookings.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  late PageController _pageController;

  // Liste des écrans accessibles via la barre de navigation
  final List<Widget> _screens = [
    const HomeContent(), // Contenu de l'écran d'accueil
    const ProfileScreen(), // Profil
    MapScreen(), // Carte
    const ChatScreen(), // Garder le chat
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Changement d'onglet
  void _onTabTapped(int index) {
    setState(() {
      _tabIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const ImageIcon(AssetImage('assets/icones/image 25.png')),
          onPressed: () {
            // Action pour le bouton de gauche
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset('assets/images/logo.png', width: 30),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PatientBookingList()),
              );
            },
          ),
          IconButton(
            icon: const ImageIcon(AssetImage('assets/icones/image 28.png')),
            onPressed: () {
              // Action pour le bouton de droite
            },
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _tabIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: CircleNavBar(
        activeIcons: const [
          Icon(Icons.home, color: Colors.deepPurple), // Accueil
          Icon(Icons.person, color: Colors.deepPurple), // Profil
          Icon(Icons.map, color: Colors.deepPurple), // Carte
          Icon(Icons.chat, color: Colors.deepPurple), // Garder le chat
        ],
        inactiveIcons: const [
          Text("Accueil"),
          Text("Profil"),
          Text("Carte"),
          Text("Chatbot"), // Garder le chatbot
        ],
        color: Colors.white,
        height: 60,
        circleWidth: 60,
        activeIndex: _tabIndex,
        onTap: _onTabTapped,
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

// 🟣 HomeContent reste inchangé mais déjà bien relié à PatientBookingList depuis le bouton d'AppBar.
// Contenu de l'écran d'accueil
class HomeContent extends StatelessWidget {
  const HomeContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildContactDoctorCard(context),
              const SizedBox(height: 16),
              _buildJournalCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactDoctorCard(BuildContext context) {
    final MessagerieService _messagerieService = MessagerieService();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(),
            const SizedBox(height: 16),
            _buildCardDescription(),
            const SizedBox(height: 20),
            _buildContactButton(context, _messagerieService),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0E6FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.medical_services,
            color: Color(0xFF8B94CD),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacter un',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4A4A),
              ),
            ),
            Text(
              'Médecin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A4A4A),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardDescription() {
    return const Text(
      'Consultez nos professionnels de santé qualifiés pour un suivi personnalisé',
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildContactButton(
      BuildContext context, MessagerieService messagerieService) {
    return InkWell(
      onTap: () => _showDoctorsList(context, messagerieService),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF8B94CD),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Text(
            'Commencer une discussion →',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showDoctorsList(
      BuildContext context, MessagerieService messagerieService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: DoctorsList(
            messagerieService: messagerieService,
            scrollController: controller,
          ),
        ),
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _navigateToAssessment(context),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildJournalIcon(),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Suivie de la journal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFF8B94CD)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssessmentHistoryScreen(),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.history, color: Color(0xFF8B94CD)),
                  SizedBox(width: 8),
                  Text(
                    'Voir l\'historique',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF8B94CD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.psychology,
        color: Color(0xFF8B94CD),
        size: 28,
      ),
    );
  }

  void _navigateToAssessment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AssessmentScreen(),
      ),
    );
  }
}

// Nouveau widget pour la liste des médecins
class DoctorsList extends StatelessWidget {
  final MessagerieService messagerieService;
  final ScrollController scrollController;

  const DoctorsList({
    Key? key,
    required this.messagerieService,
    required this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          child: const Text(
            'Sélectionnez un médecin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: messagerieService.getUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              final users = snapshot.data ?? [];

              return ListView.builder(
                controller: scrollController,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF0E6FF),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF8B94CD),
                      ),
                    ),
                    title: Text(user['name'] ?? ''),
                    subtitle: Text(user['email'] ?? ''),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            userId: user['id'].toString(),
                            userName: user['name'] ?? '',
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
