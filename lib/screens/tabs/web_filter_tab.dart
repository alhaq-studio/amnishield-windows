import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/extension_enforcer_service.dart';

class WebFilterTab extends StatefulWidget {
  final bool adultBlockActive;
  final bool socialBlockActive;
  final List<String> blockedDomains;
  final TextEditingController domainInputController;
  final ValueChanged<bool> onToggleAdultPack;
  final ValueChanged<bool> onToggleSocialPack;
  final VoidCallback onAddDomain;
  final ValueChanged<String> onRemoveDomain;
  final VoidCallback onRemoveAllDomains;

  const WebFilterTab({
    super.key,
    required this.adultBlockActive,
    required this.socialBlockActive,
    required this.blockedDomains,
    required this.domainInputController,
    required this.onToggleAdultPack,
    required this.onToggleSocialPack,
    required this.onAddDomain,
    required this.onRemoveDomain,
    required this.onRemoveAllDomains,
  });

  @override
  State<WebFilterTab> createState() => _WebFilterTabState();
}

class _WebFilterTabState extends State<WebFilterTab> {
  bool _isServiceOnline = false;
  bool _isEnforced = false;
  List<String> _detectedBrowsers = [];
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkStatus());
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    bool serviceOnline = false;
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);
      final req = await client.getUrl(Uri.parse('http://127.0.0.1:48192/status'));
      final res = await req.close();
      serviceOnline = res.statusCode == HttpStatus.ok;
      client.close();
    } catch (_) {
      serviceOnline = false;
    }

    final enforced = await ExtensionEnforcerService.isEnforced();
    final activeBrowsers = await _detectActiveBrowsers();

    if (mounted) {
      setState(() {
        _isServiceOnline = serviceOnline;
        _isEnforced = enforced;
        _detectedBrowsers = activeBrowsers;
      });
    }
  }

  Future<List<String>> _detectActiveBrowsers() async {
    final list = <String>[];
    if (!Platform.isWindows) return ['Web Browser'];

    try {
      final result = await Process.run('tasklist', ['/FO', 'CSV', '/NH']);
      final output = result.stdout.toString().toLowerCase();

      if (output.contains('chrome.exe')) list.add('Google Chrome');
      if (output.contains('msedge.exe')) list.add('Microsoft Edge');
      if (output.contains('brave.exe')) list.add('Brave Browser');
      if (output.contains('firefox.exe')) list.add('Mozilla Firefox');
      if (output.contains('opera.exe')) list.add('Opera');
    } catch (_) {}

    if (list.isEmpty) list.add('Standard Browser');
    return list;
  }

  void _confirmRemoveAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text('Remove All Custom Domains?'),
          ],
        ),
        content: Text(
          'Are you sure you want to remove all ${widget.blockedDomains.length} custom blocked domains? Prebuilt packs will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onRemoveAllDomains();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Extension & Browser Connectivity Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (_isServiceOnline ? Colors.green : Colors.amber).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isServiceOnline ? Icons.extension : Icons.extension_off,
                                color: _isServiceOnline ? Colors.green : Colors.amber.shade800,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Browser Extension Connectivity',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isServiceOnline
                                      ? 'Guardian HTTP API Active on 127.0.0.1:48192'
                                      : 'Standalone extension mode / Service offline',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isServiceOnline ? Colors.green.shade800 : Colors.grey.shade700,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isServiceOnline ? Colors.greenAccent : Colors.amber,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isServiceOnline ? 'CONNECTED' : 'DISCONNECTED',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Connected Browsers & Policy Status Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Syncing Browsers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _detectedBrowsers.map((b) {
                                  final isChromeOrEdge = b.contains('Chrome') || b.contains('Edge');
                                  return Chip(
                                    avatar: Icon(
                                      isChromeOrEdge ? Icons.language : Icons.public,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                    label: Text(b, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                                    side: BorderSide.none,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Tamper Protection Policy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Chip(
                              avatar: Icon(
                                _isEnforced ? Icons.lock : Icons.lock_open,
                                size: 14,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isEnforced ? 'POLICY ENFORCED' : 'STANDARD',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              backgroundColor: _isEnforced ? Colors.purple.shade700 : Colors.grey.shade600,
                              side: BorderSide.none,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Filter Packs & Domain Blocks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Adult Content Pack', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Blocks 50,000+ inappropriate websites offline.'),
                    value: widget.adultBlockActive,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => widget.onToggleAdultPack(val ?? false),
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Social Media Pack', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Blocks Facebook, Instagram, Twitter, etc.'),
                    value: widget.socialBlockActive,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (val) => widget.onToggleSocialPack(val ?? false),
                  ),
                )
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Custom Domain Blacklist',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (widget.blockedDomains.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmRemoveAll(context),
                    icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                    label: const Text('Clear All Domains', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.domainInputController,
                    decoration: InputDecoration(
                      hintText: 'e.g. reddit.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onSubmitted: (_) => widget.onAddDomain(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: widget.onAddDomain,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Domain'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: (widget.blockedDomains.length * 60.0).clamp(150.0, 400.0),
              child: widget.blockedDomains.isEmpty
                  ? const Center(child: Text('No custom domains blocked.'))
                  : ListView.builder(
                      itemCount: widget.blockedDomains.length > 100 ? 100 : widget.blockedDomains.length,
                      itemBuilder: (context, index) {
                        final domain = widget.blockedDomains[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: Icon(
                              Icons.public,
                              color: theme.colorScheme.secondary,
                            ),
                            title: Text(domain),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => widget.onRemoveDomain(domain),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
