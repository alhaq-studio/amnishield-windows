import 'package:flutter/material.dart';
import '../../services/app_discovery_service.dart';
import '../../services/app_usage_service.dart';
import '../../widgets/app_icon_widget.dart';

class UsageTabWidget extends StatefulWidget {
  final bool isUsageTrackerEnabled;
  final ValueChanged<bool> onToggleUsageTracker;

  const UsageTabWidget({
    super.key,
    required this.isUsageTrackerEnabled,
    required this.onToggleUsageTracker,
  });

  @override
  State<UsageTabWidget> createState() => _UsageTabWidgetState();
}

class _UsageTabWidgetState extends State<UsageTabWidget> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchFilter = '';
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchFilter = _searchController.text.trim().toLowerCase();
      });
    });
    AppUsageService.usageUpdateNotifier.addListener(_onUsageUpdated);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _subTabController.dispose();
    AppUsageService.usageUpdateNotifier.removeListener(_onUsageUpdated);
    super.dispose();
  }

  void _onUsageUpdated() {
    if (mounted) setState(() {});
  }

  String _formatSeconds(int seconds) {
    if (seconds <= 0) return '0m';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${mins}m';
    return '${mins}m';
  }

  Future<void> _showSetLimitDialog(String appExe) async {
    final TextEditingController customController = TextEditingController(text: '60');

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.alarm_add, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(child: Text('Set Daily Limit for $appExe', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'When daily screen time exceeds this limit, AmnShield will automatically block and close the app for the rest of the day.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 30, 45, 60, 90, 120, 180].map((mins) {
                      return ActionChip(
                        label: Text('${mins}m'),
                        onPressed: () {
                          setDialogState(() {
                            customController.text = '$mins';
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Custom Limit (Minutes per day)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    await AppUsageService.removeAppLimit(appExe);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Remove Limit', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final mins = int.tryParse(customController.text.trim()) ?? 0;
                    if (mins > 0) {
                      await AppUsageService.setAppLimit(appExe, mins);
                    }
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Limit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAppSelectorForLimit() async {
    final installed = await AppDiscoveryService.getInstalledApps();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = installed.where((item) {
              if (filter.isEmpty) return true;
              return item.name.toLowerCase().contains(filter) ||
                  item.executable.toLowerCase().contains(filter);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Select Application for Time Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search installed applications...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          filter = val.trim().toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            leading: AppIconWidget(
                              executable: item.executable,
                              displayName: item.name,
                              path: item.path,
                            ),
                            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(item.executable, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showSetLimitDialog(item.executable);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Set Limit'),
                            ),
                          );
                        },
                      ),
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final usageList = AppUsageService.getAllUsageLimits();
    final webStats = AppUsageService.getWebUsageStats();

    int totalAppSeconds = 0;
    int totalWebSeconds = 0;
    int limitedAppsCount = 0;
    int exceededAppsCount = 0;

    for (final item in usageList) {
      totalAppSeconds += item.usedSeconds;
      if (item.limitMinutes > 0) limitedAppsCount++;
      if (item.isExceeded) exceededAppsCount++;
    }
    for (final w in webStats) {
      totalWebSeconds += w.usedSeconds;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master Switch Card — always fully visible and interactive
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isUsageTrackerEnabled
                            ? Colors.purple.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.timer_outlined,
                        size: 32,
                        color: widget.isUsageTrackerEnabled ? Colors.purple : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'App Usage Tracker & Time Limits Engine',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.isUsageTrackerEnabled
                                ? 'Monitoring active app screen time and enforcing daily usage time limits.'
                                : 'Usage tracking is paused. App limits will not be enforced.',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: widget.isUsageTrackerEnabled,
                      activeThumbColor: theme.colorScheme.primary,
                      onChanged: widget.onToggleUsageTracker,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Everything below greyed out when tracker is off
            Opacity(
              opacity: widget.isUsageTrackerEnabled ? 1.0 : 0.45,
              child: AbsorbPointer(
                absorbing: !widget.isUsageTrackerEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily Usage Overview Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: 'App Screen Time',
                            value: _formatSeconds(totalAppSeconds),
                            subtitle: '${usageList.length} apps tracked today',
                            icon: Icons.apps,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: 'Web Browse Time',
                            value: _formatSeconds(totalWebSeconds),
                            subtitle: '${webStats.length} sites visited',
                            icon: Icons.language,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: 'Limits Active',
                            value: '$limitedAppsCount / $exceededAppsCount',
                            subtitle: 'Active / Exceeded today',
                            icon: Icons.alarm,
                            color: exceededAppsCount > 0 ? Colors.red : Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Sub TabBar: App Usage | Website Usage
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _subTabController,
                            indicatorColor: theme.colorScheme.primary,
                            labelColor: theme.colorScheme.primary,
                            unselectedLabelColor: Colors.grey,
                            indicatorWeight: 3,
                            onTap: (_) => setState(() {}),
                            tabs: const [
                              Tab(icon: Icon(Icons.apps), text: 'App Screen Time'),
                              Tab(icon: Icon(Icons.language), text: 'Website Usage'),
                            ],
                          ),
                          const Divider(height: 1),
                          SizedBox(
                            height: _subTabController.index == 0
                                ? (usageList.isEmpty ? 200 : (usageList.length * 100.0).clamp(200, 600))
                                : (webStats.isEmpty ? 200 : (webStats.length * 80.0).clamp(200, 600)),
                            child: TabBarView(
                              controller: _subTabController,
                              children: [
                                // App Screen Time Tab
                                _buildAppUsageView(context, usageList, totalAppSeconds),
                                // Website Usage Tab
                                _buildWebUsageView(context, webStats, totalWebSeconds),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Add Limit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showAppSelectorForLimit,
                        icon: const Icon(Icons.add_alarm),
                        label: const Text('Add Custom App Time Limit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageView(BuildContext context, List<AppUsageLimit> usageList, int totalSeconds) {
    final theme = Theme.of(context);
    final filteredList = usageList.where((item) {
      if (_searchFilter.isEmpty) return true;
      return item.executable.toLowerCase().contains(_searchFilter);
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No app usage recorded today yet.', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Launch desktop apps to begin tracking.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          if (usageList.length > 3)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tracked apps (${usageList.length})...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                final appName = item.executable.replaceAll('.exe', '');
                final fraction = totalSeconds > 0 ? item.usedSeconds / totalSeconds : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      AppIconWidget(executable: item.executable, displayName: appName),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.executable,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (item.isExceeded)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('EXCEEDED', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                        )
                                      else if (item.limitMinutes > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('${item.limitMinutes}m/day', style: const TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _formatSeconds(item.usedSeconds),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.primary),
                                    ),
                                    Text(
                                      ' (${(fraction * 100).toStringAsFixed(0)}%)',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: item.limitMinutes > 0 ? item.progress : fraction,
                                backgroundColor: Colors.grey.shade200,
                                color: item.isExceeded
                                    ? Colors.red
                                    : (item.limitMinutes > 0 && item.progress > 0.8
                                        ? Colors.orange
                                        : Colors.purple.shade400),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(item.limitMinutes > 0 ? Icons.edit : Icons.alarm_add, size: 18, color: Colors.grey),
                        tooltip: item.limitMinutes > 0 ? 'Edit Limit' : 'Set Limit',
                        onPressed: () => _showSetLimitDialog(item.executable),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebUsageView(BuildContext context, List<WebUsageStat> webStats, int totalSeconds) {

    if (webStats.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.language, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No web browsing data recorded today.', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Website tracking updates from browser extension sync.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    // Color palette for bar chart
    final barColors = [
      Colors.blue.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade500,
      Colors.cyan.shade600,
      Colors.purple.shade400,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.pink.shade400,
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: webStats.length,
              itemBuilder: (context, index) {
                final stat = webStats[index];
                final fraction = totalSeconds > 0 ? stat.usedSeconds / totalSeconds : 0.0;
                final barColor = barColors[index % barColors.length];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: barColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.language, color: barColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    stat.domain,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _formatSeconds(stat.usedSeconds),
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: barColor),
                                    ),
                                    Text(
                                      ' (${(fraction * 100).toStringAsFixed(0)}%)',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: fraction,
                                backgroundColor: Colors.grey.shade200,
                                color: barColor,
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
