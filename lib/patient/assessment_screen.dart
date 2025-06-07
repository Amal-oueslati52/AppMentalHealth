import 'package:flutter/material.dart';
import 'package:rahti/models/message.dart';
import 'package:rahti/services/chat_service.dart';
import 'package:rahti/user_provider.dart';
import 'assessment_history_screen.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({Key? key}) : super(key: key);

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isLoading = false;
  String _selectedLanguage = 'fr';

  @override
  void initState() {
    super.initState();
    _startAssessment();
  }

  Future<void> _startAssessment() async {
    setState(() => _isLoading = true);
    try {
      final response = await _chatService.startAssessment(_selectedLanguage);
      setState(() {
        _messages.add(Message(
          content: response['message'],
          isUser: false,
          timestamp: DateTime.parse(response['timestamp']),
        ));
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    final userId = UserProvider.user?.id.toString();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non connecté')),
      );
      return;
    }

    setState(() {
      _messages.add(Message(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    try {
      final response = await _chatService.continueAssessment(
          _messages, userId, _selectedLanguage);

      setState(() {
        _messages.add(Message(
          content: response['message'],
          isUser: false,
          timestamp: DateTime.parse(response['timestamp']),
        ));

        if (response['isComplete'] == true) {
          // Afficher un message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Évaluation terminée et sauvegardée !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-évaluation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique des évaluations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AssessmentHistoryScreen(),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.8,
                      ),
                      child: Text(
                        message.content,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Votre réponse...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _sendMessage(value);
                          _messageController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () {
                        if (_messageController.text.isNotEmpty) {
                          _sendMessage(_messageController.text);
                          _messageController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
