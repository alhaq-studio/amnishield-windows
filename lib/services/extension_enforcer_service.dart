import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'license_service.dart';

class ExtensionEnforcerService {
  static const String _keyExtensionEnforced = 'extension_protection_enforced';

  // Production WebStore Extension IDs
  static const String webstoreExtensionId = 'llbdoeiphjhnjlohogddiignodbmlomo'; // AmnShield
  static const String amngazeWebstoreExtensionId = 'opchbfkgkhchldkjhkcjhijogldbflna'; // AmnGaze

  // Local Unpacked Development Extension IDs
  static const String localExtensionId = 'jpfaddafkfdlmfbfdeniigddadpfmndn'; // AmnShield Unpacked
  static const String amngazeLocalExtensionId = 'mbljgbofghhkgfkjdfjhkgfkjdfmngz'; // AmnGaze Unpacked

  static Future<bool> isEnforced() async {
    final prefs = await SharedPreferences.getInstance();
    final isPrem = await LicenseService.isPremium();
    if (!isPrem) return false;
    return prefs.getBool(_keyExtensionEnforced) ?? false;
  }

  static Future<bool> setEnforcement(bool enable) async {
    if (enable) {
      final isPrem = await LicenseService.isPremium();
      if (!isPrem) {
        debugPrint('[ExtensionEnforcer] Extension enforcement requires Premium status.');
        return false;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExtensionEnforced, enable);

    if (kIsWeb || !Platform.isWindows) return true;

    try {
      if (enable) {
        await _applyRegistryPolicy();
      } else {
        await _removeRegistryPolicy();
      }
      return true;
    } catch (e) {
      debugPrint('[ExtensionEnforcer] Registry policy update error: $e');
      return false;
    }
  }

  static Future<void> _applyRegistryPolicy() async {
    if (kIsWeb || !Platform.isWindows) return;

    final webstorePolicy = '$webstoreExtensionId;https://clients2.google.com/service/update2/crx';
    final amngazeWebstorePolicy = '$amngazeWebstoreExtensionId;https://clients2.google.com/service/update2/crx';

    final psScript = '''
      \$val100 = "$webstorePolicy"
      \$val102 = "$amngazeWebstorePolicy"

      \$chromeForcelist = @(
        "HKCU:\\Software\\Policies\\Google\\Chrome\\ExtensionInstallForcelist",
        "HKLM:\\SOFTWARE\\Policies\\Google\\Chrome\\ExtensionInstallForcelist"
      )
      \$edgeForcelist = @(
        "HKCU:\\Software\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist",
        "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist"
      )

      # 1. Force Install Extensions (WebStore IDs only – Anti-Uninstall)
      foreach (\$p in (\$chromeForcelist + \$edgeForcelist)) {
        try {
          if (!(Test-Path \$p)) { New-Item -Path \$p -Force | Out-Null }
          # Remove any stale local/unpacked entries
          Remove-ItemProperty -Path \$p -Name "101" -ErrorAction SilentlyContinue | Out-Null
          Remove-ItemProperty -Path \$p -Name "103" -ErrorAction SilentlyContinue | Out-Null
          Set-ItemProperty -Path \$p -Name "100" -Value \$val100 -Force | Out-Null
          Set-ItemProperty -Path \$p -Name "102" -Value \$val102 -Force | Out-Null
        } catch { }
      }

      # 2. Block Incognito & Guest Mode in Chrome & Edge
      \$browserPolicyKeys = @(
        @{ Path="HKLM:\\SOFTWARE\\Policies\\Google\\Chrome"; Incognito="IncognitoModeAvailability"; Guest="BrowserGuestModeEnabled" },
        @{ Path="HKCU:\\Software\\Policies\\Google\\Chrome"; Incognito="IncognitoModeAvailability"; Guest="BrowserGuestModeEnabled" },
        @{ Path="HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge"; Incognito="InPrivateModeAvailability"; Guest="AllowGuestMode" },
        @{ Path="HKCU:\\Software\\Policies\\Microsoft\\Edge"; Incognito="InPrivateModeAvailability"; Guest="AllowGuestMode" }
      )

      foreach (\$item in \$browserPolicyKeys) {
        try {
          if (!(Test-Path \$item.Path)) { New-Item -Path \$item.Path -Force | Out-Null }
          # 1 = Incognito/InPrivate Disabled
          Set-ItemProperty -Path \$item.Path -Name \$item.Incognito -Value 1 -Type DWord -Force | Out-Null
          # 0 = Guest Mode Disabled
          Set-ItemProperty -Path \$item.Path -Name \$item.Guest -Value 0 -Type DWord -Force | Out-Null
        } catch { }
      }
    ''';

    final result = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
    debugPrint('[ExtensionEnforcer] Enforcement applied result code: ${result.exitCode}');
    if (result.stderr.toString().isNotEmpty) {
      debugPrint('[ExtensionEnforcer] stderr: ${result.stderr}');
    }
  }

  static Future<void> _removeRegistryPolicy() async {
    if (kIsWeb || !Platform.isWindows) return;

    final psScript = '''
      \$chromeForcelist = @(
        "HKCU:\\Software\\Policies\\Google\\Chrome\\ExtensionInstallForcelist",
        "HKLM:\\SOFTWARE\\Policies\\Google\\Chrome\\ExtensionInstallForcelist"
      )
      \$edgeForcelist = @(
        "HKCU:\\Software\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist",
        "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge\\ExtensionInstallForcelist"
      )

      foreach (\$p in (\$chromeForcelist + \$edgeForcelist)) {
        try {
          if (Test-Path \$p) {
            Remove-Item -Path \$p -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
          }
        } catch { }
      }

      \$browserPolicyKeys = @(
        @{ Path="HKLM:\\SOFTWARE\\Policies\\Google\\Chrome"; Incognito="IncognitoModeAvailability"; Guest="BrowserGuestModeEnabled" },
        @{ Path="HKCU:\\Software\\Policies\\Google\\Chrome"; Incognito="IncognitoModeAvailability"; Guest="BrowserGuestModeEnabled" },
        @{ Path="HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge"; Incognito="InPrivateModeAvailability"; Guest="AllowGuestMode" },
        @{ Path="HKCU:\\Software\\Policies\\Microsoft\\Edge"; Incognito="InPrivateModeAvailability"; Guest="AllowGuestMode" }
      )

      foreach (\$item in \$browserPolicyKeys) {
        try {
          if (Test-Path \$item.Path) {
            Remove-ItemProperty -Path \$item.Path -Name \$item.Incognito -ErrorAction SilentlyContinue | Out-Null
            Remove-ItemProperty -Path \$item.Path -Name \$item.Guest -ErrorAction SilentlyContinue | Out-Null
          }
        } catch { }
      }
    ''';

    final result = await Process.run('powershell', ['-NoProfile', '-Command', psScript]);
    debugPrint('[ExtensionEnforcer] Enforcement removal result code: ${result.exitCode}');
  }
}
