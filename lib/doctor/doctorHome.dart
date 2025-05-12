import 'package:flutter/material.dart';
import '../user_provider.dart';
import 'doctor_cabinets_screen.dart';
import 'doctor_profile_view.dart';

class DoctorHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userName = UserProvider.user?.name ?? 'Docteur';

    return Scaffold(
      appBar: AppBar(
        title: Text('Espace Psychologue'),
        backgroundColor: Colors.teal,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DoctorProfileView()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, $userName',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: Icon(Icons.business, color: Colors.teal),
                title: Text('Mes Cabinets'),
                subtitle: Text('Gérer vos cabinets et réservations'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DoctorCabinetsScreen()),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: Icon(Icons.calendar_today, color: Colors.teal),
                title: Text('Réservations du Jour'),
                subtitle: Text('Voir les rendez-vous à venir'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Implement daily reservations view
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.schedule, color: Colors.teal),
                title: Text('Horaires de Travail'),
                subtitle: Text('Gérer vos disponibilités'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // TODO: Implement work hours management
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person, color: Colors.teal),
                title: const Text('Mon Profil'),
                subtitle: const Text('Gérer mes informations'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DoctorProfileView()),
                  );
                },
              ),
            ),
          ],
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
