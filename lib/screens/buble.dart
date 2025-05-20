import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormatted = DateFormat('HH:mm').format(timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFCA88CD) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeFormatted,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withOpacity(0.8)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
