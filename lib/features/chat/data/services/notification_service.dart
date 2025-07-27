import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;

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
        )
      ],
    );

    // Request permission for notifications
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

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
        final senderId = message.data['senderId'];
        final messageContent = message.data['message'] ?? message.data['content'];
        
        developer.log('Received message data:', 
          name: 'NotificationService',
          error: {
            'chatId': chatId,
            'senderId': senderId,
            'content': messageContent,
            'fullData': message.data,
          }
        );
        
        // TODO: Update unread count and UI in the chat list
        // This would typically involve updating local state or triggering a refresh
      }
    } catch (e) {
      developer.log('Error handling incoming message:', 
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
        notificationLayout: NotificationLayout.Default,
      ),
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
      
      // Get the current FCM token to identify the sender
      final String? currentToken = await _firebaseMessaging.getToken();
      
      if (currentToken == null) {
        debugPrint('Failed to get current FCM token');
        return;
      }

      // Create a unique message ID
      final String messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create the message payload
      final Map<String, dynamic> message = {
        'to': receiverToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
        },
        'data': {
          ...data,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'id': '1',
          'status': 'done',
          'messageId': messageId,
        },
        'priority': 'high',
        'ttl': '60s',
      };
      
      // Show local notification
      await _showLocalNotification(
        title: title,
        body: body,
        payload: Map<String, String>.from(data.map((key, value) => MapEntry(key, value.toString()))),
      );
      
      debugPrint('Notification sent successfully');
    } catch (e) {
      debugPrint('Error in sendNotification: $e');
      // Fallback to local notification if FCM fails
      await _showLocalNotification(title: title, body: body);
      rethrow;
    }
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('Handling background message: ${message.messageId}');
    // TODO: Handle background message
  }
}
