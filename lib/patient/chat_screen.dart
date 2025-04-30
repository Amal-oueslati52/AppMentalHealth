import 'package:flutter/material.dart';
import 'package:app/services/chat_service.dart'; // Importation du service de chat
import 'package:app/models/message.dart'; // Importation du modèle de message

// Définition de l'écran du chatbot
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Contrôleur pour gérer l'entrée de texte de l'utilisateur
  final TextEditingController _messageController = TextEditingController();

  // Instance du service de chat pour gérer l'envoi et la réception des messages
  final ChatService _chatService = ChatService();

  // Indicateur de chargement pour afficher une animation lorsque le chatbot répond
  bool _isLoading = false;

  // Liste des messages envoyés et reçus sous forme de Map {'role': 'user' ou 'assistant', 'content': 'message'}
  final List<Message> _messages = [];

  // Contrôleur de défilement pour faire défiler automatiquement la liste des messages
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController
        .dispose(); // Libération des ressources du contrôleur de texte
    _scrollController
        .dispose(); // Libération des ressources du contrôleur de défilement
    super.dispose();
  }

  // Fonction pour faire défiler automatiquement la liste des messages vers le bas
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Fonction pour envoyer un message
  void _sendMessage() async {
    if (_messageController.text.isEmpty)
      return; // Vérifie si le champ de texte est vide

    final userMessage =
        _messageController.text; // Récupère le message de l'utilisateur
    _messageController.clear(); // Vide le champ de texte après l'envoi

    // Ajoute le message de l'utilisateur à la liste et affiche l'indicateur de chargement
    setState(() {
      _messages.add(Message(content: userMessage, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // Envoie le message au service et récupère la réponse
      final response = await _chatService.sendMessage(_messages);

      // Ajoute la réponse du chatbot à la liste des messages
      setState(() {
        _messages.add(Message(content: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      // Affiche une alerte en cas d'erreur
      setState(() {
        _messages.add(Message(
          content: 'Error: Unable to get response : $e',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Fonction pour construire une bulle de message
  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment:
          (message.isUser) ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(
          message.isUser ? 64.0 : 16.0,
          4.0,
          message.isUser ? 16.0 : 64.0,
          4.0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: (message.isUser)
              ? const Color.fromARGB(163, 121, 63, 116)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: (message.isUser) ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mental Health Chatbot'),
      backgroundColor: const Color.fromARGB(146, 173, 67, 177), // Couleur de la barre d'application
      ),
      body: Column(
        children: [
          // Affichage des messages sous forme de liste déroulante
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length, // Nombre total de messages
              itemBuilder: (context, index) {
                final message =
                    _messages[index]; // Récupération du message actuel
                return _buildMessageBubble(message);
              },
            ),
          ),
          // Affichage d'un indicateur de chargement si une réponse est en attente
          if (_isLoading) const LinearProgressIndicator(),

          // Zone de saisie et bouton d'envoi
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Champ de saisie pour le message de l'utilisateur
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...', // Texte indicatif
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200], // Fond gris clair
                    ),
                    onSubmitted: (_) =>
                        _sendMessage(), // Envoi du message avec "Entrée"
                  ),
                ),
                // Bouton d'envoi du message
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
