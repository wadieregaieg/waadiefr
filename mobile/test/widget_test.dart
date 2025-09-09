// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshk/main.dart'; // Make sure your package name matches

void main() {
  testWidgets('Splash screen navigates to login screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Check that the splash screen shows a CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the splash screen delay (3 seconds) plus a little extra for animations.
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Now the login screen should be visible, which contains text 'Freshk'.
    expect(find.text('Login'), findsOneWidget);
  });
}
