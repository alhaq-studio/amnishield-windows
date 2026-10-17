import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amnshield_flutter/services/config_syncer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConfigSyncer Cross-Platform Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadLocalConfig returns default settings', () async {
      final config = await ConfigSyncer.loadLocalConfig();

      expect(config['blocked_apps'], isEmpty);
      expect(config['blocked_domains'], isEmpty);
      expect(config['focus_mode_active'], isFalse);
      expect(config['password'], isEmpty);
      expect(config['theme'], equals('emerald'));
      expect(config['custom_whitelist'], isEmpty);
      expect(config['show_block_overlay'], isTrue);
      expect(config['app_blocker_enabled'], isTrue);
      expect(config['web_filter_enabled'], isTrue);
      expect(config['usage_tracker_enabled'], isTrue);
      expect(config['adult_pack_active'], isFalse);
      expect(config['social_pack_active'], isFalse);
      expect(config['sync_rules_enabled'], isTrue);
    });

    test('syncConfig updates SharedPreferences lists and flags', () async {
      await ConfigSyncer.syncConfig(
        blockedApps: ['discord.exe', 'steam.exe'],
        blockedDomains: ['example.com', 'badsite.org'],
        focusModeActive: true,
        adultPackActive: true,
        socialPackActive: false,
      );

      final config = await ConfigSyncer.loadLocalConfig();

      expect(config['blocked_apps'], equals(['discord.exe', 'steam.exe']));
      expect(config['blocked_domains'], equals(['example.com', 'badsite.org']));
      expect(config['focus_mode_active'], isTrue);
      expect(config['adult_pack_active'], isTrue);
      expect(config['social_pack_active'], isFalse);
    });

    test('saveEngineToggles updates engine settings', () async {
      await ConfigSyncer.saveEngineToggles(
        appBlockerEnabled: false,
        webFilterEnabled: true,
        usageTrackerEnabled: false,
      );

      final config = await ConfigSyncer.loadLocalConfig();

      expect(config['app_blocker_enabled'], isFalse);
      expect(config['web_filter_enabled'], isTrue);
      expect(config['usage_tracker_enabled'], isFalse);
    });

    test('saveCustomWhitelist and saveTheme persist values correctly', () async {
      await ConfigSyncer.saveCustomWhitelist(['allowed.org', 'edu.org']);
      await ConfigSyncer.saveTheme('dark');

      final config = await ConfigSyncer.loadLocalConfig();

      expect(config['custom_whitelist'], equals(['allowed.org', 'edu.org']));
      expect(config['theme'], equals('dark'));
    });

    test('saveSyncSettings persists cloud sync options', () async {
      await ConfigSyncer.saveSyncSettings(
        syncRulesEnabled: false,
        syncAppUsageEnabled: true,
        syncWebUsageEnabled: false,
        smartRecommendationsEnabled: true,
      );

      final config = await ConfigSyncer.loadLocalConfig();

      expect(config['sync_rules_enabled'], isFalse);
      expect(config['sync_app_usage_enabled'], isTrue);
      expect(config['sync_web_usage_enabled'], isFalse);
      expect(config['smart_recommendations_enabled'], isTrue);
    });

    test('onboarding state persistence works as expected', () async {
      expect(await ConfigSyncer.isOnboardingCompleted(), isFalse);

      await ConfigSyncer.saveOnboardingCompleted(true);
      expect(await ConfigSyncer.isOnboardingCompleted(), isTrue);
    });
  });
}
