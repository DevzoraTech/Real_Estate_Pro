import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../data/services/chat_service.dart';
import '../domain/entities/message.dart';

class ChatPage extends StatefulWidget {
  final String agentId;
  final String agentName;
  const ChatPage({super.key, required this.agentId, required this.agentName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  String _currentUserId = '';
  String _chatId = '';
  bool _sending = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      _chatId = _chatService.generateChatId(_currentUserId, widget.agentId);
      _createChatIfNeeded();
      _markMessagesAsRead();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _createChatIfNeeded() async {
    try {
      await _chatService.createOrGetChat(widget.agentId, widget.agentName);
    } catch (e) {
      print('Error creating chat: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(_chatId, widget.agentId);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Message ${widget.agentName}')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .doc(_getChatId(_currentUserId, widget.agentId))
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Start a conversation with ${widget.agentName}',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _currentUserId;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blue[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? 'You' : (data['senderName'] ?? 'Agent'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMe ? Colors.blue : Colors.black,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              data['message'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (data['timestamp'] != null)
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  _formatTime(data['timestamp']),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _sending
                    ? const CircularProgressIndicator()
                    : IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getChatId(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return ids.join('_');
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp is DateTime) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '';
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _sending = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
    final senderName = userDoc.data()?['displayName'] ?? user.email ?? 'User';
    final chatId = _getChatId(_currentUserId, widget.agentId);
    try {
      print('Attempting to send message to chatId: $chatId');
      print('Message: $message');
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': user.uid,
            'senderName': senderName,
            'receiverId': widget.agentId,
            'message': message,
            'timestamp': FieldValue.serverTimestamp(),
          });
      print('Message sent successfully');
      _messageController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message sent!')));
    } catch (e) {
      print('Send message error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send message.')));
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }
}
