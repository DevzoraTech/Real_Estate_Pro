import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audioplayers/audioplayers.dart' as audio_players;
import 'package:flutter_sound/flutter_sound.dart' as flutter_sound;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async'; // Added for Timer
import 'dart:typed_data';
import 'dart:math' as math;
import '../../../core/theme/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../data/services/chat_service.dart';
import '../data/services/notification_service.dart';
import '../domain/entities/message.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

extension MessageJson on Message {
  Map<String, dynamic> toJson() => {
    'id': id,
    'chatId': chatId,
    'senderId': senderId,
    'senderName': senderName,
    'receiverId': receiverId,
    'content': content,
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'timestamp': timestamp.toIso8601String(),
    'isEdited': isEdited,
    'propertyId': propertyId,
    'propertyTitle': propertyTitle,
    'propertyPrice': propertyPrice,
    'propertyImage': propertyImage,
    'propertyAddress': propertyAddress,
    'replyToMessageId': replyToMessageId,
    'replyToContent': replyToContent,
    'replyToSenderName': replyToSenderName,
  };
  static Message fromJson(Map<String, dynamic> json) => Message(
    id: json['id'],
    chatId: json['chatId'],
    senderId: json['senderId'],
    senderName: json['senderName'],
    receiverId: json['receiverId'],
    content: json['content'],
    type: MessageType.values.firstWhere(
      (e) => e.toString().split('.').last == (json['type'] ?? 'text'),
      orElse: () => MessageType.text,
    ),
    status: MessageStatus.values.firstWhere(
      (e) => e.toString().split('.').last == (json['status'] ?? 'sending'),
      orElse: () => MessageStatus.sending,
    ),
    timestamp: DateTime.parse(json['timestamp']),
    isEdited: json['isEdited'] ?? false,
    propertyId: json['propertyId'],
    propertyTitle: json['propertyTitle'],
    propertyPrice: (json['propertyPrice'] as num?)?.toDouble(),
    propertyImage: json['propertyImage'],
    propertyAddress: json['propertyAddress'],
    replyToMessageId: json['replyToMessageId'],
    replyToContent: json['replyToContent'],
    replyToSenderName: json['replyToSenderName'],
  );
}

class ImprovedChatPage extends StatefulWidget {
  final String agentId;
  final String agentName;
  final String? role;
  final String? propertyId;
  final String? propertyTitle;
  final double? propertyPrice;
  final String? propertyImage;
  final String? propertyAddress;

  const ImprovedChatPage({
    super.key,
    required this.agentId,
    required this.agentName,
    this.role,
    this.propertyId,
    this.propertyTitle,
    this.propertyPrice,
    this.propertyImage,
    this.propertyAddress,
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
  String _otherUserId = '';
  String _otherUserName = '';
  String _chatId = '';
  bool _sending = false;
  bool _isTyping = false;
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonAnimation;
  bool _initialized = false;

  // Voice recording
  final audio_players.AudioPlayer _audioPlayer = audio_players.AudioPlayer();
  final flutter_sound.FlutterSoundRecorder _audioRecorder =
      flutter_sound.FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingMessageId;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartTime;
  String? _recordingFilePath;
  Timer? _recordingTimer;

  // Reply functionality
  Message? _replyingTo;
  final TextEditingController _replyController = TextEditingController();

  // Status fields
  bool _otherUserOnline = false;
  DateTime? _otherUserLastSeen;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;

  // Add to _ImprovedChatPageState:
  List<Message> _messages = [];
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastMessageDoc;
  bool _hasMore = true;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _isOnline = true;
  List<Message> _queuedMessages = [];

  // 1. Add a getter for the Firestore stream:
  Stream<List<Message>> get _messageStream {
    if (_chatId.isEmpty) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  StreamSubscription<DocumentSnapshot>? _typingSubscription;
  bool _otherUserTyping = false;
  final _typingSubject = PublishSubject<void>();
  StreamSubscription? _typingDebounceSub;

  // Multi-message selection
  Set<String> _selectedMessageIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _messageController.addListener(_onMessageChanged);
    _scrollController.addListener(_onScroll);

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      final wasOnline = _isOnline;
      final mainResult =
          result.isNotEmpty ? result.first : ConnectivityResult.none;
      _isOnline = mainResult != ConnectivityResult.none;
      if (_isOnline && !wasOnline) {
        _sendQueuedMessages();
      }
      setState(() {});
    });

    _loadQueuedMessages();

    // Setup typing debounce
    _typingDebounceSub = _typingSubject
        .debounceTime(const Duration(milliseconds: 1500))
        .listen((_) {
          _setTyping(false);
        });

    // Initialize chat FIRST, then setup listeners
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      setState(() {
        _currentUserId = currentUser.uid;
        _otherUserId = widget.agentId;
        _otherUserName = widget.agentName;
      });

      await _createChatIfNeeded();

      // NOW setup listeners after chat is initialized
      _listenToOtherUserTyping();
      _listenToOtherUserStatus();

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 100 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadInitialMessages() async {
    setState(() {
      _isLoadingMore = true;
    });
    final query = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(20);
    final snapshot = await query.get();
    final newMessages =
        snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    setState(() {
      _messages = newMessages;
      _isLoadingMore = false;
      _hasMore = snapshot.docs.length == 20;
      _lastMessageDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_lastMessageDoc == null) return;
    setState(() {
      _isLoadingMore = true;
    });
    final query = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(_lastMessageDoc!)
        .limit(20);
    final snapshot = await query.get();
    final newMessages =
        snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    setState(() {
      _messages.addAll(newMessages);
      _isLoadingMore = false;
      _hasMore = snapshot.docs.length == 20;
      _lastMessageDoc =
          snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastMessageDoc;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initializeChatWithRoute();
      _initialized = true;
    }
    _listenToOtherUserStatus();
  }

  void _initializeChatWithRoute() {
    final user =
        _chatService.currentUserId.isNotEmpty
            ? FirebaseAuth.instance.currentUser
            : null;
    if (user != null) {
      _currentUserId = user.uid;
      // Determine the other participant
      if (_currentUserId == widget.agentId) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map) {
          _otherUserId = args['userId'] ?? '';
          _otherUserName = args['userName'] ?? '';
        }
        if (_otherUserId.isEmpty) {
          _otherUserId = widget.agentId;
          _otherUserName = widget.agentName;
        }
      } else {
        _otherUserId = widget.agentId;
        _otherUserName = widget.agentName;
      }
      _chatId = _chatService.generateChatId(_currentUserId, _otherUserId);
      _resetAndLoadMessages();
      _markMessagesAsRead();
    }
  }

  void _resetAndLoadMessages() {
    setState(() {
      _messages = [];
      _lastMessageDoc = null;
      _hasMore = true;
      _isLoadingMore = false;
    });
    _loadInitialMessages();
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
    if (hasText) {
      _setTyping(true);
      _typingSubject.add(null);
    } else {
      _setTyping(false);
    }
    if (hasText && !_sendButtonController.isCompleted) {
      _sendButtonController.forward();
    } else if (!hasText && _sendButtonController.isCompleted) {
      _sendButtonController.reverse();
    }
  }

  Future<void> _createChatIfNeeded() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userName = currentUser?.displayName ?? 'User';

      final chat = await _chatService.createOrGetChat(
        widget.agentId,
        widget.agentName,
        userName: userName,
      );
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
    _audioPlayer.dispose();
    _audioRecorder.closeRecorder();
    _recordingTimer?.cancel();
    _statusSubscription?.cancel();
    _connectivitySubscription.cancel();
    _typingSubscription?.cancel();
    _typingDebounceSub?.cancel();
    _typingSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Remove the typing indicator from here
          Expanded(child: _buildMessagesList()),
          _buildReplyPreview(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTypingAnimation() {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(
                  0,
                  -8 * math.sin((value * 2 * math.pi) + (index * 0.6)),
                ),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title:
          _selectionMode
              ? Text('${_selectedMessageIds.length} selected')
              : Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.agentName.isNotEmpty
                          ? widget.agentName[0].toUpperCase()
                          : 'A',
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
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color:
                                    _otherUserOnline
                                        ? Colors.green
                                        : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Expanded(
                              child:
                                  _otherUserOnline
                                      ? const Text(
                                        'Online',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                      : Text(
                                        _otherUserLastSeen != null
                                            ? 'Last seen: ${_formatLastSeen(_otherUserLastSeen)}'
                                            : 'Offline',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                            ),
                          ],
                        ),
                        Text(
                          widget.role ?? 'Real Estate Agent',
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
      actions:
          _selectionMode
              ? [
                if (_selectedMessageIds.length == 1)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      final msgId = _selectedMessageIds.first;
                      final msg = _messages.firstWhereOrNull(
                        (m) => m.id == msgId,
                      );
                      if (msg != null) _editMessage(msg);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed:
                      _selectedMessageIds.isEmpty
                          ? null
                          : _deleteSelectedMessages,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _exitSelectionMode,
                ),
              ]
              : [
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
                  itemBuilder:
                      (context) => [
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
                IconButton(
                  icon: Icon(Icons.bug_report),
                  onPressed: () {
                    _debugTypingSystem();
                    _setTyping(true);
                    Future.delayed(
                      Duration(seconds: 3),
                      () => _setTyping(false),
                    );
                  },
                ),
              ],
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<Message>>(
      stream: _messageStream,
      builder: (context, snapshot) {
        final firestoreMessages = snapshot.data ?? [];
        final queued =
            _queuedMessages
                .where((q) => firestoreMessages.every((m) => m.id != q.id))
                .toList();
        final allMessages = [...queued, ...firestoreMessages];

        if (allMessages.isNotEmpty &&
            allMessages.first.senderId == _currentUserId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount:
              allMessages.length +
              (_otherUserTyping ? 1 : 0), // Add 1 for typing indicator
          itemBuilder: (context, index) {
            // Show typing indicator at index 0 (top of reversed list)
            if (index == 0 && _otherUserTyping) {
              return _buildTypingIndicatorBubble();
            }

            // Adjust index for actual messages
            final messageIndex = _otherUserTyping ? index - 1 : index;
            final message = allMessages[messageIndex];
            final isMe = message.senderId == _currentUserId;
            final showDateHeader =
                messageIndex == allMessages.length - 1 ||
                _shouldShowDateHeader(allMessages, messageIndex);

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
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : 'U',
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
            child: GestureDetector(
              onLongPress: () {
                if (!_selectionMode) {
                  setState(() {
                    _selectionMode = true;
                    _selectedMessageIds.add(message.id);
                  });
                }
              },
              onTap: () {
                if (_selectionMode) {
                  setState(() {
                    if (_selectedMessageIds.contains(message.id)) {
                      _selectedMessageIds.remove(message.id);
                      if (_selectedMessageIds.isEmpty) _selectionMode = false;
                    } else {
                      _selectedMessageIds.add(message.id);
                    }
                  });
                }
              },
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0) {
                  // Swipe right - reply to message
                  _setReplyTo(message);
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      _selectedMessageIds.contains(message.id)
                          ? Colors.blue.withOpacity(0.2)
                          : (isMe ? AppColors.primary : Colors.white),
                  border:
                      _selectedMessageIds.contains(message.id)
                          ? Border.all(color: Colors.blue, width: 2)
                          : null,
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
                    _buildPropertyTag(message),
                    if (message.replyToMessageId != null)
                      _buildReplyIndicator(message),
                    if (message.type == MessageType.voice)
                      _buildVoiceMessage(message, isMe)
                    else
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
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(edited)',
                            style: TextStyle(
                              color: isMe ? Colors.white60 : Colors.grey[400],
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (!isMe) ...[
                          const SizedBox(width: 4),
                          Text(
                            message.senderName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color:
                                message.isRead
                                    ? Colors.blue[200]
                                    : Colors.white70,
                          ),
                        ],
                        if (_queuedMessages.any((m) => m.id == message.id)) ...[
                          const SizedBox(width: 4),
                          Text(
                            'Queued...',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyingTo!.senderName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyingTo!.content,
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelReply,
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
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
      child: Column(
        children: [
          // Recording indicator
          if (_isRecording)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.mic, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recording... ${_recordingDuration.inSeconds}s',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _stopRecording,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.stop,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Message input row
          Row(
            children: [
              // Attachment button
              PopupMenuButton<String>(
                icon: Icon(Icons.attach_file, color: Colors.grey[600]),
                onSelected: (value) {
                  switch (value) {
                    case 'camera':
                      _pickImage(ImageSource.camera);
                      break;
                    case 'gallery':
                      _pickImage(ImageSource.gallery);
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'camera',
                        child: Row(
                          children: [
                            Icon(Icons.camera_alt),
                            SizedBox(width: 8),
                            Text('Camera'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'gallery',
                        child: Row(
                          children: [
                            Icon(Icons.photo_library),
                            SizedBox(width: 8),
                            Text('Gallery'),
                          ],
                        ),
                      ),
                    ],
              ),
              const SizedBox(width: 8),
              // Voice recording button
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.red : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic,
                    color: _isRecording ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Text input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: _sending ? null : _sendMessage,
                child: AnimatedBuilder(
                  animation: _sendButtonAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _sendButtonAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              _messageController.text.trim().isNotEmpty
                                  ? AppColors.primary
                                  : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.send,
                          color:
                              _messageController.text.trim().isNotEmpty
                                  ? Colors.white
                                  : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _sending) return;

    // Ensure all required fields are set
    if (_currentUserId.isEmpty ||
        _otherUserId.isEmpty ||
        _otherUserName.isEmpty ||
        _chatId.isEmpty) {
      _showErrorSnackBar('Chat is not ready yet. Please wait...');
      return;
    }

    setState(() {
      _sending = true;
    });

    if (!_isOnline) {
      // Queue the message
      final queued = Message(
        id: UniqueKey().toString(),
        chatId: _chatId,
        senderId: _currentUserId,
        senderName: _otherUserName,
        receiverId: _otherUserId,
        content: message,
        timestamp: DateTime.now(),
        type: MessageType.text,
        status: MessageStatus.sending,
        isEdited: false,
        propertyId: widget.propertyId,
        propertyTitle: widget.propertyTitle,
        propertyPrice: widget.propertyPrice,
        propertyImage: widget.propertyImage,
        propertyAddress: widget.propertyAddress,
        replyToMessageId: _replyingTo?.id,
        replyToContent: _replyingTo?.content,
        replyToSenderName: _replyingTo?.senderName,
      );
      setState(() {
        _queuedMessages.insert(0, queued);
        _messages.insert(0, queued);
        _sending = false;
      });
      _saveQueuedMessages();
      _messageController.clear();
      _cancelReply();
      return;
    }

    try {
      await _chatService.sendMessage(
        chatId: _chatId,
        receiverId: _otherUserId,
        content: message,
        propertyId: widget.propertyId,
        propertyTitle: widget.propertyTitle,
        propertyPrice: widget.propertyPrice,
        propertyImage: widget.propertyImage,
        propertyAddress: widget.propertyAddress,
        replyToMessageId: _replyingTo?.id,
        replyToContent: _replyingTo?.content,
        replyToSenderName: _replyingTo?.senderName,
      );

      _messageController.clear();
      _cancelReply(); // Clear reply state
    } catch (e) {
      print('Error sending message: $e');
      _showErrorSnackBar('Error sending message: $e');
    } finally {
      setState(() {
        _sending = false;
      });
    }
  }

  Future<void> _sendQueuedMessages() async {
    if (_queuedMessages.isEmpty) return;
    final toSend = List<Message>.from(_queuedMessages);
    for (final msg in toSend) {
      try {
        await _chatService.sendMessage(
          chatId: _chatId,
          receiverId: _otherUserId,
          content: msg.content,
          propertyId: widget.propertyId,
          propertyTitle: widget.propertyTitle,
          propertyPrice: widget.propertyPrice,
          propertyImage: widget.propertyImage,
          propertyAddress: widget.propertyAddress,
          replyToMessageId: msg.replyToMessageId,
          replyToContent: msg.replyToContent,
          replyToSenderName: msg.replyToSenderName,
        );
        setState(() {
          _messages.removeWhere((m) => m.id == msg.id);
          _queuedMessages.removeWhere((m) => m.id == msg.id);
        });
        _saveQueuedMessages();
      } catch (e) {
        print('Failed to send queued message: $e');
      }
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
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat'),
            content: const Text(
              'Are you sure you want to clear this conversation? This action cannot be undone.',
            ),
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
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
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

  void _showMessageOptions(Message message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.primary),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  void _editMessage(Message message) {
    final TextEditingController editController = TextEditingController(
      text: message.content,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Edit Message',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: TextField(
                controller: editController,
                decoration: InputDecoration(
                  hintText: 'Edit your message...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                maxLines: 3,
                autofocus: true,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  textStyle: const TextStyle(fontWeight: FontWeight.w500),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newContent = editController.text.trim();
                  if (newContent.isNotEmpty && newContent != message.content) {
                    try {
                      await _chatService.editMessage(
                        _chatId,
                        message.id,
                        newContent,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message edited successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      if (mounted) _exitSelectionMode();
                    } catch (e) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error editing message: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _deleteMessage(Message message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Message'),
            content: const Text(
              'Are you sure you want to delete this message? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _chatService.deleteMessage(_chatId, message.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting message: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
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

  void _setReplyTo(Message message) {
    setState(() {
      _replyingTo = message;
    });
    _messageFocusNode.requestFocus();
    _showSuccessSnackBar(
      'Replying to: ${message.content.substring(0, message.content.length > 30 ? 30 : message.content.length)}...',
    );
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
      );

      if (image != null) {
        final file = File(image.path);
        await _chatService.sendImageMessage(
          chatId: _chatId,
          receiverId: _otherUserId,
          imageFile: file,
        );
        _scrollToBottom();
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      // Initialize recorder
      await _audioRecorder.openRecorder();

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });

      // Start timer for recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        } else {
          timer.cancel();
        }
      });

      // Store the recording start time for duration calculation
      _recordingStartTime = DateTime.now();

      // Create file path for recording
      final appDir = await getApplicationDocumentsDirectory();
      final voiceDir = Directory('${appDir.path}/voice_notes');
      if (!await voiceDir.exists()) {
        await voiceDir.create(recursive: true);
      }
      final path =
          '${voiceDir.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
      _recordingFilePath = path;

      // Start real microphone recording
      await _audioRecorder.startRecorder(
        toFile: path,
        codec: flutter_sound.Codec.aacADTS,
      );

      print('Real voice recording started: $path');
    } catch (e) {
      print('Error starting recording: $e');
      _showErrorSnackBar('Error starting recording: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      // Stop the audio recorder
      if (_isRecording) {
        final path = await _audioRecorder.stopRecorder();
        print('Real voice recording stopped: $path');
        _recordingFilePath = path;
        await _audioRecorder.closeRecorder();
      }

      // Cancel recording timer
      _recordingTimer?.cancel();

      // Send the voice message if recording duration is valid
      if (_recordingDuration.inSeconds > 0) {
        try {
          final duration = _recordingDuration.inSeconds;
          File? audioFile;

          if (_recordingFilePath != null) {
            // Use real recording file
            audioFile = File(_recordingFilePath!);
          }

          if (audioFile != null && await audioFile.exists()) {
            // Send as real voice message with file
            await _chatService.sendVoiceMessage(
              chatId: _chatId,
              receiverId: _otherUserId,
              audioFile: audioFile,
              duration: duration,
            );
            _scrollToBottom();
            print('Real voice message sent successfully: ${audioFile.path}');
          } else {
            // Fallback to text message
            await _chatService.sendMessage(
              chatId: _chatId,
              receiverId: _otherUserId,
              content: '🎤 Voice message (${duration}s)',
              type: MessageType.voice,
            );
            _scrollToBottom();
            print('Voice message sent as text: ${duration}s');
          }
        } catch (error) {
          print('Error with voice message: $error');
          _showErrorSnackBar('Error sending voice message: $error');
        }
      }

      setState(() {
        _isRecording = false;
        _recordingDuration = Duration.zero;
        _recordingFilePath = null;
      });
    } catch (e) {
      print('Error stopping recording: $e');
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  Future<void> _playVoiceMessage(String messageId, String audioUrl) async {
    try {
      if (_isPlaying && _currentPlayingMessageId == messageId) {
        // Stop current playback
        await _audioPlayer.stop();
        setState(() {
          _isPlaying = false;
          _currentPlayingMessageId = null;
        });
      } else {
        // Start new playback
        if (_isPlaying) {
          await _audioPlayer.stop();
        }

        await _audioPlayer.play(audio_players.UrlSource(audioUrl));
        setState(() {
          _isPlaying = true;
          _currentPlayingMessageId = messageId;
        });

        // Listen for completion
        _audioPlayer.onPlayerComplete.listen((_) {
          setState(() {
            _isPlaying = false;
            _currentPlayingMessageId = null;
          });
        });
      }
    } catch (e) {
      print('Error playing voice message: $e');
      _showErrorSnackBar('Error playing voice message: $e');
    }
  }

  Widget _buildVoiceMessage(Message message, bool isMe) {
    return GestureDetector(
      onTap: () {
        if (message.fileUrl != null) {
          _playVoiceMessage(message.id, message.fileUrl!);
        } else {
          // Show a message that this is a voice message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice message: ${message.content}'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? Colors.white.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying && _currentPlayingMessageId == message.id
                  ? Icons.pause
                  : Icons.play_arrow,
              color: isMe ? Colors.white : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileUrl != null ? 'Voice Message' : message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (message.duration != null)
                  Text(
                    '${message.duration}s',
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyIndicator(Message message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.replyToSenderName ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.replyToContent ?? '',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyTag(Message message) {
    if (!message.hasProperty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        if (message.propertyId != null) {
          Navigator.pushNamed(
            context,
            AppRoutes.propertyDetail,
            arguments: message.propertyId,
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (message.propertyImage != null)
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(message.propertyImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (message.propertyImage != null) const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message.propertyTitle ?? 'Property',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'View',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (message.propertyAddress != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      message.propertyAddress!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                  if (message.propertyPrice != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '\$${message.propertyPrice!.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _listenToOtherUserStatus() {
    if (_otherUserId.isEmpty) return;
    _statusSubscription?.cancel();
    _statusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(_otherUserId)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            setState(() {
              _otherUserOnline = doc['isOnline'] == true;
              final ts = doc['lastSeen'];
              _otherUserLastSeen = ts is Timestamp ? ts.toDate() : null;
            });
          }
        });
  }

  void _listenToOtherUserTyping() {
    print(
      'Setting up typing listener - ChatId: $_chatId, OtherUserId: $_otherUserId',
    );

    if (_chatId.isEmpty || _otherUserId.isEmpty) {
      print('❌ Cannot setup typing listener: missing chatId or otherUserId');
      return;
    }

    _typingSubscription?.cancel();
    _typingSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('typing')
        .doc(_otherUserId)
        .snapshots()
        .listen(
          (doc) {
            print(
              'Typing doc snapshot: exists=[${doc.exists}], data=[${doc.data()}]',
            );

            bool wasTyping = _otherUserTyping;

            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              final typing = data['typing'] == true;
              final timestamp = data['timestamp'] as int?;
              final now = DateTime.now().millisecondsSinceEpoch;

              print(
                'Typing data: typing=$typing, timestamp=$timestamp, now=$now',
              );

              if (typing && timestamp != null && (now - timestamp) < 5000) {
                print('✅ Showing typing indicator');
                if (mounted) {
                  setState(() {
                    _otherUserTyping = true;
                  });

                  // Auto-scroll to show typing indicator
                  if (!wasTyping) {
                    _scrollToTypingIndicator();
                  }
                }
              } else {
                print('⏰ Typing expired or false');
                if (mounted) {
                  setState(() {
                    _otherUserTyping = false;
                  });
                }
              }
            } else {
              print('📄 No typing document exists');
              if (mounted) {
                setState(() {
                  _otherUserTyping = false;
                });
              }
            }
          },
          onError: (error) {
            print('❌ Error listening to typing: $error');
          },
        );
  }

  void _scrollToTypingIndicator() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Top of reversed list (where typing indicator is)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return '';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return DateFormat('MMM d, h:mm a').format(lastSeen);
  }

  Future<void> _saveQueuedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList =
        _queuedMessages.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList('queued_messages_${_chatId}', jsonList);
  }

  Future<void> _loadQueuedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('queued_messages_${_chatId}') ?? [];
    setState(() {
      _queuedMessages =
          jsonList.map((s) => MessageJson.fromJson(jsonDecode(s))).toList();
    });
  }

  Future<void> _setTyping(bool typing) async {
    if (_chatId.isEmpty || _currentUserId.isEmpty) {
      print('❌ Cannot set typing: missing chatId or currentUserId');
      return;
    }

    try {
      print(
        'Setting typing status: $typing for user $_currentUserId in chat $_chatId',
      );

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('typing')
          .doc(_currentUserId)
          .set({
            'typing': typing,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'userId': _currentUserId,
          });

      print('✅ Typing status set successfully');
    } catch (e) {
      print('❌ Error setting typing status: $e');
    }
  }

  void _debugTypingSystem() {
    print('=== TYPING SYSTEM DEBUG ===');
    print('Chat ID: $_chatId');
    print('Current User ID: $_currentUserId');
    print('Other User ID: $_otherUserId');
    print('Other User Name: $_otherUserName');
    print('Other User Typing: $_otherUserTyping');
    print('Initialized: $_initialized');
    print('Typing Subscription Active: ${_typingSubscription != null}');
    print('========================');
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedMessageIds.clear();
    });
  }

  // 1. Batch delete for multi-delete
  Future<void> _deleteSelectedMessages() async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in _selectedMessageIds) {
      final docRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .doc(id);
      batch.delete(docRef);
    }
    await batch.commit();
    setState(() {
      _selectedMessageIds.clear();
      _selectionMode = false;
    });

    final messagesSnapshot =
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(_chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    if (messagesSnapshot.docs.isNotEmpty) {
      final lastMsg = messagesSnapshot.docs.first.data();
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'lastMessage': lastMsg['content'] ?? '',
        'lastMessageTime': lastMsg['timestamp'],
      });
    } else {
      // No messages left, clear lastMessage
      await FirebaseFirestore.instance.collection('chats').doc(_chatId).update({
        'lastMessage': '',
        'lastMessageTime': null,
      });
    }
  }

  Widget _buildTypingIndicatorBubble() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              _otherUserName.isNotEmpty ? _otherUserName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPulsingDots(),
                  const SizedBox(width: 8),
                  Text(
                    '$_otherUserName is typing...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildPulsingDots() {
    return SizedBox(
      width: 30,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _sendButtonController,
            builder: (context, child) {
              final animationValue =
                  (_sendButtonController.value + (index * 0.3)) % 1.0;
              final scale =
                  0.5 + (0.5 * math.sin(animationValue * 2 * math.pi));

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
