import 'package:flutter/material.dart';
import 'package:circle_nav_bar/circle_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: ImageIcon(AssetImage('assets/icones/image 25.png')),
          onPressed: () {},
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
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _tabIndex = index;
          });
        },
        children: [
          buildPage(
            screenHeight,
            "N'oubliez pas votre exercice de relaxation aujourd'hui!",
            'assets/images/image 24.png',
          ),
          buildPage(screenHeight, 'Profile', ''),
          buildPage(screenHeight, 'Auto-Évaluation', ''),
          buildPage(screenHeight, 'Ressource', ''),
          buildPage(screenHeight, 'Journal', ''),
        ],
      ),
      extendBody: true,
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
          Text("Auto"),
          Text("Ressource"),
          Text("Journal"),
        ],
        color: Colors.white,
        height: 65,
        circleWidth: 60,
        activeIndex: _tabIndex,
        onTap: (index) {
          setState(() {
            _tabIndex = index;
            _pageController.jumpToPage(_tabIndex);
          });
        },
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 15),
        cornerRadius: BorderRadius.circular(20),
        shadowColor: Colors.deepPurple,
        elevation: 8,
      ),
    );
  }

  Widget buildPage(double screenHeight, String text, String imagePath) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
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
            if (imagePath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  imagePath,
                  width: screenHeight * 0.15,
                  height: screenHeight * 0.15,
                  fit: BoxFit.contain,
                ),
              ),
            SizedBox(height: 30.0),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenHeight * 0.022,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

