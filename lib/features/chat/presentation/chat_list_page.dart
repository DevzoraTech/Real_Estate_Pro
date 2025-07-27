import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../data/services/chat_service.dart';
import '../domain/entities/chat.dart';
import 'improved_chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Please log in to view your chats',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<int>(
            stream: _chatService.getTotalUnreadCountStream(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              if (unreadCount > 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Chat list
          Expanded(
            child: StreamBuilder<List<Chat>>(
              stream: _chatService.getUserChatsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading chats',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final chats = snapshot.data ?? [];
                final filteredChats = _searchQuery.isEmpty
                    ? chats
                    : chats.where((chat) {
                        return chat.agentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            (chat.lastMessage?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                      }).toList();

                if (filteredChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No conversations yet'
                              : 'No conversations found',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Start a conversation by messaging an agent from a property listing'
                              : 'Try a different search term',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredChats.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                    indent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    return _buildChatTile(chat);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(Chat chat) {
    return Container(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                chat.agentName.isNotEmpty ? chat.agentName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            if (chat.unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          chat.agentName,
          style: TextStyle(
            fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              chat.lastMessage ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: chat.unreadCount > 0 ? Colors.black87 : Colors.grey[600],
                fontWeight: chat.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            if (chat.lastMessageTime != null)
              Text(
                _formatTime(chat.lastMessageTime!),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: chat.unreadCount > 0
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _openChat(chat),
      ),
    );
  }

  void _openChat(Chat chat) {
    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {
        'agentId': chat.agentId,
        'agentName': chat.agentName,
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
