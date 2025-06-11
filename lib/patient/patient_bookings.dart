import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../user_provider.dart';
import 'payment_dialog.dart';

class PatientBookingList extends StatefulWidget {
  const PatientBookingList({Key? key}) : super(key: key);

  @override
  _PatientBookingListState createState() => _PatientBookingListState();
}

class _PatientBookingListState extends State<PatientBookingList>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  List<dynamic> _onlineBookings = [];
  List<dynamic> _cabinetBookings = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Définir les couleurs personnalisées
  final Color lightPurple = Color(0xFFE5C1E5); // Violet clair pour les boutons
  final Color mainPurple = Color(0xFFCA88CD); // Violet principal pour l'AppBar

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
    final isPaid = paymentStatus.toUpperCase() == 'PAYE';
    final isOnline =
        consultationType == 'EN_LIGNE' || consultationType == 'EN LIGNE';

    final formattedDate = date.isNotEmpty
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(date).toLocal())
        : 'Date invalide';

    Color stateColor;
    switch (state.toUpperCase()) {
      case 'CONFIRMED':
        stateColor = Colors.green;
        break;
      case 'REJECTED':
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
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stateColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    state,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isOnline &&
                    state.toUpperCase() == 'CONFIRMED' &&
                    isPaid) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isPaid
                        ? Text(
                            "Payé",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: isOnline
            ? SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPaid
                        ? Colors.green.withAlpha(25)
                        : state.toUpperCase() == 'CONFIRMED'
                            ? Colors.green
                            : lightPurple,
                    foregroundColor: isPaid
                        ? Colors.green
                        : state.toUpperCase() == 'CONFIRMED'
                            ? Colors.white
                            : Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    elevation: isPaid ? 0 : 2,
                  ),
                  icon: Icon(
                    isPaid ? Icons.check_circle : Icons.payment,
                    size: 18,
                  ),
                  label: Text(
                    isPaid ? "Payé" : "Payer",
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: isPaid || state.toUpperCase() != 'CONFIRMED'
                      ? null
                      : () async {
                          await showDialog(
                            context: context,
                            builder: (context) => PaymentDialog(
                              reservation: booking,
                              onPaymentSuccess: () {
                                _loadReservations();
                              },
                            ),
                          );
                        },
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBookingsList(List<dynamic> bookings, {required bool isOnline}) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadReservations,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnline ? Icons.computer : Icons.local_hospital,
                    size: 70,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Aucune réservation ${isOnline ? 'en ligne' : 'en cabinet'} trouvée",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Vous n'avez pas encore de rendez-vous ${isOnline ? 'en ligne' : 'en cabinet'} programmé.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: bookings.length,
        itemBuilder: (context, index) => _buildReservationItem(bookings[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Réservations"),
        backgroundColor: mainPurple,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.computer, size: 20),
                  SizedBox(width: 8),
                  Text('En Ligne'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.local_hospital, size: 20),
                  SizedBox(width: 8),
                  Text('Cabinet'),
                ],
              ),
            ),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Online Reservations Tab
                _buildBookingsList(_onlineBookings, isOnline: true),
                // Cabinet Reservations Tab
                _buildBookingsList(_cabinetBookings, isOnline: false),
              ],
            ),
    );
  }
}
