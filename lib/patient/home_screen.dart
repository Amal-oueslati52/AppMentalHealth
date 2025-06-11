import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'profile_screen.dart';
import 'chat_screen.dart';
import 'map_screen.dart';
import '../screens/chat.dart';
import '../patient/assessment_screen.dart';
import '../patient/patient_bookings.dart';
import 'assessment_history_screen.dart';
import '../services/messagerie_service.dart';

const double kBottomNavHeight = 60.0;
const double kCircleNavWidth = 60.0;
const double kLogoWidth = 30.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  late final PageController _pageController;

  final List<({Widget screen, Icon icon, String label})> _navigationItems = [
    (
      screen: const HomeContent(),
      icon: const Icon(Icons.home, color: Colors.deepPurple),
      label: "Accueil",
    ),
    (
      screen: const ProfileScreen(),
      icon: const Icon(Icons.person, color: Colors.deepPurple),
      label: "Profil",
    ),
    (
      screen: MapScreen(),
      icon: const Icon(Icons.map, color: Colors.deepPurple),
      label: "Carte",
    ),
    (
      screen: const ChatScreen(),
      icon: const Icon(Icons.chat, color: Colors.deepPurple),
      label: "Chatbot",
    ),
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

  void _onTabTapped(int index) {
    if (!mounted) return;
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset('assets/images/logo.png', width: kLogoWidth),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PatientBookingList()),
            ),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (mounted) setState(() => _tabIndex = index);
        },
        children: _navigationItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: CircleNavBar(
        activeIcons: _navigationItems.map((item) => item.icon).toList(),
        inactiveIcons:
            _navigationItems.map((item) => Text(item.label)).toList(),
        color: Colors.white,
        height: kBottomNavHeight,
        circleWidth: kCircleNavWidth,
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
  const HomeContent({super.key});

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
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenue',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _buildServiceCard(
                context,
                'Contacter un Médecin',
                'Consultez nos professionnels de santé qualifiés',
                Icons.medical_services,
                () => _showDoctorsList(context, MessagerieService()),
              ),
              const SizedBox(height: 16),
              _buildServiceCard(
                context,
                'Journal de Suivi',
                'Suivez votre bien-être au quotidien',
                Icons.psychology,
                () => _navigateToAssessment(context),
                showHistory: true,
                onHistoryTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AssessmentHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap, {
    bool showHistory = false,
    VoidCallback? onHistoryTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0E6FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFF8B94CD),
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A4A4A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Color(0xFF8B94CD),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (showHistory && onHistoryTap != null) ...[
                const Divider(height: 1),
                InkWell(
                  onTap: onHistoryTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
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
            ],
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
    super.key,
    required this.messagerieService,
    required this.scrollController,
  });

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
                      child: const Icon(
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
