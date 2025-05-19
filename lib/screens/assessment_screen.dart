import 'package:flutter/material.dart';
import 'package:app/services/chat_service.dart';
import 'package:app/models/message.dart';
import 'package:app/services/assessment_storage_service.dart';
import 'package:app/models/assessment_session.dart';
import 'package:app/user_provider.dart';

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

    final currentUser = UserProvider.user;
    if (currentUser == null) {
      print('❌ No user found');
      return;
    }

     final userId = currentUser.id.toString();
    print('🔍 Saving assessment with user ID: $userId');

    setState(() {
      _messages.add(Message(content: text, isUser: true));
      _isLoading = true;
      _questionCount++;
    });
    _textController.clear();

    try {
      final response = await _chatService.continueAssessment(
          _messages,
          userId, // Utiliser l'ID directement
          _selectedLanguage);

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
      final currentUser = UserProvider.user;
      if (currentUser == null) {
        print('❌ No user found for saving assessment');
        return;
      }

      final userId = currentUser.id.toString();
      print('🔍 Saving assessment with user ID: $userId');

      if (_messages.isEmpty) {
        throw Exception('No messages to save');
      }

      final session = AssessmentSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId, 
        timestamp: DateTime.now(),
        conversation: _messages,
        report: _messages.last.content,
        isComplete: true,
      );

      await _storageService.saveSession(session);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suivi de la journal')),
        );
      }
    } catch (e) {
      print('❌ Error saving assessment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur lors de la sauvegarde: ${e.toString()}')),
        );
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suivi de la journal Terminée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Merci d\'avoir complété le suivi de la journal.'),
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

  void _onLanguageChanged(String? value) {
    if (value != null && !_isComplete) {
      setState(() {
        _selectedLanguage = value;
        _messages.clear();
        _startQuiz();
      });
    }
  }

  Widget _buildMessagesArea() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!message.isUser) _buildAvatar(isUser: false),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: message.isUser
                          ? [const Color(0xFFCA88CD), const Color(0xFF8B94CD)]
                          : [Colors.white, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCA88CD).withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (message.isUser) const SizedBox(width: 8),
              if (message.isUser) _buildAvatar(isUser: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 20,
        child: Icon(
          isUser ? Icons.person : Icons.psychology,
          color: const Color(0xFF8B94CD),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCA88CD).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Tapez votre réponse...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onSubmitted: _sendAnswer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendAnswer(_textController.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Suivi de la journal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                dropdownColor: const Color(0xFF8B94CD),
                icon: const Icon(Icons.language, color: Colors.white),
                value: _selectedLanguage,
                items: _languages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: _isComplete ? null : _onLanguageChanged,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              const Color(0xFFE8E9F3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            if (_questionCount > 0)
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFCA88CD),
                      Color(0xFF8B94CD)
                          .withOpacity((_questionCount / 5).clamp(0.0, 1.0)),
                    ],
                  ),
                ),
              ),
            Expanded(child: _buildMessagesArea()),
            if (_isLoading) _buildLoadingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 2,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFCA88CD), Color(0xFF8B94CD)],
        ),
      ),
      child: const LinearProgressIndicator(
        backgroundColor: Colors.transparent,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  // Reste des widgets avec le même style que le chat...
}
