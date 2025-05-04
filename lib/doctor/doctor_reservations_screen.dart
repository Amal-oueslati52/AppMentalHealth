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
      String reservationDocumentId, String newStatus) async {
    try {
      print('🔄 Updating reservation: $reservationDocumentId to $newStatus');

      final success = await _cabinetService.updateReservationStatus(
        reservationDocumentId,
        newStatus,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadReservations(); // Reload the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du statut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return '#4CAF50'; // Vert
      case 'REJECTED':
        return '#F44336'; // Rouge
      case 'PENDING':
        return '#FFA726'; // Orange
      default:
        return '#9E9E9E';
    }
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      print('❌ Error parsing date: $dateStr');
      return DateTime.now();
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
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Pas de réservations',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Ce cabinet n\'a pas encore reçu de réservations',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                          SizedBox(height: 24),
                          TextButton.icon(
                            onPressed: _loadReservations,
                            icon: Icon(Icons.refresh),
                            label: Text('Rafraîchir'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _reservations.length,
                      itemBuilder: (context, index) {
                        final reservation = _reservations[index];
                        final documentId =
                            reservation['documentId']?.toString() ?? '';
                        final date = _parseDate(reservation['date']);
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
                                if (documentId.isNotEmpty) {
                                  _updateReservationStatus(documentId, choice);
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                PopupMenuItem<String>(
                                  value: 'CONFIRMED',
                                  child: Text('Confirmer'),
                                ),
                                PopupMenuItem<String>(
                                  value: 'REJECTED',
                                  child: Text('Rejeter'),
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
