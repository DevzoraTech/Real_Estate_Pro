import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mobile_1/features/chat/domain/entities/chat.dart';
import 'package:mobile_1/features/chat/domain/entities/message.dart';
import 'notification_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
    FirebaseMessaging.onMessage.listen(
      _notificationService.handleIncomingMessage,
    );
    FirebaseMessaging.onMessageOpenedApp.listen(
      _notificationService.handleIncomingMessage,
    );
  }

  String get currentUserId => _auth.currentUser?.uid ?? '';

  // Generate consistent chat ID
  String generateChatId(String userId, String agentId) {
    final ids = [userId, agentId]..sort();
    return ids.join('_');
  }

  // Create or get existing chat
  Future<Chat> createOrGetChat(
    String agentId,
    String agentName, {
    String? userName,
  }) async {
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
        userName: userName ?? 'User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('chats').doc(chatId).set({
        ...newChat.toFirestore(),
        'participants': [currentUserId, agentId],
      });
      await _notificationService.subscribeToChatTopic(chatId);
      return newChat;
    }
  }

  // Get user's chats stream
  Stream<List<Chat>> getUserChatsStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .map((snapshot) {
          final chats =
              snapshot.docs
                  .map((doc) => Chat.fromFirestore(doc))
                  .where(
                    (chat) => chat.isActive,
                  ) // Filter active chats client-side
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
        .orderBy(
          'timestamp',
          descending: false,
        ) // Ensure messages are ordered by timestamp
        .snapshots()
        .handleError((error) {
          print('ChatService: Error in message stream: $error');
          return [];
        })
        .map((snapshot) {
          try {
            print(
              'ChatService: Received ${snapshot.docs.length} messages from stream',
            );
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

            print(
              'ChatService: Successfully processed ${messages.length} messages',
            );
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
    String? fileUrl,
    int? duration,
    String? propertyId,
    String? propertyTitle,
    double? propertyPrice,
    String? propertyImage,
    String? propertyAddress,
    String? replyToMessageId,
    String? replyToContent,
    String? replyToSenderName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    print('ChatService: Sending message - chatId: $chatId, content: $content');

    // Ensure chat document exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      print('ChatService: Chat document does not exist, creating it...');

      // Get agent name from users collection
      String agentName = 'Agent';
      try {
        final agentDoc =
            await _firestore.collection('users').doc(receiverId).get();
        if (agentDoc.exists) {
          agentName = agentDoc.data()?['displayName'] ?? 'Agent';
        }
      } catch (e) {
        print('ChatService: Error getting agent name: $e');
      }

      await _firestore.collection('chats').doc(chatId).set({
        'id': chatId,
        'userId': currentUserId,
        'agentId': receiverId,
        'agentName': agentName,
        'userName': user.displayName ?? 'User',
        'participants': [currentUserId, receiverId],
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
      fileUrl: fileUrl,
      duration: duration,
      propertyId: propertyId,
      propertyTitle: propertyTitle,
      propertyPrice: propertyPrice,
      propertyImage: propertyImage,
      propertyAddress: propertyAddress,
      replyToMessageId: replyToMessageId,
      replyToContent: replyToContent,
      replyToSenderName: replyToSenderName,
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
        // Remove the unreadCount increment - we'll calculate it dynamically
      });

      // Send notification to receiver
      final receiverToken = await _firestore
          .collection('users')
          .doc(receiverId)
          .get()
          .then((doc) => doc.data()?['fcmToken']);

      print('DEBUG: Sending notification');
      print('  currentUserId: ${user.uid}');
      print('  receiverId: $receiverId');
      print('  receiverToken: $receiverToken');

      if (receiverToken != null) {
        await _notificationService.sendMessageNotification(
          receiverToken: receiverToken,
          senderName: user.displayName ?? 'User',
          messageContent: content,
          chatId: chatId,
          senderId: user.uid,
          messageType: type,
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
    final unreadMessages =
        await _firestore
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
    // Count unread messages where current user is the receiver
    final unreadMessages =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .where('receiverId', isEqualTo: currentUserId)
            .where('readAt', isNull: true)
            .get();
    return unreadMessages.docs.length;
  }

  // Get unread count stream for a specific chat
  Stream<int> getUnreadCountStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('readAt', isNull: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get total unread messages count across all chats
  Stream<int> getTotalUnreadCountStream() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          int totalUnread = 0;
          for (final doc in snapshot.docs) {
            final chatId = doc.id;
            // Count unread messages where current user is the receiver
            final unreadMessages =
                await _firestore
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .where('receiverId', isEqualTo: currentUserId)
                    .where('readAt', isNull: true)
                    .get();
            totalUnread += unreadMessages.docs.length;
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
    final messagesSnapshot =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(100) // Limit for performance
            .get();

    final messages =
        messagesSnapshot.docs
            .map((doc) => Message.fromFirestore(doc))
            .where(
              (message) =>
                  message.content.toLowerCase().contains(query.toLowerCase()),
            )
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

  // Edit message
  Future<void> editMessage(
    String chatId,
    String messageId,
    String newContent,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify the message belongs to the current user
    final messageDoc =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .get();

    if (!messageDoc.exists) {
      throw Exception('Message not found');
    }

    final messageData = messageDoc.data() as Map<String, dynamic>;
    if (messageData['senderId'] != user.uid) {
      throw Exception('You can only edit your own messages');
    }

    // Update the message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
          'message': newContent, // Update both fields for compatibility
          'content': newContent,
          'editedAt': FieldValue.serverTimestamp(),
          'isEdited': true,
        });

    // Update chat metadata if this was the last message
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final chatData = chatDoc.data() as Map<String, dynamic>;
      if (chatData['lastMessage'] == messageData['content']) {
        await _firestore.collection('chats').doc(chatId).update({
          'lastMessage': newContent,
          'lastMessageTime':
              messageData['timestamp'], // Use the original timestamp
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Delete message
  Future<void> deleteMessage(String chatId, String messageId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Verify the message belongs to the current user
    final messageDoc =
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId)
            .get();

    if (!messageDoc.exists) {
      throw Exception('Message not found');
    }

    final messageData = messageDoc.data() as Map<String, dynamic>;
    if (messageData['senderId'] != user.uid) {
      throw Exception('You can only delete your own messages');
    }

    // Delete the message
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();

    // Update chat metadata if this was the last message
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final chatData = chatDoc.data() as Map<String, dynamic>;
      if (chatData['lastMessage'] == messageData['content']) {
        // Get the new last message
        final messages =
            await _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();

        if (messages.docs.isNotEmpty) {
          final lastMessageData = messages.docs.first.data();
          await _firestore.collection('chats').doc(chatId).update({
            'lastMessage': lastMessageData['content'],
            'lastMessageTime': lastMessageData['timestamp'],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // No messages left, clear the last message
          await _firestore.collection('chats').doc(chatId).update({
            'lastMessage': null,
            'lastMessageTime': null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  // Upload image to Firebase Storage
  Future<String> uploadImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileName =
        'chat_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);

    final uploadTask = ref.putFile(imageFile);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  // Upload voice note to Firebase Storage
  Future<String> uploadVoiceNote(File audioFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final fileName =
        'chat_voice/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = FirebaseStorage.instance.ref().child(fileName);

    final uploadTask = ref.putFile(audioFile);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    return downloadUrl;
  }

  // Send image message
  Future<void> sendImageMessage({
    required String chatId,
    required String receiverId,
    required File imageFile,
    String? caption,
  }) async {
    try {
      final imageUrl = await uploadImage(imageFile);
      await sendMessage(
        chatId: chatId,
        receiverId: receiverId,
        content: caption ?? '📷 Image',
        type: MessageType.image,
        fileUrl: imageUrl,
      );
    } catch (e) {
      print('Error sending image message: $e');
      throw e;
    }
  }

  // Send voice message
  Future<void> sendVoiceMessage({
    required String chatId,
    required String receiverId,
    required File audioFile,
    required int duration,
  }) async {
    try {
      final audioUrl = await uploadVoiceNote(audioFile);
      await sendMessage(
        chatId: chatId,
        receiverId: receiverId,
        content: '🎤 Voice message',
        type: MessageType.voice,
        fileUrl: audioUrl,
        duration: duration,
      );
    } catch (e) {
      print('Error sending voice message: $e');
      throw e;
    }
  }

  // Paginated message loading
  Future<List<Message>> fetchMessagesPaginated(
    String chatId, {
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
  }
}
