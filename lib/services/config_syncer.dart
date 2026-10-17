import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigSyncer {
  static const String _windowsConfigPath = r'C:\ProgramData\AmnShield\config.json';
  static const String _windowsConfigDir = r'C:\ProgramData\AmnShield';

  static const String _keyBlockedApps = 'blocked_apps';
  static const String _keyBlockedDomains = 'blocked_domains';
  static const String _keyFocusMode = 'focus_mode_active';
  static const String _keyPassword = 'app_password';
  static const String _passwordSalt = 'AmnShield_Secure_Salt_2026_';

  /// Hashes a plaintext password using SHA-256 with a salt
  static String hashPassword(String password) {
    if (password.isEmpty) return '';
    final bytes = utf8.encode('$_passwordSalt$password');
    return sha256.convert(bytes).toString();
  }

  /// Verifies if a user-supplied password matches the stored password hash
  static Future<bool> verifyPassword(String input) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPassword) ?? '';
    if (stored.isEmpty) return true;

    final trimmedInput = input.trim();

    // Check if stored string is legacy plaintext
    if (stored == trimmedInput) {
      // Automatic migration from legacy plaintext to hashed
      await savePassword(trimmedInput);
      return true;
    }

    return hashPassword(trimmedInput) == stored;
  }

  /// Returns true if a master password is set
  static Future<bool> hasPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyPassword) ?? '';
    return stored.isNotEmpty;
  }
  static const String _keyTheme = 'app_theme';
  static const String _keyAdultPackActive = 'adult_pack_active';
  static const String _keySocialPackActive = 'social_pack_active';

  static const List<String> _socialDomains = [
    'facebook.com', 'www.facebook.com', 'fb.com', 'instagram.com', 'www.instagram.com',
    'twitter.com', 'www.twitter.com', 'x.com', 'www.x.com', 'tiktok.com', 'www.tiktok.com',
    'reddit.com', 'www.reddit.com', 'snapchat.com', 'www.snapchat.com'
  ];

  static Future<void> savePackStates({
    bool? adultPackActive,
    bool? socialPackActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (adultPackActive != null) await prefs.setBool(_keyAdultPackActive, adultPackActive);
    if (socialPackActive != null) await prefs.setBool(_keySocialPackActive, socialPackActive);
  }

  // Save config both to local SharedPrefs and write to shared JSON for background service
  static Future<void> syncConfig({
    List<String>? blockedApps,
    List<String>? customDomains,
    List<String>? blockedDomains,
    bool? focusModeActive,
    bool? adultPackActive,
    bool? socialPackActive,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    List<String> userDomains = customDomains ?? blockedDomains ?? prefs.getStringList(_keyBlockedDomains) ?? [];
    List<String> apps = blockedApps ?? prefs.getStringList(_keyBlockedApps) ?? [];
    bool focus = focusModeActive ?? prefs.getBool(_keyFocusMode) ?? false;

    if (adultPackActive != null) await prefs.setBool(_keyAdultPackActive, adultPackActive);
    if (socialPackActive != null) await prefs.setBool(_keySocialPackActive, socialPackActive);

    bool isAdultActive = adultPackActive ?? prefs.getBool(_keyAdultPackActive) ?? false;
    bool isSocialActive = socialPackActive ?? prefs.getBool(_keySocialPackActive) ?? false;

    // Save only user custom domains locally so UI stays clean and fast
    await prefs.setStringList(_keyBlockedApps, apps);
    await prefs.setStringList(_keyBlockedDomains, userDomains);
    await prefs.setBool(_keyFocusMode, focus);

    bool webFilterEnabled = prefs.getBool(_keyWebFilterEnabled) ?? true;
    bool appBlockerEnabled = prefs.getBool(_keyAppBlockerEnabled) ?? true;

    if (kIsWeb) return; // Skip disk file writing on web

    // Format app names with .exe extension for Windows monitoring if enabled and focus active
    List<String> formattedApps = (focus && appBlockerEnabled)
        ? apps.map((app) {
            String clean = app.trim().toLowerCase();
            if (Platform.isWindows && !clean.endsWith('.exe')) {
              return '$clean.exe';
            }
            return clean;
          }).toList()
        : <String>[];

    // Prepare full domain list for background service config (empty if web filter is disabled or focus is off)
    Set<String> allBannedDomains = <String>{};

    if (webFilterEnabled) {
      allBannedDomains.addAll(userDomains.map((d) => d.trim().toLowerCase()));

      if (isSocialActive) {
        allBannedDomains.addAll(_socialDomains.map((d) => d.trim().toLowerCase()));
      }

      if (isAdultActive) {
        try {
          String data = await rootBundle.loadString('assets/blocklists/adult_domains.txt');
          final lines = data.split('\n');
          for (final line in lines) {
            final trimmed = line.trim().toLowerCase();
            if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
              allBannedDomains.add(trimmed);
            }
          }
        } catch (e) {
          debugPrint('Error loading adult blocklist asset in background sync: $e');
        }
      }
    }

    // Write to platform config path
    try {
      File? file;
      if (Platform.isWindows) {
        final dir = Directory(_windowsConfigDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        file = File(_windowsConfigPath);
      } else {
        final appDir = await getApplicationSupportDirectory();
        if (!await appDir.exists()) {
          await appDir.create(recursive: true);
        }
        file = File('${appDir.path}/config.json');
      }

      final configMap = {
        'banned_apps': formattedApps,
        'banned_domains': allBannedDomains.toList(),
        'focus_mode_active': focus && (webFilterEnabled || appBlockerEnabled),
      };

      // Output as clean formatted JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(configMap);
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Config sync file write failed: $e');
    }
  }

  static const String _keyCustomWhitelist = 'custom_whitelist';

  // Save custom whitelist
  static Future<void> saveCustomWhitelist(List<String> whitelist) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyCustomWhitelist, whitelist);
  }

  // Save new theme configuration
  static Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme);
  }

  static const String _keyShowBlockOverlay = 'show_block_overlay';
  static const String _keyAppBlockerEnabled = 'app_blocker_enabled';
  static const String _keyWebFilterEnabled = 'web_filter_enabled';
  static const String _keyUsageTrackerEnabled = 'usage_tracker_enabled';

  static const String _keySyncRulesEnabled = 'sync_rules_enabled';
  static const String _keySyncAppUsageEnabled = 'sync_app_usage_enabled';
  static const String _keySyncWebUsageEnabled = 'sync_web_usage_enabled';
  static const String _keySmartRecommendationsEnabled = 'smart_recommendations_enabled';

  // Save block overlay setting
  static Future<void> saveShowBlockOverlay(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowBlockOverlay, show);
  }

  // Save cloud sync & privacy settings
  static Future<void> saveSyncSettings({
    bool? syncRulesEnabled,
    bool? syncAppUsageEnabled,
    bool? syncWebUsageEnabled,
    bool? smartRecommendationsEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (syncRulesEnabled != null) await prefs.setBool(_keySyncRulesEnabled, syncRulesEnabled);
    if (syncAppUsageEnabled != null) await prefs.setBool(_keySyncAppUsageEnabled, syncAppUsageEnabled);
    if (syncWebUsageEnabled != null) await prefs.setBool(_keySyncWebUsageEnabled, syncWebUsageEnabled);
    if (smartRecommendationsEnabled != null) await prefs.setBool(_keySmartRecommendationsEnabled, smartRecommendationsEnabled);
  }

  // Save engine toggles
  static Future<void> saveEngineToggles({
    bool? appBlockerEnabled,
    bool? webFilterEnabled,
    bool? usageTrackerEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (appBlockerEnabled != null) await prefs.setBool(_keyAppBlockerEnabled, appBlockerEnabled);
    if (webFilterEnabled != null) await prefs.setBool(_keyWebFilterEnabled, webFilterEnabled);
    if (usageTrackerEnabled != null) await prefs.setBool(_keyUsageTrackerEnabled, usageTrackerEnabled);
  }

  // Load configuration from local SharedPreferences
  static Future<Map<String, dynamic>> loadLocalConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'blocked_apps': prefs.getStringList(_keyBlockedApps) ?? [],
      'blocked_domains': prefs.getStringList(_keyBlockedDomains) ?? [],
      'focus_mode_active': prefs.getBool(_keyFocusMode) ?? false,
      'password': prefs.getString(_keyPassword) ?? '', // password hash (or empty)
      'theme': prefs.getString(_keyTheme) ?? 'emerald', // default theme
      'custom_whitelist': prefs.getStringList(_keyCustomWhitelist) ?? [],
      'show_block_overlay': prefs.getBool(_keyShowBlockOverlay) ?? true,
      'app_blocker_enabled': prefs.getBool(_keyAppBlockerEnabled) ?? true,
      'web_filter_enabled': prefs.getBool(_keyWebFilterEnabled) ?? true,
      'usage_tracker_enabled': prefs.getBool(_keyUsageTrackerEnabled) ?? true,
      'adult_pack_active': prefs.getBool(_keyAdultPackActive) ?? false,
      'social_pack_active': prefs.getBool(_keySocialPackActive) ?? false,
      'sync_rules_enabled': prefs.getBool(_keySyncRulesEnabled) ?? true,
      'sync_app_usage_enabled': prefs.getBool(_keySyncAppUsageEnabled) ?? true,
      'sync_web_usage_enabled': prefs.getBool(_keySyncWebUsageEnabled) ?? true,
      'smart_recommendations_enabled': prefs.getBool(_keySmartRecommendationsEnabled) ?? true,
    };
  }

  static const String _keyOnboardingCompleted = 'onboarding_completed';

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  static Future<void> saveOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, completed);
  }

  // Save new password configuration (stores SHA-256 hash or empty string)
  static Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      await prefs.setString(_keyPassword, '');
    } else {
      await prefs.setString(_keyPassword, hashPassword(trimmed));
    }
  }
}
