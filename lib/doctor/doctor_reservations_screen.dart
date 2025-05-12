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
  static const Map<String, String> statusColors = {
    'CONFIRMED': '#4CAF50',
    'REJECTED': '#F44336',
    'PENDING': '#FFA726',
  };

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
      setState(() => _isLoading = true);

      final reservation = _reservations.firstWhere(
        (r) => r['id'].toString() == reservationId,
        orElse: () => throw Exception('Reservation not found'),
      );

      final documentId = reservation['documentId'];
      print(
          '📝 Updating reservation - ID: $reservationId, DocumentId: $documentId, Status: $newStatus');

      if (documentId == null || documentId.isEmpty) {
        throw Exception('DocumentId not found for reservation $reservationId');
      }

      final success =
          await _cabinetService.updateReservationStatus(documentId, newStatus);

      if (!mounted) return;

      if (success) {
        await _loadReservations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Statut mis à jour avec succès'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      print('❌ Error updating status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStatusColor(String status) {
    return statusColors[status.toUpperCase()] ?? '#9E9E9E';
  }

  DateTime _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now();
    }
    return DateTime.tryParse(dateStr)?.toLocal() ?? DateTime.now();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Pas de réservations',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF757575),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ce cabinet n\'a pas encore reçu de réservations',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _loadReservations,
            icon: const Icon(Icons.refresh),
            label: const Text('Rafraîchir'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final date = _parseDate(reservation['date']);
    final status = reservation['state'] ?? 'PENDING';
    final user = reservation['users_permissions_user'] ?? {};

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text(
          'Patient: ${user['username'] ?? 'Inconnu'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(date)}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Color(
                  int.parse(
                    _getStatusColor(status).replaceAll('#', '0xFF'),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String choice) {
            final reservationId = reservation['id']?.toString();
            if (reservationId != null) {
              _updateReservationStatus(reservationId, choice);
            }
          },
          itemBuilder: (BuildContext context) => const [
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réservations - ${widget.cabinet.title}'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReservations,
              child: _reservations.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _reservations.length,
                      itemBuilder: (context, index) =>
                          _buildReservationCard(_reservations[index]),
                    ),
            ),
    );
  }
}
