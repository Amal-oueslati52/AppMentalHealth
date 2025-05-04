import 'package:app/models/message.dart';

class AssessmentSession {
  final String id;
  final String userId;
  final DateTime timestamp;
  final List<Message> conversation;
  final String? report;
  final bool isComplete;

  AssessmentSession({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.conversation,
    this.report,
    this.isComplete = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'conversation': conversation.map((m) => m.toJson()).toList(),
        'report': report,
        'isComplete': isComplete,
      };

  factory AssessmentSession.fromJson(Map<String, dynamic> json) {
    return AssessmentSession(
      id: json['id'],
      userId: json['userId'],
      timestamp: DateTime.parse(json['timestamp']),
      conversation: (json['conversation'] as List)
          .map((m) => Message.fromJson(m))
          .toList(),
      report: json['report'],
      isComplete: json['isComplete'] ?? false,
    );
  }
}
