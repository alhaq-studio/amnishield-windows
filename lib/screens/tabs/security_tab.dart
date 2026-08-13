import 'package:flutter/material.dart';
import '../../services/config_syncer.dart';
import '../../theme/app_theme.dart';

class SecurityTabWidget extends StatefulWidget {
  const SecurityTabWidget({super.key});

  @override
  State<SecurityTabWidget> createState() => _SecurityTabWidgetState();
}

class _SecurityTabWidgetState extends State<SecurityTabWidget> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _customWhitelistController = TextEditingController();

  String _storedPassword = '';
  List<String> _customWhitelist = [];
  bool _showBlockOverlay = true;
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
    _customWhitelistController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final config = await ConfigSyncer.loadLocalConfig();
    if (mounted) {
      setState(() {
        _storedPassword = config['password'] ?? '';
        _customWhitelist = List<String>.from(config['custom_whitelist'] ?? []);
        _showBlockOverlay = config['show_block_overlay'] ?? true;
      });
    }
  }

  Future<void> _changePassword() async {
    final oldText = _oldPasswordController.text;
    final newText = _newPasswordController.text.trim();

    if (_storedPassword.isNotEmpty && oldText != _storedPassword) {
      setState(() {
        _message = 'Incorrect current passcode.';
        _messageColor = Colors.red;
      });
      return;
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
        _storedPassword = newText;
        _message = newText.isEmpty ? 'Passcode removed.' : 'Passcode updated successfully.';
        _messageColor = Colors.green;
        _oldPasswordController.clear();
        _newPasswordController.clear();
      });
    }
  }

  Future<void> _addCustomWhitelistItem() async {
    String item = _customWhitelistController.text.trim().toLowerCase();
    if (item.isNotEmpty) {
      if (!item.endsWith('.exe')) item = '$item.exe';
      if (!_customWhitelist.contains(item)) {
        setState(() {
          _customWhitelist.add(item);
          _customWhitelistController.clear();
        });
        await ConfigSyncer.saveCustomWhitelist(_customWhitelist);
      }
    }
  }

  Future<void> _removeCustomWhitelistItem(String item) async {
    setState(() {
      _customWhitelist.remove(item);
    });
    await ConfigSyncer.saveCustomWhitelist(_customWhitelist);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Configuration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure the master passcode that locks the settings panel and prevents unauthorized changes.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  if (_storedPassword.isNotEmpty) ...[
                    TextField(
                      controller: _oldPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Passcode',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _storedPassword.isEmpty ? 'Set Master Passcode' : 'New Passcode (Leave blank to remove)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_message.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(_message, style: TextStyle(color: _messageColor, fontWeight: FontWeight.bold)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Text(_storedPassword.isEmpty ? 'SET PASSCODE' : 'UPDATE PASSCODE'),
                    ),
                  )
                ],
              ),
            ),

            const Divider(height: 48),

            // Focus Block Overlay Settings Section
            Row(
              children: [
                Icon(Icons.style_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Focus Block Overlay & Warning Screen',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Show an interactive, motivational Focus Warning overlay screen when blocked applications or websites are accessed.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Motivational Focus Warning Overlay', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Displays a motivational quote, restriction notice, and passcode unlock prompt.'),
              value: _showBlockOverlay,
              onChanged: (val) async {
                setState(() {
                  _showBlockOverlay = val;
                });
                await ConfigSyncer.saveShowBlockOverlay(val);
              },
            ),

            const Divider(height: 48),

            // Allowed Applications & Whitelist Section
            Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Allowed Applications & Trusted Whitelist',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Add custom process exceptions (e.g. rg.exe, python.exe, my_dev_server.exe) to ensure AmnShield never terminates your trusted applications.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Add Custom Process Exception Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customWhitelistController,
                    decoration: InputDecoration(
                      hintText: 'e.g. rg.exe, python, my_server',
                      prefixIcon: const Icon(Icons.code),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => _addCustomWhitelistItem(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _addCustomWhitelistItem,
                  icon: const Icon(Icons.security_update_good),
                  label: const Text('Add Exception'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // List of Whitelisted Exceptions
            if (_customWhitelist.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _customWhitelist.map((item) {
                  return Chip(
                    avatar: const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                    label: Text(item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onDeleted: () => _removeCustomWhitelistItem(item),
                    deleteIconColor: Colors.red,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(height: 48),

            Text(
              'App Theme',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select the visual theme for your AmnShield desktop experience.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<String>(
              valueListenable: themeNotifier,
              builder: (context, currentTheme, _) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildThemeOption(context, 'sunset', 'Sunset Glow (Terracotta)', const Color(0xFFA45833), currentTheme),
                    _buildThemeOption(context, 'emerald', 'Emerald Calm (Sage)', const Color(0xFF3C7A67), currentTheme),
                    _buildThemeOption(context, 'cosmic', 'Cosmic Night (Violet)', const Color(0xFFC8B8FF), currentTheme),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String value,
    String label,
    Color color,
    String selectedValue,
  ) {
    final isSelected = value == selectedValue;
    return InkWell(
      onTap: () async {
        themeNotifier.value = value;
        await ConfigSyncer.saveTheme(value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
