import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../data/models/chat.dart';
import '../data/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildModernAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildSearchSection(),
              Expanded(child: _buildChatsList()),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Messages',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      actions: [
        StreamBuilder<int>(
          stream: _chatService.getTotalUnreadCountStream(),
          builder: (context, snapshot) {
            final unreadCount = snapshot.data ?? 0;
            if (unreadCount > 0) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.red.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
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
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            suffixIcon:
                _searchQuery.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
    );
  }

  Widget _buildChatsList() {
    return StreamBuilder<List<Chat>>(
      stream: _chatService.getUserChatsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        final chats = snapshot.data ?? [];
        final filteredChats =
            chats.where((chat) {
              if (_searchQuery.isEmpty) return true;
              return chat.otherUserName.toLowerCase().contains(_searchQuery) ||
                  chat.lastMessage.toLowerCase().contains(_searchQuery);
            }).toList();

        if (filteredChats.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: filteredChats.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _buildModernChatItem(filteredChats[index], index);
          },
        );
      },
    );
  }

  Widget _buildModernChatItem(Chat chat, int index) {
    return StreamBuilder<int>(
      stream: _chatService.getUnreadCountStream(chat.id),
      builder: (context, unreadSnapshot) {
        final unreadCount = unreadSnapshot.data ?? 0;
        final hasUnread = unreadCount > 0;

        return AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 50)),
          curve: Curves.easeOutBack,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border:
                  hasUnread
                      ? Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                        width: 1,
                      )
                      : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  HapticFeedback.lightImpact();
                  _navigateToChat(chat);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _buildAvatar(chat, hasUnread),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.otherUserName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          hasUnread
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  _formatTime(chat.lastMessageTime),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        hasUnread
                                            ? AppColors.primary
                                            : Colors.grey[500],
                                    fontWeight:
                                        hasUnread
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.lastMessage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          hasUnread
                                              ? Colors.black87
                                              : Colors.grey[600],
                                      fontWeight:
                                          hasUnread
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasUnread) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary,
                                          AppColors.primary.withOpacity(0.8),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      unreadCount > 99
                                          ? '99+'
                                          : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Chat chat, bool hasUnread) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors:
              hasUnread
                  ? [AppColors.primary, AppColors.primary.withOpacity(0.7)]
                  : [Colors.grey[300]!, Colors.grey[400]!],
        ),
        boxShadow: [
          BoxShadow(
            color: (hasUnread ? AppColors.primary : Colors.grey).withOpacity(
              0.3,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.transparent,
        child: Text(
          chat.otherUserName.isNotEmpty
              ? chat.otherUserName[0].toUpperCase()
              : '?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: hasUnread ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading conversations...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load your conversations',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _searchQuery.isEmpty
                    ? Icons.chat_bubble_outline_rounded
                    : Icons.search_off_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'No conversations yet'
                  : 'No conversations found',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Start a conversation by messaging an agent from a property listing'
                  : 'Try a different search term',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Browse Properties'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToChat(Chat chat) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final otherUserId = chat.participants.firstWhere(
      (id) => id != currentUserId,
    );
    final otherUserName = chat.otherUserName;
    final otherUserRole = chat.otherUserRole;

    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {
        'agentId': otherUserId,
        'agentName': otherUserName,
        'role': otherUserRole,
        'userId': currentUserId,
        'userName': '',
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
        return '${difference.inDays}d ago';
      } else {
        return DateFormat('MMM d').format(dateTime);
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
