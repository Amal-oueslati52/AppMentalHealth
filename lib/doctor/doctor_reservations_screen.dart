import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/cabinet.dart';
import '../services/doctor_cabinet_service.dart';

class DoctorReservationsScreen extends StatefulWidget {
  final Cabinet cabinet;

  const DoctorReservationsScreen({Key? key, required this.cabinet})
      : super(key: key);

  @override
  _DoctorReservationsScreenState createState() =>
      _DoctorReservationsScreenState();
}

class _DoctorReservationsScreenState extends State<DoctorReservationsScreen> {
  final DoctorCabinetService _cabinetService = DoctorCabinetService();
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Loading reservations for cabinet ID: ${widget.cabinet.id}');

      final reservations = await _cabinetService
          .getCabinetReservations(widget.cabinet.id.toString());

      print('📋 Found ${reservations.length} real reservations');

      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error loading reservations: $e');
      print('🔍 Stack trace: $stackTrace');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reservations: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateReservationStatus(
      String reservationId, String newStatus) async {
    try {
      final success = await _cabinetService.updateReservationStatus(
          reservationId, newStatus);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour avec succès')),
        );
        _loadReservations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour du statut')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  String _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return '#4CAF50'; // Green
      case 'PENDING':
        return '#FFA726'; // Orange
      case 'CANCELED':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réservations - ${widget.cabinet.title}'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReservations,
              child: _reservations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucune réservation trouvée',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tirez vers le bas pour actualiser',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _reservations.length,
                      itemBuilder: (context, index) {
                        final reservation = _reservations[index];
                        final date = reservation['date'] != null
                            ? DateTime.parse(reservation['date'])
                            : DateTime.now();
                        final status = reservation['state'] ?? 'PENDING';
                        final user =
                            reservation['users_permissions_user'] ?? {};

                        return Card(
                          margin:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            title: Text(
                              'Patient: ${user['username'] ?? 'Inconnu'}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(
                                      int.parse(
                                        _getStatusColor(status)
                                            .replaceAll('#', '0xFF'),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (String choice) {
                                _updateReservationStatus(
                                    reservation['id'].toString(), choice);
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'CONFIRMED',
                                  child: Text('Confirmer'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'CANCELED',
                                  child: Text('Annuler'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
