import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injection_container.dart' as di;
import 'package:firebase_core/firebase_core.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

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
      )
    ],
  );

  // Initialize dependency injection
  await di.init();

  runApp(const RealEstateApp());
}
