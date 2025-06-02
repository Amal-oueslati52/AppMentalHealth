import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../user_provider.dart';
import '../models/cabinet.dart';
import 'package:another_flushbar/flushbar.dart';

class BookingDialog extends StatefulWidget {
  final Cabinet cabinet;

  const BookingDialog({Key? key, required this.cabinet}) : super(key: key);

  @override
  _BookingDialogState createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final BookingService _bookingService = BookingService();
  List<DateTime> availableSlots = [];
  List<DateTime> availableDates = [];
  DateTime? selectedDate;
  String? selectedTime;
  String? selectedType;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    final slots = await _bookingService
        .fetchAvailableDatetimes(widget.cabinet.id.toString());
    final dates =
        slots.map((e) => DateTime(e.year, e.month, e.day)).toSet().toList();
    dates.sort();

    setState(() {
      availableSlots = slots;
      availableDates = dates;
    });
  }

  List<String> _getTimesForSelectedDate() {
    if (selectedDate == null) return [];
    return availableSlots
        .where((slot) =>
            slot.year == selectedDate!.year &&
            slot.month == selectedDate!.month &&
            slot.day == selectedDate!.day)
        .map((slot) => DateFormat('HH:mm').format(slot))
        .toList();
  }

  void _submitReservation() async {
    if (selectedDate == null || selectedTime == null || selectedType == null) {
      Flushbar(
        message: "Veuillez compléter tous les champs",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.orange,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
      return;
    }

    final hour = int.parse(selectedTime!.split(':')[0]);
    final minute = int.parse(selectedTime!.split(':')[1]);

    final reservationDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      hour,
      minute,
    );

    final success = await _bookingService.createReservation(
      userID: UserProvider.user!.id.toString(),
      cabinetId: widget.cabinet.id,
      dateTime: reservationDateTime,
      consultationType: selectedType!,
      paymentStatus:
          selectedType == 'EN CABINET' ? 'A_REGLE_SUR_PLACE' : 'NO_PAYE',
    );

    if (success) {
      Navigator.pop(context);
      Flushbar(
        message: "Réservation envoyée. En attente de confirmation du médecin.",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.green,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    } else {
      Flushbar(
        message: "Échec de la réservation.",
        duration: Duration(seconds: 3),
        backgroundColor: Colors.red,
        flushbarPosition: FlushbarPosition.TOP,
      ).show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Réserver chez ${widget.cabinet.title}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            if (availableDates.isNotEmpty)
              CalendarDatePicker(
                initialDate: availableDates.first,
                firstDate: availableDates.first,
                lastDate: availableDates.last,
                onDateChanged: (value) {
                  setState(() {
                    selectedDate = value;
                    selectedTime = null;
                  });
                },
              ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Créneau disponible',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: _getTimesForSelectedDate()
                  .map((time) => DropdownMenuItem(
                        value: time,
                        child: Text(time),
                      ))
                  .toList(),
              value: selectedTime,
              onChanged: (val) => setState(() => selectedTime = val),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Type de consultation',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              items: ['EN CABINET', 'EN_LIGNE'].map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type == 'EN_LIGNE'
                        ? 'En ligne (paiement après validation)'
                        : 'En cabinet (paiement sur place)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              value: selectedType,
              onChanged: (val) => setState(() => selectedType = val),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Annuler"),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFCA88CD),
                  ),
                  child: Text("Continuer"),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
