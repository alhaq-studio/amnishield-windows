import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:ecdsa/ecdsa.dart';
import 'package:elliptic/elliptic.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LicensePayload {
  final String email;
  final String type;
  final int expires;
  final int version;

  LicensePayload({
    required this.email,
    required this.type,
    required this.expires,
    required this.version,
  });

  bool get isExpired => expires < DateTime.now().millisecondsSinceEpoch;

  factory LicensePayload.fromJson(Map<String, dynamic> json) {
    return LicensePayload(
      email: json['email'] as String? ?? '',
      type: json['type'] as String? ?? 'premium',
      expires: json['expires'] as int? ?? 0,
      version: json['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'type': type,
        'expires': expires,
        'version': version,
      };
}

class LicenseService {
  static const String _keyLicenseKey = 'amnshield_license_key';
  static const String _keyIsPremiumOverride = 'amnshield_premium_override';

  /// NIST P-256 Public Key (X.509 Base64) matching Android LicenseValidator
  static const String publicKeyBase64 =
      'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE7EFR1qxpfZTMeR52M1+04+tPb6ItmVmhPbRCIJYje3jtglTdBbcct+/xvc1D1NZtXuvSb4Egtdqm/EJ6H67fEA==';

  /// Check if the desktop app currently has active Premium status
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getBool(_keyIsPremiumOverride) ?? false;
    if (override) return true;

    final key = prefs.getString(_keyLicenseKey);
    if (key == null || key.isEmpty) return false;

    final payload = verifyLicense(key);
    return payload != null && !payload.isExpired;
  }

  /// Get current saved license payload
  static Future<LicensePayload?> getActivePayload() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_keyLicenseKey);
    if (key == null || key.isEmpty) return null;
    return verifyLicense(key);
  }

  /// Activate a new license key string (Format: Base64(Payload).Base64(Signature))
  static Future<bool> activateLicense(String licenseKey) async {
    final cleanKey = licenseKey.trim();
    final payload = verifyLicense(cleanKey);
    if (payload == null || payload.isExpired) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLicenseKey, cleanKey);
    debugPrint('[LicenseService] License activated successfully for ${payload.email}');
    return true;
  }

  /// Clear active license
  static Future<void> deactivateLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLicenseKey);
    await prefs.remove(_keyIsPremiumOverride);
    debugPrint('[LicenseService] License deactivated.');
  }

  /// Parse and verify a license key string
  static LicensePayload? verifyLicense(String licenseString) {
    try {
      final parts = licenseString.trim().split('.');
      if (parts.length != 2) return null;

      final payloadBase64 = parts[0];
      final signatureBase64 = parts[1];

      // Normalize base64 padding
      String normalizedPayload = base64.normalize(payloadBase64);
      final payloadJsonString = utf8.decode(base64.decode(normalizedPayload));
      final Map<String, dynamic> jsonMap = json.decode(payloadJsonString);
      final payload = LicensePayload.fromJson(jsonMap);

      if (payload.isExpired) {
        debugPrint('[LicenseService] License key has expired.');
        return null;
      }

      // Perform NIST P-256 ECDSA SHA-256 signature verification
      if (_verifyEcdsaSignature(payloadBase64, signatureBase64, publicKeyBase64)) {
        return payload;
      } else {
        debugPrint('[LicenseService] Invalid ECDSA signature.');
      }
    } catch (e) {
      debugPrint('[LicenseService] License verification error: $e');
    }
    return null;
  }

  /// Cryptographically verify NIST P-256 ECDSA SHA-256 signature
  static bool _verifyEcdsaSignature(String payloadBase64, String signatureBase64, String pubKeyBase64) {
    try {
      final signatureBytes = base64.decode(signatureBase64);
      final payloadBytes = utf8.encode(payloadBase64);
      final hash = sha256.convert(payloadBytes).bytes;

      final pubKeyBytes = base64.decode(pubKeyBase64);
      // X.509 DER header is 26 bytes + 1 byte format (0x04)
      if (pubKeyBytes.length < 91) return false;
      final xBytes = pubKeyBytes.sublist(27, 59);
      final yBytes = pubKeyBytes.sublist(59, 91);

      final x = _bytesToBigInt(xBytes);
      final y = _bytesToBigInt(yBytes);

      final ec = getP256();
      final publicKey = PublicKey(ec, x, y);

      Signature sig;
      if (signatureBytes.length == 64) {
        // IEEE P1363 raw R || S (WebCrypto)
        final r = _bytesToBigInt(signatureBytes.sublist(0, 32));
        final s = _bytesToBigInt(signatureBytes.sublist(32, 64));
        sig = Signature.fromRS(r, s);
      } else {
        // ASN.1 DER signature (Java / Android)
        sig = Signature.fromASN1(signatureBytes);
      }

      return verify(publicKey, hash, sig);
    } catch (e) {
      debugPrint('[LicenseService] ECDSA error: $e');
      return false;
    }
  }

  static BigInt _bytesToBigInt(List<int> bytes) {
    BigInt result = BigInt.zero;
    for (final byte in bytes) {
      result = (result << 8) | BigInt.from(byte & 0xff);
    }
    return result;
  }
}

