import 'package:app/providers/user_provider.dart';
import 'package:app/screens/chat.dart';
import 'package:app/services/messagerieService.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  static const String routeName = '/chat-list';

  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final MessagerieService _messagerieService = MessagerieService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _messagerieService.getUsers();
      final currentUserId = UserProvider.user?.id.toString();

      setState(() {
        // Exclude current user from the list
        _users = users.where((user) => user['id'] != currentUserId).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshUsers() async {
    return _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = UserProvider.user?.roleType.toUpperCase() == 'PATIENT';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isPatient ? 'Available Doctors' : 'My Patients'),
            Text(
              'Authenticated as: ${UserProvider.user?.email ?? "Not logged in"}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshUsers,
        child: Builder(
          builder: (context) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (_users.isEmpty) {
              return Center(
                child: Text(
                    isPatient ? 'No doctors available' : 'No patients found'),
              );
            }

            return ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPatient ? Colors.blue : Colors.green,
                    child: Text(user['name']?[0] ?? '?'),
                  ),
                  title: Text('${user['name']}'),
                  subtitle: Text(user['email']),
                  trailing: Text(
                    user['roleType']?.toString().toUpperCase() ?? '',
                    style: TextStyle(
                      color: isPatient ? Colors.blue : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          userId: user['id'].toString(),
                          userName: '${user['name']}',
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
