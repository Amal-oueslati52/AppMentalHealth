import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

Widget showFlushBar(
  BuildContext context, {
  duration = const Duration(seconds: 3),
  required message,
  bool success = false,
  double topSpace = kToolbarHeight * 0.7,
  double bottomSpace = 100,
  bool lightBackground = true,
  bool fromBottom = false,
}) {
  // Define gradient colors
  List<Color> successGradient = [
    const Color(0xFF43A047),
    const Color(0xFF66BB6A),
  ];
  List<Color> errorGradient = [
    const Color(0xFFE53935),
    const Color(0xFFEF5350),
  ];

  return Flushbar(
    duration: duration,
    messageText: Row(
      children: [
        const SizedBox(width: 12),
        // Icon based on success/error
        Icon(
          success ? Icons.check_circle : Icons.error,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    ),
    backgroundGradient: LinearGradient(
      colors: success ? successGradient : errorGradient,
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    boxShadows: [
      BoxShadow(
        color: (success ? successGradient[0] : errorGradient[0]).withOpacity(0.3),
        offset: const Offset(0, 4),
        blurRadius: 12,
        spreadRadius: -2,
      ),
    ],
    borderRadius: BorderRadius.circular(16),
    margin: EdgeInsets.only(
      top: fromBottom ? 0 : topSpace,
      bottom: fromBottom ? bottomSpace : 0,
      left: 12,
      right: 12,
    ),
    dismissDirection: FlushbarDismissDirection.HORIZONTAL,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    flushbarPosition: fromBottom ? FlushbarPosition.BOTTOM : FlushbarPosition.TOP,
    animationDuration: const Duration(milliseconds: 400),
    forwardAnimationCurve: Curves.easeOutCubic,
    reverseAnimationCurve: Curves.easeInCubic,
  )..show(context);
}