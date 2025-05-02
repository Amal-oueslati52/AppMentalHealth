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
        title: Text('Mes Cabinets'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCabinets,
              child: _cabinets.isEmpty
                  ? Center(
                      child: Text('Vous n\'avez pas encore de cabinet'),
                    )
                  : ListView.builder(
                      itemCount: _cabinets.length,
                      itemBuilder: (context, index) {
                        final cabinet = _cabinets[index];
                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(cabinet.title),
                            subtitle: Text(cabinet.description ?? ''),
                            trailing: IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () => _navigateToReservations(cabinet),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateCabinetScreen()),
          );
          if (result == true) {
            _loadCabinets();
          }
        },
        backgroundColor: Colors.teal,
        child: Icon(Icons.add),
      ),
    );
  }
}
