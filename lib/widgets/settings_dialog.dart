import 'package:flutter/material.dart';
import '../services/config_syncer.dart';
import '../services/extension_enforcer_service.dart';
import '../services/payment_manager.dart';
import '../theme/app_theme.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _hasPasswordSet = false;
  bool _showBlockOverlay = true;
  bool _extensionEnforced = false;
  bool _syncRulesEnabled = true;
  bool _syncAppUsageEnabled = true;
  bool _syncWebUsageEnabled = true;
  bool _smartRecommendationsEnabled = true;
  String _message = '';
  Color _messageColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final config = await ConfigSyncer.loadLocalConfig();
    final enforced = await ExtensionEnforcerService.isEnforced();
    final hasPassword = await ConfigSyncer.hasPassword();
    if (mounted) {
      setState(() {
        _hasPasswordSet = hasPassword;
        _showBlockOverlay = config['show_block_overlay'] ?? true;
        _extensionEnforced = enforced;
        _syncRulesEnabled = config['sync_rules_enabled'] ?? true;
        _syncAppUsageEnabled = config['sync_app_usage_enabled'] ?? true;
        _syncWebUsageEnabled = config['sync_web_usage_enabled'] ?? true;
        _smartRecommendationsEnabled = config['smart_recommendations_enabled'] ?? true;
      });
    }
  }

  Future<void> _changePassword() async {
    final oldText = _oldPasswordController.text;
    final newText = _newPasswordController.text.trim();

    if (_hasPasswordSet) {
      final isOldCorrect = await ConfigSyncer.verifyPassword(oldText);
      if (!isOldCorrect) {
        if (mounted) {
          setState(() {
            _message = 'Incorrect current passcode.';
            _messageColor = Colors.red;
          });
        }
        return;
      }
    }

    if (newText.isNotEmpty && newText.length < 4) {
      setState(() {
        _message = 'New passcode must be at least 4 characters long.';
        _messageColor = Colors.red;
      });
      return;
    }

    await ConfigSyncer.savePassword(newText);
    if (mounted) {
      setState(() {
        _hasPasswordSet = newText.isNotEmpty;
        _message = newText.isEmpty ? 'Passcode removed.' : 'Passcode updated successfully.';
        _messageColor = Colors.green;
        _oldPasswordController.clear();
        _newPasswordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.all(24),
      title: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Icon(Icons.settings, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 12),
            Text(
              'Settings & Security',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 520,
        height: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Passcode Security
              Text(
                'Parental & Admin Passcode',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set a passcode to lock settings and prevent unauthorized rule modifications.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_hasPasswordSet)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TextField(
                            controller: _oldPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Current Passcode',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: !_hasPasswordSet ? 'New Passcode (Leave empty to disable)' : 'New Passcode',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_message.isNotEmpty)
                            Expanded(
                              child: Text(
                                _message,
                                style: TextStyle(color: _messageColor, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            )
                          else
                            const SizedBox(),
                          ElevatedButton(
                            onPressed: _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Passcode'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Block Overlay Toggle
              Text(
                'Block Overlay & Motivational Popup',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Show a full-screen block warning dialog with motivational quotes whenever a distraction app or website is blocked.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Show Block Overlay Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(_showBlockOverlay ? 'Overlay active on distraction launches' : 'Silent process termination'),
                  value: _showBlockOverlay,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) async {
                    setState(() {
                      _showBlockOverlay = val;
                    });
                    await ConfigSyncer.saveShowBlockOverlay(val);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Browser Extension Tamper Protection
              Text(
                'Browser Extension Protection & Enforcement',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enforces the AmnShield browser extension via Windows Policy in Chrome & Edge to prevent users from removing or disabling it.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Card(
                child: SwitchListTile(
                  title: const Text('Enforce Extension (Prevent Uninstall)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(_extensionEnforced ? 'Locked via Windows Policy (Chrome & Edge)' : 'Standard browser extension mode'),
                  value: _extensionEnforced,
                  activeThumbColor: theme.colorScheme.primary,
                  onChanged: (val) async {
                    setState(() {
                      _extensionEnforced = val;
                    });
                    await ExtensionEnforcerService.setEnforcement(val);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Sync & Cloud Privacy Controls
              Text(
                'Sync & Cloud Privacy',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Control what rules, app activity, and web telemetry sync with your cloud account.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Sync Rules & Blocklists', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(_syncRulesEnabled ? 'Cloud sync active for domain & app rules' : 'Local rules only (cloud sync disabled)'),
                      value: _syncRulesEnabled,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        setState(() => _syncRulesEnabled = val);
                        await ConfigSyncer.saveSyncSettings(syncRulesEnabled: val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Sync App Usage & Screentime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(_syncAppUsageEnabled ? 'App usage stats backing up to cloud' : 'App screentime stored locally only'),
                      value: _syncAppUsageEnabled,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        setState(() => _syncAppUsageEnabled = val);
                        await ConfigSyncer.saveSyncSettings(syncAppUsageEnabled: val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Sync Website Usage Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(_syncWebUsageEnabled ? 'Web metrics syncing for cross-platform analytics' : 'Web usage stats stored locally only'),
                      value: _syncWebUsageEnabled,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        setState(() => _syncWebUsageEnabled = val);
                        await ConfigSyncer.saveSyncSettings(syncWebUsageEnabled: val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Smart AI Recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(_smartRecommendationsEnabled ? 'AI recommendations active' : 'AI analytics & recommendations disabled'),
                      value: _smartRecommendationsEnabled,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: (val) async {
                        setState(() => _smartRecommendationsEnabled = val);
                        await ConfigSyncer.saveSyncSettings(smartRecommendationsEnabled: val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Color Theme Accent Selection
              Text(
                'App Theme Accent',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Customize the accent color theme of AmnShield Control Panel.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String>(
                valueListenable: themeNotifier,
                builder: (context, currentTheme, _) {
                  return Wrap(
                    spacing: 10,
                    children: [
                      _buildThemeChip('emerald', 'Emerald Green', const Color(0xFF1B5E20), currentTheme),
                      _buildThemeChip('sapphire', 'Sapphire Blue', const Color(0xFF0D47A1), currentTheme),
                      _buildThemeChip('ruby', 'Ruby Crimson', const Color(0xFFB71C1C), currentTheme),
                      _buildThemeChip('amethyst', 'Amethyst Purple', const Color(0xFF4A148C), currentTheme),
                      _buildThemeChip('midnight', 'Midnight Dark', const Color(0xFF263238), currentTheme),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Supporter & Payment Card
              Text(
                'Al-Haq Initiative Support & License',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 6),
              const Text(
                'AmnShield is 100% free and open-source. Voluntary supporter contributions help fund our AI models and cloud sync infrastructure.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final launched = await PaymentManager.openStripeCheckout(plan: 'annual');
                          if (!launched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not launch Stripe Checkout.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Support via Stripe Checkout (Web)'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildThemeChip(String id, String label, Color color, String currentTheme) {
    final isSelected = currentTheme == id;
    return ChoiceChip(
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) async {
        if (selected) {
          themeNotifier.value = id;
          await ConfigSyncer.saveTheme(id);
        }
      },
    );
  }
}
