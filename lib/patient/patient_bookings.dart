import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../user_provider.dart';

class PatientBookingList extends StatefulWidget {
  const PatientBookingList({Key? key}) : super(key: key);

  @override
  _PatientBookingListState createState() => _PatientBookingListState();
}

class _PatientBookingListState extends State<PatientBookingList> {
  final BookingService _bookingService = BookingService();
  List<dynamic> _onlineBookings = [];
  List<dynamic> _cabinetBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      print('👤 Loading reservations for user: ${UserProvider.user!.id}');

      final result = await _bookingService.fetchUserBookings(
        userID: UserProvider.user!.id.toString(),
        page: 1,
        pageSize: 100,
      );

      final data = result['data'] ?? [];
      print('📝 Received ${data.length} reservations');

      final online = data.where((r) {
        final consultationType = r['attributes']['Consultation_type']
                ?.toString()
                .trim()
                .toUpperCase() ??
            '';
        print(
            '🏥 Consultation type for reservation ${r['id']}: $consultationType');
        return consultationType == 'EN_LIGNE' || consultationType == 'EN LIGNE';
      }).toList();

      final cabinet = data.where((r) {
        final consultationType = r['attributes']['Consultation_type']
                ?.toString()
                .trim()
                .toUpperCase() ??
            '';
        return consultationType == 'EN_CABINET' ||
            consultationType == 'EN CABINET';
      }).toList();

      print(
          '📊 Found ${online.length} online and ${cabinet.length} cabinet reservations');
      print(
          '🔍 Online reservations: ${online.map((r) => r['attributes']['Consultation_type']).toList()}');
      print(
          '🔍 Cabinet reservations: ${cabinet.map((r) => r['attributes']['Consultation_type']).toList()}');

      if (mounted) {
        setState(() {
          _onlineBookings = online;
          _cabinetBookings = cabinet;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading reservations: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de chargement des réservations: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildReservationItem(dynamic booking) {
    final attributes = booking['attributes'];
    final cabinet = attributes['cabinet']['title'] ?? 'Cabinet inconnu';
    final date = attributes['date'] ?? '';
    final state = attributes['state'] ?? 'PENDING';
    final paymentStatus = attributes['payment_status'] ?? '';
    final consultationType =
        attributes['Consultation_type']?.toString().trim().toUpperCase() ?? '';

    final formattedDate = date.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date).toLocal())
        : 'Date invalide';

    Color stateColor;
    switch (state.toUpperCase()) {
      case 'CONFIRMED':
        stateColor = Colors.green;
        break;
      case 'CANCELED':
        stateColor = Colors.red;
        break;
      case 'PENDING':
      default:
        stateColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 3,
      child: ListTile(
        title:
            Text(cabinet, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text("Date: $formattedDate"),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stateColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                state,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        trailing: (consultationType == 'EN_LIGNE' ||
                    consultationType == 'EN LIGNE') &&
                paymentStatus.toUpperCase() != 'PAYE'
            ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: () {
                  // TODO: Implement payment flow
                },
                child: const Text("Payer"),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Réservations"),
        backgroundColor: const Color(0xFFCA88CD),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReservations,
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  if (_onlineBookings.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Réservations en ligne",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    ..._onlineBookings.map(_buildReservationItem).toList(),
                  ],
                  if (_cabinetBookings.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        "Réservations en cabinet",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    ..._cabinetBookings.map(_buildReservationItem).toList(),
                  ],
                  if (_onlineBookings.isEmpty && _cabinetBookings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 70,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Aucune réservation trouvée",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Vous n'avez pas encore de rendez-vous programmé. Consultez la liste des médecins pour prendre rendez-vous.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
