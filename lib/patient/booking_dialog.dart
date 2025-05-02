import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:another_flushbar/flushbar.dart';
import '../models/cabinet.dart';
import '../services/booking_service.dart';
import '../user_provider.dart';

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
    setState(() => _isLoading = true);
    try {
      if (widget.cabinet.id == 0) {
        throw Exception('Invalid cabinet ID');
      }

      final datetimes = await _bookingService
          .fetchAvailableDatetimes(widget.cabinet.id.toString());

      if (mounted) {
        setState(() {
          _dateTimeMap = _createDateTimeMap(datetimes);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading available datetimes: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Flushbar(
          message: 'Failed to load available times. Please try again later.',
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.red,
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);
      }
    }
  }

  Map<DateTime, List<String>> _createDateTimeMap(List<DateTime> datetimes) {
    final map = <DateTime, List<String>>{};
    for (var dt in datetimes) {
      final localDt = dt.toLocal();
      final date = DateTime(localDt.year, localDt.month, localDt.day);
      final time =
          '${localDt.hour.toString().padLeft(2, '0')}:${localDt.minute.toString().padLeft(2, '0')}';
      map.putIfAbsent(date, () => []).add(time);
    }
    map.forEach((_, times) => times.sort());
    return map;
  }

  bool _isDateEnabled(DateTime day) {
    if (day.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      return false;
    }
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _dateTimeMap.containsKey(normalizedDay);
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.now(),
      lastDay: DateTime.now().add(Duration(days: 90)),
      focusedDay: _selectedDate ?? DateTime.now(),
      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
      enabledDayPredicate: _isDateEnabled,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDate = selectedDay;
          _selectedTime = null;
        });
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        selectedDecoration: BoxDecoration(
          color: Colors.teal,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }

  Widget _buildTimeDropdown() {
    if (_selectedDate == null) return SizedBox.shrink();

    final date =
        DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    final times = _dateTimeMap[date] ?? [];

    if (times.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          'No available times for selected date',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select time',
        border: OutlineInputBorder(),
      ),
      value: _selectedTime,
      items: times
          .map((time) => DropdownMenuItem(
                value: time,
                child: Text(time),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedTime = value),
    );
  }

  Future<void> _handleBookingConfirmation() async {
    if (_selectedDate == null || _selectedTime == null) {
      Flushbar(
        message: 'Please select a date and time',
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: Colors.orange,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
      return;
    }

    if (UserProvider.user == null) {
      Flushbar(
        message: 'Please login to make a reservation',
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        int.parse(_selectedTime!.split(':')[0]),
        int.parse(_selectedTime!.split(':')[1]),
      );

      final success = await _bookingService.createReservation(
        userID: UserProvider.user!.id.toString(),
        cabinetId: widget.cabinet.id,
        dateTime: dateTime,
      );

      if (!mounted) return;

      Navigator.pop(context);

      Flushbar(
        message:
            success ? 'Reservation confirmed!' : 'Failed to make reservation',
        duration: Duration(seconds: 3),
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: success ? Colors.green : Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } catch (e) {
      if (mounted) {
        Flushbar(
          message: 'Error: $e',
          duration: Duration(seconds: 3),
          margin: EdgeInsets.all(8),
          borderRadius: BorderRadius.circular(8),
          backgroundColor: Colors.red,
          flushbarPosition: FlushbarPosition.TOP,
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Book ${widget.cabinet.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else ...[
              _buildCalendar(),
              SizedBox(height: 16),
              _buildTimeDropdown(),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleBookingConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text('Confirm'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
