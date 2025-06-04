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

class _DoctorReservationsScreenState extends State<DoctorReservationsScreen>
    with SingleTickerProviderStateMixin {
  static const Map<String, String> statusColors = {
    'CONFIRMED': '#4CAF50',
    'REJECTED': '#F44336',
    'PENDING': '#FFA726',
  };

  late TabController _tabController;
  List<Map<String, dynamic>> _onlineReservations = [];
  List<Map<String, dynamic>> _cabinetReservations = [];
  final DoctorCabinetService _cabinetService = DoctorCabinetService();
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 Loading reservations for cabinet ID: ${widget.cabinet.id}');
      final reservations = await _cabinetService
          .getCabinetReservations(widget.cabinet.id.toString());

      print('📋 Found ${reservations.length} real reservations');
      print('📋 Toutes les réservations: ${reservations.length}');
      reservations.forEach((r) {
        print('- Type de consultation: ${r['Consultation_type']}');
      });
      final online = reservations.where((r) {
        final consultationType = r['Consultation_type']?.toString() ?? '';
        print('🔍 Consultation type (en ligne check): $consultationType');
        return consultationType == 'EN_LIGNE';
      }).toList();

      final cabinet = reservations.where((r) {
        final consultationType = r['Consultation_type']?.toString() ?? '';
        print('🔍 Consultation type (cabinet check): $consultationType');
        return consultationType == 'EN CABINET';
      }).toList();

      print('📊 Répartition des réservations:');
      print('- Total: ${reservations.length}');
      print('- En ligne: ${online.length}');
      print('- En cabinet: ${cabinet.length}');

      print('📋 Réservations en ligne: ${online.length}');
      print('📋 Réservations en cabinet: ${cabinet.length}');

      setState(() {
        _onlineReservations = online;
        _cabinetReservations = cabinet;
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

      final reservation =
          [..._onlineReservations, ..._cabinetReservations].firstWhere(
        (r) => r['id'].toString() == reservationId,
        orElse: () => throw Exception('Reservation not found'),
      ); // Récupérer le documentId de la réservation
      final reservationDocId = reservation['documentId'];
      if (reservationDocId == null || reservationDocId.toString().isEmpty) {
        throw Exception(
            'DocumentId invalide pour la réservation $reservationId');
      }

      print('📝 Mise à jour de la réservation:');
      print('- ID: $reservationId');
      print('- DocumentId: $reservationDocId');
      print('- Nouveau statut: $newStatus');

      final success = await _cabinetService.updateReservationStatus(
          reservationDocId.toString(), newStatus);

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
    try {
      final date = DateTime.parse(dateStr).toLocal();
      print(
          '📅 Parsed date: $dateStr -> ${DateFormat('dd/MM/yyyy HH:mm').format(date)}');
      return date;
    } catch (e) {
      print('❌ Erreur de parsing de la date: $dateStr');
      return DateTime.now();
    }
  }

  Widget _buildEmptyState({required bool isOnline}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOnline ? Icons.computer : Icons.local_hospital,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Pas de réservations ${isOnline ? 'en ligne' : 'en cabinet'}',
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF757575),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Ce cabinet n\'a pas encore reçu de réservations ${isOnline ? 'en ligne' : 'en cabinet'}',
              textAlign: TextAlign.center,
              style: const TextStyle(
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
    final consultationType = reservation['Consultation_type']?.toString() ?? '';
    print('🏥 Card consultation type: $consultationType');
    final isOnline = consultationType == 'EN_LIGNE';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline ? const Color(0xFF8B94CD) : const Color(0xFFCA88CD),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA88CD).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          'Patient: ${user['username'] ?? 'Inconnu'}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B94CD),
          ),
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
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(int.parse(
                            _getStatusColor(status).replaceAll('#', '0xFF'))),
                        Color(int.parse(_getStatusColor(status)
                                .replaceAll('#', '0xFF')))
                            .withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? const Color(0xFF8B94CD).withOpacity(0.2)
                        : const Color(0xFFCA88CD).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.computer : Icons.local_hospital,
                        size: 16,
                        color: isOnline
                            ? const Color(0xFF8B94CD)
                            : const Color(0xFFCA88CD),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOnline ? 'En Ligne' : 'Cabinet',
                        style: TextStyle(
                          color: isOnline
                              ? const Color(0xFF8B94CD)
                              : const Color(0xFFCA88CD),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF8B94CD)),
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
              child: Text('Annuler'),
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
        title: Text(
          'Réservations - ${widget.cabinet.title}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.computer, size: 20),
                  SizedBox(width: 8),
                  Text('En Ligne'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital, size: 20),
                  SizedBox(width: 8),
                  Text('Au Cabinet'),
                ],
              ),
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
            : TabBarView(
                controller: _tabController,
                children: [
                  // Online Reservations Tab
                  RefreshIndicator(
                    onRefresh: _loadReservations,
                    child: _onlineReservations.isEmpty
                        ? _buildEmptyState(isOnline: true)
                        : ListView.builder(
                            itemCount: _onlineReservations.length,
                            itemBuilder: (context, index) =>
                                _buildReservationCard(
                                    _onlineReservations[index]),
                          ),
                  ),
                  // Cabinet Reservations Tab
                  RefreshIndicator(
                    onRefresh: _loadReservations,
                    child: _cabinetReservations.isEmpty
                        ? _buildEmptyState(isOnline: false)
                        : ListView.builder(
                            itemCount: _cabinetReservations.length,
                            itemBuilder: (context, index) =>
                                _buildReservationCard(
                                    _cabinetReservations[index]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
