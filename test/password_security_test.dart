import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amnshield_flutter/services/config_syncer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigSyncer Password Security Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('savePassword hashes password and does not store plaintext', () async {
      await ConfigSyncer.savePassword('MySuperSecretPassword123');
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('app_password');

      expect(stored, isNotNull);
      expect(stored, isNot(equals('MySuperSecretPassword123')));
      expect(stored, equals(ConfigSyncer.hashPassword('MySuperSecretPassword123')));
    });

    test('verifyPassword returns true for correct password and false for wrong password', () async {
      await ConfigSyncer.savePassword('Passcode2026');

      expect(await ConfigSyncer.verifyPassword('Passcode2026'), isTrue);
      expect(await ConfigSyncer.verifyPassword('WrongPassword'), isFalse);
    });

    test('verifyPassword migrates legacy plaintext password to hash', () async {
      SharedPreferences.setMockInitialValues({
        'app_password': 'LegacyPlaintextPassword',
      });

      final prefsBefore = await SharedPreferences.getInstance();
      expect(prefsBefore.getString('app_password'), equals('LegacyPlaintextPassword'));

      final verified = await ConfigSyncer.verifyPassword('LegacyPlaintextPassword');
      expect(verified, isTrue);

      final prefsAfter = await SharedPreferences.getInstance();
      final storedAfter = prefsAfter.getString('app_password');
      expect(storedAfter, isNot(equals('LegacyPlaintextPassword')));
      expect(storedAfter, equals(ConfigSyncer.hashPassword('LegacyPlaintextPassword')));
    });

    test('hasPassword returns correct status', () async {
      expect(await ConfigSyncer.hasPassword(), isFalse);

      await ConfigSyncer.savePassword('ActivePassword');
      expect(await ConfigSyncer.hasPassword(), isTrue);

      await ConfigSyncer.savePassword('');
      expect(await ConfigSyncer.hasPassword(), isFalse);
    });
  });
}
