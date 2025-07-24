import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/di/injection_container.dart' as di;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize dependency injection
  await di.init();

  runApp(const RealEstateApp());
}
