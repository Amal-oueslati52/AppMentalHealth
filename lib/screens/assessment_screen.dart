import 'package:flutter/material.dart';
import 'package:app/services/chat_service.dart';
import 'package:app/models/message.dart';
import 'package:app/services/assessment_storage_service.dart';
import 'package:app/models/assessment_session.dart';

class AssessmentScreen extends StatefulWidget {
  @override
  _AssessmentScreenState createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  final AssessmentStorageService _storageService = AssessmentStorageService();
  bool _isLoading = false;
  bool _isComplete = false;
  int _questionCount = 0;
  String _selectedLanguage = 'fr';
  final Map<String, String> _languages = {
    'fr': 'Français',
    'ar': 'العربية',
    'en': 'English'
  };

  @override
  void initState() {
    super.initState();
    _startQuiz();
  }

  Future<void> _startQuiz() async {
    setState(() => _isLoading = true);
    try {
      final response = await _chatService.startAssessment(_selectedLanguage);
      setState(() {
        _messages.add(Message(content: response['message'], isUser: false));
        _isLoading = false;
        _questionCount = 0;
      });
    } catch (e) {
      print('❌ Error starting quiz: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendAnswer(String text) async {
    if (text.isEmpty) return;
    setState(() {
      _messages.add(Message(content: text, isUser: true));
      _isLoading = true;
      _questionCount++;
    });
    _textController.clear();

    try {
      final response = await _chatService.continueAssessment(
          _messages, 'userId', _selectedLanguage);

      setState(() {
        _messages.add(Message(content: response['message'], isUser: false));
        _isLoading = false;
        _isComplete = response['isComplete'] ?? false;
      });

      if (_isComplete) {
        _showCompletionDialog();
      }
    } catch (e) {
      print('❌ Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAssessmentSession() async {
    try {
      final session = AssessmentSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'userId',
        timestamp: DateTime.now(),
        conversation: _messages,
        report: _messages.last.content,
        isComplete: true,
      );

      await _storageService.saveSession(session);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Évaluation sauvegardée')),
      );
    } catch (e) {
      print('❌ Error saving assessment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde')),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Évaluation Terminée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Merci d\'avoir complété l\'évaluation.'),
            SizedBox(height: 8),
            Text('Voulez-vous sauvegarder cette session ?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveAssessmentSession();
              Navigator.of(context).pop();
            },
            child: Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: Colors.teal[100],
              child: Icon(Icons.psychology,
                  color: const Color.fromARGB(255, 128, 72, 106)),
              radius: 20,
            ),
          SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.teal[100] : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: const Color.fromARGB(255, 158, 100, 144),
              child: Icon(Icons.person, color: Colors.white),
              radius: 20,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal[700],
        title: Text(
          'Suivi de la santé mentale',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              dropdownColor: Colors.white,
              icon: Icon(Icons.language, color: Colors.white),
              underline: Container(),
              value: _selectedLanguage,
              items: _languages.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: _isComplete
                  ? null
                  : (value) {
                      setState(() {
                        _selectedLanguage = value!;
                        _messages.clear();
                        _startQuiz();
                      });
                    },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 6,
              child: LinearProgressIndicator(
                value: _questionCount / 5,
                backgroundColor: Colors.teal[100],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[700]!),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal[700]!),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tapez votre réponse...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.teal[700],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: () => _sendAnswer(_textController.text),
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
}
