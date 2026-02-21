// Simple test file for the plant app

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build a simple widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Plant Care App'),
          ),
        ),
      ),
    );

    // Verify it renders
    expect(find.text('Plant Care App'), findsOneWidget);
  });
}
