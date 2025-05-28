import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

void showToast({required String message}) {
  // Get global navigator key if available
  final context = GlobalKey<NavigatorState>().currentContext;
  if (context == null) {
    print('⚠️ No context available for showing toast');
    return;
  }

  Flushbar(
    message: message,
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(8),
    borderRadius: BorderRadius.circular(8),
    backgroundColor: Colors.black87,
    messageColor: Colors.white,
    flushbarPosition: FlushbarPosition.BOTTOM,
  ).show(context);
}

// Nouvelle méthode avec contexte explicite
void showToastWithContext(BuildContext context, {required String message}) {
  Flushbar(
    message: message,
    duration: const Duration(seconds: 3),
    margin: const EdgeInsets.all(8),
    borderRadius: BorderRadius.circular(8),
    backgroundColor: Colors.black87,
    messageColor: Colors.white,
    flushbarPosition: FlushbarPosition.BOTTOM,
  ).show(context);
}
