import 'package:app/screens/buble.dart';
import 'package:app/services/messagerieService.dart';
import 'package:app/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ChatDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final MessagerieService _messagerieService = MessagerieService();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    if (!await UserProvider.initialize()) {
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacementNamed('/login'); // Replace with your login route
    }
  }

  // Send message to the recipient
  Future<void> sendMessage() async {
    if (!UserProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login to send messages')),
      );
      return;
    }

    if (messageController.text.trim().isEmpty) return;

    try {
      await _messagerieService.sendMessage(
        widget.userId,
        messageController.text,
      );
      messageController.clear();

      // Scroll to bottom after sending message
      Future.delayed(Duration(milliseconds: 100), () {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  // Get messages between current user and receiver
  Stream<QuerySnapshot> getMessages() {
    if (!UserProvider.isAuthenticated) {
      return Stream.empty();
    }
    final currentUser = UserProvider.user;
    if (currentUser == null) {
      // Return an empty stream if no user is logged in
      return Stream.empty();
    }
    return _messagerieService.getMessages(
      currentUser.id.toString(),
      widget.userId,
    );
  }

  // Block a user
  Future<void> blockUser() async {
    try {
      await _messagerieService.blockUser(widget.userId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to block user: $e')),
      );
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Widget _buildMessageList(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }

    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final messages = snapshot.data!.docs.reversed.toList();
    return ListView.builder(
      controller: scrollController,
      reverse: false,
      itemCount: messages.length,
      itemBuilder: (context, index) => _buildMessageItem(messages[index]),
    );
  }

  Widget _buildMessageItem(QueryDocumentSnapshot message) {
    final messageData = message.data() as Map<String, dynamic>;
    final currentUser = UserProvider.user;
    final isMe = currentUser != null &&
        messageData['senderId'].toString() == currentUser.id.toString();

    final DateTime messageTime =
        (messageData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return MessageBubble(
      message: messageData['content'] ?? '',
      isMe: isMe,
      timestamp: messageTime,
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 24.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Block User'),
                onTap: () async {
                  await blockUser();
                  if (!mounted) return;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getMessages(),
              builder: (context, snapshot) => _buildMessageList(snapshot),
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
