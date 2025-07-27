import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile_1/features/chat/domain/entities/chat.dart';
import 'package:mobile_1/features/chat/domain/entities/message.dart';
import 'notification_service.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  // Make notification service accessible for dependency injection
  NotificationService get notificationService => _notificationService;

  // Initialize chat service
  Future<void> initialize() async {
    await _notificationService.initialize();
    await _setupMessageListeners();
  }

  // Setup message listeners
  Future<void> _setupMessageListeners() async {
    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen(_notificationService.handleIncomingMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_notificationService.handleIncomingMessage);
  }

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Generate consistent chat ID
  String generateChatId(String userId, String agentId) {
    final ids = [userId, agentId]..sort();
    return ids.join('_');
  }

  // Create or get existing chat
  Future<Chat> createOrGetChat(String agentId, String agentName) async {
    final chatId = generateChatId(currentUserId, agentId);
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (chatDoc.exists) {
      final chat = Chat.fromFirestore(chatDoc);
      await _notificationService.subscribeToChatTopic(chatId);
      return chat;
    } else {
      final newChat = Chat(
        id: chatId,
        userId: currentUserId,
        agentId: agentId,
        agentName: agentName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('chats').doc(chatId).set(newChat.toFirestore());
      await _notificationService.subscribeToChatTopic(chatId);
      return newChat;
    }
  }

  // Get user's chats stream
  Stream<List<Chat>> getUserChatsStream() {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
          final chats = snapshot.docs
              .map((doc) => Chat.fromFirestore(doc))
              .where((chat) => chat.isActive) // Filter active chats client-side
              .toList();
          
          // Sort by updatedAt client-side to avoid index requirement
          chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return chats;
        });
  }

  // Get messages stream for a chat
  Stream<List<Message>> getMessagesStream(String chatId) {
    print('ChatService: Setting up message stream for chatId: $chatId');
    
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false) // Ensure messages are ordered by timestamp
        .snapshots()
        .handleError((error) {
          print('ChatService: Error in message stream: $error');
          return [];
        })
        .map((snapshot) {
          try {
            print('ChatService: Received ${snapshot.docs.length} messages from stream');
            final messages = <Message>[];
            
            for (final doc in snapshot.docs) {
              try {
                print('ChatService: Processing message ${doc.id}');
                final message = Message.fromFirestore(doc);
                messages.add(message);
              } catch (e) {
                print('ChatService: Error parsing message ${doc.id}: $e');
                print('Message data: ${doc.data()}');
              }
            }
            
            // Sort messages by timestamp
            messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            
            print('ChatService: Successfully processed ${messages.length} messages');
            return messages;
          } catch (e) {
            print('ChatService: Error processing messages: $e');
            return [];
          }
        });
  }

  // Send message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    print('ChatService: Sending message - chatId: $chatId, content: $content');

    // Ensure chat document exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      print('ChatService: Chat document does not exist, creating it...');
      await _firestore.collection('chats').doc(chatId).set({
        'id': chatId,
        'userId': currentUserId,
        'agentId': receiverId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 1,
      });
    }

    final message = Message(
      id: '', // Will be set by Firestore
      chatId: chatId,
      senderId: user.uid,
      senderName: user.displayName ?? 'User',
      receiverId: receiverId,
      content: content,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    try {
      // Add message to subcollection
      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toFirestore());

      print('ChatService: Message added with ID: ${messageRef.id}');

      // Update chat metadata
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': content,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
      });

      // Send FCM notification to receiver
      final receiverToken = await _firestore
          .collection('users')
          .doc(receiverId)
          .get()
          .then((doc) => doc.data()?['fcmToken']);

      if (receiverToken != null) {
        await _notificationService.sendNotification(
          receiverToken: receiverToken,
          title: 'New Message',
          body: content,
          data: {
            'chatId': chatId,
            'senderId': user.uid,
            'message': content,
          },
        );
      }

      print('ChatService: Chat metadata updated successfully');
    } catch (e) {
      print('ChatService: Error sending message: $e');
      throw e;
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String senderId) async {
    final batch = _firestore.batch();
    final now = DateTime.now();

    // Get unread messages from the sender
    final unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isEqualTo: senderId)
        .where('readAt', isNull: true)
        .get();

    // Mark each message as read
    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {
        'readAt': now,
        'status': MessageStatus.read.toString().split('.').last,
      });
    }

    // Reset unread count for current user
    batch.update(_firestore.collection('chats').doc(chatId), {
      'unreadCount': 0,
    });

    await batch.commit();
  }

  // Get unread message count for a chat
  Future<int> getUnreadCount(String chatId) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final data = chatDoc.data() as Map<String, dynamic>;
      return data['unreadCount'] ?? 0;
    }
    return 0;
  }

  // Get total unread messages count across all chats
  Stream<int> getTotalUnreadCountStream() {
    return _firestore
        .collection('chats')
        .where('userId', isEqualTo: currentUserId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalUnread += (data['unreadCount'] ?? 0) as int;
      }
      return totalUnread;
    });
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'isActive': false,
      'updatedAt': DateTime.now(),
    });
  }

  // Search messages in a chat
  Future<List<Message>> searchMessages(String chatId, String query) async {
    final messagesSnapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit for performance
        .get();

    final messages = messagesSnapshot.docs
        .map((doc) => Message.fromFirestore(doc))
        .where((message) => message.content.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return messages;
  }

  // Get chat by ID
  Future<Chat?> getChatById(String chatId) async {
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      return Chat.fromFirestore(chatDoc);
    }
    return null;
  }
}
