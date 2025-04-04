import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:another_flushbar/flushbar.dart';
import '../models/cabinet.dart';
import '../services/booking_service.dart';
//import 'package:app/firebase.dart/Auth.dart'; // Assurez-vous d'importer votre service FirebaseAuthService
import 'package:firebase_auth/firebase_auth.dart'; // Importer FirebaseAuth

class BookingDialog extends StatefulWidget {
  final Cabinet cabinet;

  const BookingDialog({
    Key? key,
    required this.cabinet,
  }) : super(key: key);

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final BookingService _bookingService = BookingService();
  // Removed unused field '_firebaseAuthService'
  DateTime? _selectedDate;
  String? _selectedTime;
  Map<DateTime, List<String>> _dateTimeMap = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableDatetimes();
  }

  Future<void> _loadAvailableDatetimes() async {
    try {
      final datetimes = await _bookingService.fetchAvailableDatetimes(widget.cabinet.documentId);
      setState(() {
        _dateTimeMap = _createDateTimeMap(datetimes);
      });
    } catch (e) {
      print('Error loading available datetimes: $e');
      Flushbar(
        message: 'Failed to load available times. Please try again later.',
        duration: Duration(seconds: 3),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  Map<DateTime, List<String>> _createDateTimeMap(List<DateTime> datetimes) {
    final map = <DateTime, List<String>>{};
    for (var dt in datetimes) {
      final localDt = dt.toLocal();
      final date = DateTime(localDt.year, localDt.month, localDt.day);
      final time = '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
      map.putIfAbsent(date, () => []).add(time);
    }
    map.forEach((_, times) => times.sort());
    return map;
  }

  bool _isDateEnabled(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _dateTimeMap.containsKey(normalizedDay);
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(Duration(days: 365)),
      focusedDay: _selectedDate ?? DateTime.now(),
      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
      enabledDayPredicate: _isDateEnabled,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
          _selectedTime = null;
        });
      },
      calendarStyle: CalendarStyle(outsideDaysVisible: false),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  Widget _buildTimeDropdown() {
    if (_selectedDate == null) return SizedBox.shrink();
    final date = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    final times = _dateTimeMap[date] ?? [];
    return DropdownButton<String>(
      isExpanded: true,
      hint: Text('Select time'),
      value: _selectedTime,
      items: times.map((time) => DropdownMenuItem(
        value: time,
        child: Text(time),
      )).toList(),
      onChanged: (value) => setState(() => _selectedTime = value),
    );
  }

  Future<void> _handleBookingConfirmation() async {
    if (_selectedDate == null || _selectedTime == null) {
      Flushbar(
        message: 'Please select a date and time before confirming.',
        duration: Duration(seconds: 3),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: Colors.orange,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
      return;
    }

    final timeParts = _selectedTime!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      hour,
      minute,
    );

    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer l'utilisateur actuellement connecté
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Créer la réservation
      final success = await _bookingService.createReservation(
        userID: user.uid,
        cabinetId: widget.cabinet.id,
        dateTime: dateTime,
      );

      if (!mounted) return;

      Navigator.pop(context);
      Flushbar(
        message: success ? 'Booking confirmed!' : 'Failed to book. Please try again.',
        duration: Duration(seconds: 3),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: success ? Colors.green : Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } catch (e) {
      print('Error during booking confirmation: $e');
      Flushbar(
        message: 'An error occurred. Please try again.',
        duration: Duration(seconds: 3),
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Book ${widget.cabinet.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildCalendar(),
            SizedBox(height: 16),
            _buildTimeDropdown(),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              OverflowBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  if (_selectedDate != null && _selectedTime != null)
                    TextButton(
                      onPressed: _handleBookingConfirmation,
                      child: Text('Confirm'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}