import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../data/services/chat_service.dart';
import '../domain/entities/message.dart';

class ImprovedChatPage extends StatefulWidget {
  final String agentId;
  final String agentName;
  
  const ImprovedChatPage({
    super.key,
    required this.agentId,
    required this.agentName,
  });

  @override
  State<ImprovedChatPage> createState() => _ImprovedChatPageState();
}

class _ImprovedChatPageState extends State<ImprovedChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final FocusNode _messageFocusNode = FocusNode();
  
  String _currentUserId = '';
  String _chatId = '';
  bool _sending = false;
  bool _isTyping = false;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _setupAnimations();
    _messageController.addListener(_onMessageChanged);
  }

  void _initializeChat() {
    final user = _chatService.currentUserId.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
    if (user != null) {
      _currentUserId = user.uid;
      _chatId = _chatService.generateChatId(_currentUserId, widget.agentId);
      _createChatIfNeeded();
      _markMessagesAsRead();
    }
  }

  void _setupAnimations() {
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _sendButtonAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeInOut),
    );
  }

  void _onMessageChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText && !_sendButtonController.isCompleted) {
      _sendButtonController.forward();
    } else if (!hasText && _sendButtonController.isCompleted) {
      _sendButtonController.reverse();
    }
  }

  Future<void> _createChatIfNeeded() async {
    try {
      final chat = await _chatService.createOrGetChat(widget.agentId, widget.agentName);
      print('Chat created/retrieved: ${chat.id}');
      // Ensure _chatId is set correctly
      if (_chatId != chat.id) {
        setState(() {
          _chatId = chat.id;
        });
      }
    } catch (e) {
      print('Error creating chat: $e');
      _showErrorSnackBar('Error creating chat: $e');
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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              widget.agentName.isNotEmpty ? widget.agentName[0].toUpperCase() : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.agentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Real Estate Agent',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone),
          onPressed: () => _showFeatureComingSoon('Voice call'),
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () => _showFeatureComingSoon('Video call'),
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text('Search Messages'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.clear_all),
                  SizedBox(width: 8),
                  Text('Clear Chat'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<Message>>(
      stream: _chatService.getMessagesStream(_chatId),
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
                  'Error loading messages',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data ?? [];
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Start a conversation',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a message to ${widget.agentName}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        // Auto-scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;
            final showDateHeader = _shouldShowDateHeader(messages, index);
            
            return Column(
              children: [
                if (showDateHeader) _buildDateHeader(message.timestamp),
                _buildMessageBubble(message, isMe),
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldShowDateHeader(List<Message> messages, int index) {
    if (index == 0) return true;
    
    final currentMessage = messages[index];
    final previousMessage = messages[index - 1];
    
    final currentDate = DateTime(
      currentMessage.timestamp.year,
      currentMessage.timestamp.month,
      currentMessage.timestamp.day,
    );
    final previousDate = DateTime(
      previousMessage.timestamp.year,
      previousMessage.timestamp.month,
      previousMessage.timestamp.day,
    );
    
    return currentDate != previousDate;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                widget.agentName.isNotEmpty ? widget.agentName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? Colors.white70 : Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead ? Colors.blue[200] : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _sendButtonAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _sendButtonAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: _messageController.text.trim().isNotEmpty
                        ? AppColors.primary
                        : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    // Ensure chat exists before sending message
    if (_chatId.isEmpty) {
      await _createChatIfNeeded();
      if (_chatId.isEmpty) {
        _showErrorSnackBar('Failed to create chat');
        return;
      }
    }

    setState(() => _sending = true);
    _messageController.clear();
    _sendButtonController.reverse();

    try {
      print('Sending message to chatId: $_chatId, receiverId: ${widget.agentId}');
      await _chatService.sendMessage(
        chatId: _chatId,
        receiverId: widget.agentId,
        content: message,
      );
      
      print('Message sent successfully');
      HapticFeedback.lightImpact();
      
      // Auto-scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Failed to send message: $e');
      _showErrorSnackBar('Failed to send message: $e');
      _messageController.text = message; // Restore message on error
    } finally {
      setState(() => _sending = false);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        _showFeatureComingSoon('Message search');
        break;
      case 'clear':
        _showClearChatDialog();
        break;
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChat();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearChat() async {
    try {
      await _chatService.deleteChat(_chatId);
      _showSuccessSnackBar('Chat cleared successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to clear chat: $e');
    }
  }

  void _showFeatureComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
