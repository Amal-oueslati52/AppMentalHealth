import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'ProfileScreen.dart';
import 'HomeScreen.dart' as home;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
  }

  void _navigateToScreen(int index) {
    Widget screen;

    switch (index) {
      case 0:
        screen = const home.HomeScreen(); // Accueil
        break;
      case 1:
        screen = const ProfileScreen(); // Profil
        break;

      default:
        screen = const home.HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: ImageIcon(AssetImage('assets/icones/image 25.png')),
          onPressed: () {
            // Add your onPressed code here!
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
            icon: ImageIcon(AssetImage('assets/icones/image 28.png')),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
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
            ],
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
