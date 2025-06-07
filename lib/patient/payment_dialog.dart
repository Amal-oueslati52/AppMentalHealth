import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/booking_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class PaymentDialog extends StatefulWidget {
  final Map<String, dynamic> reservation;
  final Function onPaymentSuccess;

  const PaymentDialog({
    Key? key,
    required this.reservation,
    required this.onPaymentSuccess,
  }) : super(key: key);

  @override
  _PaymentDialogState createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isProcessing = false;
  String? _currentPaymentStatus;
  Timer? _statusCheckTimer;
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
    // Vérifier le statut toutes les 5 secondes
    _statusCheckTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _checkPaymentStatus());
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  String _formatCardNumber(String text) {
    if (text.isEmpty) return '';
    text = text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      // Simuler un délai de traitement
      await Future.delayed(const Duration(seconds: 2));

      // Get the documentId from the reservation data
      final documentId =
          widget.reservation['attributes']?['documentId']?.toString();
      if (documentId == null) throw Exception('Invalid reservation ID');

      print('📝 Processing payment for reservation: $documentId');

      final success = await _bookingService.updatePaymentStatus(
        documentId,
        'PAYE',
      );

      if (!mounted) return;

      if (success) {
        widget.onPaymentSuccess();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement effectué avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Échec du paiement');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _checkPaymentStatus() async {
    try {
      // Get the documentId from the reservation data
      final documentId =
          widget.reservation['attributes']?['documentId']?.toString();
      if (documentId == null) return;

      print('🔍 Checking payment status for reservation: $documentId');

      final status = await _bookingService.checkPaymentStatus(documentId);

      if (!mounted) return;

      if (status != _currentPaymentStatus) {
        setState(() => _currentPaymentStatus = status);
        if (status == 'PAYE') {
          widget.onPaymentSuccess();
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement confirmé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du statut: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.reservation['amount'] ?? 30.0;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement de la consultation',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Montant à payer: ${NumberFormat.currency(locale: 'fr_FR', symbol: 'Dt').format(amount)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                // Numéro de carte
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de carte',
                    hintText: '1234 5678 9012 3456',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un numéro de carte';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    final formattedValue = _formatCardNumber(value);
                    if (formattedValue != value) {
                      _cardNumberController.value = TextEditingValue(
                        text: formattedValue,
                        selection: TextSelection.collapsed(
                            offset: formattedValue.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Date d'expiration
                TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'Date d\'expiration',
                    hintText: 'MM/YY',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // CVV
                TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un CVV';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Nom sur la carte
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom sur la carte',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le nom sur la carte';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCA88CD),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Payer',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
