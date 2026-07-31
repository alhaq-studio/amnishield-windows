// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amnshield_flutter/main.dart';

void main() {
  testWidgets('AmnShield Guardian initial launch test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AmnShieldApp());
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that fresh launch without a set password opens Control Panel directly
    expect(find.text('AmnShield Control Panel'), findsOneWidget);
    expect(find.text('Guardian Protection Active'), findsOneWidget);
  });
}
