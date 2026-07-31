import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/app_discovery_service.dart';
import '../../widgets/app_icon_widget.dart';

class AppBlockerTab extends StatefulWidget {
  final List<String> blockedApps;
  final List<String> customWhitelist;
  final TextEditingController appInputController;
  final ValueChanged<String> onAddApp;
  final ValueChanged<String> onRemoveApp;
  final ValueChanged<String> onAddWhitelistApp;
  final ValueChanged<String> onRemoveWhitelistApp;

  const AppBlockerTab({
    super.key,
    required this.blockedApps,
    required this.customWhitelist,
    required this.appInputController,
    required this.onAddApp,
    required this.onRemoveApp,
    required this.onAddWhitelistApp,
    required this.onRemoveWhitelistApp,
  });

  @override
  State<AppBlockerTab> createState() => _AppBlockerTabState();
}

class _AppBlockerTabState extends State<AppBlockerTab> {
  final TextEditingController _searchFilterController = TextEditingController();
  String _searchFilter = '';
  int _selectedViewIndex = 0; // 0 = Banned Apps, 1 = Allowed Apps / Exceptions

  @override
  void initState() {
    super.initState();
    _searchFilterController.addListener(() {
      setState(() {
        _searchFilter = _searchFilterController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchFilterController.dispose();
    super.dispose();
  }

  Future<void> _pickExeFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exe'],
        dialogTitle: _selectedViewIndex == 0
            ? 'Select Application Executable (.exe) to Block'
            : 'Select Application Executable (.exe) to Allow/Whitelist',
      );

      if (result != null && result.files.single.name.isNotEmpty) {
        String exeName = result.files.single.name.toLowerCase();
        if (_selectedViewIndex == 0) {
          widget.onAddApp(exeName);
        } else {
          widget.onAddWhitelistApp(exeName);
        }
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
    }
  }

  Future<void> _showAppPickerModal() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _AppPickerModalDialog(
          blockedApps: widget.blockedApps,
          customWhitelist: widget.customWhitelist,
          onSelectBlockApp: (exeName) {
            widget.onAddApp(exeName);
          },
          onSelectWhitelistApp: (exeName) {
            widget.onAddWhitelistApp(exeName);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBannedTab = _selectedViewIndex == 0;
    final currentList = isBannedTab ? widget.blockedApps : widget.customWhitelist;

    final filteredApps = currentList.where((app) {
      if (_searchFilter.isEmpty) return true;
      return app.toLowerCase().contains(_searchFilter);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Mode Toggle Segment
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isBannedTab ? 'Banned Applications' : 'Allowed Applications (Whitelist)',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBannedTab
                          ? 'Select installed applications, running processes, or browse .exe files to block execution.'
                          : 'Applications added to the Whitelist are trusted and will NEVER be blocked or killed by AmnShield.',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Segmented Button Mode Selector
              SegmentedButton<int>(
                segments: [
                  ButtonSegment<int>(
                    value: 0,
                    label: Text('Banned (${widget.blockedApps.length})'),
                    icon: const Icon(Icons.block, size: 16),
                  ),
                  ButtonSegment<int>(
                    value: 1,
                    label: Text('Allowed (${widget.customWhitelist.length})'),
                    icon: const Icon(Icons.verified_user_outlined, size: 16),
                  ),
                ],
                selected: {_selectedViewIndex},
                onSelectionChanged: (Set<int> newSelection) {
                  setState(() {
                    _selectedViewIndex = newSelection.first;
                    _searchFilterController.clear();
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Control Toolbar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.appInputController,
                  decoration: InputDecoration(
                    hintText: isBannedTab
                        ? 'e.g. discord, chrome, epicgames'
                        : 'e.g. rg.exe, python, my_server',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      if (isBannedTab) {
                        widget.onAddApp(val.trim());
                      } else {
                        widget.onAddWhitelistApp(val.trim());
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final text = widget.appInputController.text.trim();
                  if (text.isNotEmpty) {
                    if (isBannedTab) {
                      widget.onAddApp(text);
                    } else {
                      widget.onAddWhitelistApp(text);
                    }
                  }
                },
                icon: Icon(isBannedTab ? Icons.add : Icons.shield),
                label: Text(isBannedTab ? 'Add Banned' : 'Add Exception'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBannedTab
                      ? Theme.of(context).colorScheme.primary
                      : Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showAppPickerModal,
                icon: const Icon(Icons.apps),
                label: const Text('App Selector'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickExeFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Browse .exe'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search Filter for Applications List
          if (currentList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                controller: _searchFilterController,
                decoration: InputDecoration(
                  hintText: 'Search ${isBannedTab ? "banned" : "allowed"} apps list (${currentList.length})...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchFilter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchFilterController.clear(),
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          // Applications List View
          Expanded(
            child: currentList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isBannedTab ? Icons.app_blocking_outlined : Icons.verified_user_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isBannedTab
                              ? 'No applications banned yet.'
                              : 'No whitelist exceptions added yet.',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isBannedTab
                              ? 'Click "App Selector" above to choose apps to block.'
                              : 'Click "App Selector" or "Add Exception" to whitelist trusted apps.',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : filteredApps.isEmpty
                    ? const Center(child: Text('No matching applications found.'))
                    : ListView.builder(
                        itemCount: filteredApps.length,
                        itemBuilder: (context, index) {
                          final app = filteredApps[index];
                          final appName = app.replaceAll('.exe', '');
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: AppIconWidget(
                                executable: app,
                                displayName: appName,
                                isWhitelisted: !isBannedTab,
                              ),
                              title: Text(app, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                isBannedTab ? 'Banned Execution' : 'Trusted Exception (Allowed)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isBannedTab ? Colors.red : Colors.green.shade700,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  if (isBannedTab) {
                                    widget.onRemoveApp(app);
                                  } else {
                                    widget.onRemoveWhitelistApp(app);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}

class _AppPickerModalDialog extends StatefulWidget {
  final List<String> blockedApps;
  final List<String> customWhitelist;
  final ValueChanged<String> onSelectBlockApp;
  final ValueChanged<String> onSelectWhitelistApp;

  const _AppPickerModalDialog({
    required this.blockedApps,
    required this.customWhitelist,
    required this.onSelectBlockApp,
    required this.onSelectWhitelistApp,
  });

  @override
  State<_AppPickerModalDialog> createState() => _AppPickerModalDialogState();
}

class _AppPickerModalDialogState extends State<_AppPickerModalDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _filterController = TextEditingController();

  List<AppItem> _installedApps = [];
  List<AppItem> _runningApps = [];
  bool _loadingInstalled = true;
  bool _loadingRunning = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filterController.addListener(() {
      setState(() {
        _filter = _filterController.text.trim().toLowerCase();
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    AppDiscoveryService.getInstalledApps().then((installed) {
      if (mounted) {
        setState(() {
          _installedApps = installed;
          _loadingInstalled = false;
        });
      }
    });

    AppDiscoveryService.getRunningApps().then((running) {
      if (mounted) {
        setState(() {
          _runningApps = running;
          _loadingRunning = false;
        });
      }
    });
  }

  List<AppItem> _getFilteredList(List<AppItem> list) {
    if (_filter.isEmpty) return list;
    return list.where((item) {
      return item.name.toLowerCase().contains(_filter) ||
          item.executable.toLowerCase().contains(_filter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.apps_outage, size: 28),
                SizedBox(width: 12),
                Text('Application Selector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _filterController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search installed or running applications...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [
                Tab(
                  icon: const Icon(Icons.widgets_outlined, size: 20),
                  text: 'Installed Apps (${_installedApps.length})',
                ),
                Tab(
                  icon: const Icon(Icons.bolt, size: 20),
                  text: 'Running Apps (${_runningApps.length})',
                ),
              ],
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 580,
        height: 380,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAppListView(
              isLoading: _loadingInstalled,
              items: _getFilteredList(_installedApps),
              emptyMessage: 'No installed apps found.',
            ),
            _buildAppListView(
              isLoading: _loadingRunning,
              items: _getFilteredList(_runningApps),
              emptyMessage: 'No running desktop apps found.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildAppListView({
    required bool isLoading,
    required List<AppItem> items,
    required String emptyMessage,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isBanned = widget.blockedApps.contains(item.executable);
        final isWhitelisted = widget.customWhitelist.contains(item.executable);

        return ListTile(
          leading: AppIconWidget(
            executable: item.executable,
            displayName: item.name,
            path: item.path,
            isWhitelisted: isWhitelisted,
          ),
          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(item.executable, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWhitelisted)
                const Chip(
                  label: Text('Whitelisted', style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Colors.green,
                  side: BorderSide.none,
                )
              else
                OutlinedButton.icon(
                  onPressed: () {
                    widget.onSelectWhitelistApp(item.executable);
                    setState(() {});
                  },
                  icon: const Icon(Icons.shield_outlined, size: 14, color: Colors.green),
                  label: const Text('Allow', style: TextStyle(fontSize: 12, color: Colors.green)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
              const SizedBox(width: 8),
              if (isBanned)
                const Chip(
                  label: Text('Banned', style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Colors.red,
                  side: BorderSide.none,
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    widget.onSelectBlockApp(item.executable);
                    setState(() {});
                  },
                  icon: const Icon(Icons.block, size: 14),
                  label: const Text('Block', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
