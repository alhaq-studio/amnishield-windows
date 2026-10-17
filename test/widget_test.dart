import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amnshield_flutter/main.dart';
import 'package:amnshield_flutter/screens/control_panel_screen.dart';
import 'package:amnshield_flutter/screens/onboarding_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AmnShield Guardian first-time launch shows OnboardingScreen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AmnShieldApp());
    await tester.pumpAndSettle();

    // Verify Onboarding wizard is presented on fresh install
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.textContaining('Welcome to AmnShield'), findsOneWidget);
  });

  testWidgets('AmnShield launch with completed onboarding opens Control Panel directly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'app_password': '',
    });
    await tester.pumpWidget(const AmnShieldApp());
    await tester.pumpAndSettle();

    // Verify that launch with completed onboarding and no password opens ControlPanel
    expect(find.byType(ControlPanelScreen), findsOneWidget);
    expect(find.text('AmnShield Control Panel'), findsOneWidget);
  });

  testWidgets('AmnShield launch with passcode set requires authentication', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'app_password': 'secret_password_123', // Legacy plaintext or hashed
    });
    await tester.pumpWidget(const AmnShieldApp());
    await tester.pumpAndSettle();

    // Verify that passcode gate is displayed
    expect(find.text('AMNSHIELD GUARDIAN'), findsOneWidget);
    expect(find.text('Enter passcode to unlock settings'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
