import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'ProfileScreen.dart';
import 'chat_screen.dart';
import 'map_screen.dart';
import '../screens/assessment_screen.dart';
import '../screens/contacts.dart'; // Ajouter cet import

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
    const ChatListScreen(), // Ajouter l'écran des contacts
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
          Icon(Icons.contacts,
              color: Colors.deepPurple), // Ajouter les contacts
        ],
        inactiveIcons: const [
          Text("Accueil"),
          Text("Profil"),
          Text("Carte"),
          Text("Chatbot"), // Garder le chatbot
          Text("Contacts"), // Ajouter les contacts
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/image 24.png',
              width: 100.0,
              height: 100.0,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20.0),
            const Text(
              'N\'oubliez pas votre exercice de relaxation d\'aujourd\'hui!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, color: Colors.white),
            ),
            const SizedBox(height: 30.0),
            ElevatedButton.icon(
              icon: Icon(Icons.psychology, color: Colors.deepPurple),
              label: Text(
                'Suivie de la journal',
                style: TextStyle(color: Colors.deepPurple),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssessmentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
