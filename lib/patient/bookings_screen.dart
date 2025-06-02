import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import 'package:intl/intl.dart';
import '../user_provider.dart';
import 'package:another_flushbar/flushbar.dart';

class BookingsScreen extends StatefulWidget {
  @override
  _BookingsScreenState createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final BookingService _bookingService = BookingService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings({int page = 1}) async {
    if (mounted) setState(() => _isLoading = true);

    try {
      if (UserProvider.user == null) throw Exception('User not logged in');

      final result = await _bookingService.fetchUserBookings(
        userID: UserProvider.user!.id.toString(),
        page: page,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          _bookings = result['data'] ?? [];
          final pagination = result['meta']?['pagination'];
          if (pagination != null) {
            _currentPage = pagination['page'] ?? 1;
            _totalPages = pagination['pageCount'] ?? 1;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        Flushbar(
          message: 'Error loading bookings: $e',
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.red,
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return Colors.green;
      case 'CANCELED':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      final success = await _bookingService.cancelReservation(bookingId);
      if (success) {
        _loadBookings(page: _currentPage);
        if (mounted) {
          Flushbar(
            message: 'Réservation annulée avec succès',
            duration: Duration(seconds: 3),
            margin: EdgeInsets.all(8),
            borderRadius: BorderRadius.circular(8),
            backgroundColor: Colors.green,
            flushbarPosition: FlushbarPosition.TOP,
          ).show(context);
        }
      } else {
        throw Exception('Échec de l\'annulation');
      }
    } catch (e) {
      if (mounted) {
        Flushbar(
          message: 'Erreur: $e',
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.red,
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);
      }
    }
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1
                ? () => _loadBookings(page: _currentPage - 1)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFCA88CD),
            ),
            child: Text('Précédent'),
          ),
          Text('Page $_currentPage sur $_totalPages'),
          ElevatedButton(
            onPressed: _currentPage < _totalPages
                ? () => _loadBookings(page: _currentPage + 1)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFCA88CD),
            ),
            child: Text('Suivant'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Réservations'),
        backgroundColor: Color(0xFFCA88CD),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadBookings(page: _currentPage),
              child: _bookings.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune réservation trouvée',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              final booking = _bookings[index];
                              final attributes = booking['attributes'] ?? {};
                              DateTime? date;
                              try {
                                date = DateTime.parse(attributes['date'] ?? '')
                                    .toLocal();
                              } catch (_) {
                                date = DateTime.now();
                              }

                              final formattedDate =
                                  DateFormat('dd/MM/yyyy HH:mm').format(date);
                              final cabinet = attributes['cabinet']?['data']
                                      ?['attributes'] ??
                                  {};
                              final status = attributes['state'] ?? 'PENDING';
                              final consultationType =
                                  attributes['Consultation_type'] ?? 'N/A';
                              final paymentStatus =
                                  attributes['payment_status'] ?? 'N/A';

                              return Card(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: ListTile(
                                  title: Text(
                                    cabinet['title'] ?? 'Cabinet inconnu',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(formattedDate),
                                      SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(status),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Type: $consultationType',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Paiement: $paymentStatus',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: status == 'PENDING'
                                      ? IconButton(
                                          icon: Icon(Icons.cancel,
                                              color: Colors.red),
                                          onPressed: () => _cancelBooking(
                                              booking['id'].toString()),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                        if (_totalPages > 1) _buildPaginationControls(),
                      ],
                    ),
            ),
    );
  }
}