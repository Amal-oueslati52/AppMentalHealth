import 'package:flutter/material.dart';
import '../models/cabinet.dart';
import '../services/doctor_cabinet_service.dart';
import '../user_provider.dart';
import 'create_cabinet_screen.dart';
import 'doctor_reservations_screen.dart';

class DoctorCabinetsScreen extends StatefulWidget {
  @override
  _DoctorCabinetsScreenState createState() => _DoctorCabinetsScreenState();
}

class _DoctorCabinetsScreenState extends State<DoctorCabinetsScreen> {
  final DoctorCabinetService _cabinetService = DoctorCabinetService();
  List<Cabinet> _cabinets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCabinets();
  }

  Future<void> _loadCabinets() async {
    if (UserProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Get the doctor ID from the user's doctor object
      final doctorId = UserProvider.user!.doctorId;
      print('🔍 Loading cabinets for doctorId: $doctorId');

      if (doctorId == null) {
        print('⚠️ Doctor ID is null');
        throw Exception('Doctor ID not found');
      }

      final cabinets = await _cabinetService.getDoctorCabinets(doctorId);
      print('📋 Cabinets loaded: ${cabinets.length}');
      print('📋 Cabinet data: $cabinets');

      setState(() {
        _cabinets = cabinets;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading cabinets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading cabinets: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _navigateToReservations(Cabinet cabinet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorReservationsScreen(cabinet: cabinet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Cabinets',
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
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8E9F3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadCabinets,
                child: _cabinets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined,
                                size: 64, color: Color(0xFF8B94CD)),
                            const SizedBox(height: 16),
                            const Text(
                              'Aucun cabinet trouvé',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF8B94CD),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _cabinets.length,
                        itemBuilder: (context, index) {
                          final cabinet = _cabinets[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFFCA88CD).withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                cabinet.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B94CD),
                                ),
                              ),
                              subtitle: Text(cabinet.description ?? ''),
                              trailing: ElevatedButton.icon(
                                icon: Icon(
                                  Icons.list_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                label: const Text(
                                  'Réservations',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFCA88CD),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                onPressed: () =>
                                    _navigateToReservations(cabinet),
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateCabinetScreen()),
            );
            if (result == true) {
              _loadCabinets();
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
