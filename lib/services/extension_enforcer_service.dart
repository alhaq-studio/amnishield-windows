import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExtensionEnforcerService {
  static const String _keyExtensionEnforced = 'extension_protection_enforced';

  // Production WebStore Extension ID
  static const String webstoreExtensionId = 'llbdoeiphjhnjlohogddiignodbmlomo';

  // Local Unpacked Development Extension ID
  static const String localExtensionId = 'jpfaddafkfdlmfbfdeniigddadpfmndn';

  static Future<bool> isEnforced() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExtensionEnforced) ?? false;
  }

  static Future<void> setEnforcement(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExtensionEnforced, enable);

    if (!Platform.isWindows) return;

    try {
      if (enable) {
        await _applyRegistryPolicy();
      } else {
        await _removeRegistryPolicy();
      }
    } catch (e) {
      debugPrint('[ExtensionEnforcer] Registry policy update error: $e');
    }
  }

  static Future<void> _applyRegistryPolicy() async {
    final webstorePolicy = '$webstoreExtensionId;https://clients2.google.com/service/update2/crx';
    final localPolicy = '$localExtensionId;https://clients2.google.com/service/update2/crx';

    final psScript = '''
      \$webstoreVal = "$webstorePolicy"
      \$localVal = "$localPolicy"

      \$chromePaths = @(
        "HKCU:\\Software\\Policies\\Google\\Chrome\\ExtensionInstallForcelist",
        "HKLM:\\SOFTWARE\\Policies\\Google\\Chrome\\ExtensionInstallForcelist"
      )
      \$edgePaths = @(
        "HKCU:\\Software\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist",
        "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist"
      )

      foreach (\$p in (\$chromePaths + \$edgePaths)) {
        try {
          if (!(Test-Path \$p)) { New-Item -Path \$p -Force | Out-Null }
          Set-ItemProperty -Path \$p -Name "100" -Value \$webstoreVal -Force | Out-Null
          Set-ItemProperty -Path \$p -Name "101" -Value \$localVal -Force | Out-Null
        } catch { }
      }
    ''';

    final result = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
    debugPrint('[ExtensionEnforcer] Dual policy set result code: ${result.exitCode}');
    if (result.stderr.toString().isNotEmpty) {
      debugPrint('[ExtensionEnforcer] stderr: ${result.stderr}');
    }
  }

  static Future<void> _removeRegistryPolicy() async {
    final psScript = '''
      \$chromePaths = @(
        "HKCU:\\Software\\Policies\\Google\\Chrome\\ExtensionInstallForcelist",
        "HKLM:\\SOFTWARE\\Policies\\Google\\Chrome\\ExtensionInstallForcelist"
      )
      \$edgePaths = @(
        "HKCU:\\Software\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist",
        "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist"
      )

      foreach (\$p in (\$chromePaths + \$edgePaths)) {
        try {
          if (Test-Path \$p) {
            Remove-ItemProperty -Path \$p -Name "100" -ErrorAction SilentlyContinue | Out-Null
            Remove-ItemProperty -Path \$p -Name "101" -ErrorAction SilentlyContinue | Out-Null
          }
        } catch { }
      }
    ''';

    final result = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
    debugPrint('[ExtensionEnforcer] Dual policy removal result code: ${result.exitCode}');
  }
}
