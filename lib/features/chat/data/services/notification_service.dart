import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../domain/entities/message.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> initialize() async {
    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      null, // Use default local resource for the app icon
      [
        NotificationChannel(
          channelKey: 'high_importance_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          onlyAlertOnce: true,
          playSound: true,
          criticalAlerts: true,
        ),
      ],
    );

    // Request permission for notifications
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) {
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

    // Request permission for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Handle incoming messages
  Future<void> handleIncomingMessage(RemoteMessage message) async {
    try {
      developer.log('Handling incoming message: ${message.messageId}');

      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;
      final senderId = message.data['senderId'] ?? message.data['userId'];
      if (senderId == currentUserId) {
        debugPrint('Skipping notification: message sent by current user');
        return;
      }

      // Handle notification payload
      if (message.notification != null) {
        final notification = message.notification!;
        await _showLocalNotification(
          title: notification.title ?? 'New Message',
          body: notification.body ?? 'You have a new message',
          payload: {'data': message.data.toString()},
        );
      }

      // Handle data payload
      if (message.data.isNotEmpty) {
        final chatId = message.data['chatId'];
        final messageContent =
            message.data['message'] ?? message.data['content'];

        developer.log(
          'Received message data:',
          name: 'NotificationService',
          error: {
            'chatId': chatId,
            'senderId': senderId,
            'content': messageContent,
            'fullData': message.data,
          },
        );

        // TODO: Update unread count and UI in the chat list
        // This would typically involve updating local state or triggering a refresh
      }
    } catch (e) {
      developer.log(
        'Error handling incoming message:',
        name: 'NotificationService',
        error: e,
        stackTrace: StackTrace.current,
      );
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, String?>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: 'high_importance_channel',
        title: title,
        body: body,
        payload: payload ?? {},
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Message,
        wakeUpScreen: true,
        autoDismissible: false,
        backgroundColor: const Color(0xFF9D50DD),
        color: Colors.white,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'REPLY',
          label: 'Reply',
          color: const Color(0xFF9D50DD),
          autoDismissible: true,
        ),
        NotificationActionButton(
          key: 'VIEW',
          label: 'View',
          color: const Color(0xFF9D50DD),
          autoDismissible: true,
        ),
      ],
    );
  }

  // Subscribe to chat topic
  Future<void> subscribeToChatTopic(String chatId) async {
    await _firebaseMessaging.subscribeToTopic('chat_$chatId');
  }

  // Unsubscribe from chat topic
  Future<void> unsubscribeFromChatTopic(String chatId) async {
    await _firebaseMessaging.unsubscribeFromTopic('chat_$chatId');
  }

  // Get FCM token
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Send notification to a specific device using FCM
  Future<void> sendNotification({
    required String receiverToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint('Sending notification to $receiverToken');
      debugPrint('Title: $title, Body: $body, Data: $data');

      // Send FCM push notification
      const String serverKey =
          'YOUR_SERVER_KEY_HERE'; // TODO: Replace with your actual FCM server key
      final postUrl = 'https://fcm.googleapis.com/fcm/send';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };
      final payload = {
        'to': receiverToken,
        'notification': {'title': title, 'body': body},
        'data': data,
      };
      final response = await http.post(
        Uri.parse(postUrl),
        headers: headers,
        body: jsonEncode(payload),
      );
      debugPrint('FCM response: \\${response.statusCode} \\${response.body}');

      // Show local notification immediately (optional, for fallback/testing)
      await _showLocalNotification(
        title: title,
        body: body,
        payload: Map<String, String>.from(
          data.map((key, value) => MapEntry(key, value.toString())),
        ),
      );

      debugPrint('Notification sent successfully');
    } catch (e) {
      debugPrint('Error in sendNotification: $e');
      // Fallback to local notification if FCM fails
      await _showLocalNotification(title: title, body: body);
      rethrow;
    }
  }

  // Send message notification with proper formatting
  Future<void> sendMessageNotification({
    required String receiverToken,
    required String senderName,
    required String messageContent,
    required String chatId,
    required String senderId,
    MessageType messageType = MessageType.text,
  }) async {
    try {
      debugPrint('=== SENDING MESSAGE NOTIFICATION ===');
      debugPrint('Receiver Token: ${receiverToken.substring(0, 20)}...');
      debugPrint('Sender Name: $senderName');
      debugPrint('Message Content: $messageContent');
      debugPrint('Chat ID: $chatId');
      debugPrint('Message Type: $messageType');

      String title = 'New Message';
      String body = messageContent;
      String emoji = '💬';

      // Format notification based on message type
      switch (messageType) {
        case MessageType.text:
          title = '$senderName';
          body = messageContent;
          emoji = '💬';
          break;
        case MessageType.image:
          title = '$senderName';
          body = 'Sent an image';
          emoji = '📷';
          break;
        case MessageType.voice:
          title = '$senderName';
          body = 'Sent a voice message';
          emoji = '🎤';
          break;
        case MessageType.file:
          title = '$senderName';
          body = 'Sent a file';
          emoji = '📎';
          break;
        default:
          title = '$senderName';
          body = messageContent;
          emoji = '💬';
      }

      debugPrint('Creating notification: $emoji $title - $body');

      // Create a more attractive notification
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'high_importance_channel',
          title: '$emoji $title',
          body: body,
          payload: {
            'chatId': chatId,
            'senderId': senderId,
            'message': messageContent,
            'type': messageType.toString().split('.').last,
            'senderName': senderName,
          },
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Message,
          wakeUpScreen: true,
          autoDismissible: false,
          backgroundColor: const Color(0xFF9D50DD),
          color: Colors.white,

          displayOnBackground: true,
          displayOnForeground: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'REPLY',
            label: 'Reply',
            color: const Color(0xFF9D50DD),
            autoDismissible: true,
          ),
          NotificationActionButton(
            key: 'VIEW',
            label: 'View Chat',
            color: const Color(0xFF9D50DD),
            autoDismissible: true,
          ),
        ],
      );

      debugPrint('✅ Message notification sent successfully: $title - $body');
    } catch (e) {
      debugPrint('❌ Error sending message notification: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Test notification method
  Future<void> sendTestNotification() async {
    try {
      debugPrint('=== SENDING TEST NOTIFICATION ===');
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          channelKey: 'high_importance_channel',
          title: '🧪 Test Notification',
          body: 'This is a test notification to verify the system is working!',
          notificationLayout: NotificationLayout.BigText,
          category: NotificationCategory.Message,
          wakeUpScreen: true,
          autoDismissible: false,
          backgroundColor: const Color(0xFF9D50DD),
          color: Colors.white,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'TEST',
            label: 'Test',
            color: const Color(0xFF9D50DD),
            autoDismissible: true,
          ),
        ],
      );
      debugPrint('✅ Test notification sent successfully');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    debugPrint('Handling background message: ${message.messageId}');
    // TODO: Handle background message
  }
}
