// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_1/app/app.dart';

void main() {
  testWidgets('Real Estate App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RealEstateApp());

    // Wait for splash screen to load
    await tester.pump();

    // Verify that the splash screen shows the app name
    expect(find.text('RealEstate Pro'), findsOneWidget);
    expect(find.text('Find Your Dream Property'), findsOneWidget);
  });
}
