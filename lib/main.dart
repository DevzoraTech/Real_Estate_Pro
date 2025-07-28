import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injection_container.dart' as di;
import 'package:firebase_core/firebase_core.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/chat/data/services/notification_service.dart';
import 'features/chat/data/services/user_status_service.dart';

// Top-level function for handling notification actions (required by Awesome Notifications)
@pragma('vm:entry-point')
Future<void> myNotificationTapHandler(ReceivedAction receivedAction) async {
  debugPrint('Notification tapped: ${receivedAction.payload}');

  // Handle action button taps
  if (receivedAction.buttonKeyPressed == 'REPLY') {
    debugPrint('Reply button pressed');
    // TODO: Open quick reply interface
  } else if (receivedAction.buttonKeyPressed == 'VIEW') {
    debugPrint('View button pressed');
    // TODO: Navigate to chat
  }

  // Handle notification tap here - navigate to chat if needed
  if (receivedAction.payload != null) {
    final chatId = receivedAction.payload!['chatId'];
    final senderId = receivedAction.payload!['senderId'];
    if (chatId != null) {
      debugPrint('Navigate to chat: $chatId from sender: $senderId');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

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

  // Initialize dependency injection
  await di.init();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Start user status service
  UserStatusService().start();

  // Handle notification taps
  AwesomeNotifications().setListeners(
    onActionReceivedMethod: myNotificationTapHandler,
  );

  // Handle FCM notification taps
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data.isNotEmpty) {
      final chatId = message.data['chatId'];
      final senderId = message.data['senderId'];
      if (chatId != null) {
        print('FCM notification tapped - ChatId: $chatId, SenderId: $senderId');
      }
    }
  });

  runApp(const RealEstateApp());
}
