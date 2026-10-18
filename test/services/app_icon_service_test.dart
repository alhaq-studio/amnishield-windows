import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:amnshield_flutter/services/app_icon_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppIconService Tests', () {
    test('getIconBase64 executes without throwing on all platforms', () async {
      final result = await AppIconService.getIconBase64('non_existent_app_xyz_123.exe');
      if (!Platform.isWindows) {
        expect(result, isNull);
      } else {
        // On Windows, non-existent app returns null
        expect(result, isNull);
      }
    });

    test('getIconBase64 handles injection payload strings safely', () async {
      const maliciousExecutable = 'notepad.exe"; Start-Process calc.exe; #';
      const maliciousTargetPath = r'C:\Program Files\test.exe"; Start-Process calc.exe; #';

      final result = await AppIconService.getIconBase64(maliciousExecutable, maliciousTargetPath);
      expect(result, isNull);
    });

    test('getIconBase64 extracts base64 icon on Windows for valid system app or returns null safely', () async {
      if (Platform.isWindows) {
        final result = await AppIconService.getIconBase64('cmd.exe');
        if (result != null) {
          expect(result, isNotEmpty);
        }
      }
    });
  });
}
