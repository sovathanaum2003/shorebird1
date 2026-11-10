import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shorebird/main.dart';

void main() {
  testWidgets('Shorebird demo screen widget smoke test', (WidgetTester tester) async {
    // Build ShorebirdApp and trigger a frame.
    await tester.pumpWidget(const ShorebirdApp());

    // Verify app metadata and welcome message render.
    expect(find.text('shorebird'), findsOneWidget);
    expect(find.text('Hello from Shorebird OTA Patch V2 (Live Test 🎉)'), findsOneWidget);

    // Verify counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Scroll to and tap increment counter button.
    final counterButton = find.widgetWithText(OutlinedButton, 'Increment Counter');
    await tester.ensureVisible(counterButton);
    await tester.tap(counterButton);
    await tester.pump();

    // Verify that counter has incremented to 1.
    expect(find.text('1'), findsOneWidget);
  });
}
