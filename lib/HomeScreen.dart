import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          // Icône en haut à gauche
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFCA88CD),
              const Color(0xFF8B94CD),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[
              Image(
                image: AssetImage('assets/images/image 24.png'),
                width: 100.0,
                height: 100.0,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 20.0),
              Text(
                'N\'oubliez pas votre exercice de relaxation d\'aujourd\'hui!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color.fromARGB(255, 75, 3, 69)),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, color: Color.fromARGB(255, 75, 3, 69)),
            label: 'Ressource',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment, color: Color.fromARGB(255, 75, 3, 69)),
            label: 'Auto Evaluation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message, color: Color.fromARGB(255, 75, 3, 69)),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Color.fromARGB(255, 75, 3, 69)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
