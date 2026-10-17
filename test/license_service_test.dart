import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:amnshield_flutter/services/license_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LicensePayload', () {
    test('fromJson parses complete json correctly', () {
      final jsonMap = {
        'email': 'user@example.com',
        'type': 'enterprise',
        'expires': 2000000000000,
        'version': 2,
      };

      final payload = LicensePayload.fromJson(jsonMap);

      expect(payload.email, equals('user@example.com'));
      expect(payload.type, equals('enterprise'));
      expect(payload.expires, equals(2000000000000));
      expect(payload.version, equals(2));
    });

    test('fromJson uses default values when fields are missing or null', () {
      final payload = LicensePayload.fromJson({});

      expect(payload.email, equals(''));
      expect(payload.type, equals('premium'));
      expect(payload.expires, equals(0));
      expect(payload.version, equals(1));
    });

    test('toJson serializes payload back to map', () {
      final payload = LicensePayload(
        email: 'test@domain.com',
        type: 'pro',
        expires: 1700000000000,
        version: 1,
      );

      final jsonMap = payload.toJson();

      expect(jsonMap, equals({
        'email': 'test@domain.com',
        'type': 'pro',
        'expires': 1700000000000,
        'version': 1,
      }));
    });

    test('isExpired returns true for past timestamps and false for future timestamps', () {
      final expiredPayload = LicensePayload(
        email: 'test@example.com',
        type: 'premium',
        expires: 1000000, // Past timestamp (1970)
        version: 1,
      );

      final futureTimestamp = DateTime.now().millisecondsSinceEpoch + 1000000;
      final validPayload = LicensePayload(
        email: 'test@example.com',
        type: 'premium',
        expires: futureTimestamp,
        version: 1,
      );

      expect(expiredPayload.isExpired, isTrue);
      expect(validPayload.isExpired, isFalse);
    });
  });

  group('LicenseService.verifyLicense', () {
    test('returns null for empty or whitespace string', () {
      expect(LicenseService.verifyLicense(''), isNull);
      expect(LicenseService.verifyLicense('   '), isNull);
      expect(LicenseService.verifyLicense('\n\t'), isNull);
    });

    test('returns null when license string does not have exactly two parts', () {
      expect(LicenseService.verifyLicense('singlepart'), isNull);
      expect(LicenseService.verifyLicense('part1.part2.part3'), isNull);
      expect(LicenseService.verifyLicense('.'), isNull);
      expect(LicenseService.verifyLicense('a.b.c.d'), isNull);
    });

    test('returns null for invalid base64 in payload part', () {
      const invalidBase64Payload = '!!!not_base64!!!.validSignature';
      expect(LicenseService.verifyLicense(invalidBase64Payload), isNull);
    });

    test('returns null when payload is not valid UTF-8 or JSON', () {
      // Base64 encoded non-JSON plain string "hello world"
      final nonJsonBase64 = base64.encode(utf8.encode('hello world'));
      final licenseStr = '$nonJsonBase64.signature';
      expect(LicenseService.verifyLicense(licenseStr), isNull);
    });

    test('returns null when decoded JSON is not a JSON object map', () {
      // Base64 encoded JSON array "[1, 2, 3]"
      final arrayJsonBase64 = base64.encode(utf8.encode('[1, 2, 3]'));
      final licenseStr = '$arrayJsonBase64.signature';
      expect(LicenseService.verifyLicense(licenseStr), isNull);
    });

    test('returns null when license key is expired', () {
      final expiredPayloadMap = {
        'email': 'user@example.com',
        'type': 'premium',
        'expires': 1000, // Far in the past
        'version': 1,
      };
      final payloadJsonStr = json.encode(expiredPayloadMap);
      final payloadBase64 = base64.encode(utf8.encode(payloadJsonStr));
      final licenseStr = '$payloadBase64.fakesignature';

      expect(LicenseService.verifyLicense(licenseStr), isNull);
    });

    test('returns null when signature is invalid base64', () {
      final validFuturePayloadMap = {
        'email': 'user@example.com',
        'type': 'premium',
        'expires': DateTime.now().millisecondsSinceEpoch + 360000000,
        'version': 1,
      };
      final payloadJsonStr = json.encode(validFuturePayloadMap);
      final payloadBase64 = base64.encode(utf8.encode(payloadJsonStr));
      final licenseStr = '$payloadBase64.!!!invalid_base64_signature!!!';

      expect(LicenseService.verifyLicense(licenseStr), isNull);
    });

    test('returns null when 64-byte raw IEEE P1363 signature is cryptographically invalid', () {
      final validFuturePayloadMap = {
        'email': 'user@example.com',
        'type': 'premium',
        'expires': DateTime.now().millisecondsSinceEpoch + 360000000,
        'version': 1,
      };
      final payloadJsonStr = json.encode(validFuturePayloadMap);
      final payloadBase64 = base64.encode(utf8.encode(payloadJsonStr));
      // 64 bytes signature (32 bytes R, 32 bytes S) with random/fake data
      final fake64ByteSig = base64.encode(List<int>.filled(64, 0xAA));
      final licenseStr = '$payloadBase64.$fake64ByteSig';

      expect(LicenseService.verifyLicense(licenseStr), isNull);
    });

    test('returns null when ASN.1 signature is cryptographically invalid', () {
      final validFuturePayloadMap = {
        'email': 'user@example.com',
        'type': 'premium',
        'expires': DateTime.now().millisecondsSinceEpoch + 360000000,
        'version': 1,
      };
      final payloadJsonStr = json.encode(validFuturePayloadMap);
      final payloadBase64 = base64.encode(utf8.encode(payloadJsonStr));
      // ASN.1 encoded fake signature bytes
      final fakeAsn1Sig = base64.encode([0x30, 0x06, 0x02, 0x01, 0x01, 0x02, 0x01, 0x01]);
      final licenseStr = '$payloadBase64.$fakeAsn1Sig';

      expect(LicenseService.verifyLicense(licenseStr), isNull);
    });
  });
}
