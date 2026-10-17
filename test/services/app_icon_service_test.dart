import 'package:flutter_test/flutter_test.dart';
import 'package:amnshield_flutter/services/app_icon_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppIconService Tests', () {
    test('getIconBase64 returns null on non-Windows platforms without throwing', () async {
      final result = await AppIconService.getIconBase64('notepad.exe');
      expect(result, isNull);
    });

    test('getIconBase64 handles injection payload strings safely', () async {
      const maliciousExecutable = 'notepad.exe"; Start-Process calc.exe; #';
      const maliciousTargetPath = r'C:\Program Files\test.exe"; Start-Process calc.exe; #';

      final result = await AppIconService.getIconBase64(maliciousExecutable, maliciousTargetPath);
      expect(result, isNull);
    });
  });
}
