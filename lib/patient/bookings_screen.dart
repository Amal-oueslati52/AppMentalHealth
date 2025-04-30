import 'package:flutter/material.dart';
import 'package:app/services/booking_service.dart';
import 'package:intl/intl.dart';
import 'package:app/user_provider.dart';

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
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      if (UserProvider.user == null) {
        throw Exception('User not logged in');
      }

      final result = await _bookingService.fetchUserBookings(
        userID: UserProvider.user!.id.toString(),
        page: page,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          _bookings = result['data'];
          final pagination = result['meta']?['pagination'];
          if (pagination != null) {
            _currentPage = pagination['page'] ?? 1;
            _totalPages = pagination['pageCount'] ?? 1;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: _currentPage > 1
              ? () => _loadBookings(page: _currentPage - 1)
              : null,
          child: Text('Previous'),
        ),
        Text('Page $_currentPage of $_totalPages'),
        ElevatedButton(
          onPressed: _currentPage < _totalPages
              ? () => _loadBookings(page: _currentPage + 1)
              : null,
          child: Text('Next'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        backgroundColor: Color(0xFFCA88CD),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadBookings(page: _currentPage),
              child: _bookings.isEmpty
                  ? Center(child: Text('No bookings found'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _bookings.length,
                            itemBuilder: (context, index) {
                              final booking = _bookings[index];
                              DateTime? date;
                              try {
                                // Parse UTC date et convertit en local
                                date = DateTime.parse(booking['date'] ?? '')
                                    .toLocal();
                              } catch (e) {
                                date = DateTime.now();
                              }

                              final formattedDate =
                                  DateFormat('MMM d, y - HH:mm').format(date);
                              final cabinet = booking['cabinet'] ?? {};

                              return ListTile(
                                title:
                                    Text(cabinet['title'] ?? 'Unknown cabinet'),
                                subtitle: Text(formattedDate),
                                trailing: Text(
                                  booking['state'] ?? 'PENDING',
                                  style: TextStyle(
                                    color: (booking['state'] ?? 'PENDING')
                                                .trim() ==
                                            'CONFIRMED'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
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
