import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../services/config_syncer.dart';
import '../services/process_blocker_service.dart';
import '../services/app_usage_service.dart';
import '../widgets/window_caption_controls.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/app_blocker_tab.dart';
import 'tabs/web_filter_tab.dart';
import 'tabs/usage_tab.dart';

import '../widgets/block_overlay_dialog.dart';
import '../widgets/about_dialog.dart';
import '../widgets/settings_dialog.dart';

class ControlPanelScreen extends StatefulWidget {
  const ControlPanelScreen({super.key});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Master Engine Toggles
  bool _isBlockerActive = true;
  bool _isAppBlockerEnabled = true;
  bool _isWebFilterEnabled = true;
  bool _isUsageTrackerEnabled = true;

  bool _adultBlockActive = false;
  bool _socialBlockActive = false;
  
  List<String> _blockedApps = [];
  List<String> _blockedDomains = [];
  List<String> _customWhitelist = [];

  final TextEditingController _appInputController = TextEditingController();
  final TextEditingController _domainInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConfiguration();

    ProcessBlockerService.lastBlockedNotifier.addListener(() async {
      final blockedItem = ProcessBlockerService.lastBlockedNotifier.value;
      if (blockedItem != null && mounted) {
        ProcessBlockerService.lastBlockedNotifier.value = null;

        try {
          if (await windowManager.isMinimized()) {
            await windowManager.restore();
          }
          await windowManager.show();
          await windowManager.focus();
        } catch (e) {
          debugPrint('WindowManager focus error: $e');
        }

        if (mounted) {
          BlockOverlayDialog.show(context, blockedItem);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appInputController.dispose();
    _domainInputController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    final config = await ConfigSyncer.loadLocalConfig();
    if (mounted) {
      setState(() {
        _blockedApps = List<String>.from(config['blocked_apps']);
        // Only load custom user-added domains (pack domains are never in UI state)
        _blockedDomains = List<String>.from(config['blocked_domains']);
        _customWhitelist = List<String>.from(config['custom_whitelist'] ?? []);
        _isBlockerActive = config['focus_mode_active'] ?? true;

        _isAppBlockerEnabled = config['app_blocker_enabled'] ?? true;
        _isWebFilterEnabled = config['web_filter_enabled'] ?? true;
        _isUsageTrackerEnabled = config['usage_tracker_enabled'] ?? true;

        // Pack states are stored as dedicated booleans, not inferred from domain list
        _adultBlockActive = config['adult_pack_active'] ?? false;
        _socialBlockActive = config['social_pack_active'] ?? false;
      });

      ProcessBlockerService.updateRules(
        isBlockerActive: _isBlockerActive && _isAppBlockerEnabled,
        blockedApps: _blockedApps,
        customWhitelist: _customWhitelist,
      );

      AppUsageService.updateStatus(_isBlockerActive && _isUsageTrackerEnabled);

      // Write merged config.json for the C# service in background
      _updateConfig();
    }
  }

  Future<void> _updateConfig() async {
    // Save custom domains + pack states to SharedPreferences
    await ConfigSyncer.syncConfig(
      blockedApps: _blockedApps,
      customDomains: _blockedDomains,
      focusModeActive: _isBlockerActive,
      adultPackActive: _adultBlockActive,
      socialPackActive: _socialBlockActive,
    );
    await ConfigSyncer.saveCustomWhitelist(_customWhitelist);
    await ConfigSyncer.saveEngineToggles(
      appBlockerEnabled: _isAppBlockerEnabled,
      webFilterEnabled: _isWebFilterEnabled,
      usageTrackerEnabled: _isUsageTrackerEnabled,
    );

    ProcessBlockerService.updateRules(
      isBlockerActive: _isBlockerActive && _isAppBlockerEnabled,
      blockedApps: _blockedApps,
      customWhitelist: _customWhitelist,
    );

    AppUsageService.updateStatus(_isBlockerActive && _isUsageTrackerEnabled);
  }

  void _addBlockedApp([String? customApp]) {
    String app = (customApp ?? _appInputController.text).trim().toLowerCase();
    if (app.isNotEmpty) {
      if (!app.endsWith('.exe')) app = '$app.exe';
      if (!_blockedApps.contains(app)) {
        setState(() {
          _blockedApps.add(app);
          _customWhitelist.remove(app);
          _appInputController.clear();
        });
        _updateConfig();
      }
    }
  }

  void _removeBlockedApp(String app) {
    setState(() {
      _blockedApps.remove(app);
    });
    _updateConfig();
  }

  void _addCustomWhitelistApp([String? customApp]) {
    String app = (customApp ?? _appInputController.text).trim().toLowerCase();
    if (app.isNotEmpty) {
      if (!app.endsWith('.exe')) app = '$app.exe';
      if (!_customWhitelist.contains(app)) {
        setState(() {
          _customWhitelist.add(app);
          _blockedApps.remove(app);
          _appInputController.clear();
        });
        _updateConfig();
      }
    }
  }

  void _removeCustomWhitelistApp(String app) {
    setState(() {
      _customWhitelist.remove(app);
    });
    _updateConfig();
  }

  void _addCustomDomain() {
    String raw = _domainInputController.text.trim().toLowerCase();
    // Strip common protocol prefixes
    raw = raw.replaceAll(RegExp(r'^https?://'), '');
    raw = raw.replaceAll(RegExp(r'^www\.'), '');
    // Remove trailing slashes/paths
    raw = raw.split('/').first;
    final domain = raw.trim();

    debugPrint('[AmnShield] _addCustomDomain called with: "$domain"');

    if (domain.isEmpty) return;

    if (_blockedDomains.contains(domain)) {
      _domainInputController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$domain" is already in the blacklist.'), duration: const Duration(seconds: 2)),
        );
      }
      return;
    }

    setState(() {
      _blockedDomains.add(domain);
      _domainInputController.clear();
    });
    _updateConfig();
    debugPrint('[AmnShield] Domain added: $domain. Total blocked domains: ${_blockedDomains.length}');
  }

  void _removeCustomDomain(String domain) {
    setState(() {
      _blockedDomains.remove(domain);
    });
    _updateConfig();
  }

  void _removeAllCustomDomains() {
    setState(() {
      _blockedDomains.clear();
    });
    _updateConfig();
    debugPrint('[AmnShield] All custom domains removed.');
  }

  Future<void> _toggleAdultPack(bool active) async {
    // Just toggle the state — pack domains are merged in ConfigSyncer background write
    // Never add 50K+ domains to UI state
    setState(() {
      _adultBlockActive = active;
    });
    await ConfigSyncer.savePackStates(
      adultPackActive: _adultBlockActive,
      socialPackActive: _socialBlockActive,
    );
    _updateConfig();
  }

  Future<void> _toggleSocialPack(bool active) async {
    // Just toggle the state — pack domains are merged in ConfigSyncer background write
    setState(() {
      _socialBlockActive = active;
    });
    await ConfigSyncer.savePackStates(
      adultPackActive: _adultBlockActive,
      socialPackActive: _socialBlockActive,
    );
    _updateConfig();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => windowManager.startDragging(),
          onDoubleTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          child: DragToMoveArea(
            child: AppBar(
              leading: Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.onPrimary),
                  tooltip: 'Navigation Menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              titleSpacing: 0,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'AmnShield Control Panel',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Chip(
                    avatar: Icon(
                      _isBlockerActive ? Icons.check_circle : Icons.pause_circle_filled,
                      color: Colors.white,
                      size: 14,
                    ),
                    label: Text(
                      _isBlockerActive ? 'SHIELD ACTIVE' : 'INACTIVE',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: _isBlockerActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: _isBlockerActive
                        ? 'Guardian Service & Browser Extension Synced (127.0.0.1:48192)'
                        : 'Guardian Engine Disconnected / Standby',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isBlockerActive
                            ? const Color(0xFF1B5E20).withValues(alpha: 0.8)
                            : Colors.red.shade900.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isBlockerActive ? Colors.greenAccent : Colors.redAccent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isBlockerActive ? Colors.greenAccent : Colors.redAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: _isBlockerActive ? Colors.greenAccent : Colors.redAccent,
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isBlockerActive ? 'SYS & EXT ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: const [
                WindowCaptionControls(),
                SizedBox(width: 4),
              ],
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 2,
              bottom: TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                indicatorColor: Theme.of(context).colorScheme.onPrimary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
                  Tab(icon: Icon(Icons.app_blocking), text: 'App Blocker'),
                  Tab(icon: Icon(Icons.web), text: 'Website Filter'),
                  Tab(icon: Icon(Icons.timer), text: 'Usage Tracker'),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              currentAccountPicture: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white24,
                ),
                child: const Icon(Icons.shield, size: 36, color: Colors.white),
              ),
              accountName: const Text('AmnShield Guardian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              accountEmail: Text(_isBlockerActive ? '● Shield Active' : '○ Shield Paused', style: const TextStyle(fontSize: 12)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Dashboard'),
              selected: _tabController.index == 0,
              onTap: () {
                _tabController.animateTo(0);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.app_blocking_outlined),
              title: const Text('App Blocker & Whitelist'),
              selected: _tabController.index == 1,
              onTap: () {
                _tabController.animateTo(1);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.web_outlined),
              title: const Text('Website Filter'),
              selected: _tabController.index == 2,
              onTap: () {
                _tabController.animateTo(2);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Usage Tracker & Limits'),
              selected: _tabController.index == 3,
              onTap: () {
                _tabController.animateTo(3);
                Navigator.of(context).pop();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings & Security'),
              onTap: () {
                Navigator.of(context).pop();
                SettingsDialog.show(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About AmnShield'),
              onTap: () {
                Navigator.of(context).pop();
                AboutAmnShieldDialog.show(context);
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'v8.26.2026 - Windows Edition',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Dashboard Tab
          DashboardTab(
            isBlockerActive: _isBlockerActive,
            isUsageTrackerEnabled: _isUsageTrackerEnabled,
            blockedAppsCount: _blockedApps.length,
            blockedDomainsCount: _blockedDomains.length,
            customWhitelistCount: _customWhitelist.length,
            adultBlockActive: _adultBlockActive,
            socialBlockActive: _socialBlockActive,
            onToggleBlocker: (val) {
              setState(() {
                _isBlockerActive = val;
              });
              _updateConfig();
            },
            onNavigateTab: (index) => _tabController.animateTo(index),
            onActivatePreset: (presetName, duration) {
              if (presetName == 'Deen Mode') {
                _toggleAdultPack(true);
                _toggleSocialPack(true);
              }
            },
          ),

          // 2. App Blocker Tab (Banned & Allowed Whitelist)
          AppBlockerTab(
            blockedApps: _blockedApps,
            customWhitelist: _customWhitelist,
            appInputController: _appInputController,
            onAddApp: _addBlockedApp,
            onRemoveApp: _removeBlockedApp,
            onAddWhitelistApp: _addCustomWhitelistApp,
            onRemoveWhitelistApp: _removeCustomWhitelistApp,
          ),

          // 3. Website Filter Tab
          WebFilterTab(
            adultBlockActive: _adultBlockActive,
            socialBlockActive: _socialBlockActive,
            blockedDomains: _blockedDomains,
            domainInputController: _domainInputController,
            onToggleAdultPack: _toggleAdultPack,
            onToggleSocialPack: _toggleSocialPack,
            onAddDomain: _addCustomDomain,
            onRemoveDomain: _removeCustomDomain,
            onRemoveAllDomains: _removeAllCustomDomains,
          ),

          // 4. Usage Tracker & Time Limits Tab
          UsageTabWidget(
            isUsageTrackerEnabled: _isUsageTrackerEnabled,
            onToggleUsageTracker: (val) {
              setState(() {
                _isUsageTrackerEnabled = val;
              });
              _updateConfig();
            },
          ),
        ],
      ),
    );
  }
}
